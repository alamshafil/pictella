import 'package:flutter/material.dart';
import 'package:image_app/components/glass_button.dart';
import 'package:image_app/utils/app_preferences.dart';
import 'api_key_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // Function to mark onboarding as completed and navigate to API key screen
  Future<void> _proceedToApiKeyScreen(BuildContext context) async {
    // Save that the user has seen onboarding
    await AppPreferences.setOnboardingComplete();

    if (!context.mounted) return;

    // Navigate to API key screen and remove the welcome screen from stack
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const ApiKeyScreen(isFirstSetup: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D47A1), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transform Your Photos\nWith AI Magic',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Upload your photos and tell AI what to add, remove or modify',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Examples showcase - using pairs of images for before/after
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView(
                    children: [
                      _buildBeforeAfterSection(
                        "Add people to your photos",
                        "Original photo",
                        "Added Elon Musk to scene",
                        'assets/sample/elon_before.jpg',
                        'assets/sample/elon_after.jpg',
                      ),
                      const SizedBox(height: 24),
                      _buildBeforeAfterSection(
                        "Put on different clothes",
                        "Image of clothes",
                        "Added clothes to person",
                        'assets/sample/clothes.png',
                        'assets/sample/clothes_on.png',
                      ),
                      const SizedBox(height: 24),
                      _buildBeforeAfterSection(
                        "Restore old photos",
                        "Old photo",
                        "Restored photo",
                        'assets/sample/old_photo.png',
                        'assets/sample/old_photo_restore.png',
                      ),
                    ],
                  ),
                ),
              ),

              // CTA Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: GlassButton(
                    text: 'Get Started!',
                    onPressed: () => _proceedToApiKeyScreen(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBeforeAfterSection(
    String title,
    String beforeDesc,
    String afterDesc,
    String beforeImagePath,
    String afterImagePath,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      image: DecorationImage(
                        image: AssetImage(beforeImagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    beforeDesc,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      image: DecorationImage(
                        image: AssetImage(afterImagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    afterDesc,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
