import 'package:flutter/material.dart';

import '../../domain/entities/app_notification.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  NotificationNavigationHandler  ·  Navegación contextual
//
//  Resuelve la navegación basada en actionRoute + data de cada notificación.
//  Extensible: para añadir nuevas rutas solo se agrega un caso en [navigate].
//
//  NO hardcodea rutas concretas de la app; usa un mapa de handlers registrables.
// ─────────────────────────────────────────────────────────────────────────────

/// Callback que ejecuta la navegación real dado un [BuildContext] y datos.
typedef NavigationAction = void Function(
  BuildContext context,
  Map<String, dynamic> data,
);

class NotificationNavigationHandler {
  NotificationNavigationHandler._();

  static final NotificationNavigationHandler _instance =
      NotificationNavigationHandler._();

  /// Singleton para acceso global.
  static NotificationNavigationHandler get instance => _instance;

  /// Registro de handlers por ruta.
  ///
  /// Para registrar un nuevo handler:
  /// ```dart
  /// NotificationNavigationHandler.instance.registerRoute(
  ///   '/tournament/detail',
  ///   (context, data) {
  ///     final tournamentId = data['tournamentId'] as String;
  ///     Navigator.push(context, ...);
  ///   },
  /// );
  /// ```
  final Map<String, NavigationAction> _routes = {};

  /// Registra un handler para una ruta específica.
  void registerRoute(String route, NavigationAction action) {
    _routes[route] = action;
  }

  /// Registra múltiples handlers de una sola vez.
  void registerRoutes(Map<String, NavigationAction> routes) {
    _routes.addAll(routes);
  }

  /// Elimina un handler registrado.
  void unregisterRoute(String route) {
    _routes.remove(route);
  }

  /// Navega a la ruta especificada en la notificación.
  ///
  /// Retorna `true` si se encontró un handler para la ruta, `false` si no.
  bool navigate(BuildContext context, AppNotification notification) {
    final route = notification.actionRoute;
    if (route == null || route.isEmpty) return false;

    final handler = _routes[route];
    if (handler == null) {
      debugPrint(
        'NotificationNavigationHandler: No handler registrado para ruta "$route"',
      );
      return false;
    }

    handler(context, notification.data);
    return true;
  }

  /// Comprueba si existe un handler para la ruta dada.
  bool hasRoute(String route) => _routes.containsKey(route);

  /// Limpia todos los handlers registrados (útil para testing).
  void clearRoutes() => _routes.clear();
}
