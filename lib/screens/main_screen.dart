import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_theme.dart';
import 'dashboard_screen.dart';
import 'scanner_screen.dart';
import 'map_screen.dart';
import 'guidelines_screen.dart';
import 'about_screen.dart';
import 'admin_screen.dart';
import 'signin_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onTabChange: (i) => setState(() => _currentIndex = i)),
      const ScannerScreen(),
      const MapScreen(),
    ];
    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: _AppDrawer(),
      body: Stack(
        children: [
          // Background mesh
          Positioned(
            top: -50,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.magenta.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.magentaDark.withValues(alpha: 0.3),
              ),
            ),
          ),
          // Screens
          IndexedStack(index: _currentIndex, children: screens),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.transparent,
      child: Container(
        decoration: AppTheme.glassDecoration(radius: 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.dashboard_rounded,
              label: 'Home',
              active: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            // Center scanner button
            GestureDetector(
              onTap: () => onTap(1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                height: 56,
                decoration: currentIndex == 1
                    ? AppTheme.magentaGlow(radius: 16)
                    : AppTheme.glassDecoration(radius: 16),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: currentIndex == 1 ? Colors.white : Colors.white38,
                  size: 28,
                ),
              ),
            ),
            _NavItem(
              icon: Icons.map_rounded,
              label: 'Venues',
              active: currentIndex == 2,
              onTap: () => onTap(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.magenta.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: active ? AppColors.magentaLight : Colors.white30,
                size: 20),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: active ? AppColors.magentaLight : Colors.white30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    return Drawer(
      backgroundColor: const Color(0xFF13010C),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.magenta.withValues(alpha: 0.2), Colors.transparent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8E0A57), Color(0xFFFF6EC7)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.magenta.withValues(alpha: 0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.verified_rounded, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'HALAL SCANNER',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.isGuest
                        ? 'Guest User'
                        : auth.user?.email ?? 'Guest User',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  if (auth.isGuest) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        'GUEST MODE',
                        style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Home',
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerItem(
                    icon: Icons.camera_alt_rounded,
                    title: 'Scanner',
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerItem(
                    icon: Icons.map_rounded,
                    title: 'Venues',
                    onTap: () => Navigator.pop(context),
                  ),
                  const Divider(color: Colors.white12, height: 32),
                  _DrawerItem(
                    icon: Icons.menu_book_rounded,
                    title: 'Guidelines',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const GuidelinesScreen()));
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.info_rounded,
                    title: 'About',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
                    },
                  ),
                  if (auth.isAdmin)
                    _DrawerItem(
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'Admin Panel',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
                      },
                    ),
                ],
              ),
            ),
            // Logout / Sign In
            Container(
              padding: const EdgeInsets.all(16),
              child: auth.isGuest
                  ? _DrawerItem(
                      icon: Icons.login_rounded,
                      title: 'Sign In',
                      onTap: () async {
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const SignInScreen()),
                          );
                        }
                      },
                    )
                  : _DrawerItem(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      isLogout: true,
                      onTap: () async {
                        await auth.logout();
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLogout;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isLogout ? Colors.red.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLogout ? Colors.red.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isLogout ? Colors.redAccent : AppColors.magentaLight,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isLogout ? Colors.redAccent : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
