import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../data/services/geocoding_service.dart';
import '../widgets/form_helpers.dart';
import '../widgets/location_search_field.dart';
import '../widgets/step_card.dart';

const LatLng _fallbackMapCenter = LatLng(28.1235, -15.4363);
const double _fallbackZoom = 11;
const double _focusedZoom = 15;

enum _LocationIssue {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unavailable,
}

/// Paso 3 - Geolocalización: Autocompletado + mapa interactivo con pin.
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
  final MapController _mapController = MapController();

  late LatLng _mapCenter;
  late double _mapZoom;

  bool _isResolvingLocation = false;
  bool _didRequestLocationOnEntry = false;
  String? _locationStatusMessage;
  _LocationIssue? _locationIssue;
  LatLng? _lastSyncedPoint;

  LatLng? get _selectedPoint {
    final latitude = widget.latitude;
    final longitude = widget.longitude;
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude, longitude);
  }

  bool get _hasSelectedPoint => _selectedPoint != null;

  @override
  void initState() {
    super.initState();
    _mapCenter = _selectedPoint ?? _fallbackMapCenter;
    _mapZoom = _hasSelectedPoint ? _focusedZoom : _fallbackZoom;
    _syncMapWithSelectedPoint(animate: false);

    if (_hasSelectedPoint) {
      _locationStatusMessage = 'Ubicación lista para ajustar en el mapa.';
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didRequestLocationOnEntry) return;
        _didRequestLocationOnEntry = true;
        unawaited(_prepareLocationAccess(source: _LocationRequestSource.entry));
      });
    }
  }

  @override
  void didUpdateWidget(covariant Step3Geolocation oldWidget) {
    super.didUpdateWidget(oldWidget);

    final coordinatesChanged =
        oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude;

    if (coordinatesChanged && _hasSelectedPoint) {
      _locationIssue = null;
      _locationStatusMessage = 'Ubicación actualizada en el mapa.';
      _syncMapWithSelectedPoint();
    }
  }

  Future<void> _prepareLocationAccess({
    required _LocationRequestSource source,
  }) async {
    if (_isResolvingLocation) return;

    final shouldContinue = await _showPermissionPrimerIfNeeded(source);
    if (!shouldContinue || !mounted) return;

    await _resolveInitialLocation();
  }

  Future<bool> _showPermissionPrimerIfNeeded(
    _LocationRequestSource source,
  ) async {
    if (_hasSelectedPoint && source == _LocationRequestSource.recenter) {
      return true;
    }

    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.denied) return true;
    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.my_location_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Permitir ubicación',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Gromy necesita acceso a tu ubicación para centrar el mapa en tu posición real y ayudarte a seleccionar el lugar del torneo con precisión.',
          style: TextStyle(color: Color(0xFF475569), height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Ahora no',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _resolveInitialLocation() async {
    setState(() {
      _isResolvingLocation = true;
      _locationIssue = null;
      _locationStatusMessage = 'Buscando tu ubicación actual...';
    });

    try {
      final position = await _getCurrentUserPosition();
      if (!mounted) return;

      final currentPoint = LatLng(position.latitude, position.longitude);
      _updateViewport(currentPoint, _focusedZoom);

      setState(() {
        _isResolvingLocation = false;
        _locationIssue = null;
        _locationStatusMessage = 'Mapa centrado en tu ubicación actual.';
      });

      if (!_hasSelectedPoint) {
        await Future.sync(
          () => widget.onMapTap(position.latitude, position.longitude),
        );
      }
    } on _LocationException catch (error) {
      if (!mounted) return;

      _updateViewport(_fallbackMapCenter, _fallbackZoom);

      setState(() {
        _isResolvingLocation = false;
        _locationIssue = error.issue;
        _locationStatusMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      _updateViewport(_fallbackMapCenter, _fallbackZoom);

      setState(() {
        _isResolvingLocation = false;
        _locationIssue = _LocationIssue.unavailable;
        _locationStatusMessage =
            'No se pudo obtener tu ubicación real. Mostrando una ubicación por defecto.';
      });
    }
  }

  Future<Position> _getCurrentUserPosition() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      throw const _LocationException(
        _LocationIssue.servicesDisabled,
        'Activa la ubicación del dispositivo para centrar el mapa en tu posición real.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const _LocationException(
        _LocationIssue.permissionDenied,
        'No concediste permiso de ubicación. Puedes seguir usando el mapa manualmente.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const _LocationException(
        _LocationIssue.permissionDeniedForever,
        'El permiso de ubicación está bloqueado. Abre ajustes para permitir el acceso.',
      );
    }

    final lastKnown = await Geolocator.getLastKnownPosition();

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      ).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      if (lastKnown != null) return lastKnown;
      throw const _LocationException(
        _LocationIssue.timeout,
        'La ubicación tardó demasiado en responder. Mostrando una ubicación por defecto.',
      );
    }
  }

  void _syncMapWithSelectedPoint({bool animate = true}) {
    final selectedPoint = _selectedPoint;
    if (selectedPoint == null) return;

    final hasChanged =
        _lastSyncedPoint?.latitude != selectedPoint.latitude ||
        _lastSyncedPoint?.longitude != selectedPoint.longitude;

    if (!hasChanged) return;

    _lastSyncedPoint = selectedPoint;

    if (animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateViewport(selectedPoint, _focusedZoom);
      });
    } else {
      _mapCenter = selectedPoint;
      _mapZoom = _focusedZoom;
    }
  }

  Future<void> _handleMapTap(LatLng point) async {
    _updateViewport(point, _focusedZoom);

    setState(() {
      _locationIssue = null;
      _locationStatusMessage = 'Ubicación actualizada desde el mapa.';
    });

    await Future.sync(() => widget.onMapTap(point.latitude, point.longitude));
  }

  Future<void> _handleRecenter() async {
    if (_hasSelectedPoint) {
      final selectedPoint = _selectedPoint!;
      _updateViewport(selectedPoint, _focusedZoom);
      setState(() {
        _locationIssue = null;
        _locationStatusMessage = 'Mapa centrado en la ubicación seleccionada.';
      });
      return;
    }

    await _prepareLocationAccess(source: _LocationRequestSource.recenter);
  }

  Future<void> _handleIssueAction() async {
    switch (_locationIssue) {
      case _LocationIssue.servicesDisabled:
        await Geolocator.openLocationSettings();
        if (!mounted) return;
        await _prepareLocationAccess(source: _LocationRequestSource.recenter);
      case _LocationIssue.permissionDeniedForever:
        await Geolocator.openAppSettings();
      case _LocationIssue.permissionDenied:
      case _LocationIssue.timeout:
      case _LocationIssue.unavailable:
        await _prepareLocationAccess(source: _LocationRequestSource.recenter);
      case null:
        return;
    }
  }

  String get _issueActionLabel {
    switch (_locationIssue) {
      case _LocationIssue.servicesDisabled:
        return 'Activar ubicación';
      case _LocationIssue.permissionDeniedForever:
        return 'Abrir ajustes';
      case _LocationIssue.permissionDenied:
      case _LocationIssue.timeout:
      case _LocationIssue.unavailable:
        return 'Reintentar';
      case null:
        return 'Reintentar';
    }
  }

  void _updateViewport(LatLng center, double zoom) {
    _mapCenter = center;
    _mapZoom = zoom;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(center, zoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedPoint = _selectedPoint;

    return Column(
      children: [
        StepCard(
          icon: Icons.location_on_rounded,
          title: 'Geolocalización',
          subtitle:
              'Busca la dirección o toca el mapa para colocar el marcador con precisión.',
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
        _MapView(
          mapController: _mapController,
          mapCenter: _mapCenter,
          mapZoom: _mapZoom,
          markerPoint: selectedPoint,
          isResolvingLocation: _isResolvingLocation,
          locationStatusMessage: _locationStatusMessage,
          locationIssue: _locationIssue,
          issueActionLabel: _issueActionLabel,
          onMapTap: _handleMapTap,
          onRecenterPressed: _handleRecenter,
          onIssueActionPressed: _handleIssueAction,
        ),
        const SizedBox(height: 12),
        _MapFooter(
          latitude: widget.latitude,
          longitude: widget.longitude,
          hasSelection: _hasSelectedPoint,
        ),
      ],
    );
  }
}

enum _LocationRequestSource { entry, recenter }

class _MapView extends StatelessWidget {
  const _MapView({
    required this.mapController,
    required this.mapCenter,
    required this.mapZoom,
    required this.markerPoint,
    required this.isResolvingLocation,
    required this.locationStatusMessage,
    required this.locationIssue,
    required this.issueActionLabel,
    required this.onMapTap,
    required this.onRecenterPressed,
    required this.onIssueActionPressed,
  });

  final MapController mapController;
  final LatLng mapCenter;
  final double mapZoom;
  final LatLng? markerPoint;
  final bool isResolvingLocation;
  final String? locationStatusMessage;
  final _LocationIssue? locationIssue;
  final String issueActionLabel;
  final ValueChanged<LatLng> onMapTap;
  final VoidCallback onRecenterPressed;
  final VoidCallback onIssueActionPressed;

  bool get _hasIssue => locationIssue != null;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapHeight = constraints.maxWidth >= 560 ? 420.0 : 360.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: mapHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFCBD5E1)),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFF1F5F9),
                  Color(0xFFE2E8F0),
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0F172A),
                  blurRadius: 28,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: mapCenter,
                      initialZoom: mapZoom,
                      minZoom: 3,
                      maxZoom: 18,
                      onTap: (_, point) => onMapTap(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.gromy.app',
                      ),
                      if (markerPoint != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: markerPoint!,
                              width: 70,
                              height: 86,
                              alignment: Alignment.topCenter,
                              child: const _MapMarker(),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _MapStatusPill(
                          message:
                              locationStatusMessage ??
                              'Toca el mapa para elegir la ubicación.',
                          locationIssue: locationIssue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _MapActionButton(
                        icon: Icons.my_location_rounded,
                        tooltip: 'Centrar mapa',
                        onPressed: onRecenterPressed,
                      ),
                    ],
                  ),
                ),
                if (_hasIssue && !isResolvingLocation)
                  Positioned(
                    bottom: 18,
                    left: 18,
                    right: 18,
                    child: _MapIssueCard(
                      text:
                          locationStatusMessage ??
                          'No se pudo acceder a la ubicación.',
                      actionLabel: issueActionLabel,
                      onPressed: onIssueActionPressed,
                    ),
                  )
                else if (markerPoint == null && !isResolvingLocation)
                  const Positioned(
                    bottom: 18,
                    left: 18,
                    right: 18,
                    child: _MapHintCard(
                      icon: Icons.touch_app_rounded,
                      text: 'Pulsa sobre el mapa para fijar el punto exacto.',
                    ),
                  ),
                if (isResolvingLocation)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        child: const Center(child: _MapLoadingState()),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 86,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 50,
            child: Container(
              width: 18,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0x330F172A),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x220F172A),
                    blurRadius: 16,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          const Icon(
            Icons.location_on,
            size: 58,
            color: Colors.redAccent,
            shadows: [
              Shadow(
                color: Color(0x33000000),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
              Shadow(color: Color(0x66FF5252), blurRadius: 22),
            ],
          ),
          Positioned(
            top: 18,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapStatusPill extends StatelessWidget {
  const _MapStatusPill({required this.message, required this.locationIssue});

  final String message;
  final _LocationIssue? locationIssue;

  @override
  Widget build(BuildContext context) {
    final isError = locationIssue != null;
    final accent = isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final icon = isError ? Icons.gps_off_rounded : Icons.gps_fixed_rounded;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 11.8,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF0F172A), size: 20),
          ),
        ),
      ),
    );
  }
}

class _MapIssueCard extends StatelessWidget {
  const _MapIssueCard({
    required this.text,
    required this.actionLabel,
    required this.onPressed,
  });

  final String text;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 12.3,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              onPressed: onPressed,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapHintCard extends StatelessWidget {
  const _MapHintCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF334155)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 12.2,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapLoadingState extends StatelessWidget {
  const _MapLoadingState();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Obteniendo ubicación...',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
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
              'La dirección se actualizará automáticamente cuando elijas un punto.',
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

class _LocationException implements Exception {
  const _LocationException(this.issue, this.message);

  final _LocationIssue issue;
  final String message;
}
