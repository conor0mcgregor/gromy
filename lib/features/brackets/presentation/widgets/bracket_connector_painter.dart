import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  BracketConnectorPainter  ·  Widget
//
//  CustomPainter que dibuja las líneas de conexión entre rounds
//  en el bracket visual. Conecta la salida (derecha) de un match con
//  la entrada (izquierda) del match hijo en el siguiente round.
// ─────────────────────────────────────────────────────────────────────────────

class BracketConnectorPainter extends CustomPainter {
  const BracketConnectorPainter({
    required this.matchPositions,
    required this.connections,
    this.lineColor,
    this.lineWidth = 1.5,
    this.completedConnections = const {},
  });

  /// Mapa de matchId → rectángulo del match card.
  final Map<String, Rect> matchPositions;

  /// Mapa de matchId (padre) → matchId (hijo).
  final Map<String, String> connections;

  /// Set de conexiones que representan ganadores (para colorear).
  final Set<String> completedConnections;

  /// Color base de las líneas.
  final Color? lineColor;

  /// Grosor de las líneas.
  final double lineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final defaultColor = lineColor ?? Colors.white.withValues(alpha: 0.12);
    final winnerColor = const Color(0xFF22C55E).withValues(alpha: 0.4);

    for (final entry in connections.entries) {
      final parentId = entry.key;
      final childId = entry.value;

      final parentRect = matchPositions[parentId];
      final childRect = matchPositions[childId];

      if (parentRect == null || childRect == null) continue;

      final isCompleted = completedConnections.contains(parentId);

      final paint = Paint()
        ..color = isCompleted ? winnerColor : defaultColor
        ..strokeWidth = isCompleted ? lineWidth + 0.5 : lineWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // La salida es el centro derecho del padre
      final startX = parentRect.right;
      final startY = parentRect.center.dy;
      
      // La entrada es el centro izquierdo del hijo
      final endX = childRect.left;
      final endY = childRect.center.dy;

      // Dibujar conexión con curva suave (estilo bracket profesional)
      final midX = (startX + endX) / 2;

      final path = Path()
        ..moveTo(startX, startY)
        ..lineTo(midX, startY)
        ..lineTo(midX, endY)
        ..lineTo(endX, endY);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BracketConnectorPainter oldDelegate) {
    return oldDelegate.matchPositions != matchPositions ||
        oldDelegate.connections != connections ||
        oldDelegate.completedConnections != completedConnections;
  }
}
