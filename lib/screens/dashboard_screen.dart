import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_theme.dart';
import 'about_screen.dart';
import 'guidelines_screen.dart';
import 'admin_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onTabChange;
  const DashboardScreen({super.key, this.onTabChange});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tapCount = 0;
  int _lastTap = 0;

  void _handleSecretTap(AppAuthProvider auth) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTap < 1000) {
      _tapCount++;
      if (_tapCount >= 5) {
        if (auth.user == null) {
          await auth.login();
        } else if (auth.isAdmin) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin access required')),
          );
        }
        _tapCount = 0;
      }
    } else {
      _tapCount = 1;
    }
    _lastTap = now;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.magenta.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.magenta.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.menu_rounded, color: AppColors.magentaLight, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _handleSecretTap(auth),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.magenta.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.magenta.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.shield_rounded, color: AppColors.magentaLight, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
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
                  const Text(
                    'PRECISION ANALYSIS',
                    style: TextStyle(fontSize: 8, color: Colors.white30, letterSpacing: 3, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const Spacer(),
              if (auth.user == null && !auth.isGuest)
                GestureDetector(
                  onTap: auth.login,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: AppTheme.glassDecoration(radius: 12),
                    child: const Icon(Icons.login_rounded, color: Colors.white60, size: 20),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: AppTheme.glassDecoration(radius: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.person_rounded, color: AppColors.magentaLight, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        auth.isGuest ? 'Guest' : (auth.user?.email?.split('@')[0] ?? ''),
                        style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Scanner Button
          _ActionCard(
            title: 'SCIENTIFIC SCANNER',
            subtitle: 'Real-time Ingredient Validation',
            tag: 'Science-First',
            icon: Icons.shield_rounded,
            iconBg: AppColors.magenta,
            hasGlow: true,
            onTap: () => widget.onTabChange?.call(1),
          ),
          const SizedBox(height: 16),

          // Map Button
          _ActionCard(
            title: 'TRUSTED VENUES',
            subtitle: 'Explore Verified Establishments',
            tag: 'Community Map',
            icon: Icons.star_rounded,
            iconBg: Colors.white10,
            hasGlow: false,
            onTap: () => widget.onTabChange?.call(2),
          ),
          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.05))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'STANDARDS & SUPPORT',
                  style: TextStyle(fontSize: 8, color: Colors.white30, letterSpacing: 3, fontWeight: FontWeight.w900),
                ),
              ),
              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.05))),
            ],
          ),
          const SizedBox(height: 16),

          // Grid
          Row(
            children: [
              Expanded(
                child: _GridCard(
                  icon: Icons.menu_book_rounded,
                  title: 'Guidelines',
                  subtitle: 'Food Standards',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuidelinesScreen())),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _GridCard(
                  icon: Icons.info_rounded,
                  title: 'Research',
                  subtitle: 'Verified Data',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Footer
          const Row(
            children: [
              Icon(Icons.lock_rounded, size: 12, color: Colors.white24),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Powered by Global Halal Research Standards',
                  style: TextStyle(fontSize: 8, color: Colors.white24, fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

class _ActionCard extends StatelessWidget {
  final String title, subtitle, tag;
  final IconData icon;
  final Color iconBg;
  final bool hasGlow;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.icon,
    required this.iconBg,
    required this.hasGlow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: hasGlow
            ? BoxDecoration(
                color: AppColors.glass,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white12),
                boxShadow: [BoxShadow(color: AppColors.magenta.withValues(alpha: 0.2), blurRadius: 20)],
              )
            : AppTheme.glassDecoration(radius: 32),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tag,
                      style: const TextStyle(fontSize: 9, color: AppColors.magentaLight, fontWeight: FontWeight.w700, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  Text(title,
                      style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: AppTheme.glassDecoration(radius: 18),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white30, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  const _GridCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassDecoration(radius: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.magenta.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.magentaLight, size: 20),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
