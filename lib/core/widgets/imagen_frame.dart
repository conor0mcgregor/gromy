import 'package:flutter/material.dart';

class ImageFrame extends StatelessWidget {
  const ImageFrame({
    required this.coverUrl,
    required this.accent,
  });

  final String? coverUrl;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 118,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CoverImage(url: coverUrl, accent: accent),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class CoverImage extends StatelessWidget {
  const CoverImage({required this.url, required this.accent});

  final String? url;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final uri = url?.trim();
    final hasUrl = uri != null && uri.isNotEmpty;

    // Widget base para el estado de carga o espera
    Widget loadingPlaceholder() {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.22),
              Colors.white.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(accent),
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }

    // Si no hay URL, ahora mostramos el cargando en lugar del logo
    if (!hasUrl) return loadingPlaceholder();

    return Image.network(
      uri,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return loadingPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) => loadingPlaceholder(),
    );
  }
}