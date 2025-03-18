import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import '../components/glass_container.dart';
import '../components/glass_button.dart';
import '../services/gemini_api_service.dart';
import 'result_screen.dart';
import '../services/storage_service.dart';

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
  final FocusNode _promptFocusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;
  Uint8List? _originalImageBytes;

  // List to store edit history
  final List<Map<String, dynamic>> _editHistory = [];
  int _currentEditIndex = -1; // -1 means showing original image

  // Animation controller for transitions
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Suggestions with icons
  final List<Map<String, dynamic>> _suggestions = [
    {'icon': Icons.beach_access, 'text': 'Change background to beach'},
    {'icon': Icons.wb_sunny, 'text': 'Make it look like sunset'},
    {'icon': Icons.pets, 'text': 'Add a dog next to subject'},
    {'icon': Icons.animation, 'text': 'Convert to anime style'},
    {'icon': Icons.business, 'text': 'Make it look professional'},
    {'icon': Icons.brightness_5, 'text': 'Make it brighter'},
    {'icon': Icons.remove_circle_outline, 'text': 'Remove background objects'},
    {'icon': Icons.color_lens, 'text': 'Add vintage filter'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.previousPrompt.isNotEmpty) {
      _promptController.text = widget.previousPrompt;
    }

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadOriginalImage();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _animationController.dispose();
    _promptFocusNode.dispose();
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
      // Call the Gemini API service
      final base64GeneratedImage = await GeminiApiService.editImage(
        imageData: sourceImageBytes,
        prompt: _promptController.text,
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
        title: Text(
          'Edit Image',
          style: GoogleFonts.albertSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Blurred background using the current image being edited
          _buildBackgroundBlur(),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Image Display with Carousel
                Expanded(
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

                // Edit Control Section
                _buildEditControls(),
              ],
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Processing your request...',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
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

  Widget _buildImageCarousel() {
    return Column(
      children: [
        // Main image display with animation
        Expanded(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return AnimatedOpacity(
                opacity: _isLoading ? 0.5 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
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
                    child: _buildCurrentImageDisplay(),
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

                  // Original image thumbnail
                  if (index == 0) {
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
    if (_currentEditIndex >= 0 && _currentEditIndex < _editHistory.length) {
      // Show selected edit from history
      return FadeTransition(
        opacity: _animation,
        child: Image.memory(
          _editHistory[_currentEditIndex]['imageBytes'],
          fit: BoxFit.cover,
        ),
      );
    } else if (_originalImageBytes != null) {
      // Show original image from memory
      return Image.memory(_originalImageBytes!, fit: BoxFit.cover);
    } else {
      // Fallback - try to load from path
      return widget.imageUrl.startsWith('/')
          ? Image.file(
            File(widget.imageUrl),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 64,
                ),
              );
            },
          )
          : FutureBuilder<String>(
            future: StorageService.getAbsolutePath(widget.imageUrl),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                return Image.file(
                  File(snapshot.data!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 64,
                      ),
                    );
                  },
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          );
    }
  }

  Widget _buildEditControls() {
    return GlassContainer(
      margin: const EdgeInsets.all(12),
      borderRadius: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Icon(
                  _editHistory.isNotEmpty ? Icons.edit : Icons.draw,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 6),
                Text(
                  _editHistory.isNotEmpty
                      ? 'Continue Editing'
                      : 'Describe your edit',
                ),
              ],
            ),
          ),

          // Edit number indicator - only when needed
          if (_editHistory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Icon(Icons.tag, color: Colors.white.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text('Edit #${_editHistory.length + 1}'),
                ],
              ),
            ),

          // Text input field
          Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _promptController,
                focusNode: _promptFocusNode,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Example: Change the background to a beach sunset',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  contentPadding: const EdgeInsets.all(10),
                  border: InputBorder.none,
                  isDense: true,
                ),
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                onTap: () {
                  if (!_promptFocusNode.hasFocus) {
                    _promptFocusNode.requestFocus();
                  }
                },
                onEditingComplete: () {
                  _promptFocusNode.unfocus();
                },
              ),
            ),
          ),

          // Error message - if needed
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(fontSize: 14, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 10), // Extra spacing
          // Suggestions section
          Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text('Suggestions'),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 36, // Fixed height for suggestions
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
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _suggestions.length,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            _promptController.text =
                                _suggestions[index]['text'];
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_suggestions[index]['icon'], size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  _suggestions[index]['text'],
                                  style: TextStyle(fontSize: 12),
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
            ),
          ),

          // Action buttons - at the bottom with padding
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 40,
              child:
                  _editHistory.isEmpty
                      ? GlassButton(
                        text: 'Generate Edit',
                        onPressed: _saveCurrentEdit,
                        fullWidth: true,
                        fontSize: 14,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        icon: Icons.auto_fix_high,
                      )
                      : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _finishEditing,
                              icon: const Icon(Icons.check, size: 14),
                              label: Text(
                                'Finish',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GlassButton(
                              text: 'Apply Edit',
                              onPressed: _saveCurrentEdit,
                              fullWidth: true,
                              fontSize: 13,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              icon: Icons.move_down,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
