import 'package:flutter/material.dart';
import '../widgets/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
        child: Column(
          children: [
            // Back button
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: AppTheme.glassDecoration(radius: 14),
                  child: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_rounded, color: AppColors.magentaLight, size: 36),
                const SizedBox(width: 12),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                    children: [
                      TextSpan(text: 'halal'),
                      TextSpan(
                        text: 'scanner',
                        style: TextStyle(
                          color: AppColors.magentaLight,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.magenta,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'HALAL VERIFICATION SOLUTIONS',
              style: TextStyle(fontSize: 9, color: Colors.white30, letterSpacing: 3, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 32),

            // Main card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: AppTheme.glassDecoration(radius: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Halal Food Scanner',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 4),
                  const Text('Personal Project / Professional Standard',
                      style: TextStyle(fontSize: 11, color: AppColors.magentaLight, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 20),

                  const _Section(
                    icon: Icons.menu_book_rounded,
                    label: 'Project Scope',
                    content:
                        'This application was developed as a specialized task for a mobile development course. It integrates various APIs and AI models—including Gemini for scientific ingredient analysis—to demonstrate the practical application of the Halal industry\'s digital transformation.',
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_rounded, size: 14, color: Colors.white38),
                            SizedBox(width: 6),
                            Text('THE CREATOR',
                                style: TextStyle(fontSize: 9, color: Colors.white38, letterSpacing: 2, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text('Habibun-najal Kayting',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                        SizedBox(height: 4),
                        Text('BSIT - Database Systems',
                            style: TextStyle(fontSize: 12, color: Colors.white54)),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.badge_rounded, size: 14, color: Colors.white38),
                            SizedBox(width: 6),
                            Text('Student ID: 23-30080',
                                style: TextStyle(fontSize: 12, color: Colors.white54)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const _Section(
                    icon: Icons.mail_rounded,
                    label: 'Contact',
                    content: 'Kayting4k@gmail.com',
                  ),
                  const SizedBox(height: 20),

                  Divider(color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 14, color: Colors.redAccent),
                      SizedBox(width: 6),
                      Text('DISCLAIMER',
                          style: TextStyle(fontSize: 9, color: Colors.redAccent, letterSpacing: 2, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This app is an academic output created solely for educational purposes and is not intended for commercial publication or online distribution.',
                    style: TextStyle(fontSize: 11, color: Colors.white30, fontStyle: FontStyle.italic, height: 1.5),
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

class _Section extends StatelessWidget {
  final IconData icon;
  final String label, content;

  const _Section({required this.icon, required this.label, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white38),
            const SizedBox(width: 6),
            Text(label.toUpperCase(),
                style: const TextStyle(fontSize: 9, color: Colors.white38, letterSpacing: 2, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(fontSize: 13, color: Colors.white60, height: 1.6)),
      ],
    );
  }
}
