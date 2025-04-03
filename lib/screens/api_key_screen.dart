import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_app/components/glass_button.dart';
import 'package:image_app/components/glass_container.dart';
import 'package:image_app/utils/app_preferences.dart';
import 'main_screen.dart';

class ApiKeyScreen extends StatefulWidget {
  final bool isFirstSetup;
  final VoidCallback? onKeyUpdated;

  const ApiKeyScreen({super.key, this.isFirstSetup = false, this.onKeyUpdated});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscureText = true;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (!widget.isFirstSetup) {
      _loadCurrentKey();
    }
  }

  Future<void> _loadCurrentKey() async {
    setState(() => _isLoading = true);
    try {
      final apiKey = await AppPreferences.getApiKey();
      if (apiKey != null) {
        // Show only last 5 characters of the key
        final maskedKey =
            '•••••••••••••••${apiKey.substring(apiKey.length - 5)}';
        _apiKeyController.text = maskedKey;
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load API key');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      setState(() => _errorMessage = 'Please enter your API key');
      return;
    }

    if (apiKey.startsWith('•')) {
      setState(() => _errorMessage = 'Please enter a new API key');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AppPreferences.saveApiKey(apiKey);

      if (widget.onKeyUpdated != null) {
        widget.onKeyUpdated!();
      }

      if (widget.isFirstSetup) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API key saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save API key: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar:
          widget.isFirstSetup
              ? null
              : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text('API Key Settings'),
              ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF01579B), Color(0xFF111111)],
          ),
        ),
        // Add an intermediate container to prevent the gray background
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isFirstSetup) ...[
                    const SizedBox(height: 40),
                    Text(
                      'Almost there!',
                      style: GoogleFonts.albertSans(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Enter your Google AI Studio API key to start using the app',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],

                  GlassContainer(
                    borderRadius: 16,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.key, color: Colors.amber),
                              const SizedBox(width: 10),
                              Text(
                                'Google AI Studio API Key',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'To use this app, you need an API key from Google AI Studio:',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionStep(
                            '1',
                            'Go to aistudio.google.com and sign in with your Google account',
                          ),
                          _buildInstructionStep(
                            '2',
                            'Create a new API key in the "API Keys" section',
                          ),
                          _buildInstructionStep(
                            '3',
                            'For security, create a key specifically for this app',
                          ),
                          _buildInstructionStep(
                            '4',
                            'Copy and paste the API key below',
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: TextField(
                              controller: _apiKeyController,
                              decoration: InputDecoration(
                                hintText: 'Paste your API key here',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                                border: InputBorder.none,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureText = !_obscureText;
                                    });
                                  },
                                ),
                              ),
                              obscureText: _obscureText,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.redAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            '🔒 Your API key is stored securely on your device and is never shared.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.6),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GlassButton(
                    text: widget.isFirstSetup ? 'Get Started' : 'Save API Key',
                    onPressed: _isLoading ? null : _saveApiKey,
                    fullWidth: true,
                    icon: _isLoading ? null : Icons.save,
                  ),
                  if (!widget.isFirstSetup) ...[
                    const SizedBox(height: 16),
                    GlassButton(
                      text: 'Delete API Key',
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                _showDeleteConfirmationDialog();
                              },
                      fullWidth: true,
                      buttonColor: Colors.redAccent.withValues(alpha: 0.3),
                      textColor: Colors.redAccent,
                      borderColor: Colors.redAccent.withValues(alpha: 0.5),
                      icon: Icons.delete_outline,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete API Key?'),
            content: const Text(
              'This will remove your API key from the app. '
              'You will need to enter it again to use the app.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('DELETE'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await AppPreferences.deleteApiKey();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('API key deleted')));
      Navigator.of(context).pop();
    }
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.blue.shade300,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }
}
