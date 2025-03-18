import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:image_app/utils/log.dart';
import 'package:image_picker/image_picker.dart';
import 'result_screen.dart';
import 'edit_screen.dart';
import '../utils/app_settings.dart';
import '../services/storage_service.dart';
import '../models/edited_image.dart';

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
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadSavedImages();
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

  // Updated method to handle image picking
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        // User canceled the picker
        return;
      }

      if (!mounted) return;

      // Show loading indicator
      setState(() {
        _isLoadingImages = true;
      });

      // Copy the picked image to permanent storage
      final String pickedPath = pickedFile.path;
      final String permanentPath = await StorageService.copyImageToStorage(
        pickedPath,
      );

      setState(() {
        _isLoadingImages = false;
      });

      // Debug
      printDebug('📷 Picked image path: $pickedPath');
      printDebug('📷 Permanent image path: $permanentPath');

      if (!mounted) return;

      // Navigate to EditScreen with the permanent path
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  EditScreen(imageUrl: permanentPath, previousPrompt: ''),
        ),
      ).then((_) => _loadSavedImages()); // Refresh the list when returning
    } catch (e) {
      // Show error if something goes wrong
      if (!mounted) return;
      printDebug('❌ Error picking image: $e');

      setState(() {
        _isLoadingImages = false;
      });

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

  // Method to show image source selection dialog
  void _showImageSourceDialog() {
    final blurEffectsEnabled = AppSettings.instance.blurEffectsEnabled;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child:
                blurEffectsEnabled
                    ? BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: _buildDialogContent(context),
                    )
                    : _buildDialogContent(context),
          ),
        );
      },
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select Image Source',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSourceOption(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              _buildSourceOption(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceOption({
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

  @override
  Widget build(BuildContext context) {
    final blurEffectsEnabled = AppSettings.instance.blurEffectsEnabled;

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

          // Frosted glass effect - only if blur is enabled
          if (blurEffectsEnabled)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withValues(alpha: 0.05)),
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
                        _buildSectionHeader('Editing Features'),

                        const SizedBox(height: 10),

                        _buildHorizontalFeaturesList(context),

                        const SizedBox(height: 25),

                        // Recently Edited Section
                        _buildSectionHeader('Recently Edited'),

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
            'PhotoMagic AI',
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
        onTap: _showImageSourceDialog,
        child: Container(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
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
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Widget _buildHorizontalFeaturesList(BuildContext context) {
    final features = [
      {'icon': Icons.person_add, 'name': 'Add People'},
      {'icon': Icons.remove_circle_outline, 'name': 'Remove Objects'},
      {'icon': Icons.style, 'name': 'Change Style'},
      {'icon': Icons.landscape, 'name': 'Change Background'},
      {'icon': Icons.auto_fix_high, 'name': 'Enhanced'},
    ];

    return SizedBox(
      height: 130,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        scrollDirection: Axis.horizontal,
        itemCount: features.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // Feature selection logic
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    features[index]['icon'] as IconData,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    features[index]['name'] as String,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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

    final blurEffectsEnabled = AppSettings.instance.blurEffectsEnabled;

    // Modified to work within SingleChildScrollView
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _savedImages.length,
      itemBuilder: (context, index) {
        final editedImage = _savedImages[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ResultScreen(
                      editedImage: editedImage,
                      heroTagPrefix: 'dashboard_', // Add this parameter
                    ),
              ),
            ).then((_) => _loadSavedImages()); // Refresh list when returning
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  blurEffectsEnabled
                      ? BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: _buildEditItemContainer(editedImage),
                      )
                      : _buildEditItemContainer(editedImage),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditItemContainer(EditedImage editedImage) {
    return FutureBuilder<Uint8List?>(
      future: StorageService.loadImageBytes(editedImage.localPath),
      builder: (context, snapshot) {
        final imageData = snapshot.data;
        final hasImage =
            snapshot.connectionState == ConnectionState.done &&
            imageData != null;

        return Container(
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            children: [
              // The Hero widget with proper tag and image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: SizedBox(
                  width: 80,
                  height: 110,
                  child: Hero(
                    tag:
                        'dashboard_image_${editedImage.id}', // Updated hero tag with prefix
                    child: Material(
                      color: Colors.transparent,
                      child:
                          hasImage
                              ? Image.memory(
                                imageData,
                                fit: BoxFit.cover,
                                width: 80,
                                height: double.infinity,
                                gaplessPlayback: true,
                                cacheWidth:
                                    160, // Cache image for smoother transitions
                              )
                              : Container(
                                width: 80,
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.white70,
                                ),
                              ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        editedImage.timestamp.toString().substring(0, 16),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        editedImage.prompt,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        editedImage.title,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
