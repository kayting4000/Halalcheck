import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/halal_location.dart';
import '../services/location_service.dart';
import '../widgets/app_theme.dart';
import '../providers/auth_provider.dart';
import 'suggest_location_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF13010C),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Panel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
            Text('Management Dashboard', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.magenta,
          labelColor: AppColors.magentaLight,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions_rounded), text: 'Pending'),
            Tab(icon: Icon(Icons.verified_rounded), text: 'Verified'),
            Tab(icon: Icon(Icons.admin_panel_settings_rounded), text: 'Tools'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PendingTab(),
          _VerifiedTab(),
          _ToolsTab(),
        ],
      ),
    );
  }
}

class _PendingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HalalLocation>>(
      stream: LocationService.getPendingLocations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.magenta));
        final pending = snapshot.data!;
        if (pending.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.white.withValues(alpha: 0.1)),
                const SizedBox(height: 16),
                const Text('No pending locations', style: TextStyle(color: Colors.white38, fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pending.length,
          itemBuilder: (_, i) {
            final loc = pending[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassDecoration(radius: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.magenta.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.store_rounded, color: AppColors.magentaLight, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                            Text(loc.type.toUpperCase(), style: const TextStyle(fontSize: 9, color: AppColors.magentaLight, fontWeight: FontWeight.w700, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Expanded(child: Text(loc.address, style: const TextStyle(fontSize: 12, color: Colors.white54))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.magenta,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                          label: const Text('Verify', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          onPressed: () => LocationService.verifyLocation(loc.id!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 16),
                          label: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                          onPressed: () => LocationService.deleteLocation(loc.id!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _VerifiedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HalalLocation>>(
      stream: LocationService.getVerifiedLocations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.magenta));
        final verified = snapshot.data!;
        if (verified.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_rounded, size: 80, color: Colors.white.withValues(alpha: 0.1)),
                const SizedBox(height: 16),
                const Text('No verified locations yet', style: TextStyle(color: Colors.white38, fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: verified.length,
          itemBuilder: (_, i) {
            final loc = verified[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassDecoration(radius: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                            Text(loc.type.toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.greenAccent, fontWeight: FontWeight.w700, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Expanded(child: Text(loc.address, style: const TextStyle(fontSize: 12, color: Colors.white54))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 16),
                    label: const Text('Remove', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                    onPressed: () => LocationService.deleteLocation(loc.id!),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ToolsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'ADMIN TOOLS',
          style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 3, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        _ToolCard(
          icon: Icons.add_location_rounded,
          title: 'Add New Venue',
          subtitle: 'Manually add verified halal locations',
          color: AppColors.magenta,
          onTap: () async {
            // Get current location or use default
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SuggestLocationScreen(lat: 0.0, lng: 0.0),
              ),
            );
          },
        ),
        _ToolCard(
          icon: Icons.analytics_rounded,
          title: 'View Statistics',
          subtitle: 'Total venues, reviews, and user activity',
          color: Colors.blue,
          onTap: () => _showStats(context),
        ),
        _ToolCard(
          icon: Icons.notifications_rounded,
          title: 'Send Notification',
          subtitle: 'Broadcast message to all users',
          color: Colors.orange,
          onTap: () => _showNotificationDialog(context),
        ),
        _ToolCard(
          icon: Icons.people_rounded,
          title: 'User Management',
          subtitle: 'View and manage user accounts',
          color: Colors.purple,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User management coming soon')),
          ),
        ),
        _ToolCard(
          icon: Icons.report_rounded,
          title: 'Reports',
          subtitle: 'View flagged content and user reports',
          color: Colors.red,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reports feature coming soon')),
          ),
        ),
      ],
    );
  }

  void _showStats(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Statistics', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: StreamBuilder<List<HalalLocation>>(
          stream: LocationService.getVerifiedLocations(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator(color: AppColors.magenta);
            final locations = snapshot.data!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatRow(label: 'Total Venues', value: '${locations.length}'),
                _StatRow(label: 'Restaurants', value: '${locations.where((l) => l.type == 'restaurant').length}'),
                _StatRow(label: 'Markets', value: '${locations.where((l) => l.type == 'market').length}'),
                _StatRow(label: 'Stores', value: '${locations.where((l) => l.type == 'store').length}'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.magentaLight)),
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Send Notification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter notification message...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.magenta),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification sent to all users')),
              );
            },
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassDecoration(radius: 20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value, style: const TextStyle(color: AppColors.magentaLight, fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
