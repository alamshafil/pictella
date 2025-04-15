import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_app/components/glass_container.dart';
import 'package:image_app/components/flexible_dialog.dart';
import 'package:image_app/models/edited_image.dart';
import 'package:image_app/models/saved_style.dart';
import 'package:image_app/screens/prompts_screen.dart';
import 'package:image_app/screens/search_screen.dart';
import 'package:image_app/services/storage_service.dart';
import 'package:image_app/utils/log.dart';
import 'package:image_app/config/advanced_prompts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'result_screen.dart';
import 'edit_screen.dart';
import 'styles_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool isInTabView;

  const DashboardScreen({super.key, this.isInTabView = false});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoadingImages = false;
  List<EditedImage> _savedImages = [];
  bool _isLoadingStyles = false;
  List<SavedStyle> _savedStyles = [];
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadSavedImages();
    _loadSavedStyles();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Updated method to handle image picking and navigate with optional style
  Future<void> _pickImageAndNavigate({
    required ImageSource source,
    SavedStyle? styleToApply, // Optional style
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 90,
      );

      if (pickedFile == null || !mounted) return;

      setState(
        () => _isLoadingImages = true,
      ); // Use general loading flag or add a new one

      final String pickedPath = pickedFile.path;

      setState(() => _isLoadingImages = false);

      printDebug('📷 Picked image path: $pickedPath');
      if (styleToApply != null) {
        printDebug('🎨 Applying style: ${styleToApply.name}');
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => EditScreen(
                imageUrl: pickedPath,
                previousPrompt: '',
                initialStyle: styleToApply, // Pass the style here
              ),
        ),
      ).then((_) {
        // Refresh both lists when returning
        _loadSavedImages();
        _loadSavedStyles(); // Refresh styles as well
      });
    } catch (e) {
      if (!mounted) return;
      printDebug('❌ Error picking image: $e');
      setState(() => _isLoadingImages = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _loadSavedImages() async {
    setState(() {
      _isLoadingImages = true;
    });

    try {
      final images = await StorageService.getEditedImages();
      setState(() {
        _savedImages = images;
        _isLoadingImages = false;
      });
    } catch (e) {
      printDebug('❌ Error loading saved images: $e');
      setState(() {
        _isLoadingImages = false;
      });
    }
  }

  // Load saved styles
  Future<void> _loadSavedStyles() async {
    setState(() => _isLoadingStyles = true);
    try {
      final styles = await StorageService.getSavedStyles();
      if (mounted) {
        setState(() {
          _savedStyles = styles;
          _isLoadingStyles = false;
        });
      }
    } catch (e) {
      printDebug('❌ Error loading saved styles: $e');
      if (mounted) {
        setState(() => _isLoadingStyles = false);
      }
    }
  }

  // Method to show image source selection dialog, now accepts optional style
  void _showImageSourceDialog({SavedStyle? styleToApply}) {
    FlexibleDialog.showImageSource(
      context: context,
      onSourceSelected: (source) {
        _pickImageAndNavigate(source: source, styleToApply: styleToApply);
      },
      title:
          styleToApply != null
              ? 'Select Image for Style "${styleToApply.name}"'
              : 'Select Image Source',
      message:
          styleToApply != null
              ? 'Choose an image to apply the selected style to.'
              : 'Choose how you want to upload your image',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF01579B), Color(0xFF111111)],
              ),
            ),
          ),

          // Content
          SafeArea(
            bottom: false, // Allow content to extend to bottom (under navbar)
            child: Column(
              children: [
                // Top navbar with fading effect
                _buildTopNavbar(),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Upload button section
                        _buildUploadSection(context),

                        const SizedBox(height: 25),

                        // Editing Features Section
                        _buildSectionHeader(
                          'Editing Prompts',
                          Icons.edit,
                          onActionPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const AdvancedPromptsScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        _buildHorizontalFeaturesList(context),

                        const SizedBox(height: 25),

                        // Saved Styles Section
                        _buildSectionHeader(
                          'Saved Styles',
                          Icons.style,
                          onActionPressed: () {
                            // Add action to navigate
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const StylesScreen(),
                              ),
                            ).then(
                              (_) => _loadSavedStyles(),
                            ); // Refresh on return
                          },
                        ),
                        const SizedBox(height: 10),

                        _buildSavedStylesList(),

                        const SizedBox(height: 25),

                        // Recently Edited Section
                        _buildSectionHeader(
                          'Recently Edited',
                          Icons.history,
                          onActionPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SearchScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        _buildRecentlyEditedList(),

                        // Extra space at bottom to allow content to be visible under the navbar
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // We no longer need a bottom navigation bar here as it's handled by MainScreen
      bottomNavigationBar: widget.isInTabView ? null : null,
    );
  }

  Widget _buildTopNavbar() {
    return Stack(
      children: [
        // The main profile section
        _buildProfileSection(),
      ],
    );
  }

  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withValues(alpha: 0.3),
                  spreadRadius: 1,
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.photo_camera,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Pictella AI',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildUploadSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GestureDetector(
        onTap: () => _showImageSourceDialog(), // Call without style here
        child: Container(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 36,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload a photo to edit',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData? icon, {
    VoidCallback? onActionPressed,
  }) {
    return Row(
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 8),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.9),
              size: 24,
            ),
          ),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const Spacer(), // Add Spacer to push the button to the end
        if (onActionPressed != null)
          Padding(
            padding: const EdgeInsets.only(
              right: 12,
            ), // Adjust padding if needed
            child: IconButton(
              icon: Icon(
                Icons.arrow_forward_ios, // Use iOS style arrow
                color: Colors.white.withValues(alpha: 0.9),
                size: 18, // Slightly smaller arrow
              ),
              onPressed: onActionPressed,
              tooltip: 'View all',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8), // Add padding for tap area
            ),
          ),
      ],
    );
  }

  Widget _buildHorizontalFeaturesList(BuildContext context) {
    final displayedPrompts = advancedPrompts.take(10).toList();

    return Column(
      children: [
        SizedBox(
          height: 130,
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white,
                  Colors.white,
                  Colors.white.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.05, 0.95, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              scrollDirection: Axis.horizontal,
              itemCount: displayedPrompts.length,
              itemBuilder: (context, index) {
                final prompt = displayedPrompts[index];
                return GestureDetector(
                  onTap: () => _showImageSourceWithPrompt(prompt),
                  child: GlassContainer(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    blurEnabled: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: prompt.accentColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            prompt.icon,
                            color: prompt.accentColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(prompt.title, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // --- New Widget for Saved Styles List ---
  Widget _buildSavedStylesList() {
    if (_isLoadingStyles) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_savedStyles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Center(
          child: Text(
            'No saved styles yet. Save styles from the edit screen.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
        ),
      );
    }

    // Limit the number of styles shown horizontally
    final displayedStyles = _savedStyles.take(20).toList();

    // Horizontal scrolling list similar to recently edited
    return SizedBox(
      height: 110, // Adjust height for style cards
      child: ShaderMask(
        // ... (same shader as recently edited) ...
        shaderCallback: (bounds) {
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white,
              Colors.white,
              Colors.white.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.05, 0.95, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          scrollDirection: Axis.horizontal,
          itemCount: displayedStyles.length, // Use limited list
          itemBuilder: (context, index) {
            final style = displayedStyles[index]; // Use limited list
            return _buildStyleCard(style);
          },
        ),
      ),
    );
  }

  Widget _buildStyleCard(SavedStyle style) {
    return GestureDetector(
      onTap: () {
        // Navigate to the StylesScreen, optionally passing the ID to pre-select
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StylesScreen()),
        ).then((_) => _loadSavedStyles()); // Refresh on return
      },
      child: Container(
        width: 150, // Adjust width
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.style, size: 20, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    style.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(), // Pushes timestamp to bottom
            Text(
              DateFormat('MMM dd, h:mma').format(style.timestamp.toLocal()),
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --- End Saved Styles Widget ---

  void _showImageSourceWithPrompt(AdvancedPrompt prompt) {
    FlexibleDialog.showCustomDialog(
      context: context,
      icon: prompt.icon,
      iconColor: prompt.accentColor,
      title: prompt.title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            prompt.description,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSourceOptionForPrompt(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: () {
                  Navigator.pop(context);
                  _pickImageWithPrompt(ImageSource.camera, prompt);
                },
              ),
              const SizedBox(width: 20),
              _buildSourceOptionForPrompt(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImageWithPrompt(ImageSource.gallery, prompt);
                },
              ),
            ],
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
  }

  Future<void> _pickImageWithPrompt(
    ImageSource source,
    AdvancedPrompt prompt,
  ) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 90,
    );

    if (pickedFile == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditScreen(
              imageUrl: pickedFile.path,
              previousPrompt: prompt.prompt,
            ),
      ),
    ).then((_) => _loadSavedImages());
  }

  Widget _buildRecentlyEditedList() {
    if (_isLoadingImages) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_savedImages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.image_not_supported,
                size: 48,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No edited images yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your edited images will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Horizontal scrolling list with faded edges
    return SizedBox(
      height: 220, // Adjust height as needed
      child: ShaderMask(
        shaderCallback: (bounds) {
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white,
              Colors.white,
              Colors.white.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.05, 0.95, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          scrollDirection: Axis.horizontal,
          itemCount: _savedImages.length,
          itemBuilder: (context, index) {
            final editedImage = _savedImages[index];
            return _buildImageGridItem(editedImage);
          },
        ),
      ),
    );
  }

  Widget _buildImageGridItem(EditedImage image) {
    // Pre-load the image to avoid flashing during Hero transitions
    final Future<Uint8List?> imageFuture = StorageService.loadImageBytes(
      image.localPath,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ResultScreen(
                  editedImage: image,
                  heroTagPrefix: 'dashboard_',
                ),
          ),
        ).then((_) => _loadSavedImages());
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Improved thumbnail with Hero and optimized image loading
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Hero(
                  tag: 'dashboard_image_${image.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: FutureBuilder<Uint8List?>(
                      future: imageFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.data != null) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            gaplessPlayback: true, // Prevent image flickering
                            frameBuilder: (
                              context,
                              child,
                              frame,
                              wasSynchronouslyLoaded,
                            ) {
                              // Use a fade transition if the image wasn't loaded immediately
                              return frame == null
                                  ? Container(
                                    color: Colors.grey[800],
                                    child: Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  : child;
                            },
                          );
                        }
                        // Show loading indicator with same background as the loaded image container
                        return Container(
                          color: Colors.grey[800],
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  flightShuttleBuilder: (
                    BuildContext flightContext,
                    Animation<double> animation,
                    HeroFlightDirection flightDirection,
                    BuildContext fromHeroContext,
                    BuildContext toHeroContext,
                  ) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return Material(
                          color: Colors.transparent,
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: FutureBuilder<Uint8List?>(
                              future: imageFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                        ConnectionState.done &&
                                    snapshot.data != null) {
                                  return Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    gaplessPlayback: true,
                                  );
                                }
                                return Container(
                                  color: Colors.grey[800],
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    image.prompt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, h:mma').format(image.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOptionForPrompt({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
                color: Colors.white.withValues(alpha: 0.1),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
