import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_app/models/edited_image.dart';
import 'package:image_app/utils/log.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static const String _editedImagesKey = 'edited_images';
  static final Uuid _uuid = Uuid();
  static const String _imagesSubdirectory = 'edited_images';
  static const String _originalImagesSubdirectory = 'original_images';

  // Get the images directory
  static Future<Directory> getImagesDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${directory.path}/$_imagesSubdirectory');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  // Get directory for original images
  static Future<Directory> getOriginalImagesDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final origImagesDir = Directory(
      '${directory.path}/$_originalImagesSubdirectory',
    );
    if (!await origImagesDir.exists()) {
      await origImagesDir.create(recursive: true);
    }
    return origImagesDir;
  }

  // Convert relative path to absolute path
  static Future<String> getAbsolutePath(String relativePath) async {
    final docDir = await getApplicationDocumentsDirectory();
    return path.join(docDir.path, relativePath);
  }

  // Convert absolute path to relative path
  static Future<String> getRelativePath(String absolutePath) async {
    final docDir = await getApplicationDocumentsDirectory();
    return path.relative(absolutePath, from: docDir.path);
  }

  // Copy an image from a temporary location to permanent storage
  static Future<String> copyImageToStorage(String sourcePath) async {
    try {
      // Check if the source file exists
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist: $sourcePath');
      }

      // Get directory for original images
      final origImagesDir = await getOriginalImagesDirectory();

      // Create a unique filename using the original extension
      final extension = path.extension(sourcePath).toLowerCase();
      final filename = 'original_${_uuid.v4()}$extension';
      final destinationPath = '${origImagesDir.path}/$filename';

      // Copy the file
      await sourceFile.copy(destinationPath);

      // Return the relative path for storage
      final relativePath = '$_originalImagesSubdirectory/$filename';

      printDebug('📝 Copied original image:');
      printDebug('   - From: $sourcePath');
      printDebug('   - To: $destinationPath');
      printDebug('   - Relative Path: $relativePath');

      return relativePath;
    } catch (e) {
      printDebug('❌ Error copying image to storage: $e');
      rethrow;
    }
  }

  // Save an edited image to local storage
  static Future<EditedImage> saveEditedImage({
    required Uint8List imageBytes,
    required String prompt,
    String title = 'Edited Image',
    String? originalImagePath,
  }) async {
    try {
      // Get app document directory
      final imagesDir = await getImagesDirectory();

      // Create unique ID and filename
      final id = _uuid.v4();
      final timestamp = DateTime.now();
      final fileName = 'edit_$id.png';
      final filePath = '${imagesDir.path}/$fileName';

      // Write the file
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // Get the relative path for storage
      final relativePath = '$_imagesSubdirectory/$fileName';

      // Handle the original image path
      String? relativeOriginalPath;

      if (originalImagePath != null) {
        if (originalImagePath.startsWith('/') &&
            !originalImagePath.startsWith(_originalImagesSubdirectory)) {
          // This is a full path but not temporary (from previous version compatibility)
          try {
            final origFile = File(originalImagePath);
            if (await origFile.exists()) {
              relativeOriginalPath = await copyImageToStorage(
                originalImagePath,
              );
            }
          } catch (e) {
            printDebug('⚠️ Could not copy original image: $e');
            relativeOriginalPath = null;
          }
        } else {
          // Already a relative path, just use it
          relativeOriginalPath = originalImagePath;
        }
      }

      // Create EditedImage object with relative path
      final editedImage = EditedImage(
        id: id,
        title: title,
        prompt: prompt,
        localPath: relativePath, // Store relative path for edited image
        originalImagePath:
            relativeOriginalPath, // Store relative path for original
        timestamp: timestamp,
      );

      // Save metadata to shared preferences
      await _saveEditedImageMetadata(editedImage);

      printDebug('✅ Image saved successfully: $filePath');
      printDebug('📝 Image details:');
      printDebug('   - ID: $id');
      printDebug(
        '   - Size: ${(imageBytes.length / 1024).toStringAsFixed(2)} KB',
      );
      printDebug('   - Path: $filePath');
      printDebug('   - Relative Path: $relativePath');
      printDebug('   - Original image: ${relativeOriginalPath ?? "None"}');

      return editedImage;
    } catch (e) {
      printDebug('❌ Error saving image: $e');
      rethrow;
    }
  }

  // Save metadata of edited image
  static Future<void> _saveEditedImageMetadata(EditedImage editedImage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getStringList(_editedImagesKey) ?? [];

      // Add new image metadata
      existingData.add(jsonEncode(editedImage.toJson()));

      // Save updated list
      await prefs.setStringList(_editedImagesKey, existingData);

      printDebug('💾 Saved metadata for image ${editedImage.id}');
      printDebug('   Total images in storage: ${existingData.length}');
    } catch (e) {
      printDebug('❌ Error saving image metadata: $e');
      rethrow;
    }
  }

  // Get all edited images
  static Future<List<EditedImage>> getEditedImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList(_editedImagesKey) ?? [];

      final images =
          data.map((jsonString) {
              final map = jsonDecode(jsonString) as Map<String, dynamic>;
              return EditedImage.fromJson(map);
            }).toList()
            ..sort(
              (a, b) => b.timestamp.compareTo(a.timestamp),
            ); // Sort by most recent

      printDebug('📋 Retrieved ${images.length} edited images');

      return images;
    } catch (e) {
      printDebug('❌ Error retrieving edited images: $e');
      return [];
    }
  }

  // Get an edited image by ID
  static Future<EditedImage?> getEditedImageById(String id) async {
    try {
      final images = await getEditedImages();
      return images.firstWhere((img) => img.id == id);
    } catch (e) {
      printDebug('❌ Error retrieving image by ID: $e');
      return null;
    }
  }

  // Load image bytes from file path
  static Future<Uint8List?> loadImageBytes(String localPath) async {
    try {
      // Convert to absolute path if it's a relative path
      final String absolutePath =
          localPath.startsWith('/')
              ? localPath
              : await getAbsolutePath(localPath);

      final file = File(absolutePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return bytes;
      }

      printDebug('⚠️ File not found: $absolutePath');
      return null;
    } catch (e) {
      printDebug('❌ Error loading image bytes: $e');
      return null;
    }
  }

  // Delete an edited image by ID (both file and metadata)
  static Future<bool> deleteEditedImage(String id) async {
    try {
      // Get all images
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList(_editedImagesKey) ?? [];

      // Find the image metadata
      String? targetJsonString;
      String? relativePath;

      for (final jsonString in data) {
        final map = jsonDecode(jsonString) as Map<String, dynamic>;
        if (map['id'] == id) {
          targetJsonString = jsonString;
          relativePath = map['localPath'] as String;
          break;
        }
      }

      if (targetJsonString == null || relativePath == null) {
        printDebug('⚠️ Could not find metadata for image with ID: $id');
        return false;
      }

      // Get the absolute path if needed
      final String absolutePath =
          relativePath.startsWith('/')
              ? relativePath
              : await getAbsolutePath(relativePath);

      // Delete the file
      final file = File(absolutePath);
      if (await file.exists()) {
        await file.delete();
        printDebug('🗑️ Deleted file: $absolutePath');
      }

      // Remove from metadata
      data.remove(targetJsonString);
      await prefs.setStringList(_editedImagesKey, data);

      printDebug('🗑️ Removed metadata for image: $id');

      return true;
    } catch (e) {
      printDebug('❌ Error deleting image: $e');
      return false;
    }
  }

  // Delete all edited images (both files and metadata)
  static Future<bool> deleteAllEditedImages() async {
    try {
      // Get all metadata
      final images = await getEditedImages();

      // Get images directory and clean it
      final imagesDir = await getImagesDirectory();

      // Delete directory if it exists
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
        printDebug('🗑️ Deleted entire images directory: ${imagesDir.path}');
      }

      // Create empty directory again
      await imagesDir.create(recursive: true);

      // Clear metadata
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_editedImagesKey, []);

      printDebug('🧹 Cleared all image metadata (${images.length} entries)');

      return true;
    } catch (e) {
      printDebug('❌ Error deleting all images: $e');
      return false;
    }
  }

  // Get total storage usage in bytes
  static Future<int> getTotalStorageUsage() async {
    try {
      int totalSize = 0;
      final imagesDir = await getImagesDirectory();

      if (!await imagesDir.exists()) {
        return 0;
      }

      final files = await imagesDir.list().toList();

      for (final entity in files) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      printDebug('❌ Error calculating storage usage: $e');
      return 0;
    }
  }

  // Debug Methods
  /// Validate storage integrity and return structured results
  static Future<Map<String, dynamic>> validateStorageIntegrity() async {
    try {
      // Check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final metadataExists = prefs.containsKey(_editedImagesKey);

      // Get all images metadata
      final images = await getEditedImages();

      // Get all actual image files
      final imagesDir = await getImagesDirectory();

      if (!await imagesDir.exists()) {
        return {
          'status': 'warning',
          'message': 'Images directory does not exist',
          'metadata_exists': metadataExists,
          'images_count': images.length,
          'files_count': 0,
          'issues': [],
        };
      }

      final files =
          await imagesDir
              .list()
              .where((entity) => entity is File && entity.path.endsWith('.png'))
              .toList();

      // Check for missing files
      List<Map<String, dynamic>> issues = [];
      int missingFiles = 0;
      for (final image in images) {
        final absolutePath = await getAbsolutePath(image.localPath);
        final file = File(absolutePath);
        if (!await file.exists()) {
          missingFiles++;
          issues.add({
            'type': 'missing_file',
            'id': image.id,
            'path': image.localPath,
          });
        }
      }

      // Check for orphaned files (files without metadata)
      int orphanedFiles = 0;
      for (final entity in files) {
        if (entity is File) {
          final filePath = entity.path;
          final relativePath = await getRelativePath(filePath);
          final hasMetadata = images.any(
            (img) => img.localPath == relativePath,
          );

          if (!hasMetadata) {
            orphanedFiles++;
            issues.add({'type': 'orphaned_file', 'path': filePath});
          }
        }
      }

      String status = 'success';
      String message = 'Storage integrity check passed';

      if (missingFiles > 0 || orphanedFiles > 0) {
        status = 'warning';
        message = 'Storage integrity issues found';
      }

      return {
        'status': status,
        'message': message,
        'metadata_exists': metadataExists,
        'images_count': images.length,
        'files_count': files.length,
        'issues': issues,
        'missing_files': missingFiles,
        'orphaned_files': orphanedFiles,
      };
    } catch (e) {
      return {'status': 'error', 'message': 'Error validating storage: $e'};
    }
  }
}
