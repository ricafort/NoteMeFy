import 'package:flutter/material.dart';
import 'package:notemefy/services/haptic_service.dart';
import 'package:notemefy/services/pro_upgrade_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProUpgradeScreen extends ConsumerWidget {
  const ProUpgradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(proUpgradeProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.amber, size: 64),
                      const SizedBox(height: 24),
                      const Text(
                        'NoteMeFy Pro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Unlock the full power of frictionless capture.',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      const SizedBox(height: 48),
                      _FeatureRow(icon: Icons.repeat_rounded, text: 'Recurring Routines (Daily/Weekly)'),
                      const SizedBox(height: 16),
                      _FeatureRow(icon: Icons.work_rounded, text: 'Business / Personal Tagging'),
                      const SizedBox(height: 16),
                      _FeatureRow(icon: Icons.file_download_rounded, text: 'CSV Export for ABN Tracking'),
                      const SizedBox(height: 16),
                      _FeatureRow(icon: Icons.auto_awesome, text: 'On-Device AI Categorization'),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              
              // Bottom Action Area
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPro ? Colors.grey[800] : Colors.amber,
                    foregroundColor: isPro ? Colors.white54 : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: isPro ? null : () async {
                    ref.read(hapticServiceProvider).click();
                    
                    // Show a quick dialog indicating purchase
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
                    );

                    await ref.read(proUpgradeProvider.notifier).unlockPro();
                    
                    if (context.mounted) {
                      Navigator.pop(context); // close dialog
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('NoteMeFy VIP Unlocked! Thank you! 🌟'),
                          backgroundColor: Colors.amber,
                        ),
                      );
                      
                      Navigator.pop(context); // close paywall screen
                    }
                  },
                  child: Text(
                    isPro ? 'Pro Unlocked' : 'Unlock Lifetime - \$9.99',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (!isPro)
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Restore Purchases', style: TextStyle(color: Colors.white54)),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.amberAccent, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
