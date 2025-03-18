import 'package:flutter/material.dart';
import '../utils/app_settings.dart';

class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final double fontSize;
  final double iconSize;
  final EdgeInsetsGeometry? padding;
  final IconData? icon;
  final Color? buttonColor;
  final Color? textColor;
  final Color? borderColor;

  const GlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.fullWidth = false,
    this.fontSize = 16,
    this.iconSize = 24,
    this.padding,
    this.icon,
    this.buttonColor,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final blurEffectsEnabled = AppSettings.instance.blurEffectsEnabled;
    final defaultButtonColor = const Color(
      0xFF2196F3,
    ).withValues(alpha: blurEffectsEnabled ? 0.8 : 1.0);
    final actualButtonColor = buttonColor ?? defaultButtonColor;
    final actualTextColor = textColor ?? Colors.white;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: actualButtonColor,
          foregroundColor: actualTextColor,
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              color: borderColor ?? Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          elevation: onPressed == null ? 0 : 8,
          shadowColor: actualButtonColor.withValues(alpha: 0.5),
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          disabledBackgroundColor: actualButtonColor.withValues(alpha: 0.3),
          disabledForegroundColor: actualTextColor.withValues(alpha: 0.5),
        ),
        child:
            icon != null
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: iconSize),
                    const SizedBox(width: 6),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
                : Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }
}
