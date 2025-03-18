import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/edited_image.dart';
import '../services/storage_service.dart';
import '../utils/log.dart';
import 'result_screen.dart';

class SearchScreen extends StatefulWidget {
  final bool isInTabView;

  const SearchScreen({super.key, this.isInTabView = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  List<EditedImage> _allImages = [];
  List<EditedImage> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadAllImages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadAllImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final images = await StorageService.getEditedImages();
      setState(() {
        _allImages = images;
        _searchResults = images;
        _isLoading = false;
      });
    } catch (e) {
      printDebug('❌ Error loading images: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _isSearching = query.isNotEmpty;

      if (query.isEmpty) {
        _searchResults = _allImages;
      } else {
        _searchResults =
            _allImages.where((image) {
              return image.prompt.toLowerCase().contains(_searchQuery) ||
                  image.title.toLowerCase().contains(_searchQuery);
            }).toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
      _searchResults = _allImages;
    });
    _searchFocusNode.unfocus();
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

          // Frosted glass effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.black.withValues(alpha: 0.05)),
          ),

          // Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildSearchBar(),

                // Result count display
                if (_isSearching && !_isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Found ${_searchResults.length} results',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const Spacer(),
                        _searchResults.isNotEmpty
                            ? TextButton.icon(
                              icon: Icon(Icons.grid_view, size: 18),
                              label: Text('Grid'),
                              onPressed:
                                  () {}, // Toggle view type in future implementation
                            )
                            : const SizedBox(),
                      ],
                    ),
                  ),

                // Results or loading indicator
                _isLoading
                    ? const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                    : _buildSearchResultsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search by prompt or title...',
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          suffixIcon:
              _isSearching
                  ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    onPressed: _clearSearch,
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
        style: const TextStyle(fontSize: 16),
        onChanged: _performSearch,
      ),
    );
  }

  Widget _buildSearchResultsList() {
    if (_searchResults.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isSearching ? Icons.search_off : Icons.image_not_supported,
                size: 64,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _isSearching
                    ? 'No results found for "$_searchQuery"'
                    : 'No edited images yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isSearching
                    ? 'Try a different search term'
                    : 'Your edited images will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          padding: const EdgeInsets.only(bottom: 100), // Space for bottom nav
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            return _buildImageGridItem(_searchResults[index]);
          },
        ),
      ),
    );
  }

  Widget _buildImageGridItem(EditedImage image) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ResultScreen(
                  editedImage: image,
                  heroTagPrefix: 'search_', // Add this parameter
                ),
          ),
        ).then((_) => _loadAllImages());
      },
      child: Container(
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
            // Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Hero(
                  tag:
                      'search_image_${image.id}', // Updated hero tag with prefix
                  child: FutureBuilder<Uint8List?>(
                    future: StorageService.loadImageBytes(image.localPath),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.data != null) {
                        return Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        );
                      }
                      return Container(
                        color: Colors.grey[800],
                        child: const Center(child: Icon(Icons.image)),
                      );
                    },
                  ),
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
                    image.timestamp.toString().substring(0, 10),
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
}
