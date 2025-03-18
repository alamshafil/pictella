import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Terms of Service',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                Container(
                  margin: const EdgeInsets.only(top: 30),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Note: This is a placeholder. If you are testing this app, contact support for more information.',
                          style: TextStyle(color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Last Updated: March 16, 2025',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 30),

                _buildSection(
                  '1. Introduction',
                  'This is placeholder text for the Terms of Service. In a production app, this '
                      'would contain your actual legal terms and conditions that users must agree to '
                      'before using the application.',
                ),

                _buildSection(
                  '2. Acceptance of Terms',
                  'By accessing or using the PhotoMagic AI Editor application, you agree to be bound '
                      'by these Terms of Service. If you do not agree to these terms, please do not use '
                      'the application.',
                ),

                _buildSection(
                  '3. Description of Service',
                  'PhotoMagic AI Editor provides AI-powered photo editing capabilities. This is a '
                      'placeholder for a detailed description of services provided by the application.',
                ),

                _buildSection(
                  '4. User Content',
                  'Users retain all ownership rights to their content. This section would describe '
                      'how user content is handled, stored, and processed within the application.',
                ),

                _buildSection(
                  '5. Limitations and Restrictions',
                  'This section would outline limitations on use of the service, prohibited '
                      'activities, and restrictions.',
                ),

                _buildSection(
                  '6. Disclaimer of Warranty',
                  'The service is provided "as is" without warranty of any kind. This section would '
                      'contain full disclaimer language.',
                ),

                _buildSection(
                  '7. Limitation of Liability',
                  'This section would limit the liability of the app developer for various types of '
                      'damages or issues that might arise from use of the application.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }
}
