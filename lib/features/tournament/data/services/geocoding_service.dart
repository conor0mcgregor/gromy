import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/map_provider_config.dart';

/// Resultado de una búsqueda de geocodificación.
class GeocodingResult {
  const GeocodingResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  final String displayName;
  final double latitude;
  final double longitude;

  @override
  String toString() => 'GeocodingResult($displayName, $latitude, $longitude)';
}

/// Servicio de geocodificación usando MapTiler sobre datos OpenStreetMap.
///
/// SRP: su única responsabilidad es traducir texto de dirección ↔ coordenadas.
class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Busca ubicaciones que coincidan con [query].
  ///
  /// Devuelve una lista de resultados de geocodificación. Si la respuesta no
  /// es exitosa o no hay resultados, devuelve una lista vacía.
  Future<List<GeocodingResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return const [];

    final encodedQuery = Uri.encodeComponent(trimmed);
    final uri = Uri.https(
      TournamentMapProviderConfig.mapTilerHost,
      '/geocoding/$encodedQuery.json',
      {
        'key': TournamentMapProviderConfig.mapTilerApiKey,
        'language': TournamentMapProviderConfig.geocodingLanguage,
        'limit': '6',
        'autocomplete': 'true',
      },
    );

    try {
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return const [];

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) return const [];

      final features = decoded['features'];
      if (features is! List) return const [];

      return features
          .map(_featureToResult)
          .whereType<GeocodingResult>()
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// Geocodificación inversa: coordenadas → dirección legible.
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    final uri = Uri.https(
      TournamentMapProviderConfig.mapTilerHost,
      '/geocoding/$longitude,$latitude.json',
      {
        'key': TournamentMapProviderConfig.mapTilerApiKey,
        'language': TournamentMapProviderConfig.geocodingLanguage,
        'limit': '1',
      },
    );

    try {
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final features = decoded['features'];
      if (features is! List || features.isEmpty) return null;

      final firstFeature = features.first;
      if (firstFeature is! Map<String, dynamic>) return null;

      return _readDisplayName(firstFeature);
    } catch (_) {
      return null;
    }
  }

  Map<String, String> get _headers => {
    'User-Agent': '${TournamentMapProviderConfig.userAgentPackageName}/1.0',
  };

  GeocodingResult? _featureToResult(dynamic feature) {
    if (feature is! Map<String, dynamic>) return null;

    final coordinates = _readCoordinates(feature);
    final displayName = _readDisplayName(feature);

    if (coordinates == null || displayName == null || displayName.isEmpty) {
      return null;
    }

    return GeocodingResult(
      displayName: displayName,
      latitude: coordinates.$1,
      longitude: coordinates.$2,
    );
  }

  (double, double)? _readCoordinates(Map<String, dynamic> feature) {
    final center = feature['center'];
    if (center is List && center.length >= 2) {
      final longitude = _toDouble(center[0]);
      final latitude = _toDouble(center[1]);
      if (latitude != null && longitude != null) {
        return (latitude, longitude);
      }
    }

    final geometry = feature['geometry'];
    if (geometry is Map<String, dynamic>) {
      final coordinates = geometry['coordinates'];
      if (coordinates is List && coordinates.length >= 2) {
        final longitude = _toDouble(coordinates[0]);
        final latitude = _toDouble(coordinates[1]);
        if (latitude != null && longitude != null) {
          return (latitude, longitude);
        }
      }
    }

    return null;
  }

  String? _readDisplayName(Map<String, dynamic> feature) {
    final placeNameEs = feature['place_name_es'] as String?;
    if (placeNameEs != null && placeNameEs.isNotEmpty) return placeNameEs;

    final placeName = feature['place_name'] as String?;
    if (placeName != null && placeName.isNotEmpty) return placeName;

    final textEs = feature['text_es'] as String?;
    if (textEs != null && textEs.isNotEmpty) return textEs;

    final text = feature['text'] as String?;
    if (text != null && text.isNotEmpty) return text;

    return null;
  }

  double? _toDouble(dynamic value) {
    return switch (value) {
      final num number => number.toDouble(),
      _ => double.tryParse(value?.toString() ?? ''),
    };
  }

  void dispose() {
    _client.close();
  }
}
