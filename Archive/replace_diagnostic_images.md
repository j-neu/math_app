# Replace Diagnostic Photos with Flutter Widgets

**Goal:** Remove all `Image.asset()` calls for the 14 diagnostic pictures and replace them with generated Flutter widgets.

---

## 1. Already-built widgets (ready to use)

| Widget | File |
|---|---|
| `HundredFieldWidget(visibleCount)` | `widgets/common/hundred_field_widget.dart` |
| `DienesBlockWidget(type, cellSize)` | `widgets/common/dienes_block_widget.dart` |
| `RechenschiffchenWidget(topCount, bottomCount, topColor, bottomColor)` | `widgets/common/rechenschiffchen_widget.dart` |

---

## 2. New widget needed: `PatternDotsWidget`

Needed for the subitizing / Plättchen images (Q28–Q31, Q1–Q2).

```dart
PatternDotsWidget({
  required List<Offset> positions, // normalised 0..1
  required int count,
  double size = 280,
  Color dotColor = Colors.red,     // or green
})
```

Draws `count` filled circles at the given normalised positions inside a square canvas. No border (transparent background so it matches the page).

---

## 3. Image → widget mapping

### Hundred field (Q39–Q42)

| File | Widget call |
|---|---|
| `img1809.jpg` | `HundredFieldWidget(visibleCount: 100)` |
| `img1810.jpg` | `HundredFieldWidget(visibleCount: 12)` |
| `img1811.jpg` | `HundredFieldWidget(visibleCount: 85)` |
| `img1812.jpg` | `HundredFieldWidget(visibleCount: 99)` |

### Rechenschiffchen (Q32–Q35)

| File | Answer | Widget call |
|---|---|---|
| `img1888.jpg` | 9  | `RechenschiffchenWidget(topCount: 9, bottomCount: 0)` |
| `img1890.jpg` | 14 | `RechenschiffchenWidget(topCount: 9, bottomCount: 5)` |
| `img1889.jpg` | 19 | `RechenschiffchenWidget(topCount: 9, bottomCount: 10)` |
| `img1891.jpg` | 16 | `RechenschiffchenWidget(topCount: 8, bottomCount: 8)` |

All use `topColor: Colors.red, bottomColor: Colors.red`.

### Dienes (Q36–Q37)

These need a small helper `_buildDienesRow(rods, units)` built inline or as a private method — just a Row of `DienesBlockWidget` instances.

| File | Answer | Layout |
|---|---|---|
| `img1858.jpg` | 57 | 5× `DienesType.rod` + 7× `DienesType.unit`, cellSize 14 |
| `img1859.jpg` | 35 | 2× `DienesType.rod` + 15× `DienesType.unit`, cellSize 14 |

Wrap in a `Wrap` so units overflow to a second line naturally.

### Subitizing patterns — Plättchen (Q28–Q31)

Build `PatternDotsWidget` with hardcoded positions (normalised, mirroring the original photos):

| File | Count | Pattern description |
|---|---|---|
| `img1936.jpg` | 7 | 3 top row, 3 middle row, 1 centre bottom |
| `img1937.jpg` | 8 | 3×3 grid minus centre |
| `img1938.jpg` | 6 | 3 top, 2 middle, 1 bottom-centre |
| `img1939.jpg` | 10 | 3×3 grid + 1 to the right of row 2 |

### Scattered dots (Q1–Q2)

| File | Count | Color |
|---|---|---|
| `img2113.jpg` | 8  | green |
| `img2114.jpg` | 17 | green |

Use `PatternDotsWidget` with fixed pseudo-random positions (generated once, hardcoded). Positions must spread across the canvas without clustering.

---

## 4. Wiring it up in `diagnostic_screen.dart`

Modify `_buildImageWidget` to dispatch on filename before falling back to `Image.asset`:

```dart
Widget _buildImageWidget(DiagnosticQuestion question) {
  if (question.imagePath == null) return const SizedBox.shrink();

  final name = question.imagePath!.split('/').last;
  final override = _widgetForImage(name);
  if (override != null) return override;

  // existing Image.asset fallback (handles any remaining images)
  ...
}

Widget? _widgetForImage(String name) {
  switch (name) {
    case 'img1809.jpg': return HundredFieldWidget(visibleCount: 100, size: 280);
    case 'img1810.jpg': return HundredFieldWidget(visibleCount: 12,  size: 280);
    // ... etc.
    default: return null;
  }
}
```

No changes to the CSV or data model needed.

---

## 5. Order of work

1. Build `PatternDotsWidget` (~30 min)
2. Write `_widgetForImage` switch with all 14 entries (~20 min)
3. Verify each question visually in the diagnostic flow (~20 min)
4. Remove unused image assets from `pubspec.yaml` assets list if desired (optional)

---

## Questions to clarify before starting

- **img1858 / img1859 Dienes layout:** should the rods and ones be in separate columns (like the reference photo) or a flat `Wrap`? Answer: in Separate columns. 
- **img2113 / img2114 green dots:** should they match the original photo positions exactly, or is "plausible random scatter" acceptable? Answer: "plausible random scatter" is acceptable
- **Rechenschiffchen colour:** the originals appear to use a single colour for all filled slots — confirm red for all four questions. Answer: Yes
