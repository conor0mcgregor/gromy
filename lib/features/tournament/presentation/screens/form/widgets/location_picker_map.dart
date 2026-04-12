import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../config/map_provider_config.dart';
import '../../../controllers/location_picker_controller.dart';

class LocationPickerMap extends StatelessWidget {
  const LocationPickerMap({super.key, required this.controller});

  final LocationPickerController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapHeight = constraints.maxWidth >= 560 ? 430.0 : 370.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            height: mapHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5F0),
              borderRadius: BorderRadius.circular(28),
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
                Positioned.fill(
                  child: FlutterMap(
                    mapController: controller.mapController,
                    options: MapOptions(
                      initialCenter: controller.cameraCenter,
                      initialZoom: controller.zoom,
                      minZoom: 3,
                      maxZoom: 20,
                      backgroundColor: const Color(0xFFF4F2EE),
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onTap: (_, point) => controller.handleMapTap(point),
                      onPositionChanged: controller.handlePositionChanged,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            TournamentMapProviderConfig.stadiaTileUrlTemplate,
                        userAgentPackageName:
                            TournamentMapProviderConfig.userAgentPackageName,
                        retinaMode: MediaQuery.devicePixelRatioOf(context) > 1,
                        keepBuffer: 4,
                        panBuffer: 2,
                        maxNativeZoom: 20,
                        maxZoom: 20,
                        tileDisplay: const TileDisplay.fadeIn(
                          duration: Duration(milliseconds: 120),
                        ),
                      ),
                      if (controller.selectedPoint != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: controller.selectedPoint!,
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
                        popupBackgroundColor: Colors.white.withValues(
                          alpha: 0.97,
                        ),
                        attributions: const [
                          TextSourceAttribution(
                            'Stadia Maps',
                            textStyle: TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 11.5,
                            ),
                          ),
                          TextSourceAttribution(
                            'OpenMapTiles',
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
                Positioned(
                  top: 14,
                  left: 14,
                  right: 14,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _MapStatusPill(
                          message: controller.message,
                          hasSelection: controller.hasSelection,
                          hasError: controller.hasError,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _MapActionButton(
                        icon: Icons.my_location_rounded,
                        tooltip: 'Centrar en mi ubicación',
                        onPressed: controller.centerOnUserLocation,
                      ),
                    ],
                  ),
                ),
                if (controller.hasError && !controller.isLoading)
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 54,
                    child: _MapIssueCard(
                      text: controller.message,
                      actionLabel: controller.issueActionLabel,
                      onPressed: controller.handleIssueAction,
                    ),
                  )
                else if (!controller.hasSelection && !controller.isLoading)
                  const Positioned(
                    left: 18,
                    right: 18,
                    bottom: 54,
                    child: _MapHintCard(
                      icon: Icons.touch_app_rounded,
                      text:
                          'Explora el mapa libremente y toca el punto exacto donde quieres colocar el torneo.',
                    ),
                  ),
                if (controller.isLoading)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
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
          CustomPaint(
            size: const Size(96, 118),
            painter: _DynamicLocationPinPainter(),
          ),
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
        size.width * 0.18,
        size.height * 0.74,
        size.width * 0.04,
        size.height * 0.48,
        size.width * 0.18,
        size.height * 0.24,
      )
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.02,
        size.width * 0.70,
        size.height * 0.02,
        size.width * 0.82,
        size.height * 0.24,
      )
      ..cubicTo(
        size.width * 0.96,
        size.height * 0.48,
        size.width * 0.82,
        size.height * 0.74,
        size.width / 2,
        size.height,
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

class _MapStatusPill extends StatelessWidget {
  const _MapStatusPill({
    required this.message,
    required this.hasSelection,
    required this.hasError,
  });

  final String message;
  final bool hasSelection;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final accent = switch ((hasError, hasSelection)) {
      (true, _) => const Color(0xFFDC2626),
      (false, true) => const Color(0xFF16A34A),
      (false, false) => const Color(0xFF2563EB),
    };
    final icon = switch ((hasError, hasSelection)) {
      (true, _) => Icons.gps_off_rounded,
      (false, true) => Icons.gps_fixed_rounded,
      (false, false) => Icons.place_rounded,
    };

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
          children: [
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: 8),
            Expanded(
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

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            unawaited(onPressed());
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD8D2C7)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x120F172A),
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
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(20),
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
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                unawaited(onPressed());
              },
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8D2C7)),
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
                  fontSize: 12.4,
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

class _MapLoadingState extends StatelessWidget {
  const _MapLoadingState();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8D2C7)),
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
