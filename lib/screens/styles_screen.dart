import 'dart:convert';
import 'dart:ui'; // Import for ImageFilter

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_app/components/flexible_dialog.dart';
import 'package:image_app/components/glass_button.dart';
import 'package:image_app/models/saved_style.dart';
import 'package:image_app/screens/edit_screen.dart';
import 'package:image_app/services/storage_service.dart';
import 'package:image_app/components/glass_container.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class StylesScreen extends StatefulWidget {
  const StylesScreen({super.key});

  @override
  State<StylesScreen> createState() => _StylesScreenState();
}

class _StylesScreenState extends State<StylesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SavedStyle> _allStyles = [];
  List<SavedStyle> _filteredStyles = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadStyles();
    _searchController.addListener(_filterStyles);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterStyles);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStyles() async {
    setState(() => _isLoading = true);
    try {
      final styles = await StorageService.getSavedStyles();
      if (mounted) {
        setState(() {
          _allStyles = styles;
          _filteredStyles = styles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading styles: $e')));
      }
    }
  }

  void _filterStyles() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStyles =
          _allStyles.where((style) {
            return style.name.toLowerCase().contains(query);
          }).toList();
    });
  }

  Future<void> _deleteStyle(String styleId, String styleName) async {
    // Close the modal first if it's open
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    await FlexibleDialog.showConfirmation(
      context: context,
      title: 'Delete Style?',
      message: 'Are you sure you want to delete the style "$styleName"?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      icon: Icons.delete_forever,
      iconColor: Colors.redAccent,
      onConfirm: () async {
        final success = await StorageService.deleteStyle(styleId);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Style deleted successfully')),
          );
          _loadStyles(); // Refresh the list
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete style')),
          );
        }
      },
    );
  }

  void _showImageSourceDialog(SavedStyle style) {
    // Close the modal first if it's open
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    FlexibleDialog.showImageSource(
      context: context,
      onSourceSelected: (source) {
        _pickImageAndNavigate(style: style, source: source);
      },
      title: 'Select Image for Style "${style.name}"',
      message: 'Choose an image to apply this style to.',
    );
  }

  Future<void> _pickImageAndNavigate({
    required SavedStyle style,
    required ImageSource source,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
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
                initialStyle: style, // Pass the selected style
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _copyJsonToClipboard(String jsonString) {
    Clipboard.setData(ClipboardData(text: jsonString)).then((_) {
      // Close the modal first if it's open
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Style JSON copied to clipboard!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  String _formatJsonString(String jsonString) {
    try {
      const encoder = JsonEncoder.withIndent('  '); // Indent with 2 spaces
      final object = jsonDecode(jsonString);
      return encoder.convert(object);
    } catch (e) {
      return jsonString; // Return original if formatting fails
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _showStyleDetailModal(SavedStyle style) {
    final formattedJson = _formatJsonString(style.styleJson);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take up more height
      backgroundColor: Colors.transparent, // Make sheet transparent
      builder: (context) {
        return BackdropFilter(
          // Apply blur to background
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6, // Start at 60% height
            minChildSize: 0.4, // Min height
            maxChildSize: 0.9, // Max height
            expand: false,
            builder: (_, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF01579B).withValues(alpha: 0.85),
                      const Color(0xFF111111).withValues(alpha: 0.95),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: ListView(
                  controller: scrollController, // Use the controller
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    // Handle to indicate draggable sheet
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                style.name,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Saved: ${DateFormat('MMM dd, yyyy, h:mma').format(style.timestamp.toLocal())}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Delete Style',
                          onPressed: () => _deleteStyle(style.id, style.name),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action Button
                    GlassButton(
                      text: 'Use This Style',
                      icon: Icons.add_photo_alternate_outlined,
                      onPressed: () => _showImageSourceDialog(style),
                      fullWidth: true,
                    ),

                    const SizedBox(height: 24),

                    // Raw JSON Viewer
                    _buildSectionHeader('Raw Style JSON', Icons.code),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              12,
                              12,
                              45,
                              12,
                            ), // Add padding for button
                            child: SingleChildScrollView(
                              // Make JSON scrollable if long
                              child: Text(
                                formattedJson,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: Icon(
                                Icons.copy,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              tooltip: 'Copy JSON',
                              onPressed:
                                  () => _copyJsonToClipboard(style.styleJson),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16), // Space at the bottom
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Saved Styles'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF01579B), Color(0xFF111111)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search bar
              Padding(
                // ... existing search bar setup ...
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search styles by name...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),

              // Styles grid/list
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredStyles.isEmpty
                        ? Center(
                          // ... existing empty state text ...
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'No saved styles yet.'
                                : 'No styles found matching your search.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        )
                        : GridView.builder(
                          // ... existing GridView setup ...
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.1, // Adjust aspect ratio
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: _filteredStyles.length,
                          itemBuilder: (context, index) {
                            final style = _filteredStyles[index];
                            return _buildStyleGridItem(style);
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyleGridItem(SavedStyle style) {
    return GlassContainer(
      onTap: () => _showStyleDetailModal(style), // Updated onTap
      child: Column(
        // ... existing grid item content ...
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
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
          ),
          const Spacer(), // Pushes timestamp to bottom
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              DateFormat('MMM dd, yyyy').format(style.timestamp.toLocal()),
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
