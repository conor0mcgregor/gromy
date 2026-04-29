import 'dart:ui';

import 'package:flutter/material.dart';

class BarSmallBotton extends StatelessWidget {
  const BarSmallBotton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
    this.backgroundColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: backgroundColor ?? Colors.black.withValues(alpha: 0.3),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onTap(),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(icon, color: iconColor, size: 18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
