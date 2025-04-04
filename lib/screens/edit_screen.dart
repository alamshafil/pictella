import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_app/components/glass_button.dart';
import 'package:image_app/components/flexible_dialog.dart';
import 'package:image_app/screens/prompts_screen.dart';
import 'package:image_app/screens/image_viewer.dart';
import 'package:image_app/screens/result_screen.dart';
import 'package:image_app/services/gemini_api_service.dart';
import 'package:image_app/services/storage_service.dart';
import 'package:image_app/config/advanced_prompts.dart';
import 'package:shimmer/shimmer.dart';

class EditScreen extends StatefulWidget {
  final String imageUrl;
  final String previousPrompt;

  const EditScreen({
    super.key,
    required this.imageUrl,
    this.previousPrompt = '',
  });

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> with TickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Uint8List? _originalImageBytes;
  bool _isOriginalSizeFit = false;

  // Advanced options
  bool _showAdvancedOptions = false;
  bool _enhancedThinkingEnabled = false;
  double _temperature = 0.7;

  // AI Model selection
  String _selectedAIModel = "Gemini 2.0 Flash"; // Default model
  final List<String> _availableAIModels = ["Gemini 2.0 Flash"];

  // Bottom sheet configuration
  bool _isBottomSheetExpanded = true;
  final double _collapsedBottomSheetHeight =
      70.0; // Slightly reduced height when collapsed
  final double _expandedBottomSheetHeight = 320.0; // Height when expanded
  late AnimationController _bottomSheetAnimationController;
  late Animation<double> _bottomSheetHeightAnimation;

  // List to store edit history
  final List<Map<String, dynamic>> _editHistory = [];
  int _currentEditIndex = -1; // -1 means showing original image

  // Animation controller for transitions
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Suggestions with icons
  final List<AdvancedPrompt> _suggestions = advancedPrompts;

  @override
  void initState() {
    super.initState();
    if (widget.previousPrompt.isNotEmpty) {
      _promptController.text = widget.previousPrompt;
    }

    // Initialize animation controller for image transitions
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Initialize bottom sheet animation controller
    _bottomSheetAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Animation for bottom sheet height
    _bottomSheetHeightAnimation = Tween<double>(
      begin: _collapsedBottomSheetHeight,
      end: _expandedBottomSheetHeight,
    ).animate(
      CurvedAnimation(
        parent: _bottomSheetAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Animation for image area scaling

    // Start with expanded bottom sheet
    _bottomSheetAnimationController.value = 1.0;

    _loadOriginalImage();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _animationController.dispose();
    _bottomSheetAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadOriginalImage() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load the original image bytes - handle both absolute and relative paths
      Uint8List? imageBytes;

      if (widget.imageUrl.startsWith('/')) {
        // Absolute path
        final file = File(widget.imageUrl);
        if (await file.exists()) {
          imageBytes = await file.readAsBytes();
        }
      } else {
        // Relative path
        imageBytes = await StorageService.loadImageBytes(widget.imageUrl);
      }

      if (imageBytes == null) {
        throw Exception("Couldn't load image from path: ${widget.imageUrl}");
      }

      setState(() {
        _originalImageBytes = imageBytes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load image: $e';
        _isLoading = false;
      });
    }
  }

  // Get current image bytes based on selected index
  Uint8List _getCurrentImageBytes() {
    if (_currentEditIndex >= 0 && _currentEditIndex < _editHistory.length) {
      return _editHistory[_currentEditIndex]['imageBytes'];
    }
    return _originalImageBytes!;
  }

  // Method for saving current edit and adding to history
  Future<void> _saveCurrentEdit() async {
    // Only proceed if we have a prompt and source image
    if (_promptController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an edit description';
      });
      return;
    }

    final Uint8List sourceImageBytes = _getCurrentImageBytes();

    // Set loading state
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Format the prompt based on enhanced thinking mode
      String formattedPrompt = _promptController.text;
      if (_enhancedThinkingEnabled) {
        formattedPrompt =
            "${_promptController.text}. First, describe this image. Then, describe the new image you will create. Then generate it.";
      }

      // Call the Gemini API service with selected model
      final base64GeneratedImage = await GeminiApiService.editImage(
        imageData: sourceImageBytes,
        prompt: formattedPrompt,
        // model: _selectedAIModel, // TODO: Pass the selected model
      );

      // Convert base64 back to image bytes
      final generatedImageBytes = base64Decode(base64GeneratedImage);

      // Play animation
      _animationController.forward(from: 0.0);

      // Add to edit history
      setState(() {
        _editHistory.add({
          'prompt': _promptController.text,
          'imageBytes': generatedImageBytes,
          'timestamp': DateTime.now(),
        });
        _currentEditIndex = _editHistory.length - 1;
        _isLoading = false;
        _promptController.clear();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate image: $e';
        _isLoading = false;
      });
    }
  }

  // Save the edited image and navigate to result screen
  Future<void> _finishEditing() async {
    if (_editHistory.isEmpty) {
      setState(() {
        _errorMessage = 'Please make at least one edit first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get the latest edit
      final latestEdit = _editHistory[_currentEditIndex];
      final imageBytes = latestEdit['imageBytes'] as Uint8List;
      final prompt = latestEdit['prompt'] as String;

      // Save the edited image
      final editedImage = await StorageService.saveEditedImage(
        imageBytes: imageBytes,
        prompt: prompt,
        originalImagePath: widget.imageUrl,
      );

      if (!mounted) return;

      // Navigate to result screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => ResultScreen(
                editedImage: editedImage,
                isFromEditScreen:
                    true, // Indicate we're coming from edit screen
              ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save image: $e';
        _isLoading = false;
      });
    }
  }

  // Smooth toggle for bottom sheet with proper animations
  void _toggleBottomSheet() {
    if (_isBottomSheetExpanded) {
      // Collapsing
      _bottomSheetAnimationController.reverse().then((_) {
        setState(() {
          _isBottomSheetExpanded = false;
        });
      });
    } else {
      // Expanding
      setState(() {
        _isBottomSheetExpanded = true;
      });
      _bottomSheetAnimationController.forward();
    }
  }

  void _showConfirmAdvancedEditDialog(AdvancedPrompt prompt) {
    FlexibleDialog.showConfirmation(
      context: context,
      title: prompt.title,
      message: prompt.description,
      icon: prompt.icon,
      iconColor: prompt.accentColor,
      confirmText: 'Apply Edit',
      cancelText: 'Cancel',
      onConfirm: () {
        _promptController.text = prompt.prompt;
        _saveCurrentEdit();
      },
    );
  }

  // Check if bottom sheet animation is at either end
  bool _isBottomSheetAnimationCompleted() {
    return _bottomSheetAnimationController.status ==
            AnimationStatus.completed ||
        _bottomSheetAnimationController.status == AnimationStatus.dismissed;
  }

  // Content to show during animation between states
  Widget _buildAnimatingBottomSheetContent() {
    // Calculate the available height during animation
    final double availableHeight = _bottomSheetHeightAnimation.value;

    // Dynamically determine which content to show and how to limit its height
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: availableHeight, // Explicitly constrain the height
        child:
            _bottomSheetAnimationController.value > 0.5
                ? Opacity(
                  opacity: (_bottomSheetAnimationController.value - 0.5) * 2,
                  child: _buildExpandedBottomSheetContent(),
                )
                : Opacity(
                  opacity: (0.5 - _bottomSheetAnimationController.value) * 2,
                  child: _buildCollapsedBottomSheetContent(),
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate available height for image display
    final double screenHeight = MediaQuery.of(context).size.height;
    final double appBarHeight = AppBar().preferredSize.height;
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Image',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Blurred background using the current image being edited
          _buildBackgroundBlur(),

          // Main content with animated layout
          AnimatedBuilder(
            animation: _bottomSheetAnimationController,
            builder: (context, child) {
              final double currentBottomSheetHeight =
                  _bottomSheetHeightAnimation.value;
              final double imageAreaHeight =
                  screenHeight -
                  appBarHeight -
                  statusBarHeight -
                  currentBottomSheetHeight -
                  bottomPadding;

              return Stack(
                children: [
                  // Image area - expands and contracts with animation
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: imageAreaHeight + statusBarHeight + appBarHeight,
                    child: SafeArea(
                      bottom: false,
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: _buildImageCarousel(),
                        ),
                      ),
                    ),
                  ),

                  // Bottom sheet - fixed at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: currentBottomSheetHeight + bottomPadding,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        border: Border(
                          top: BorderSide(
                            width: 1.8,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Padding(
                            padding: EdgeInsets.only(bottom: bottomPadding),
                            child:
                                _isBottomSheetAnimationCompleted()
                                    ? (_isBottomSheetExpanded
                                        ? _buildExpandedBottomSheetContent()
                                        : _buildCollapsedBottomSheetContent())
                                    : _buildAnimatingBottomSheetContent(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundBlur() {
    final Uint8List? backgroundImageBytes =
        _originalImageBytes != null
            ? (_currentEditIndex >= 0 && _currentEditIndex < _editHistory.length
                ? _editHistory[_currentEditIndex]['imageBytes']
                : _originalImageBytes)
            : null;

    if (backgroundImageBytes == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF01579B).withValues(alpha: 0.8),
              Colors.black.withValues(alpha: 0.8),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: MemoryImage(backgroundImageBytes),
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
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Column(
      children: [
        // Main image display with animation
        Expanded(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Center(
                child: AnimatedOpacity(
                  opacity: _isLoading ? 0.7 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Stack(
                    children: [
                      Container(
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
                          child: Stack(
                            children: [
                              _buildCurrentImageDisplay(),
                              if (_isLoading)
                                Positioned.fill(
                                  child: Shimmer.fromColors(
                                    baseColor: Colors.black45,
                                    highlightColor: Colors.black26,
                                    child: Container(color: Colors.white),
                                  ),
                                ),
                              if (_isLoading)
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Generating your edit...',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Control buttons
                      Positioned(
                        bottom: 10,
                        right: 10,
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
              );
            },
          ),
        ),
        // Edit history carousel with fading edges
        if (_editHistory.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0),
                    Colors.black,
                    Colors.black,
                    Colors.black.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.1, 0.9, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _editHistory.length + 1, // +1 for original image
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemBuilder: (context, index) {
                  bool isSelected = index == _currentEditIndex + 1;

                  if (index == 0) {
                    // Original image thumbnail
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentEditIndex = -1;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: isSelected ? 58 : 50,
                        margin: EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: isSelected ? 0 : 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                isSelected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow:
                              isSelected
                                  ? [
                                    BoxShadow(
                                      color: Colors.blue.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                  : null,
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                isSelected ? 6 : 7,
                              ),
                              child:
                                  _originalImageBytes != null
                                      ? Image.memory(
                                        _originalImageBytes!,
                                        fit: BoxFit.cover,
                                      )
                                      : Container(color: Colors.grey),
                            ),
                            if (isSelected)
                              Positioned(
                                right: 3,
                                bottom: 3,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Edit history thumbnails
                  final historyIndex = index - 1;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentEditIndex = historyIndex;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: isSelected ? 58 : 50,
                      margin: EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: isSelected ? 0 : 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                                : null,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              isSelected ? 6 : 7,
                            ),
                            child: Image.memory(
                              _editHistory[historyIndex]['imageBytes'],
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              right: 3,
                              bottom: 3,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCurrentImageDisplay() {
    // Show current image (either original or from edit history)
    Widget imageWidget;

    if (_currentEditIndex >= 0 && _currentEditIndex < _editHistory.length) {
      // Show selected edit from history
      imageWidget = GestureDetector(
        onTap: _openFullscreenPreview,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: FadeTransition(
            opacity: _animation,
            child: Image.memory(
              _editHistory[_currentEditIndex]['imageBytes'],
              fit: _isOriginalSizeFit ? BoxFit.contain : BoxFit.cover,
            ),
          ),
        ),
      );
    } else if (_originalImageBytes != null) {
      // Show original image from memory
      imageWidget = GestureDetector(
        onTap: _openFullscreenPreview,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Image.memory(
            _originalImageBytes!,
            fit: _isOriginalSizeFit ? BoxFit.contain : BoxFit.cover,
          ),
        ),
      );
    } else {
      // Fallback - try to load from path
      return widget.imageUrl.startsWith('/')
          ? GestureDetector(
            onTap: _openFullscreenPreview,
            child: Image.file(
              File(widget.imageUrl),
              fit: _isOriginalSizeFit ? BoxFit.contain : BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 64,
                  ),
                );
              },
            ),
          )
          : FutureBuilder<String>(
            future: StorageService.getAbsolutePath(widget.imageUrl),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                return GestureDetector(
                  onTap: _openFullscreenPreview,
                  child: Image.file(
                    File(snapshot.data!),
                    fit: _isOriginalSizeFit ? BoxFit.contain : BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 64,
                        ),
                      );
                    },
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          );
    }

    // Return the image with proper fit mode
    return imageWidget;
  }

  // Method to handle fullscreen preview
  void _openFullscreenPreview() {
    if (_currentEditIndex >= 0 && _currentEditIndex < _editHistory.length) {
      // Preview edited image
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => FullscreenImageViewer(
                imageBytes: _editHistory[_currentEditIndex]['imageBytes'],
                heroTag: 'preview_edit_$_currentEditIndex',
                promptTitle: _editHistory[_currentEditIndex]['prompt'],
              ),
        ),
      );
    } else if (_originalImageBytes != null) {
      // Preview original image
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => FullscreenImageViewer(
                imageBytes: _originalImageBytes!,
                heroTag: 'preview_original',
                promptTitle: 'Original Image',
              ),
        ),
      );
    }
  }

  // Builds a control button with consistent styling
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
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
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

  Widget _buildCollapsedBottomSheetContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            _editHistory.isNotEmpty ? Icons.edit : Icons.draw,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _editHistory.isNotEmpty
                  ? "Continue editing this image..."
                  : "Describe how you want to edit...",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
          _buildExpandToggle(expanded: false),
        ],
      ),
    );
  }

  // The expanded version of the bottom sheet with scrollable content
  Widget _buildExpandedBottomSheetContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row with collapse button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Icon(
                _editHistory.isNotEmpty ? Icons.edit : Icons.draw,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Text(
                _editHistory.isNotEmpty
                    ? 'Continue Editing'
                    : 'Describe your edit',
                style: TextStyle(fontSize: 16),
              ),
              const Spacer(),
              _buildExpandToggle(expanded: true),
            ],
          ),
        ),

        // Scrollable content area
        Expanded(child: _buildScrollableContent()),

        // Action buttons at bottom
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: SizedBox(
            height: 40,
            child:
                _editHistory.isEmpty
                    ? _buildPrimaryButton(
                      text: 'Generate Edit',
                      onPressed: _saveCurrentEdit,
                      icon: Icons.auto_fix_high,
                    )
                    : _buildActionButtonRow(),
          ),
        ),
      ],
    );
  }

  // UI Helper methods
  Widget _buildExpandToggle({required bool expanded}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleBottomSheet,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            expanded ? Icons.expand_more : Icons.expand_less,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableContent() {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white,
            Colors.white,
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.05, 0.95, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          spacing: 20,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_editHistory.isNotEmpty) _buildEditNumberIndicator(),
            _buildPromptField(),
            if (_errorMessage != null) _buildErrorMessage(),
            _buildModelSelector(),
            Divider(color: Colors.white.withValues(alpha: 0.2)),
            _buildAdvancedEditingSection(),
            _buildAdvancedOptionsToggle(),
            if (_showAdvancedOptions) _buildAdvancedOptionsContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildEditNumberIndicator() {
    return Row(
      children: [
        Icon(Icons.tag, color: Colors.white.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text('Edit #${_editHistory.length + 1}'),
      ],
    );
  }

  Widget _buildPromptField() {
    return TextField(
      controller: _promptController,
      decoration: InputDecoration(
        hintText: 'Example: Change the background to a beach sunset',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 14, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelector() {
    return Row(
      children: [
        Icon(
          Icons.auto_awesome,
          color: Colors.purpleAccent.withValues(alpha: 0.9),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'AI Model',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedAIModel,
              isDense: true,
              dropdownColor: Colors.black87,
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              items:
                  _availableAIModels.map((String model) {
                    return DropdownMenuItem<String>(
                      value: model,
                      child: Text(
                        model,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedAIModel = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedEditingSection() {
    final displayedPrompts = _suggestions.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildSectionHeader(
              icon: Icons.lightbulb_outline,
              text: 'Advanced Editing',
              iconColor: Colors.amber,
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdvancedPromptsScreen(),
                  ),
                );
              },
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: _buildHorizontalScrollableList(
            itemCount: displayedPrompts.length,
            itemBuilder: (context, index) {
              final prompt = displayedPrompts[index];
              return _buildSuggestionCard(prompt);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String text,
    Color? iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor ?? Colors.white.withValues(alpha: 0.8)),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalScrollableList({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    return ShaderMask(
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
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: itemCount,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        itemBuilder: itemBuilder,
      ),
    );
  }

  Widget _buildSuggestionCard(AdvancedPrompt prompt) {
    return GestureDetector(
      onTap: () => _showConfirmAdvancedEditDialog(prompt),
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: prompt.accentColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(prompt.icon, color: prompt.accentColor, size: 22),
            const SizedBox(height: 8),
            Text(
              prompt.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptionsToggle() {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() {
          _showAdvancedOptions = !_showAdvancedOptions;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.settings, color: Colors.white.withValues(alpha: 0.8)),
            const SizedBox(width: 6),
            const Text(
              'Advanced Options',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 6),
            Icon(
              _showAdvancedOptions
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 16,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptionsContent() {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white,
            Colors.white,
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.04, 0.96, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          spacing: 10,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOptionContainer(child: _buildEnhancedThinkingToggle()),
            _buildOptionContainer(child: _buildTemperatureControl()),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }

  Widget _buildEnhancedThinkingToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.psychology,
              color:
                  _enhancedThinkingEnabled
                      ? Colors.blueAccent
                      : Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Enhanced AI Thinking',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Switch(
              value: _enhancedThinkingEnabled,
              onChanged: (value) {
                setState(() {
                  _enhancedThinkingEnabled = value;
                });
              },
              activeColor: Colors.blueAccent,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Analyzes image and plans changes before editing',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.thermostat, color: Colors.orangeAccent),
            const SizedBox(width: 8),
            Text(
              'Temperature: ${_temperature.toStringAsFixed(1)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: _temperature,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            activeColor: Colors.orangeAccent,
            inactiveColor: Colors.white.withValues(alpha: 0.2),
            onChanged: (value) {
              setState(() => _temperature = value);
            },
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _temperature < 0.3
              ? 'Lower: More predictable, consistent results'
              : _temperature < 0.7
              ? 'Medium: Balanced variations'
              : 'Higher: More diverse, experimental outcomes',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _finishEditing,
            icon: const Icon(Icons.check, size: 14, color: Colors.white),
            label: const Text(
              'Finish',
              style: TextStyle(fontSize: 13, color: Colors.white),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPrimaryButton(
            text: 'Apply Edit',
            onPressed: _saveCurrentEdit,
            icon: Icons.move_down,
            fontSize: 13,
            iconSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    required IconData icon,
    double fontSize = 14,
    double iconSize = 18,
  }) {
    return GlassButton(
      text: text,
      onPressed: onPressed,
      fullWidth: true,
      fontSize: fontSize,
      padding: const EdgeInsets.symmetric(vertical: 10),
      icon: icon,
      iconSize: iconSize,
      textColor: Colors.white,
    );
  }
}
