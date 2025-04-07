import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_app/utils/app_settings.dart';
import 'dart:ui';
import 'settings/about_screen.dart';
import 'settings/storage_screen.dart';
import 'settings/contact_screen.dart';
import 'settings/legal/terms_screen.dart';
import 'settings/legal/privacy_screen.dart';
import 'api_key_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isInTabView;

  const SettingsScreen({super.key, this.isInTabView = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  Future<void> _toggleBlurEffects(bool newValue) async {
    setState(() {
      _isLoading = true;
    });

    // Update both the singleton and persistent storage
    await AppSettings.instance.setBlurEffectsEnabled(newValue);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newValue ? 'Blur effects enabled.' : 'Blur effects disabled.',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final blurEffectsEnabled = AppSettings.instance.blurEffectsEnabled;

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
          if (blurEffectsEnabled)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withValues(alpha: 0.05)),
            ),

          // Content
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App bar
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Settings',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),

                // Settings list
                Expanded(
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            children: [
                              _buildSettingCategory('App Settings'),

                              // API Key Management
                              _buildSettingTile(
                                context,
                                icon: Icons.key,
                                title: 'API Key Management',
                                subtitle: 'Configure your Gemini API key',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const ApiKeyScreen(
                                            isFirstSetup: false,
                                          ),
                                    ),
                                  );
                                },
                              ),

                              // Storage Management
                              _buildSettingTile(
                                context,
                                icon: Icons.storage,
                                title: 'Storage Management',
                                subtitle: 'Manage saved images and app data',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const StorageManagementScreen(),
                                    ),
                                  );
                                },
                              ),

                              // Blur effects switch
                              _buildSwitchTile(
                                icon: Icons.blur_on,
                                title: 'Enable Blur Effects',
                                subtitle:
                                    'Apply glass blur effects throughout the app',
                                value: blurEffectsEnabled,
                                onChanged: _toggleBlurEffects,
                              ),

                              const SizedBox(height: 20),

                              _buildSettingCategory('Contact'),

                              _buildSettingTile(
                                context,
                                icon: Icons.email_outlined,
                                title: 'Contact Support',
                                subtitle: 'Get help with the app',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const ContactScreen(),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 20),

                              if (kDebugMode) ...[
                                _buildSettingCategory('Legal'),

                                _buildSettingTile(
                                  context,
                                  icon: Icons.description_outlined,
                                  title: 'Terms of Service',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const TermsScreen(),
                                      ),
                                    );
                                  },
                                ),

                                _buildSettingTile(
                                  context,
                                  icon: Icons.privacy_tip_outlined,
                                  title: 'Privacy Policy',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const PrivacyScreen(),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 20),
                              ],

                              _buildSettingCategory('Info'),

                              _buildSettingTile(
                                context,
                                icon: Icons.info_outline,
                                title: 'About App',
                                subtitle: 'Version, developer info, and more',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AboutScreen(),
                                    ),
                                  );
                                },
                              ),

                              _buildSettingTile(
                                context,
                                icon: Icons.policy_outlined,
                                title: 'Licenses',
                                subtitle: 'Open source licenses',
                                onTap: () {
                                  showLicensePage(
                                    context: context,
                                    applicationName: 'Pictella AI Editor',
                                    applicationVersion: '1.0.0',
                                    applicationIcon: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.photo_filter,
                                        size: 48,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(
                                height: 100,
                              ), // Bottom padding for nav bar
                            ],
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.isInTabView ? null : null,
    );
  }

  Widget _buildSettingCategory(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.blue[300],
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: Colors.white, size: 24),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle:
            subtitle != null
                ? Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                )
                : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        secondary: Icon(icon, color: Colors.white, size: 24),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        value: value,
        activeColor: Colors.blue,
        onChanged: onChanged,
      ),
    );
  }
}
