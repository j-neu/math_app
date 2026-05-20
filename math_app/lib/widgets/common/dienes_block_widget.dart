import 'package:flutter/material.dart';

enum DienesType { unit, rod, plate, largeCube }

/// Isometric Dienes base-10 block.
///
/// | type       | dims      | German      |
/// |------------|-----------|-------------|
/// | unit       | 1×1×1     | Einer       |
/// | rod        | 10×1×1    | Zehner      |
/// | plate      | 10×10×1   | Hunderter   |
/// | largeCube  | 10×10×10  | Tausender   |
///
/// [cellSize] is the isometric unit in logical pixels.
/// The widget auto-sizes to its bounding box.
class DienesBlockWidget extends StatelessWidget {
  final DienesType type;
  final double cellSize;
  final Color? color;

  static const _unitColor = Color(0xFF43A047);
  static const _rodColor = Color(0xFF1E88E5);
  static const _plateColor = Color(0xFFE53935);
  static const _largeCubeColor = Color(0xFF388E3C);

  const DienesBlockWidget({
    super.key,
    required this.type,
    this.cellSize = 20,
    this.color,
  });

  Color get _defaultColor => switch (type) {
        DienesType.unit => _unitColor,
        DienesType.rod => _rodColor,
        DienesType.plate => _plateColor,
        DienesType.largeCube => _largeCubeColor,
      };

  (int, int, int) get _dims => switch (type) {
        DienesType.unit => (1, 1, 1),
        DienesType.rod => (10, 1, 1),
        DienesType.plate => (10, 10, 1),
        DienesType.largeCube => (10, 10, 10),
      };

  @override
  Widget build(BuildContext context) {
    const sqrt3 = 1.7320508;
    final hx = cellSize * sqrt3 / 2;
    final hy = cellSize * 0.5;
    final (nx, ny, nz) = _dims;

    return CustomPaint(
      size: Size(
        (nx + ny) * hx + 2,
        (nx + ny) * hy + nz * cellSize + 2,
      ),
      painter: _DienesBlockPainter(
        nx: nx,
        ny: ny,
        nz: nz,
        cellSize: cellSize,
        color: color ?? _defaultColor,
      ),
    );
  }
}

class _DienesBlockPainter extends CustomPainter {
  final int nx, ny, nz;
  final double cellSize;
  final Color color;

  static const double _sqrt3 = 1.7320508;

  const _DienesBlockPainter({
    required this.nx,
    required this.ny,
    required this.nz,
    required this.cellSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hx = cellSize * _sqrt3 / 2;
    final hy = cellSize * 0.5;
    final u = cellSize;

    // A = back-top corner, shifted right by ny*hx so left edge lands at x=1
    final origin = Offset(ny * hx + 1, 1.0);

    Offset pt(double dx, double dy) => origin + Offset(dx, dy);

    // 8 corners of the block
    final A = pt(0, 0);
    final B = pt(nx * hx, nx * hy);
    final C = pt((nx - ny) * hx, (nx + ny) * hy);
    final D = pt(-ny * hx, ny * hy);
    final F = B + Offset(0, nz * u);
    final G = C + Offset(0, nz * u);
    final H = D + Offset(0, nz * u);

    final hsl = HSLColor.fromColor(color);
    final topColor =
        hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();
    final leftColor =
        hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();

    final border = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final grid = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Paint order: left → right → top (painter's algorithm)
    _fillFace(canvas, [D, C, G, H], leftColor, border);
    _fillFace(canvas, [B, C, G, F], color, border);
    _fillFace(canvas, [A, B, C, D], topColor, border);

    _drawGridTop(canvas, grid, hx, hy, origin);
    _drawGridRight(canvas, grid, hx, hy, u, B, C, F);
    _drawGridLeft(canvas, grid, hx, hy, u, D, C, H);
  }

  void _fillFace(
      Canvas canvas, List<Offset> pts, Color c, Paint border) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = c);
    canvas.drawPath(path, border);
  }

  // Grid on top face: nx-1 lines parallel to AD, ny-1 lines parallel to AB
  void _drawGridTop(
      Canvas canvas, Paint p, double hx, double hy, Offset origin) {
    for (int i = 1; i < ny; i++) {
      canvas.drawLine(
        origin + Offset(-i * hx, i * hy),
        origin + Offset((nx - i) * hx, (nx + i) * hy),
        p,
      );
    }
    for (int i = 1; i < nx; i++) {
      canvas.drawLine(
        origin + Offset(i * hx, i * hy),
        origin + Offset((i - ny) * hx, (i + ny) * hy),
        p,
      );
    }
  }

  // Grid on right face (B→C depth, B→F height)
  void _drawGridRight(Canvas canvas, Paint p, double hx, double hy, double u,
      Offset B, Offset C, Offset F) {
    for (int i = 1; i < ny; i++) {
      final shift = Offset(-i * hx, i * hy);
      canvas.drawLine(B + shift, F + shift, p);
    }
    for (int i = 1; i < nz; i++) {
      final drop = Offset(0, i * u);
      canvas.drawLine(B + drop, C + drop, p);
    }
  }

  // Grid on left face (D→C width, D→H height)
  void _drawGridLeft(Canvas canvas, Paint p, double hx, double hy, double u,
      Offset D, Offset C, Offset H) {
    for (int i = 1; i < nx; i++) {
      final shift = Offset(i * hx, i * hy);
      canvas.drawLine(D + shift, H + shift, p);
    }
    for (int i = 1; i < nz; i++) {
      final drop = Offset(0, i * u);
      canvas.drawLine(D + drop, C + drop, p);
    }
  }

  @override
  bool shouldRepaint(_DienesBlockPainter old) =>
      old.nx != nx ||
      old.ny != ny ||
      old.nz != nz ||
      old.cellSize != cellSize ||
      old.color != color;
}
