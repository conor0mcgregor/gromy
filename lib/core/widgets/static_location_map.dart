import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../features/tournament/config/map_provider_config.dart';

/// Widget reutilizable de mapa con marcador fijo.
///
/// Visualmente idéntico al `LocationPickerMap` del formulario:
/// mismos tiles (Stadia osm_bright), mismo pin, mismo estilo de contenedor.
///
/// Permite interacción (zoom, pan) pero el marcador NO se puede mover.
/// Pensado para pantallas de detalle, previews, etc.
class StaticLocationMap extends StatefulWidget {
  const StaticLocationMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 280,
    this.zoom = 15.0,
    this.borderRadius = 28.0,
    this.locationLabel,
    this.tileUrlTemplate,
  });

  final double latitude;
  final double longitude;
  final double height;
  final double zoom;
  final double borderRadius;

  /// Texto informativo que se muestra en el pill superior.
  /// Si es null se usa un texto por defecto.
  final String? locationLabel;

  /// URL de tiles. Si es null usa Stadia osm_bright (requiere
  /// `TournamentMapProviderConfig` como fuente canónica de la key).
  final String? tileUrlTemplate;

  @override
  State<StaticLocationMap> createState() => _StaticLocationMapState();
}

class _StaticLocationMapState extends State<StaticLocationMap> {
  // Controlador necesario para mover el mapa al pulsar el botón
  final MapController _mapController = MapController();

  void _recenterMap() {
    _mapController.move(
      LatLng(widget.latitude, widget.longitude),
      widget.zoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(widget.latitude, widget.longitude);

    final tiles = widget.tileUrlTemplate ??
        TournamentMapProviderConfig.stadiaTileUrlTemplate;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F5F0),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: const Color(0xFFD8D2C7)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A0F172A),
              blurRadius: 30,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── Map ──
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController, // <-- Asignamos el controlador
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: widget.zoom,
                  minZoom: 3,
                  maxZoom: 20,
                  backgroundColor: const Color(0xFFF4F2EE),
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: tiles,
                    userAgentPackageName: 'com.app.gromy',
                    retinaMode: MediaQuery.devicePixelRatioOf(context) > 1,
                    keepBuffer: 4,
                    panBuffer: 2,
                    maxNativeZoom: 20,
                    maxZoom: 20,
                    tileDisplay: const TileDisplay.fadeIn(
                      duration: Duration(milliseconds: 120),
                    ),
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center,
                        width: 96,
                        height: 118,
                        alignment: Alignment.topCenter,
                        child: const _DynamicLocationPin(),
                      ),
                    ],
                  ),
                  RichAttributionWidget(
                    alignment: AttributionAlignment.bottomLeft,
                    showFlutterMapAttribution: false,
                    permanentHeight: 20,
                    popupInitialDisplayDuration: const Duration(seconds: 3),
                    popupBackgroundColor:
                    Colors.white.withValues(alpha: 0.97),
                    attributions: const [
                      TextSourceAttribution(
                        'Stadia Maps',
                        textStyle: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 11.5,
                        ),
                      ),
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        textStyle: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Status pill & Recenter Button ──
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _MapStatusPill(
                      message: widget.locationLabel ?? 'Ubicación del torneo',
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botón de centrado
                  _RecenterButton(onPressed: _recenterMap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botón para volver a centrar
// ─────────────────────────────────────────────────────────────────────────────

class _RecenterButton extends StatelessWidget {
  const _RecenterButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999), // Redondo como el pill
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(
              Icons.my_location_rounded,
              color: Color(0xFF0F172A),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dynamic Location Pin (idéntico al de location_picker_map.dart)
// ─────────────────────────────────────────────────────────────────────────────

class _DynamicLocationPin extends StatelessWidget {
  const _DynamicLocationPin();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 118,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // Shadow ellipse
          Positioned(
            bottom: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x240F172A),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x220F172A),
                    blurRadius: 18,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const SizedBox(width: 22, height: 10),
            ),
          ),
          // Pin body
          CustomPaint(
            size: const Size(96, 118),
            painter: _DynamicLocationPinPainter(),
          ),
          // White dot
          Positioned(
            top: 25,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFFCBD5E1)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x160F172A),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicLocationPinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..cubicTo(
        size.width * 0.18, size.height * 0.74,
        size.width * 0.04, size.height * 0.48,
        size.width * 0.18, size.height * 0.24,
      )
      ..cubicTo(
        size.width * 0.30, size.height * 0.02,
        size.width * 0.70, size.height * 0.02,
        size.width * 0.82, size.height * 0.24,
      )
      ..cubicTo(
        size.width * 0.96, size.height * 0.48,
        size.width * 0.82, size.height * 0.74,
        size.width / 2, size.height,
      )
      ..close();

    canvas.drawShadow(path, const Color(0x550F172A), 18, false);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF121A35), Color(0xFF0F1530)],
      ).createShader(Offset.zero & size);

    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF202B49)
      ..strokeWidth = 1.2;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Pill (idéntico al de location_picker_map.dart)
// ─────────────────────────────────────────────────────────────────────────────

class _MapStatusPill extends StatelessWidget {
  const _MapStatusPill({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF16A34A);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.gps_fixed_rounded, size: 15, color: accent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}