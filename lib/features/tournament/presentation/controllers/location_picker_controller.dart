import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/services/location_service.dart';

enum LocationPickerStatus { loading, error, success }

class LocationPickerController extends ChangeNotifier {
  LocationPickerController({
    LocationService? locationService,
    required Future<void> Function(LatLng point) onLocationConfirmed,
    required LatLng fallbackCenter,
    LatLng? initialPoint,
    this.fallbackZoom = 11,
    this.focusedZoom = 16,
  }) : _locationService = locationService ?? LocationService(),
       _onLocationConfirmed = onLocationConfirmed,
       _fallbackCenter = fallbackCenter,
       _cameraCenter = initialPoint ?? fallbackCenter,
       _zoom = initialPoint != null ? focusedZoom : fallbackZoom,
       _selectedPoint = initialPoint,
       _status = initialPoint != null
           ? LocationPickerStatus.success
           : LocationPickerStatus.loading,
       _message = initialPoint != null
           ? 'Ubicación lista. Puedes afinarla moviendo el mapa.'
           : 'Obteniendo tu ubicación actual...';

  final LocationService _locationService;
  final Future<void> Function(LatLng point) _onLocationConfirmed;
  final LatLng _fallbackCenter;

  final MapController mapController = MapController();

  final double fallbackZoom;
  final double focusedZoom;

  LocationPickerStatus _status;
  String _message;
  LocationIssue? _issue;
  LatLng _cameraCenter;
  double _zoom;
  LatLng? _selectedPoint;
  bool _hasBootstrapped = false;
  bool _isResolvingLocation = false;
  bool _isInteracting = false;
  Timer? _selectionDebounce;

  LocationPickerStatus get status => _status;
  bool get isLoading => _status == LocationPickerStatus.loading;
  bool get hasError => _status == LocationPickerStatus.error;
  bool get hasSelection => _selectedPoint != null;
  bool get isInteracting => _isInteracting;
  String get message => _message;
  LocationIssue? get issue => _issue;
  LatLng get cameraCenter => _cameraCenter;
  double get zoom => _zoom;
  LatLng? get selectedPoint => _selectedPoint;

  String get issueActionLabel {
    return switch (_issue) {
      LocationIssue.servicesDisabled => 'Activar ubicación',
      LocationIssue.permissionDeniedForever => 'Abrir ajustes',
      LocationIssue.permissionDenied ||
      LocationIssue.timeout ||
      LocationIssue.unavailable => 'Reintentar',
      null => 'Reintentar',
    };
  }

  Future<void> bootstrap() async {
    if (_hasBootstrapped) return;
    _hasBootstrapped = true;

    if (_selectedPoint != null) {
      return;
    }

    await centerOnUserLocation();
  }

  void syncExternalSelection(LatLng? point) {
    _selectionDebounce?.cancel();
    _isInteracting = false;

    if (point == null) {
      if (_selectedPoint == null) return;

      _selectedPoint = null;
      _status = LocationPickerStatus.success;
      _issue = null;
      _message =
          'Selecciona una sugerencia o mueve el mapa para fijar el punto.';
      notifyListeners();
      return;
    }

    final alreadySynced =
        _selectedPoint?.latitude == point.latitude &&
        _selectedPoint?.longitude == point.longitude;
    if (alreadySynced) return;

    _selectedPoint = point;
    _cameraCenter = point;
    _zoom = _zoom < focusedZoom ? focusedZoom : _zoom;
    _status = LocationPickerStatus.success;
    _issue = null;
    _message = 'Ubicación actualizada.';
    notifyListeners();

    _moveMap(point, _zoom, id: 'external-selection');
  }

  Future<void> centerOnUserLocation() async {
    if (_isResolvingLocation) return;

    _selectionDebounce?.cancel();
    _isResolvingLocation = true;
    _isInteracting = false;
    _status = LocationPickerStatus.loading;
    _issue = null;
    _message = 'Obteniendo tu ubicación actual...';
    notifyListeners();

    try {
      final result = await _locationService.getCurrentPosition();
      final point = LatLng(result.latitude, result.longitude);

      _selectedPoint = point;
      _cameraCenter = point;
      _zoom = focusedZoom;
      _status = LocationPickerStatus.success;
      _issue = null;
      _message = 'Mapa centrado en tu ubicación actual.';
      notifyListeners();

      _moveMap(point, focusedZoom, id: 'device-location');
      await _onLocationConfirmed(point);
    } on LocationException catch (error) {
      _status = LocationPickerStatus.error;
      _issue = error.issue;
      _message = error.message;

      if (_selectedPoint == null) {
        _cameraCenter = _fallbackCenter;
        _zoom = fallbackZoom;
        _moveMap(_fallbackCenter, fallbackZoom, id: 'fallback-location');
      }

      notifyListeners();
    } catch (_) {
      _status = LocationPickerStatus.error;
      _issue = LocationIssue.unavailable;
      _message =
          'No se pudo obtener tu ubicación real. Puedes elegir el punto manualmente.';

      if (_selectedPoint == null) {
        _cameraCenter = _fallbackCenter;
        _zoom = fallbackZoom;
        _moveMap(_fallbackCenter, fallbackZoom, id: 'fallback-location');
      }

      notifyListeners();
    } finally {
      _isResolvingLocation = false;
    }
  }

  void handleMapTap(LatLng point) {
    _selectionDebounce?.cancel();
    _isInteracting = false;
    _cameraCenter = point;
    _zoom = focusedZoom;
    _moveMap(point, focusedZoom, id: 'map-tap');
    unawaited(
      _commitSelection(point, message: 'Ubicación actualizada desde el mapa.'),
    );
  }

  void handlePositionChanged(MapCamera camera, bool hasGesture) {
    _cameraCenter = camera.center;
    _zoom = camera.zoom;

    if (!hasGesture) {
      return;
    }

    if (!_isInteracting) {
      _isInteracting = true;
      _status = LocationPickerStatus.success;
      _issue = null;
      _message = 'Mueve el mapa y suéltalo para fijar el punto exacto.';
      notifyListeners();
    }

    _selectionDebounce?.cancel();
    _selectionDebounce = Timer(const Duration(milliseconds: 280), () {
      _isInteracting = false;
      unawaited(
        _commitSelection(
          _cameraCenter,
          message: 'Ubicación fijada en el centro del mapa.',
        ),
      );
    });
  }

  Future<void> handleIssueAction() async {
    switch (_issue) {
      case LocationIssue.servicesDisabled:
        await _locationService.openLocationSettings();
        await centerOnUserLocation();
        return;
      case LocationIssue.permissionDeniedForever:
        await _locationService.openAppSettings();
        return;
      case LocationIssue.permissionDenied:
      case LocationIssue.timeout:
      case LocationIssue.unavailable:
        await centerOnUserLocation();
        return;
      case null:
        return;
    }
  }

  Future<void> _commitSelection(LatLng point, {required String message}) async {
    final didChange =
        _selectedPoint?.latitude != point.latitude ||
        _selectedPoint?.longitude != point.longitude;

    _selectedPoint = point;
    _status = LocationPickerStatus.success;
    _issue = null;
    _message = message;
    notifyListeners();

    if (!didChange) return;

    await _onLocationConfirmed(point);
  }

  void _moveMap(LatLng center, double zoom, {required String id}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mapController.move(center, zoom, id: id);
    });
  }

  @override
  void dispose() {
    _selectionDebounce?.cancel();
    mapController.dispose();
    super.dispose();
  }
}
