import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../data/services/geocoding_service.dart';
import '../widgets/step_card.dart';
import '../widgets/form_fields.dart';
import '../widgets/form_helpers.dart';
import '../widgets/location_search_field.dart';

/// Paso 3 — Geolocalización: Autocompletado + mapa interactivo con pin.
class Step3Geolocation extends StatelessWidget {
  const Step3Geolocation({
    super.key,
    required this.locationController,
    required this.locationError,
    required this.latitude,
    required this.longitude,
    required this.suggestions,
    required this.isSearching,
    required this.onQueryChanged,
    required this.onSuggestionSelected,
    required this.onMapTap,
  });

  final TextEditingController locationController;
  final String? locationError;
  final double? latitude;
  final double? longitude;
  final List<GeocodingResult> suggestions;
  final bool isSearching;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<GeocodingResult> onSuggestionSelected;
  final void Function(double lat, double lng) onMapTap;

  @override
  Widget build(BuildContext context) {
    final hasCoords = latitude != null && longitude != null;
    final mapCenter = hasCoords
        ? LatLng(latitude!, longitude!)
        : const LatLng(28.1235, -15.4363); // Default: Las Palmas de GC

    return StepCard(
      icon: Icons.location_on_rounded,
      title: 'Geolocalización',
      subtitle:
          'Busca la dirección o haz tap en el mapa para colocar el marcador.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Buscador con autocompletado ──
          LocationSearchField(
            controller: locationController,
            errorText: locationError,
            suggestions: suggestions,
            isSearching: isSearching,
            onQueryChanged: onQueryChanged,
            onSuggestionSelected: onSuggestionSelected,
          ),
          const SizedBox(height: 16),

          // ── Mapa interactivo ──
          const FieldLabel(label: 'Ubicación en el mapa'),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: mapCenter,
                  initialZoom: hasCoords ? 15.0 : 5.0,
                  onTap: (tapPosition, point) {
                    onMapTap(point.latitude, point.longitude);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.gromy.app',
                  ),
                  if (hasCoords)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(latitude!, longitude!),
                          width: 40,
                          height: 40,
                          child: const _MapPin(),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (hasCoords) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.gps_fixed_rounded,
                    color: Colors.white.withValues(alpha: 0.4), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.location_on_rounded,
          color: Colors.white, size: 22),
    );
  }
}
