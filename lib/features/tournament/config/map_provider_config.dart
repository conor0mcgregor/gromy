final class TournamentMapProviderConfig {
  const TournamentMapProviderConfig._();

  static const String stadiaApiKey = 'a10ab322-db33-412a-b359-898efac5bc2f';
  static const String mapTilerApiKey = 'Sny8Ikg2G6WpqTURh8N7';

  static const String stadiaStyle = 'osm_bright';
  static const String stadiaTileUrlTemplate =
      'https://tiles.stadiamaps.com/tiles/$stadiaStyle/{z}/{x}/{y}{r}.png?api_key=$stadiaApiKey';

  static const String mapTilerHost = 'api.maptiler.com';
  static const String geocodingLanguage = 'es';
  static const String userAgentPackageName = 'com.example.gromy';
}
