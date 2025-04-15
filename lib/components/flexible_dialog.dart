import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:image_picker/image_picker.dart';

class FlexibleDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData? icon;
  final Color? iconColor;
  final Widget? content;
  final List<Widget> actions;
  final bool blurBackground;
  final double? maxWidth;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final MainAxisAlignment actionsAlignment;
  final CrossAxisAlignment contentAlignment;

  const FlexibleDialog({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.iconColor,
    this.content,
    required this.actions,
    this.blurBackground = true,
    this.maxWidth,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(24),
    this.actionsAlignment = MainAxisAlignment.center,
    this.contentAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    Widget dialogContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: contentAlignment,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 48, color: iconColor ?? Colors.white),
            const SizedBox(height: 16),
          ],
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          if (message != null) ...[
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),
          ],
          if (content != null) ...[content!, const SizedBox(height: 24)],
          Row(
            mainAxisAlignment: actionsAlignment,
            children: _buildActionButtons(),
          ),
        ],
      ),
    );

    if (blurBackground) {
      dialogContent = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: dialogContent,
        ),
      );
    }

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: dialogContent,
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    List<Widget> result = [];
    for (int i = 0; i < actions.length; i++) {
      if (i > 0) result.add(const SizedBox(width: 16));
      result.add(Expanded(child: actions[i]));
    }
    return result;
  }

  // Static helper methods for common dialog types
  static Future<T?> showConfirmation<T>({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData? icon,
    Color? iconColor,
    bool isDanger = false,
  }) {
    return showDialog<T>(
      context: context,
      builder: (BuildContext context) {
        return FlexibleDialog(
          title: title,
          message: message,
          icon: icon,
          iconColor: iconColor ?? (isDanger ? Colors.redAccent : null),
          actions: [
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              label: Text(cancelText),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(true);
                onConfirm();
              },
              icon: Icon(isDanger ? Icons.delete_outline : Icons.check),
              label: Text(confirmText),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDanger ? Colors.redAccent : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<T?> showCustomDialog<T>({
    required BuildContext context,
    required Widget content,
    String? title,
    IconData? icon,
    Color? iconColor,
    List<Widget>? actions,
    double? maxWidth,
  }) {
    return showDialog<T>(
      context: context,
      builder: (BuildContext context) {
        return FlexibleDialog(
          title: title,
          icon: icon,
          iconColor: iconColor,
          content: content,
          maxWidth: maxWidth,
          actions:
              actions ??
              [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ],
        );
      },
    );
  }

  static Future<T?> showImageSource<T>({
    required BuildContext context,
    required Function(ImageSource) onSourceSelected,
    String title = 'Select Image Source',
    String? message,
    IconData? titleIcon,
  }) {
    return showDialog<T>(
      context: context,
      builder: (BuildContext context) {
        return FlexibleDialog(
          title: title,
          message: message,
          icon: titleIcon ?? Icons.add_photo_alternate,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSourceOption(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: () {
                  Navigator.pop(context);
                  onSourceSelected(ImageSource.camera);
                },
              ),
              _buildSourceOption(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: () {
                  Navigator.pop(context);
                  onSourceSelected(ImageSource.gallery);
                },
              ),
            ],
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              label: const Text('Close'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
