import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../data/services/geocoding_service.dart';
import '../../../../data/services/location_service.dart';
import '../../../controllers/location_picker_controller.dart';
import '../widgets/form_helpers.dart';
import '../widgets/location_picker_map.dart';
import '../widgets/location_search_field.dart';
import '../widgets/step_card.dart';

const LatLng _fallbackMapCenter = LatLng(28.1235, -15.4363);

/// Paso 3 - Geolocalización: búsqueda + selector preciso en mapa.
class Step3Geolocation extends StatefulWidget {
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
  final FutureOr<void> Function(double lat, double lng) onMapTap;

  @override
  State<Step3Geolocation> createState() => _Step3GeolocationState();
}

class _Step3GeolocationState extends State<Step3Geolocation> {
  late final LocationPickerController _locationPickerController;

  LatLng? get _selectedPoint => _pointFrom(widget.latitude, widget.longitude);

  @override
  void initState() {
    super.initState();

    _locationPickerController = LocationPickerController(
      locationService: LocationService(),
      fallbackCenter: _fallbackMapCenter,
      initialPoint: _selectedPoint,
      onLocationConfirmed: (point) async {
        await Future.sync(
          () => widget.onMapTap(point.latitude, point.longitude),
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_locationPickerController.bootstrap());
    });
  }

  @override
  void didUpdateWidget(covariant Step3Geolocation oldWidget) {
    super.didUpdateWidget(oldWidget);

    final previousPoint = _pointFrom(oldWidget.latitude, oldWidget.longitude);
    final currentPoint = _selectedPoint;

    final coordinatesChanged =
        previousPoint?.latitude != currentPoint?.latitude ||
        previousPoint?.longitude != currentPoint?.longitude;

    if (coordinatesChanged) {
      _locationPickerController.syncExternalSelection(currentPoint);
    }
  }

  @override
  void dispose() {
    _locationPickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StepCard(
          icon: Icons.location_on_rounded,
          title: 'Geolocalización',
          subtitle:
              'Busca una dirección o toca el mapa para colocar el marcador exactamente donde debe quedar.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocationSearchField(
                controller: widget.locationController,
                errorText: widget.locationError,
                suggestions: widget.suggestions,
                isSearching: widget.isSearching,
                onQueryChanged: widget.onQueryChanged,
                onSuggestionSelected: widget.onSuggestionSelected,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const FieldLabel(label: 'Ubicación en el mapa'),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: _locationPickerController,
          builder: (context, _) {
            return LocationPickerMap(controller: _locationPickerController);
          },
        ),
        const SizedBox(height: 12),
        _MapFooter(
          latitude: widget.latitude,
          longitude: widget.longitude,
          hasSelection: widget.latitude != null && widget.longitude != null,
        ),
      ],
    );
  }

  LatLng? _pointFrom(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude, longitude);
  }
}

class _MapFooter extends StatelessWidget {
  const _MapFooter({
    required this.latitude,
    required this.longitude,
    required this.hasSelection,
  });

  final double? latitude;
  final double? longitude;
  final bool hasSelection;

  @override
  Widget build(BuildContext context) {
    final lat = latitude;
    final lng = longitude;

    if (!hasSelection || lat == null || lng == null) {
      return const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 14),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'La dirección y las coordenadas se actualizarán cuando toques una ubicación válida en el mapa.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11.8,
                height: 1.35,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.gps_fixed_rounded,
            color: Color(0xFF2563EB),
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
