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
  // ==========================================
  // 🌌 CÓSMICAS & MÍSTICAS
  // ==========================================

  /// Aurora boreal: Verde → Turquesa → Púrpura
  aurora(
    colors: [Color(0xFF00F5A0), Color(0xFF00D9F5), Color(0xFF9D4EDD)],
    shadowColor: Color(0xFF7B2FF7),
  ),

  /// Nebulosa: Rosa intenso → Naranja cósmico → Azul estelar
  nebula(
    colors: [Color(0xFFFF006E), Color(0xFFFF7B00), Color(0xFF3A0CA3)],
    shadowColor: Color(0xFF7209B7),
  ),

  /// Eclipse: Dorado → Ámbar → Negro azulado
  eclipse(
    colors: [Color(0xFFFFD700), Color(0xFFFF8C00), Color(0xFF1A1B41)],
    shadowColor: Color(0xFFB8860B),
  ),

  /// Luna mística: Plata → Lavanda → Índigo profundo
  mysticMoon(
    colors: [Color(0xFFE2E2E2), Color(0xFFB8A9C9), Color(0xFF2D1B69)],
    shadowColor: Color(0xFF6B5B95),
  ),

  // ==========================================
  // 🍹 TROPICALES & VIBRANTES
  // ==========================================

  /// Sunset tropical: Mandarina → Coral → Fucsia
  tropicalSunset(
    colors: [Color(0xFFFF6B35), Color(0xFFFF4757), Color(0xFFD81159)],
    shadowColor: Color(0xFFFF4757),
  ),

  /// Piña colada: Amarillo tropical → Naranja → Verde caribeño
  pinacolada(
    colors: [Color(0xFFFEDC5E), Color(0xFFF7931E), Color(0xFF00B4D8)],
    shadowColor: Color(0xFFF7931E),
  ),

  /// Arrecife: Coral vivo → Turquesa → Azul profundo
  reef(
    colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFF1A535C)],
    shadowColor: Color(0xFFFF6B6B),
  ),

  /// Sandía: Verde → Rojo sandía → Rosa
  watermelon(
    colors: [Color(0xFF45B649), Color(0xFFFF416C), Color(0xFFFF6B9D)],
    shadowColor: Color(0xFFFF416C),
  ),

  // ==========================================
  // 🎨 ARTÍSTICAS & RETRO
  // ==========================================

  /// Memphis design: Rosa neón → Amarillo → Azul eléctrico
  memphis(
    colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D), Color(0xFF4ECDC4)],
    shadowColor: Color(0xFFFF6B6B),
  ),

  /// Synthwave: Rosa neón → Cian → Púrpura oscuro
  synthwave(
    colors: [Color(0xFFFF007F), Color(0xFF00F0FF), Color(0xFF2D00F7)],
    shadowColor: Color(0xFFFF007F),
  ),

  /// Vaporwave: Rosa pastel → Azul glaciar → Púrpura suave
  vaporwave(
    colors: [Color(0xFFFF71CE), Color(0xFF01CDFE), Color(0xFFB967FF)],
    shadowColor: Color(0xFFFF71CE),
  ),

  /// Cómic retro: Rojo intenso → Amarillo → Azul primario
  comicPop(
    colors: [Color(0xFFE63946), Color(0xFFFFD166), Color(0xFF118AB2)],
    shadowColor: Color(0xFFE63946),
  ),

  // ==========================================
  // 🌿 NATURALEZA & ORGÁNICO
  // ==========================================

  /// Miel: Ámbar → Dorado → Marrón cálido
  honey(
    colors: [Color(0xFFFFB347), Color(0xFFFFD700), Color(0xFFD2691E)],
    shadowColor: Color(0xFFD2691E),
  ),

  /// Lavanda: Púrpura suave → Rosa → Verde menta
  lavender(
    colors: [Color(0xFF9B72AA), Color(0xFFC86B98), Color(0xFF98D8C8)],
    shadowColor: Color(0xFF9B72AA),
  ),

  /// Terracota: Terracota → Arena → Verde oliva
  terracotta(
    colors: [Color(0xFFE2725B), Color(0xFFF4A261), Color(0xFF90A955)],
    shadowColor: Color(0xFFE2725B),
  ),

  /// Musgo: Verde bosque → Verde lima → Marrón tierra
  moss(
    colors: [Color(0xFF2D6A4F), Color(0xFF52B788), Color(0xFFD4A373)],
    shadowColor: Color(0xFF2D6A4F),
  ),

  // ==========================================
  // 💎 LUJO & ELEGANCIA
  // ==========================================

  /// Champán rosado: Oro rosado → Champagne → Blanco perla
  roseChampagne(
    colors: [Color(0xFFD4A5A5), Color(0xFFF5E6CA), Color(0xFFFFF5E6)],
    shadowColor: Color(0xFFC49595),
  ),

  /// Zafiro real: Azul profundo → Azul real → Cian
  royalSapphire(
    colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
    shadowColor: Color(0xFF0F2027),
  ),

  /// Ónix nocturno: Negro → Gris carbón → Plata
  blackTie(
    colors: [Color(0xFF1A1A1A), Color(0xFF4A4A4A), Color(0xFFC0C0C0)],
    shadowColor: Color(0xFF1A1A1A),
  ),

  /// Esmeralda preciosa: Verde oscuro → Esmeralda → Jade brillante
  preciousEmerald(
    colors: [Color(0xFF004D40), Color(0xFF00BFA5), Color(0xFF64FFDA)],
    shadowColor: Color(0xFF004D40),
  ),

  // ==========================================
  // 🔥 ENERGÍA & ACCIÓN
  // ==========================================

  /// Fuego infernal: Rojo → Naranja → Amarillo intenso
  inferno(
    colors: [Color(0xFFD00000), Color(0xFFFF6B35), Color(0xFFFFF75E)],
    shadowColor: Color(0xFFD00000),
  ),

  /// Relámpago: Azul eléctrico → Blanco → Púrpura eléctrico
  lightning(
    colors: [Color(0xFF00D2FF), Color(0xFFF0F8FF), Color(0xFF9D4EDD)],
    shadowColor: Color(0xFF00D2FF),
  ),

  /// Energía cuántica: Verde neón → Amarillo → Cian brillante
  quantum(
    colors: [Color(0xFF39FF14), Color(0xFFFFF200), Color(0xFF00FFFF)],
    shadowColor: Color(0xFF39FF14),
  ),

  // ==========================================
  // 🎭 CONCEPTUALES & TEMÁTICOS
  // ==========================================

  /// Unicornio: Rosa → Púrpura → Turquesa (con brillo mágico)
  unicorn(
    colors: [Color(0xFFFF69B4), Color(0xFFBA55D3), Color(0xFF7B68EE)],
    shadowColor: Color(0xFFDA70D6),
  ),

  /// Cyberpunk: Amarillo neón → Magenta → Cian digital
  cyberpunk(
    colors: [Color(0xFFF7FF00), Color(0xFFFF00FF), Color(0xFF00FFFF)],
    shadowColor: Color(0xFFFF00FF),
  ),

  /// Galaxia: Azul profundo → Púrpura → Rosa galáctico
  galaxy(
    colors: [Color(0xFF1B1B4B), Color(0xFF6B2FA0), Color(0xFFFF69B4)],
    shadowColor: Color(0xFF6B2FA0),
  ),

  /// Fénix: Rojo carmesí → Naranja → Dorado brillante
  phoenix(
    colors: [Color(0xFFDC143C), Color(0xFFFF6B35), Color(0xFFFFD700)],
    shadowColor: Color(0xFFDC143C),
  ),

  // ==========================================
  // 🌈 GRADIENTES MODERNOS
  // ==========================================

  /// Neón pop: Verde neón → Rosa neón → Azul neón
  neonPop(
    colors: [Color(0xFF00FF87), Color(0xFFFF69B4), Color(0xFF60EFFF)],
    shadowColor: Color(0xFF00FF87),
  ),

  /// Pastel dream: Rosa suave → Azul bebé → Verde menta
  pastelDream(
    colors: [Color(0xFFFFB5C2), Color(0xFFB5D8FF), Color(0xFFB5FFB5)],
    shadowColor: Color(0xFFFFB5C2),
  ),

  /// Atardecer en París: Rosa polvo → Lavanda → Crema
  parisSunset(
    colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF), Color(0xFFFDFBFB)],
    shadowColor: Color(0xFFFF9A9E),
  ),

  // ==========================================
  // 🎯 ESTADOS & FUNCIONES ESPECIALES
  // ==========================================

  /// Premium/VIP: Dorado → Oro brillante → Champagne
  premium(
    colors: [Color(0xFFBF953F), Color(0xFFFCF6B5), Color(0xFFB38728)],
    shadowColor: Color(0xFFBF953F),
  ),

  /// Gaming: Verde gamer → Negro → Rojo
  gamer(
    colors: [Color(0xFF00FF00), Color(0xFF1A1A1A), Color(0xFFFF0044)],
    shadowColor: Color(0xFF00FF00),
  ),

  /// Navidad: Rojo navideño → Verde pino → Dorado festivo
  christmas(
    colors: [Color(0xFFC41E3A), Color(0xFF2D5F2D), Color(0xFFFFD700)],
    shadowColor: Color(0xFFC41E3A),
  ),

  // ==========================================
  // 🌊 SERENIDAD & CALMA
  // ==========================================

  /// Meditación: Azul cielo → Lavanda → Blanco
  zen(
    colors: [Color(0xFF7EC8E3), Color(0xFFC3B1E1), Color(0xFFF5F5F5)],
    shadowColor: Color(0xFF7EC8E3),
  ),

  /// Paraíso: Turquesa → Verde mar → Azul cielo
  paradise(
    colors: [Color(0xFF00B4DB), Color(0xFF0083B0), Color(0xFF00C9FF)],
    shadowColor: Color(0xFF00B4DB),
  ),

  paradiseGreen(
    colors: [Color(0xFF00DB6A), Color(0xFF00B084), Color(0xFF00FF9D)],
    shadowColor: Color(0xFF00DB4D),
  ),

  /// Cerezo en flor: Rosa pálido → Blanco → Verde primavera
  sakura(
    colors: [Color(0xFFFFB7C5), Color(0xFFFFF0F3), Color(0xFFC1E1C1)],
    shadowColor: Color(0xFFFFB7C5),
  ),

  // Los originales que ya tenías
  violet(
    colors: [Color(0xFF6C63FF), Color(0xFFA855F7), Color(0xFF00D4FF)],
    shadowColor: Color(0xFF6C63FF),
  ),
  sunset(
    colors: [Color(0xFFF97316), Color(0xFFEC4899), Color(0xFF8B5CF6)],
    shadowColor: Color(0xFFEC4899),
  ),
  ocean(
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6), Color(0xFF6366F1)],
    shadowColor: Color(0xFF3B82F6),
  ),
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
  ),
  simple(
    colors: [Color(0xFF97CFDB), Color(0xFF97DBB8), Color(0xFFC9DB97)],
    shadowColor: Color(0xFFE7E7E7),
  );

  const GradientButtonVariant({
    required this.colors,
    required this.shadowColor,
  });

  final List<Color> colors;
  final Color shadowColor;
}