import 'dart:ui';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'edit_screen.dart';
import 'main_screen.dart';
import 'image_viewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:before_after/before_after.dart';
import 'package:image_app/components/glass_button.dart';
import 'package:image_app/components/glass_container.dart';
import 'package:image_app/components/flexible_dialog.dart';
import 'package:image_app/models/edited_image.dart';
import 'package:image_app/services/storage_service.dart';
import 'package:image_app/utils/log.dart';

// Add an enum for comparison modes
enum ComparisonMode { none, sideBySide, slider }

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
  ComparisonMode _comparisonMode = ComparisonMode.none;
  bool isLoading = true;
  bool isDeleting = false;
  Uint8List? editedImageBytes;
  Uint8List? originalImageBytes;
  String? errorMessage;
  bool _isOriginalSizeFit = false;
  double _sliderValue = 0.5; // Add state for slider position

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
    FlexibleDialog.showConfirmation(
      context: context,
      title: 'Delete Image',
      message:
          'Are you sure you want to delete this image? This action cannot be undone.',
      icon: Icons.delete_forever,
      iconColor: Colors.redAccent,
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDanger: true,
      onConfirm: _deleteImage,
    );
  }

  // Method for generating the correct hero tag
  String get _heroTag =>
      '${widget.heroTagPrefix}image_${widget.editedImage.id}';

  // New method to build control buttons
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 18),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ),
    );
  }

  // Updated method to handle fullscreen preview - removes slider case
  void _openFullscreenPreview() {
    if (editedImageBytes != null) {
      if (showComparison &&
          originalImageBytes != null &&
          _comparisonMode == ComparisonMode.sideBySide) {
        // Open side-by-side comparison viewer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => SideBySideImageViewer(
                  beforeImageBytes: originalImageBytes!,
                  afterImageBytes: editedImageBytes!,
                  promptTitle: widget.editedImage.prompt,
                ),
          ),
        );
      } else {
        // Open regular fullscreen viewer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => FullscreenImageViewer(
                  imageBytes: editedImageBytes!,
                  heroTag: _heroTag,
                  promptTitle: widget.editedImage.prompt,
                ),
          ),
        );
      }
    }
  }

  // Add new methods to open individual images in fullscreen
  void _openBeforeImageFullscreen() {
    if (originalImageBytes != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => FullscreenImageViewer(
                imageBytes: originalImageBytes!,
                heroTag: '${_heroTag}_before',
                promptTitle: 'Before: ${widget.editedImage.prompt}',
              ),
        ),
      );
    }
  }

  void _openAfterImageFullscreen() {
    if (editedImageBytes != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => FullscreenImageViewer(
                imageBytes: editedImageBytes!,
                heroTag: '${_heroTag}_after',
                promptTitle: 'After: ${widget.editedImage.prompt}',
              ),
        ),
      );
    }
  }

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

    return Center(
      // Added Center widget to center small images
      child: GestureDetector(
        onTap: _openFullscreenPreview,
        child: Hero(
          tag: _heroTag, // Use the consistent tag
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(
                      editedImageBytes!,
                      fit: _isOriginalSizeFit ? BoxFit.contain : BoxFit.cover,
                      gaplessPlayback: true,
                      cacheWidth: 1080, // Cache for smoother transitions
                    ),
                  ),
                ),

                // Keep control buttons inside the image
                Positioned(
                  bottom: 20,
                  right: 30,
                  child: Row(
                    children: [
                      // Fit to original size button
                      _buildControlButton(
                        icon:
                            _isOriginalSizeFit
                                ? Icons.fit_screen
                                : Icons.fullscreen,
                        onPressed: () {
                          setState(() {
                            _isOriginalSizeFit = !_isOriginalSizeFit;
                          });
                        },
                        tooltip:
                            _isOriginalSizeFit
                                ? 'Container fit'
                                : 'Original size',
                      ),

                      const SizedBox(width: 8),
                      // Fullscreen preview button
                      _buildControlButton(
                        icon: Icons.open_in_full,
                        onPressed: _openFullscreenPreview,
                        tooltip: 'Fullscreen preview',
                      ),
                    ],
                  ),
                ),
              ],
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
                      fit: _isOriginalSizeFit ? BoxFit.contain : BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  ),
                );
              },
            );
          },
        ),
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
          color: Colors.grey.withOpacity(0.3),
        ),
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      );
    }

    // Don't use Hero in the comparison view
    return GestureDetector(
      onTap: isAfter ? _openAfterImageFullscreen : _openBeforeImageFullscreen,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Image.memory(
                  imageBytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
                // Add subtle indicator that image is tappable
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.zoom_in,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
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
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.6),
                ],
              ),
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

    return _comparisonMode == ComparisonMode.slider
        ? _buildImageComparisonSlider()
        : Row(
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

  // Updated method to build the image comparison slider using before_after package
  Widget _buildImageComparisonSlider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 200,
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: BeforeAfter(
                value: _sliderValue,
                onValueChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                  });
                },
                thumbColor: Colors.white,
                before: Image.memory(
                  originalImageBytes!,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
                after: Image.memory(
                  editedImageBytes!,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
            ),

            // Add "BEFORE" label manually
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'BEFORE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Add "AFTER" label manually
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'AFTER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 18,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Edit Request',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              // Add info button to show full prompt
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
                onPressed: () => _showFullPromptDialog(context),
                tooltip: 'View full prompt',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            // Truncate the prompt to one line
            widget.editedImage.prompt.length > 100
                ? '${widget.editedImage.prompt.substring(0, 100)}...'
                : widget.editedImage.prompt,
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 20),

          // Comparison mode toggle
          if (originalImageBytes != null) ...[
            Center(
              child: Column(
                children: [
                  // Segmented button for comparison type
                  SegmentedButton<ComparisonMode>(
                    segments: const [
                      ButtonSegment(
                        value: ComparisonMode.none,
                        icon: Icon(Icons.image),
                        label: Text('Single'),
                      ),
                      ButtonSegment(
                        value: ComparisonMode.sideBySide,
                        icon: Icon(Icons.compare),
                        label: Text('Compare'),
                      ),
                      ButtonSegment(
                        value: ComparisonMode.slider,
                        icon: Icon(Icons.compare_arrows),
                        label: Text('Slider'),
                      ),
                    ],
                    selected: {_comparisonMode},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _comparisonMode = newSelection.first;
                        showComparison = _comparisonMode != ComparisonMode.none;
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      selectedForegroundColor: Colors.white,
                      selectedBackgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ],

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
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
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
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
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

  void _showFullPromptDialog(BuildContext context) {
    FlexibleDialog.showCustomDialog(
      context: context,
      title: 'Edit Request Details',
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        child: SingleChildScrollView(
          child: Text(
            widget.editedImage.prompt,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// Side by Side Image Viewer remains unchanged
class SideBySideImageViewer extends StatelessWidget {
  final Uint8List beforeImageBytes;
  final Uint8List afterImageBytes;
  final String? promptTitle;

  const SideBySideImageViewer({
    Key? key,
    required this.beforeImageBytes,
    required this.afterImageBytes,
    this.promptTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.4),
        title: Text(promptTitle ?? 'Image Comparison'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4.0,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'BEFORE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Image.memory(
                        beforeImageBytes,
                        fit: BoxFit.contain,
                      ),
                    ),
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
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Image.memory(afterImageBytes, fit: BoxFit.contain),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Fix the SliderImageViewer implementation
class SliderImageViewer extends StatelessWidget {
  final Uint8List beforeImageBytes;
  final Uint8List afterImageBytes;
  final String? promptTitle;

  const SliderImageViewer({
    Key? key,
    required this.beforeImageBytes,
    required this.afterImageBytes,
    this.promptTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.4),
        title: Text(promptTitle ?? 'Image Comparison'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4.0,
          child: Stack(
            children: [
              BeforeAfter(
                value: 0.5, // Initial value
                thumbColor: Colors.white,
                before: Image.memory(beforeImageBytes, fit: BoxFit.contain),
                after: Image.memory(afterImageBytes, fit: BoxFit.contain),
              ),

              // Add "BEFORE" label manually
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'BEFORE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Add "AFTER" label manually
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'AFTER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
