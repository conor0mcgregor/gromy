import 'dart:async';
import 'dart:developer' as developer;

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../../invitation/presentation/screens/invitation_landing_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DeepLinkService
//
//  Maneja los custom scheme deep links  gromy://invite/{token}  tanto en
//  cold start (app cerrada) como en warm start (app en segundo plano).
//
//  Integración:
//    final deepLinkService = DeepLinkService();
//    await deepLinkService.initialize();  // llamar en main(), después de runApp
//
//  Usa el mismo navigatorKey que PushNotificationService para no duplicar
//  dependencias.
//
//  Esquema esperado:
//    gromy://invite/<token>
//    host  = invite
//    path  = /<token>
// ─────────────────────────────────────────────────────────────────────────────

class DeepLinkService {
  DeepLinkService({
    required GlobalKey<NavigatorState> navigatorKey,
    AppLinks? appLinks,
  })  : _navigatorKey = navigatorKey,
        _appLinks = appLinks ?? AppLinks();

  final GlobalKey<NavigatorState> _navigatorKey;
  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;

  // ── Inicialización ────────────────────────────────────────────────────────

  /// Llama a este método una vez, preferiblemente en [main()] después de
  /// [runApp()], o en [initState()] del widget raíz.
  Future<void> initialize() async {
    // 1. Cold start: app was completely closed; launched via deep link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        developer.log(
          '[DeepLinkService] Cold start URI: $initialUri',
          name: 'DeepLinkService',
        );
        // Pequeño delay para asegurarnos de que el navigator está montado
        await Future<void>.delayed(const Duration(milliseconds: 300));
        _handleUri(initialUri);
      }
    } catch (e) {
      developer.log(
        '[DeepLinkService] Error reading initial link: $e',
        name: 'DeepLinkService',
      );
    }

    // 2. Warm start: app already running; new link arrives
    _subscription = _appLinks.uriLinkStream.listen(
      (uri) {
        developer.log(
          '[DeepLinkService] Warm start URI: $uri',
          name: 'DeepLinkService',
        );
        _handleUri(uri);
      },
      onError: (Object err) {
        developer.log(
          '[DeepLinkService] Stream error: $err',
          name: 'DeepLinkService',
        );
      },
    );
  }

  // ── Procesamiento de URI ──────────────────────────────────────────────────

  void _handleUri(Uri uri) {
    developer.log(
      '[DeepLinkService] Handling URI: $uri  scheme=${uri.scheme}  host=${uri.host}  path=${uri.path}',
      name: 'DeepLinkService',
    );

    if (uri.scheme != 'gromy') return;
    if (uri.host != 'invite') return;

    // Extraer token del path: /LChXhzswysCUbZ3SKyLc → LChXhzswysCUbZ3SKyLc
    final token = _extractToken(uri);

    developer.log(
      '[DeepLinkService] Extracted token: "$token"',
      name: 'DeepLinkService',
    );

    _navigateToInvitation(token);
  }

  /// Extrae el token del path de la URI.
  ///
  /// gromy://invite/LChXhzswysCUbZ3SKyLc → 'LChXhzswysCUbZ3SKyLc'
  /// gromy://invite/               → '' (inválido)
  String _extractToken(Uri uri) {
    // uri.pathSegments filtra automáticamente los segmentos vacíos
    final segments = uri.pathSegments;
    if (segments.isEmpty) return '';
    return segments.first.trim();
  }

  void _navigateToInvitation(String token) {
    final context = _navigatorKey.currentContext;
    if (context == null) {
      developer.log(
        '[DeepLinkService] Navigator context is null — cannot navigate.',
        name: 'DeepLinkService',
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InvitationLandingScreen(
          // Si token está vacío la landing screen mostrará el estado InvitationNotFound
          token: token,
        ),
      ),
    );
  }

  // ── Limpieza ──────────────────────────────────────────────────────────────

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
