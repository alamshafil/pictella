import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
                  'Privacy Policy',
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
                  '1. Information We Collect',
                  'This is placeholder text for the Privacy Policy. This section would describe '
                      'what personal data the app collects from users and how it is collected.',
                ),

                _buildSection(
                  '2. Use of Information',
                  'This section would explain how the collected information is used within the '
                      'application, such as for improving user experience or providing services.',
                ),

                _buildSection(
                  '3. Data Storage',
                  'PhotoMagic AI Editor stores user data locally on the device. This section would '
                      'detail how user data is stored, whether it\'s transmitted to servers, and any '
                      'encryption methods used.',
                ),

                _buildSection(
                  '4. Data Sharing',
                  'This section would explain if and how user data is shared with third parties, '
                      'such as service providers or AI processing services.',
                ),

                _buildSection(
                  '5. User Rights',
                  'This section would outline the rights users have regarding their data, such as '
                      'the right to access, modify, or delete their information.',
                ),

                _buildSection(
                  '6. Data Retention',
                  'This section would explain how long user data is kept and the process for data '
                      'deletion when requested by users or when no longer needed.',
                ),

                _buildSection(
                  '7. Children\'s Privacy',
                  'This section would address compliance with regulations regarding children\'s '
                      'privacy and whether the app is intended for use by children.',
                ),

                _buildSection(
                  '8. Changes to Privacy Policy',
                  'This section would explain how changes to the privacy policy are communicated '
                      'to users and how users can stay informed of updates.',
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
