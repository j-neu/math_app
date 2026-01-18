import 'package:flutter/material.dart';

class WendeplaettchenWidget extends StatelessWidget {
  final Color color;
  final double size;
  final VoidCallback? onTap;
  final bool isFlipped; // For visual 3D effect if needed

  const WendeplaettchenWidget({
    Key? key,
    required this.color,
    this.size = 40.0,
    this.onTap,
    this.isFlipped = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: Colors.black12,
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 2,
              offset: Offset(0, 2),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.9),
              color,
              color.withOpacity(0.8),
            ],
          ),
        ),
        // Add a slight inner bevel effect
        child: Container(
          margin: EdgeInsets.all(size * 0.1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
