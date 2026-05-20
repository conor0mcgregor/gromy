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
//    1. App Links / Universal Links:
//       https://gromy-ps.firebaseapp.com/invite/<token>
//       host = gromy-ps.firebaseapp.com
//       path = /invite/<token>
//
//    2. Custom Scheme (Legacy / Fallback):
//       gromy://invite/<token>
//       host = invite
//       path = /<token>
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

    bool isValid = false;
    
    // Check for Universal/App Link
    if (uri.scheme == 'https' && uri.host == 'gromy-ps.firebaseapp.com' && uri.path.startsWith('/invite/')) {
      isValid = true;
    }
    // Check for custom scheme (legacy / fallback)
    else if (uri.scheme == 'gromy' && uri.host == 'invite') {
      isValid = true;
    }

    if (!isValid) return;

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
  /// https://gromy-ps.firebaseapp.com/invite/ID → 'ID'
  /// gromy://invite/ID → 'ID'
  String _extractToken(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.isEmpty) return '';
    
    if (uri.scheme == 'https') {
      // Para https, segments = ['invite', 'ID']
      if (segments.length >= 2 && segments.first == 'invite') {
        return segments[1].trim();
      }
    } else if (uri.scheme == 'gromy') {
      // Para gromy, segments = ['ID']
      return segments.first.trim();
    }
    
    return '';
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
