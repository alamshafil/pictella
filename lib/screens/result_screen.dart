import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:typed_data';
import '../components/glass_button.dart';
import '../components/glass_container.dart';
import '../models/edited_image.dart';
import '../services/storage_service.dart';
import 'edit_screen.dart';
import 'main_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import '../utils/log.dart';
import 'image_viewer.dart';

class ResultScreen extends StatefulWidget {
  final EditedImage editedImage;
  final bool isFromEditScreen;
  final String heroTagPrefix;

  const ResultScreen({
    super.key,
    required this.editedImage,
    this.isFromEditScreen = false,
    this.heroTagPrefix = '', // Default to empty for backward compatibility
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool showComparison = false;
  bool isLoading = true;
  bool isDeleting = false;
  Uint8List? editedImageBytes;
  Uint8List? originalImageBytes;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Load edited image bytes
      final bytes = await StorageService.loadImageBytes(
        widget.editedImage.localPath,
      );
      if (bytes == null) {
        throw Exception("Couldn't load edited image");
      }

      // Load original image if available
      Uint8List? originalBytes;
      if (widget.editedImage.originalImagePath != null) {
        originalBytes = await StorageService.loadImageBytes(
          widget.editedImage.originalImagePath!,
        );
      }

      setState(() {
        editedImageBytes = bytes;
        originalImageBytes = originalBytes;
        isLoading = false;
      });
    } catch (e) {
      printDebug('❌ Error loading images: $e');
      setState(() {
        errorMessage = 'Failed to load images: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _saveToGallery() async {
    try {
      // Save to gallery using gallery_saver
      await GallerySaver.saveImage(widget.editedImage.localPath);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image saved to gallery')));
    } catch (e) {
      printDebug('❌ Error saving to gallery: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save image: $e')));
    }
  }

  Future<void> _shareImage() async {
    try {
      // Create a temporary file for sharing
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/shared_image.png');
      await file.writeAsBytes(editedImageBytes!);

      // Share the file
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Check out this image I edited with PhotoMagic AI!');
    } catch (e) {
      printDebug('❌ Error sharing image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to share image: $e')));
    }
  }

  // New method to handle image deletion with confirmation
  Future<void> _deleteImage() async {
    setState(() {
      isDeleting = true;
    });

    try {
      // Delete the image from storage
      await StorageService.deleteEditedImage(widget.editedImage.id);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image deleted successfully')),
      );

      // Go back to previous screen
      Navigator.of(context).pop(true); // Pass true to indicate deletion
    } catch (e) {
      printDebug('❌ Error deleting image: $e');
      if (!mounted) return;

      setState(() {
        isDeleting = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete image: $e')));
    }
  }

  // New method to go to home/dashboard
  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (Route<dynamic> route) => false,
    );
  }

  // Complete implementation of the confirmation dialog
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.delete_forever,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Delete Image',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Are you sure you want to delete this image? This action cannot be undone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _deleteImage();
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Method for generating the correct hero tag
  String get _heroTag =>
      '${widget.heroTagPrefix}image_${widget.editedImage.id}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Delete button - now calls the confirmation dialog
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: isDeleting ? null : _showDeleteConfirmationDialog,
            tooltip: 'Delete image',
          ),

          // Home button (only if coming from edit screen)
          if (widget.isFromEditScreen)
            IconButton(
              icon: const Icon(Icons.home_outlined, color: Colors.white),
              onPressed: _goToHome,
              tooltip: 'Go to home',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Blurred background
          _buildBackgroundBlur(),

          // Content
          SafeArea(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                    ? Center(child: Text(errorMessage!))
                    : isDeleting
                    ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text("Deleting image..."),
                        ],
                      ),
                    )
                    : Column(
                      children: [
                        // Image Display
                        Expanded(
                          child: Center(
                            child:
                                showComparison
                                    ? _buildBeforeAfterComparison()
                                    : _buildHeroImage(),
                          ),
                        ),

                        // Prompt result card
                        _buildEditResultCard(context),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  // New method specifically for the Hero image
  Widget _buildHeroImage() {
    if (editedImageBytes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => FullscreenImageViewer(
                  imageBytes: editedImageBytes!,
                  heroTag: _heroTag, // Use the consistent tag
                ),
          ),
        );
      },
      child: Hero(
        tag: _heroTag, // Use the consistent tag
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.memory(
                editedImageBytes!,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                cacheWidth: 1080, // Cache for smoother transitions
              ),
            ),
          ),
        ),
        // Keep existing flightShuttleBuilder
        flightShuttleBuilder: (
          BuildContext flightContext,
          Animation<double> animation,
          HeroFlightDirection flightDirection,
          BuildContext fromHeroContext,
          BuildContext toHeroContext,
        ) {
          // Custom flight shuttle for smoother image transitions
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    20.0 *
                            (flightDirection == HeroFlightDirection.push
                                ? animation.value
                                : 1.0 - animation.value) +
                        12.0 *
                            (flightDirection == HeroFlightDirection.push
                                ? 1.0 - animation.value
                                : animation.value),
                  ),
                  child: Image.memory(
                    editedImageBytes!,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildImageContainer({required bool isAfter}) {
    final imageBytes = isAfter ? editedImageBytes : originalImageBytes;

    if (imageBytes == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey.withValues(alpha: 0.3),
        ),
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            size: 64,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    // Don't use Hero in the comparison view
    return Material(
      type: MaterialType.transparency,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundBlur() {
    if (editedImageBytes == null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF01579B), Color(0xFF111111)],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: MemoryImage(editedImageBytes!),
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBeforeAfterComparison() {
    if (originalImageBytes == null) {
      // If original image is not available
      return Center(child: Text("Original image not available for comparison"));
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'BEFORE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              _buildImageContainer(isAfter: false),
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'AFTER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              _buildImageContainer(isAfter: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditResultCard(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.all(20),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 18,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                'Edit Request',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.editedImage.prompt,
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 20),

          // Before/After Toggle Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: TextButton.icon(
              icon: Icon(
                showComparison ? Icons.visibility_off : Icons.compare,
                color: Colors.white,
              ),
              label: Text(
                showComparison ? 'Hide Comparison' : 'Show Before & After',
                style: const TextStyle(color: Colors.white),
              ),
              onPressed:
                  originalImageBytes != null
                      ? () {
                        setState(() {
                          showComparison = !showComparison;
                        });
                      }
                      : null,
            ),
          ),

          const SizedBox(height: 15),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saveToGallery,
                  icon: const Icon(Icons.download),
                  label: const Text('Save'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareImage,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          GlassButton(
            text: 'Edit Further',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => EditScreen(
                        imageUrl: widget.editedImage.localPath,
                        previousPrompt: '',
                      ),
                ),
              ).then((_) => _loadImages()); // Refresh when returning
            },
            fullWidth: true,
            icon: Icons.edit,
          ),
        ],
      ),
    );
  }
}
