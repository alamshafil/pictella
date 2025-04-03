import 'package:flutter/material.dart';
import 'package:image_app/config/advanced_prompts.dart';
import 'package:image_app/components/glass_container.dart';
import 'package:image_app/components/flexible_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'edit_screen.dart';

class AdvancedPromptsScreen extends StatefulWidget {
  const AdvancedPromptsScreen({super.key});

  @override
  State<AdvancedPromptsScreen> createState() => _AdvancedPromptsScreenState();
}

class _AdvancedPromptsScreenState extends State<AdvancedPromptsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String _selectedCategory = 'All';
  List<AdvancedPrompt> _filteredPrompts = [];

  @override
  void initState() {
    super.initState();
    _filteredPrompts = advancedPrompts;
  }

  void _filterPrompts(String query) {
    setState(() {
      _filteredPrompts =
          advancedPrompts.where((prompt) {
            final matchesSearch =
                prompt.title.toLowerCase().contains(query.toLowerCase()) ||
                prompt.description.toLowerCase().contains(query.toLowerCase());
            final matchesCategory =
                _selectedCategory == 'All' ||
                prompt.category == _selectedCategory;
            return matchesSearch && matchesCategory;
          }).toList();
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _filterPrompts(_searchController.text);
    });
  }

  void _showPromptDetails(AdvancedPrompt prompt) {
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
            style: TextStyle(color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              prompt.prompt,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSourceButton(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: () => _pickImageWithPrompt(ImageSource.camera, prompt),
              ),
              _buildSourceButton(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: () => _pickImageWithPrompt(ImageSource.gallery, prompt),
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
            side: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImageWithPrompt(
    ImageSource source,
    AdvancedPrompt prompt,
  ) async {
    Navigator.pop(context); // Close the dialog

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
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(label)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...advancedPromptCategories];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Advanced Prompts'),
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
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterPrompts,
                  decoration: InputDecoration(
                    hintText: 'Search prompts...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),

              // Category filter
              Container(
                height: 48,
                margin: const EdgeInsets.only(bottom: 16),
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0),
                        Colors.black,
                        Colors.black,
                        Colors.black.withOpacity(0),
                      ],
                      stops: const [0.0, 0.05, 0.95, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    physics: const BouncingScrollPhysics(),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = _selectedCategory == category;
                      final categoryInfo = categoryInfoMap[category]!;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GlassContainer(
                          onTap: () => _filterByCategory(category),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color:
                              isSelected ? Colors.white.withOpacity(0.2) : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                categoryInfo.icon,
                                size: 18,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.7),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                categoryInfo.name,
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.7),
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

              // Prompts grid with fade
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0),
                        Colors.black,
                        Colors.black,
                        Colors.black.withOpacity(0),
                      ],
                      stops: const [0.0, 0.05, 0.95, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: _filteredPrompts.length,
                    itemBuilder: (context, index) {
                      final prompt = _filteredPrompts[index];
                      return GlassContainer(
                        onTap: () => _showPromptDetails(prompt),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: prompt.accentColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                prompt.icon,
                                color: prompt.accentColor,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              prompt.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                prompt.description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
