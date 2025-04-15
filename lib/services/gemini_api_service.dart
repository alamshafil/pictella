import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_app/config/api_config.dart';
import 'package:image_app/utils/log.dart';
import 'dart:ui' as ui;

class GeminiApiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _modelName = 'gemini-2.0-flash-exp';

  // Method to edit an image with a text prompt and optional style
  static Future<String> editImage({
    required Uint8List imageData,
    required String prompt,
    String? styleJson, // Optional style description
  }) async {
    try {
      _logInfo('🚀 Starting API request to Gemini (Edit Image)');
      _logInfo('📝 Prompt: $prompt');
      if (styleJson != null) {
        _logInfo('🎨 Applying Style JSON: ${_truncateString(styleJson, 100)}');
      }
      _logInfo('🖼️ Image size: ${imageData.length} bytes');

      // Get the API key
      final apiKey = await ApiConfig.getGeminiApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception(
          'No API key found. Please add your API key in settings.',
        );
      }

      // Ensure the image isn't too large
      Uint8List processedImageData = imageData;
      if (imageData.length > 4000000) {
        _logInfo('⚠️ Image is large. Attempting to resize/compress...');
        processedImageData = await resizeImageIfNeeded(
          imageData,
          maxDimension: 800,
        );
        _logInfo('✓ Resized image to ${processedImageData.length} bytes');
      }

      // Convert image to base64
      final String base64Image = base64Encode(processedImageData);
      _logInfo('✓ Image converted to base64');

      // Construct the prompt, incorporating the style if provided
      String combinedPrompt =
          "Update the attached image based on the following prompt: \"$prompt\".";
      if (styleJson != null && styleJson.isNotEmpty) {
        combinedPrompt +=
            "\n\nApply the visual style described by this JSON object: $styleJson";
      }

      // Prepare the request body
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': combinedPrompt}, // Use the combined prompt
              {
                'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
              },
            ],
          },
        ],
        'generation_config': {
          'response_modalities': ['TEXT', 'IMAGE'],
        },
      };

      _logInfo(
        '📤 REST API body:\n ${_truncateString(jsonEncode(requestBody))}',
      );
      _logInfo('📤 Sending request to $_baseUrl/$_modelName:generateContent');

      // Make the API call
      final response = await http.post(
        Uri.parse('$_baseUrl/$_modelName:generateContent?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      _logInfo('📥 Received response with status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Parse response and extract the image
        _logInfo('✅ Response successful (200)');

        final jsonResponse = jsonDecode(response.body);
        _logDebug('Full response: ${_truncateString(response.body)}');

        // Extract the base64 image from the response
        String? base64GeneratedImage;

        try {
          final candidates = jsonResponse['candidates'];
          if (candidates == null || candidates.isEmpty) {
            throw Exception('No candidates in response');
          }

          final parts = candidates[0]['content']['parts'];
          if (parts == null || parts.isEmpty) {
            throw Exception('No parts in response');
          }

          var imagePart = parts.firstWhere(
            (part) => part['inlineData'] != null,
            orElse: () => null,
          );

          if (imagePart == null) {
            _logError('⚠️ No image found in response parts');
            throw Exception('No image found in response');
          }

          base64GeneratedImage = imagePart['inlineData']['data'];
          if (base64GeneratedImage == null) {
            throw Exception('Image data is null');
          }

          _logInfo('✓ Successfully extracted image from response');
          return base64GeneratedImage;
        } catch (e) {
          _logError('❌ Error extracting image: $e');

          // Try to log the response structure for debugging
          try {
            var structure = _mapResponseStructure(jsonResponse);
            _logDebug('Response structure: $structure');
          } catch (e2) {
            _logError('Failed to map response structure: $e2');
          }

          throw Exception('Failed to extract image from response: $e');
        }
      } else {
        _logError('❌ API request failed with status: ${response.statusCode}');
        _logError('Error response body: ${response.body}');

        // Try to parse the error for more details
        try {
          var errorJson = jsonDecode(response.body);
          var errorMessage = errorJson['error']['message'] ?? 'Unknown error';
          var errorCode = errorJson['error']['code'] ?? 'Unknown code';
          _logError('Error code: $errorCode, Error message: $errorMessage');
          throw Exception('API error $errorCode: $errorMessage');
        } catch (e) {
          throw Exception(
            'API request failed with status: ${response.statusCode}, message: ${response.body}',
          );
        }
      }
    } catch (e) {
      _logError('❌ Exception during API call (editImage): $e');
      rethrow;
    }
  }

  /// Generates a JSON description of the image's style.
  static Future<String> generateStyleDescription({
    required Uint8List imageData,
  }) async {
    try {
      _logInfo(
        '🎨 Starting API request to Gemini (Generate Style Description)',
      );
      _logInfo('🖼️ Image size: ${imageData.length} bytes');

      final apiKey = await ApiConfig.getGeminiApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('No API key found.');
      }

      // Resize if needed (optional, but good for consistency/cost)
      Uint8List processedImageData = await resizeImageIfNeeded(
        imageData,
        maxDimension:
            512, // Smaller dimension might be sufficient for style analysis
      );
      _logInfo(
        '✓ Resized image for style analysis to ${processedImageData.length} bytes',
      );

      final String base64Image = base64Encode(processedImageData);
      _logInfo('✓ Image converted to base64');

      // Prompt asking for JSON style description
      const String stylePrompt = """
Analyze the attached image and describe its visual style in JSON format.

Provide ONLY the JSON object as your response.

This JSON will be sent to an AI image generator to generate a new image based on style from JSON.

""";

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': stylePrompt},
              {
                'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
              },
            ],
          },
        ],
        'generation_config': {
          // Ensure JSON output if the model supports it directly, otherwise rely on prompt
          // 'response_mime_type': 'application/json', // Uncomment if model supports direct JSON output
        },
        // Safety settings might need adjustment if style descriptions get blocked
        // 'safety_settings': [ ... ]
      };

      _logInfo('📤 Sending request for style description...');
      _logDebug('Style Request Body: ${jsonEncode(requestBody)}');

      // Use a model potentially better suited for analysis if available, like gemini-pro-vision
      // For now, using the same model.
      final response = await http.post(
        Uri.parse('$_baseUrl/$_modelName:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      _logInfo(
        '📥 Received style response with status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        _logDebug('Full style response: ${_truncateString(response.body)}');

        // Extract the text part containing the JSON
        try {
          final candidates = jsonResponse['candidates'];
          if (candidates == null || candidates.isEmpty) {
            throw Exception('No candidates in style response');
          }
          final parts = candidates[0]['content']['parts'];
          if (parts == null || parts.isEmpty || parts[0]['text'] == null) {
            throw Exception('No text part found in style response');
          }

          String styleJsonText = parts[0]['text'];

          // Clean up potential markdown code fences
          styleJsonText =
              styleJsonText
                  .replaceAll('```json', '')
                  .replaceAll('```', '')
                  .trim();

          // Validate if it's valid JSON (basic check)
          try {
            jsonDecode(styleJsonText);
            _logInfo('✓ Successfully extracted style JSON description.');
            return styleJsonText;
          } catch (jsonError) {
            _logError('❌ Extracted text is not valid JSON: $jsonError');
            _logError('Raw text received: $styleJsonText');
            throw Exception('Generated style description is not valid JSON.');
          }
        } catch (e) {
          _logError('❌ Error extracting style JSON from response: $e');
          _logDebug(
            'Response structure: ${_mapResponseStructure(jsonResponse)}',
          );
          throw Exception('Failed to extract style JSON from response: $e');
        }
      } else {
        _logError(
          '❌ Style generation API request failed: ${response.statusCode}',
        );
        _logError('Error response body: ${response.body}');
        throw Exception(
          'Style generation failed: ${response.statusCode}, ${response.body}',
        );
      }
    } catch (e) {
      _logError('❌ Exception during style generation: $e');
      rethrow;
    }
  }

  // Helper method to log the structure of the response
  static Map<String, dynamic> _mapResponseStructure(
    dynamic json, [
    int depth = 0,
  ]) {
    if (depth > 3) return {'truncated': '...'};

    if (json is Map) {
      return json.map((key, value) {
        if (value is Map || value is List) {
          return MapEntry(key, _mapResponseStructure(value, depth + 1));
        } else if (value is String && value.length > 100) {
          return MapEntry(key, '${value.substring(0, 100)}... (truncated)');
        } else {
          return MapEntry(key, value.runtimeType.toString());
        }
      });
    } else if (json is List) {
      if (json.isEmpty) return {'emptyList': '[]'};
      return {
        'list[${json.length}]': _mapResponseStructure(json[0], depth + 1),
      };
    } else {
      return {'value': json.toString()};
    }
  }

  // Helper method to truncate long strings for logging
  static String _truncateString(String text, [int maxLength = 500]) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}... (truncated, total length: ${text.length})';
  }

  // Logger methods for different levels
  static void _logInfo(String message) {
    printDebug('📘 INFO: $message');
  }

  static void _logDebug(String message) {
    printDebug('🔍 DEBUG: $message');
  }

  static void _logError(String message) {
    printDebug('🚨 ERROR: $message');
  }

  // Updated method to handle both network and file URLs with better path handling
  static Future<Uint8List> getImageBytesFromUrl(String imageUrl) async {
    try {
      _logInfo('📥 Loading image from: $imageUrl');

      // Check if the path is a local file path (could be with or without file:// prefix)
      if (imageUrl.startsWith('file://') || !imageUrl.startsWith('http')) {
        // Handle local file - strip file:// prefix if present
        String filePath =
            imageUrl.startsWith('file://')
                ? imageUrl.replaceFirst('file://', '')
                : imageUrl;

        _logInfo('🔍 Resolving local file path: $filePath');
        final file = File(filePath);

        if (!await file.exists()) {
          _logError('❌ File does not exist: ${file.path}');
          throw Exception('File does not exist: ${file.path}');
        }

        try {
          final bytes = await file.readAsBytes();
          _logInfo('✓ Loaded image from file: ${bytes.length} bytes');
          return bytes;
        } catch (e) {
          _logError('❌ Failed to read file bytes: $e');
          throw Exception('Failed to read file bytes: $e');
        }
      } else {
        // Handle network URL
        final http.Response response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          _logInfo(
            '✓ Loaded image from network: ${response.bodyBytes.length} bytes',
          );
          return response.bodyBytes;
        } else {
          _logError('❌ Failed to load image: ${response.statusCode}');
          throw Exception('Failed to load image: ${response.statusCode}');
        }
      }
    } catch (e) {
      _logError('❌ Error loading image: $e');
      throw Exception('Error loading image: $e');
    }
  }

  // Helper method to resize image to appropriate dimensions if needed
  static Future<Uint8List> resizeImageIfNeeded(
    Uint8List imageBytes, {
    int maxDimension = 1024,
  }) async {
    try {
      _logInfo('🔍 Checking if image needs resizing...');

      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      _logInfo(
        '📏 Original image dimensions: ${image.width} x ${image.height}',
      );

      // Check if image needs resizing
      if (image.width <= maxDimension && image.height <= maxDimension) {
        _logInfo('✓ No resizing needed');
        return imageBytes;
      }

      // Calculate new dimensions while maintaining aspect ratio
      double scale = maxDimension / math.max(image.width, image.height);
      int newWidth = (image.width * scale).round();
      int newHeight = (image.height * scale).round();

      _logInfo('🔄 Resizing image to: $newWidth x $newHeight');

      // Create a new image with the resized dimensions
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
        Paint()..filterQuality = FilterQuality.high,
      );

      final ui.Image resizedImage = await recorder.endRecording().toImage(
        newWidth,
        newHeight,
      );
      final ByteData? byteData = await resizedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        _logError('❌ Failed to get byte data from resized image');
        throw Exception('Failed to resize image: ByteData is null');
      }

      final result = byteData.buffer.asUint8List();
      _logInfo(
        '✅ Image resized successfully. New size: ${result.length} bytes',
      );

      return result;
    } catch (e) {
      _logError('❌ Error resizing image: $e');
      // Return original if resizing fails
      return imageBytes;
    }
  }
}
