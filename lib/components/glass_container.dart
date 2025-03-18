import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/app_settings.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? color;
  final double? blur;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 12,
    this.color,
    this.blur = 5,
  });

  @override
  Widget build(BuildContext context) {
    final blurEnabled = AppSettings.instance.blurEffectsEnabled;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius!),
        color: color ?? Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius!),
        child:
            blurEnabled
                ? BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blur!, sigmaY: blur!),
                  child: Padding(padding: padding!, child: child),
                )
                : Padding(padding: padding!, child: child),
      ),
    );
  }
}
