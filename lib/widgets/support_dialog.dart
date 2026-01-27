import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/services.dart';

class SupportDialog extends StatefulWidget {
  const SupportDialog({super.key});

  @override
  State<SupportDialog> createState() => _SupportDialogState();
}

class _SupportDialogState extends State<SupportDialog> {
  bool _doNotShowAgain = false;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label address copied to clipboard'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                Icon(Icons.favorite_rounded, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Support Musly',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Discord Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF5865F2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF5865F2).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_rounded,
                        color: const Color(0xFF5865F2),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Join our Discord Community',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Get support, share feedback, and connect with other users!',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _launchUrl('https://discord.gg/k9FqpbT65M'),
                      icon: const Icon(Icons.discord, size: 18),
                      label: const Text('Join Discord (Optional)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5865F2),
                        side: const BorderSide(color: Color(0xFF5865F2)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Donations Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Support Development ☕',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 12),

            // Buy Me a Coffee
            _DonationButton(
              icon: Icons.coffee_rounded,
              label: 'Buy Me a Coffee',
              color: const Color(0xFFFFDD00),
              onTap: () => _launchUrl('https://buymeacoffee.com/devidd'),
            ),

            const SizedBox(height: 8),

            // Bitcoin
            _CryptoAddress(
              icon: Icons.currency_bitcoin,
              label: 'Bitcoin',
              address: 'bc1qrfv880kc8qamanalc5kcqs9q5wszh90e5eggyz',
              color: const Color(0xFFF7931A),
              onCopy: () => _copyToClipboard(
                'bc1qrfv880kc8qamanalc5kcqs9q5wszh90e5eggyz',
                'Bitcoin',
              ),
            ),

            const SizedBox(height: 8),

            // Solana
            _CryptoAddress(
              icon: Icons.wallet_rounded,
              label: 'Solana',
              address: 'E3JUcjyR6UCJtppU24iDrq82FyPeV9nhL1PKHx57iPXu',
              color: const Color(0xFF00FFA3),
              onCopy: () => _copyToClipboard(
                'E3JUcjyR6UCJtppU24iDrq82FyPeV9nhL1PKHx57iPXu',
                'Solana',
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: _doNotShowAgain,
                  onChanged: (value) {
                    setState(() {
                      _doNotShowAgain = value ?? false;
                    });
                    Provider.of<StorageService>(
                      context,
                      listen: false,
                    ).saveHideSupportDialog(_doNotShowAgain);
                  },
                ),
                const Text("Don't show again"),
              ],
            ),

              Text(
                'Your support helps keep development going! 🚀',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DonationButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.15),
          foregroundColor: color.withOpacity(0.9),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _CryptoAddress extends StatelessWidget {
  final IconData icon;
  final String label;
  final String address;
  final Color color;
  final VoidCallback onCopy;

  const _CryptoAddress({
    required this.icon,
    required this.label,
    required this.address,
    required this.color,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: onCopy,
            tooltip: 'Copy address',
          ),
        ],
      ),
    );
  }
}
