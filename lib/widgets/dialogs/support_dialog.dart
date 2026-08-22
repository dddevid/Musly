import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dialog shown on app startup asking users to join Discord or support the project
class SupportDialog extends StatefulWidget {
  const SupportDialog({super.key});

  static const String _prefsKey = 'support_dialog_dont_show';

  /// Check if dialog should be shown
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_prefsKey) ?? false);
  }

  /// Mark dialog as "don't show again"
  static Future<void> dontShowAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  @override
  State<SupportDialog> createState() => _SupportDialogState();
}

class _SupportDialogState extends State<SupportDialog> {
  bool _dontShowAgain = false;

  Future<void> _launchDiscord() async {
    final uri = Uri.parse('https://discord.gg/RrcFvFPdRU');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchDonation() async {
    final uri = Uri.parse('https://revolut.me/ddevid_1');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _onClose() {
    if (_dontShowAgain) {
      SupportDialog.dontShowAgain();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360 || size.height < 600;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: isSmallScreen ? 16 : 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? size.width - 32 : 400,
          maxHeight: size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Logo/Icon
              Container(
                width: isSmallScreen ? 64 : 80,
                height: isSmallScreen ? 64 : 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFA2D48), Color(0xFFFF6B6B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  CupertinoIcons.heart_fill,
                  color: Colors.white,
                  size: isSmallScreen ? 32 : 40,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Support Musly',
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),

              // Description
              Text(
                'Musly is a free, open-source project. Your support helps keep it alive!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.5,
                ),
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),

              // Discord button
              _buildActionButton(
                icon: CupertinoIcons.chat_bubble_fill,
                title: 'Join our Discord',
                subtitle: 'Get help, suggest features, chat with us',
                color: const Color(0xFF5865F2),
                onTap: _launchDiscord,
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),

              // Donation button
              _buildActionButton(
                icon: CupertinoIcons.heart_fill,
                title: 'Support with a Donation',
                subtitle: 'Help cover server costs and development',
                color: const Color(0xFFFA2D48),
                onTap: _launchDonation,
                compact: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),

              // Don't show again checkbox
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _dontShowAgain,
                      onChanged: (value) {
                        setState(() {
                          _dontShowAgain = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFFFA2D48),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _dontShowAgain = !_dontShowAgain;
                        });
                      },
                      child: Text(
                        'Don\'t show this again',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),

              // Close button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _onClose,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                  ),
                  child: Text(
                    'Maybe Later',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(compact ? 12 : 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 36 : 44,
                height: compact ? 36 : 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(compact ? 8 : 10),
                ),
                child: Icon(icon, color: Colors.white, size: compact ? 18 : 22),
              ),
              SizedBox(width: compact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: compact ? 1 : 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_forward,
                color: color,
                size: compact ? 16 : 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
