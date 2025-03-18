import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:typed_data';
import '../../models/edited_image.dart';
import '../../services/storage_service.dart';
import '../../utils/app_settings.dart';
import '../../utils/app_preferences.dart';
import '../../utils/log.dart';
import '../result_screen.dart';
import '../welcome_screen.dart';

class StorageManagementScreen extends StatefulWidget {
  const StorageManagementScreen({super.key});

  @override
  State<StorageManagementScreen> createState() =>
      _StorageManagementScreenState();
}

class _StorageManagementScreenState extends State<StorageManagementScreen> {
  bool _isLoading = true;
  List<EditedImage> _savedImages = [];
  int _totalStorageBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadStorageData();
  }

  Future<void> _loadStorageData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load images
      final images = await StorageService.getEditedImages();

      // Get total storage usage
      final storageBytes = await StorageService.getTotalStorageUsage();

      setState(() {
        _savedImages = images;
        _totalStorageBytes = storageBytes;
        _isLoading = false;
      });
    } catch (e) {
      printDebug('❌ Error loading storage data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _deleteImage(EditedImage image) async {
    // Confirm with dialog
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('Delete Image'),
                content: const Text(
                  'Are you sure you want to delete this image? This cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await StorageService.deleteEditedImage(image.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image deleted successfully')),
        );
        _loadStorageData();
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete image')));
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      printDebug('❌ Error deleting image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting image: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAllImages() async {
    // Confirm with dialog
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete All Images'),
                  ],
                ),
                content: const Text(
                  'Warning: This will permanently delete ALL edited images and cannot be undone. Are you sure?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Delete All',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await StorageService.deleteAllEditedImages();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All images deleted successfully')),
        );
        _loadStorageData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete all images')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      printDebug('❌ Error deleting all images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting all images: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetAllData() async {
    // Confirm with user before resetting
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: Theme.of(context).colorScheme.surface,
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    SizedBox(width: 12),
                    Text('Reset All App Data'),
                  ],
                ),
                content: const Text(
                  'This will reset ALL app data including preferences, settings, and saved images. The app will restart. Continue?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Reset Everything',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Delete all image files
      await StorageService.deleteAllEditedImages();

      // Reset all preferences
      await AppPreferences.resetAll();

      if (mounted) {
        // Navigate back to welcome screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error resetting data: $e')));
      }
    }
  }

  Future<void> _checkStorageIntegrity() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Perform storage validation
      final validation = await StorageService.validateStorageIntegrity();

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      // Show results in dialog
      _showStorageIntegrityDialog(validation);
    } catch (e) {
      printDebug('❌ Error checking storage integrity: $e');
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      // Show error dialog
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to check storage integrity: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  void _showStorageIntegrityDialog(Map<String, dynamic> validation) {
    Color statusColor;
    IconData statusIcon;

    switch (validation['status']) {
      case 'success':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'warning':
        statusColor = Colors.orange;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case 'error':
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.info_outline;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                const Text('Storage Integrity Check'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      validation['message'] ?? 'Unknown status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (validation.containsKey('missing_files')) ...[
                      Text('Missing files: ${validation['missing_files']}'),
                      const SizedBox(height: 4),
                    ],
                    if (validation.containsKey('orphaned_files')) ...[
                      Text('Orphaned files: ${validation['orphaned_files']}'),
                      const SizedBox(height: 4),
                    ],
                    if (validation.containsKey('images_count') &&
                        validation.containsKey('files_count')) ...[
                      Text('Images in metadata: ${validation['images_count']}'),
                      const SizedBox(height: 4),
                      Text('Files on disk: ${validation['files_count']}'),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blurEffectsEnabled = AppSettings.instance.blurEffectsEnabled;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Storage Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background
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
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Storage usage header
                    _buildStorageHeader(),

                    // Divider
                    Divider(
                      color: Colors.white.withValues(alpha: 0.2),
                      height: 30,
                    ),

                    // Storage management options
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Actions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[200],
                        ),
                      ),
                    ),

                    // Management buttons
                    _buildManagementButtons(),

                    // Divider
                    Divider(
                      color: Colors.white.withValues(alpha: 0.2),
                      height: 30,
                    ),

                    // Saved images list header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Saved Images (${_savedImages.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[200],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Saved images list
                    Expanded(
                      child:
                          _savedImages.isEmpty
                              ? _buildEmptyState()
                              : _buildImagesList(),
                    ),
                  ],
                ),
              ),

          // Overlay loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildStorageHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage_rounded, size: 24, color: Colors.blue[300]),
              const SizedBox(width: 8),
              Text(
                'Storage Usage',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[300],
                ),
              ),
              // Add small check button
              IconButton(
                tooltip: 'Check Storage Integrity',
                icon: const Icon(Icons.check_circle_outline),
                onPressed: _checkStorageIntegrity,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Images',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
              Text(
                '${_savedImages.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Storage Used',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
              Text(
                _formatBytes(_totalStorageBytes),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManagementButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Delete all images button
          ElevatedButton.icon(
            onPressed: _savedImages.isEmpty ? null : _deleteAllImages,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete All Images'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Reset all app data button
          OutlinedButton.icon(
            onPressed: _resetAllData,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset All App Data'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.red.withValues(alpha: 0.7)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 64,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No images saved',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Edited images will appear here',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _savedImages.length,
      itemBuilder: (context, index) {
        final image = _savedImages[index];
        return _buildImageListItem(image);
      },
    );
  }

  Widget _buildImageListItem(EditedImage image) {
    return Dismissible(
      key: Key(image.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Delete Image'),
                content: const Text(
                  'Are you sure you want to delete this image?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        );
      },
      onDismissed: (direction) {
        _deleteImage(image);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 60,
              height: 60,
              child: FutureBuilder<Uint8List?>(
                future: StorageService.loadImageBytes(image.localPath),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.data != null) {
                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                  }
                  return Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.image),
                  );
                },
              ),
            ),
          ),
          title: Text(
            image.title,
            style: const TextStyle(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                image.prompt,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${image.timestamp.day}/${image.timestamp.month}/${image.timestamp.year} ${image.timestamp.hour}:${image.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteImage(image),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultScreen(editedImage: image),
              ),
            ).then((_) => _loadStorageData());
          },
        ),
      ),
    );
  }
}
