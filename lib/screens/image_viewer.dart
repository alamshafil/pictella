import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';

class FullscreenImageViewer extends StatefulWidget {
  final Uint8List imageBytes;
  final String heroTag;
  final String? promptTitle;

  const FullscreenImageViewer({
    super.key,
    required this.imageBytes,
    required this.heroTag,
    this.promptTitle,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  // Track if controls are visible
  bool _showControls = true;

  // Controller for the photo view
  final PhotoViewController _controller = PhotoViewController();

  // For drag to dismiss
  double _dragStartY = 0;
  double _dragCurrentY = 0;
  bool _isDragging = false;

  // Drag scaling and opacity
  double _dragScale = 1.0;
  double _dragOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    // Set preferred orientation to landscape and portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    // Reset to portrait only when closing
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  // Close with animation
  void _animateAndClose() {
    Navigator.of(context).pop();
  }

  // Handle drag events for dismiss animation
  void _onDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragStartY = details.globalPosition.dy;
      _dragCurrentY = _dragStartY;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    // Only enable dragging down when zoom is at 1.0
    if (_controller.scale != null && _controller.scale! > 1.05) return;

    setState(() {
      _dragCurrentY = details.globalPosition.dy;

      // Calculate how far we've dragged as a percentage of screen height
      double dragDistance = (_dragCurrentY - _dragStartY).abs();
      double screenHeight = MediaQuery.of(context).size.height;
      double dragPercent = (dragDistance / screenHeight).clamp(0.0, 1.0);

      // Adjust scale and opacity based on drag
      _dragScale = 1.0 - (dragPercent * 0.3); // Scale to 70% at most
      _dragOpacity = 1.0 - (dragPercent * 0.7); // Fade to 30% opacity at most
    });
  }

  void _onDragEnd(DragEndDetails details) {
    // If we've dragged far enough, close the viewer
    if (_dragCurrentY - _dragStartY > 100) {
      _animateAndClose();
    } else {
      // Otherwise, reset the drag state
      setState(() {
        _isDragging = false;
        _dragScale = 1.0;
        _dragOpacity = 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // iOS-like styling with system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar:
          _showControls
              ? AppBar(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title:
                    widget.promptTitle != null
                        ? Text(
                          widget.promptTitle!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                        : null,
              )
              : null,
      body: GestureDetector(
        onTap: _toggleControls,
        onVerticalDragStart: _onDragStart,
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: Container(
          constraints: BoxConstraints.expand(
            height: MediaQuery.of(context).size.height,
          ),
          child: AnimatedOpacity(
            opacity: _dragOpacity,
            duration: Duration(milliseconds: _isDragging ? 0 : 200),
            child: Transform.scale(
              scale: _dragScale,
              child: PhotoView(
                controller: _controller,
                imageProvider: MemoryImage(widget.imageBytes),
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.contained * 5,
                initialScale: PhotoViewComputedScale.contained,
                disableGestures: false,
                enableRotation: false,
                tightMode: false,
                gaplessPlayback: true,
                // Using PhotoViewHeroAttributes for smoother transitions
                heroAttributes: PhotoViewHeroAttributes(tag: widget.heroTag),
                loadingBuilder:
                    (context, event) =>
                        const Center(child: CircularProgressIndicator()),
                errorBuilder:
                    (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 64,
                      ),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
