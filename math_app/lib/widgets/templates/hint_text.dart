import 'dart:ui' show Color;

/// Colour of the small instructional hint lines in the template widgets
/// (e.g. "Tippe auf ein Stäbchen, um 10 zu bündeln.").
///
/// Chosen for WCAG AA contrast on the app's light surface: 0xFF424242
/// (Material grey 850) is ≈ 12:1 on white, comfortably above the 4.5:1
/// minimum for normal text (the previous Colors.black54 was a borderline
/// ≈ 4.6:1). The practice-screen error-taxonomy hint already uses the
/// theme's primary colour, which sits at ≈ 10:1 on the surface.
const Color kHintTextColor = Color(0xFF424242);
