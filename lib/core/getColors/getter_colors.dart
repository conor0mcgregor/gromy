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

//explandable_card
