import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../../core/widgets/static_location_map.dart';

class TournamentMapSection extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String location;
  final Color primaryColor;

  const TournamentMapSection({
    super.key,
    required this.location,
    required this.primaryColor,
    this.latitude,
    this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    final hasCoords = latitude != null && longitude != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section title ──
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Ubicación',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // ── Map (identical to step3 picker visually) ──
          if (hasCoords)
            StaticLocationMap(
              latitude: latitude!,
              longitude: longitude!,
              height: 280,
              zoom: 15.0,
              locationLabel: 'Ubicación seleccionada en el mapa.',
            ),

          if (hasCoords) const SizedBox(height: 12),

          // ── Address card ──
          _GlassCard(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.place_rounded,
                      color: primaryColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dirección',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        location,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.09),
              width: 1.1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
