import 'dart:convert';
import 'package:http/http.dart' as http;

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

/// Servicio de geocodificación usando la API de Nominatim (OpenStreetMap).
///
/// SRP: su única responsabilidad es traducir texto de dirección ↔ coordenadas.
/// No requiere API key.
class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://nominatim.openstreetmap.org';

  /// Busca ubicaciones que coincidan con [query].
  ///
  /// Devuelve una lista de resultados de geocodificación. Si la respuesta no
  /// es exitosa o no hay resultados, devuelve una lista vacía.
  Future<List<GeocodingResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return const [];

    final uri = Uri.parse('$_baseUrl/search').replace(
      queryParameters: {
        'q': trimmed,
        'format': 'json',
        'limit': '6',
        'addressdetails': '0',
      },
    );

    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': 'gromy-app/1.0'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return const [];

      final List<dynamic> data = json.decode(response.body);
      return data
          .map((item) => GeocodingResult(
                displayName: item['display_name'] as String? ?? '',
                latitude:
                    double.tryParse(item['lat']?.toString() ?? '') ?? 0.0,
                longitude:
                    double.tryParse(item['lon']?.toString() ?? '') ?? 0.0,
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Geocodificación inversa: coordenadas → dirección legible.
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    final uri = Uri.parse('$_baseUrl/reverse').replace(
      queryParameters: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'json',
      },
    );

    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': 'gromy-app/1.0'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
