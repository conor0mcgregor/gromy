import 'package:flutter/material.dart';

class ImageFrame extends StatelessWidget {
  const ImageFrame({super.key, required this.coverUrl, required this.accent});

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
  const CoverImage({super.key, required this.url, required this.accent});

  final String? url;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final uri = url?.trim();
    final hasUrl = uri != null && uri.isNotEmpty;

    Widget placeholder({bool loading = false}) {
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
          child: loading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                    strokeWidth: 2.5,
                  ),
                )
              : Icon(
                  Icons.image_rounded,
                  color: accent.withValues(alpha: 0.5),
                  size: 42,
                ),
        ),
      );
    }

    if (!hasUrl) return placeholder();

    return Image.network(
      uri,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return placeholder(loading: true);
      },
      errorBuilder: (context, error, stackTrace) => placeholder(),
    );
  }
}
