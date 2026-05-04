import 'package:flutter/material.dart';
import '../widgets/app_theme.dart';

class GuidelinesScreen extends StatelessWidget {
  const GuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      {
        'title': 'Core Verification Standards',
        'items': [
          {'label': 'Traceability', 'desc': 'Every ingredient must be traceable back to its source of synthesis.'},
          {'label': 'Ethanol Threshold', 'desc': 'Alcohol content must remain below 0.1% for natural fermentation.'},
          {'label': 'Enzyme Origins', 'desc': 'Industrial enzymes must not be derived from porcine sources.'},
        ]
      },
      {
        'title': 'Common Ingredients to Watch',
        'items': [
          {'label': 'E-Numbers', 'desc': 'Specific additives (e.g., E471) require verified plant-based status.'},
          {'label': 'Gelatin', 'desc': 'Requires definitive bovine (halal-slaughtered) or marine origin.'},
          {'label': 'Flavorings', 'desc': 'Proprietary flavor blends must be screened for carrier alcohols.'},
        ]
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: AppTheme.glassDecoration(radius: 14),
                child: const Icon(Icons.chevron_left_rounded, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Icon(Icons.menu_book_rounded, color: AppColors.magentaLight, size: 36),
                SizedBox(width: 12),
                Text(
                  'Verification Guidelines',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Our AI scanner uses these scientific standards for thorough verification.',
              style: TextStyle(fontSize: 13, color: Colors.white38, height: 1.5),
            ),
            const SizedBox(height: 24),
            ...sections.map((section) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.glassDecoration(radius: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield_rounded, color: AppColors.magentaLight, size: 22),
                            const SizedBox(width: 10),
                            Text(section['title'] as String,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...(section['items'] as List).map((item) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text((item as Map)['label'] as String,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.magentaLight,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1)),
                                  const SizedBox(height: 4),
                                  Text(item['desc'] as String,
                                      style: const TextStyle(fontSize: 12, color: Colors.white54, height: 1.4)),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                )),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.magenta.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.magenta.withValues(alpha: 0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_rounded, color: AppColors.magentaLight, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Disclaimer',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
                        SizedBox(height: 4),
                        Text(
                          'This app is a research tool for academic purposes. Always consult local religious authorities and certified labs for definitive Halal certification.',
                          style: TextStyle(fontSize: 12, color: Colors.white54, height: 1.5),
                        ),
                      ],
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
}
