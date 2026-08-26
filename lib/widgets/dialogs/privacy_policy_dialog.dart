import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';

class PrivacyPolicyDialog extends StatefulWidget {
  const PrivacyPolicyDialog({super.key});

  static const String _prefsKey = 'privacy_policy_accepted';
  static const String _firstLaunchKey = 'first_app_launch';

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAccepted = prefs.getBool(_prefsKey) ?? false;
    final isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;

    if (isFirstLaunch) {
      await prefs.setBool(_firstLaunchKey, false);
    }

    return !hasAccepted && isFirstLaunch;
  }

  static Future<void> markAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  @override
  State<PrivacyPolicyDialog> createState() => _PrivacyPolicyDialogState();
}

class _PrivacyPolicyDialogState extends State<PrivacyPolicyDialog> {
  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://musly.devid.lol/privacy');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _onAccept() async {
    await PrivacyPolicyDialog.markAccepted();
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _onDecline() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      CupertinoIcons.shield_fill,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.privacyFirstTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.privacyFirstSubtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPrivacyPoint(
                      icon: CupertinoIcons.lock_fill,
                      color: const Color(0xFF22C55E),
                      title: l10n.noDataSellingTitle,
                      description: l10n.noDataSellingDescription,
                    ),
                    const SizedBox(height: 16),
                    _buildPrivacyPoint(
                      icon: CupertinoIcons.device_phone_portrait,
                      color: const Color(0xFF3B82F6),
                      title: l10n.localFirstStorageTitle,
                      description: l10n.localFirstStorageDescription,
                    ),
                    const SizedBox(height: 16),
                    _buildPrivacyPoint(
                      icon: CupertinoIcons.shield_fill,
                      color: const Color(0xFFF59E0B),
                      title: l10n.privateOpenTitle,
                      description: l10n.privateOpenDescription,
                    ),
                    const SizedBox(height: 24),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openPrivacyPolicy,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  CupertinoIcons.doc_text_fill,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.readFullPrivacyPolicy,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.viewCompleteDetailsWebsite,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                CupertinoIcons.chevron_forward,
                                color: Color(0xFF3B82F6),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.understandAndContinue,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _onDecline,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[500],
                    ),
                    child: Text(
                      l10n.declineAndExit,
                      style: const TextStyle(fontSize: 14),
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

  Widget _buildPrivacyPoint({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
