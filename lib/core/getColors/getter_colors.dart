import 'dart:ui';

Color sportColor(dynamic sport) {
  // Devuelve un color distinto por deporte para el borde izquierdo
  final name = sport.label.toLowerCase();
  if (name.contains('futbol')) return const Color(0xFF4961DD);
  if (name.contains('baloncesto')) return const Color(0xFFFFB347);
  if (name.contains('voleibol')) return const Color(0xFFD627F5);
  if (name.contains('tenis')) return const Color(0xFF44C831);
  if (name.contains('padel')) return const Color(0xFFFF6B9D);
  if (name.contains('karate')) {
    return const Color(0xFFB0A8FF);
  }
  return const Color(0xFFB10F0F);
}

Color occupancyColor(double occupancy) {
  if (occupancy >= 0.8) return const Color(0xFFFF4D6A);
  if (occupancy >= 0.6) return const Color(0xFFFFB347);
  return const Color(0xFF22C55E);
}

//boton gradiente
enum GradientButtonVariant {
  /// Violeta → cian  (por defecto, ideal para acciones principales)
  violet(
    colors: [Color(0xFF6C63FF), Color(0xFFA855F7), Color(0xFF00D4FF)],
    shadowColor: Color(0xFF6C63FF),
  ),

  /// Naranja → rosa → violeta  (energético, CTA destacado)
  sunset(
    colors: [Color(0xFFF97316), Color(0xFFEC4899), Color(0xFF8B5CF6)],
    shadowColor: Color(0xFFEC4899),
  ),

  /// Cian → azul → índigo  (tecnológico, confianza)
  ocean(
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6), Color(0xFF6366F1)],
    shadowColor: Color(0xFF3B82F6),
  ),

  /// Verde esmeralda → lima  (éxito, confirmación)
  forest(
    colors: [Color(0xFF10B981), Color(0xFF22C55E), Color(0xFF84CC16)],
    shadowColor: Color(0xFF10B981),
  ),

  danger(
    colors: [Color(0xFFFF0000), Color(0xFFD60000), Color(0xFFD60039)],
    shadowColor: Color(0xFFFF8A8A),
  ),

  select(
    colors: [Color(0xFF00A393), Color(0xFF00A341), Color(0xFF1000A3)],
    shadowColor: Color(0xFF958AFF),
  );



  const GradientButtonVariant({
    required this.colors,
    required this.shadowColor,
  });

  final List<Color> colors;
  final Color shadowColor;
}