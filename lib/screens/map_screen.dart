import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../models/halal_location.dart';
import '../services/location_service.dart';
import '../widgets/glass_container.dart';
import '../providers/auth_provider.dart';
import 'suggest_location_screen.dart';
import 'signin_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  HalalLocation? _selected;
  String _search = '';
  String? _selectedType;
  List<HalalLocation> _locations = [];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final status = await Permission.location.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied. Please enable it in settings.')),
          );
          setState(() => _userLocation = const LatLng(5.0482, 119.7428));
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
        _mapController.move(_userLocation!, 15);
      }
    } catch (_) {
      if (mounted) setState(() => _userLocation = const LatLng(5.0482, 119.7428));
    }
  }

  void _showGuestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8E0A57).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded, color: Color(0xFFFF6EC7), size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sign In Required',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Philosopher'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You need an account to suggest a venue. Sign in or create one — it\'s free!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontFamily: 'CenturyGothic'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8E0A57),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 8,
                        shadowColor: const Color(0xFF8E0A57).withValues(alpha: 0.5),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const SignInScreen()),
                        );
                      },
                      child: const Text('SIGN IN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontFamily: 'Philosopher')),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Maybe Later', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontFamily: 'CenturyGothic')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openNavigation(HalalLocation location) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${location.lat},${location.lng}&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<HalalLocation> get _filtered => _locations.where((loc) {
        final matchSearch = loc.name.toLowerCase().contains(_search.toLowerCase()) ||
            loc.address.toLowerCase().contains(_search.toLowerCase());
        final matchType = _selectedType == null || loc.type == _selectedType;
        return matchSearch && matchType;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13010C),
      body: StreamBuilder<List<HalalLocation>>(
        stream: LocationService.getVerifiedLocations(),
        builder: (context, snapshot) {
          if (snapshot.hasData) _locations = snapshot.data!;
          return Stack(
            children: [
              // Dark map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(5.0482, 119.7428),
                  initialZoom: 13,
                  onLongPress: (_, point) {
                    final auth = context.read<AppAuthProvider>();
                    if (auth.isGuest) {
                      _showGuestDialog(context);
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SuggestLocationScreen(lat: point.latitude, lng: point.longitude),
                      ),
                    );
                  },
                  onTap: (_, __) => setState(() => _selected = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.halalscanner.halalscanner',
                  ),
                  MarkerLayer(markers: [
                    if (_userLocation != null)
                      Marker(
                        point: _userLocation!,
                        width: 20,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 8)],
                          ),
                        ),
                      ),
                    ..._filtered.map((loc) {
                      IconData markerIcon;
                      switch (loc.type.toLowerCase()) {
                        case 'restaurant':
                          markerIcon = Icons.restaurant_rounded;
                          break;
                        case 'market':
                          markerIcon = Icons.shopping_basket_rounded;
                          break;
                        case 'store':
                          markerIcon = Icons.store_rounded;
                          break;
                        default:
                          markerIcon = Icons.place_rounded;
                      }
                      return Marker(
                        point: LatLng(loc.lat, loc.lng),
                        width: 36,
                        height: 36,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selected = loc);
                            _mapController.move(LatLng(loc.lat, loc.lng), 16);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: loc.isVerified ? const Color(0xFF8E0A57) : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: (loc.isVerified ? const Color(0xFF8E0A57) : Colors.grey).withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: Icon(markerIcon, color: Colors.white, size: 18),
                          ),
                        ),
                      );
                    }),
                  ]),
                ],
              ),

              // Floating Search Bar
              Positioned(
                top: 50,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    GlassContainer(
                      height: 56,
                      borderRadius: 20,
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const Icon(Icons.search_rounded, color: Colors.white60, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              onChanged: (v) => setState(() => _search = v),
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'CenturyGothic'),
                              decoration: const InputDecoration(
                                hintText: 'Search halal venues...',
                                hintStyle: TextStyle(color: Colors.white38, fontFamily: 'CenturyGothic'),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          if (_userLocation != null)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF8E0A57),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
                                onPressed: () => _mapController.move(_userLocation!, 15),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _Chip(label: 'ALL', icon: Icons.map_rounded, active: _selectedType == null, onTap: () => setState(() => _selectedType = null)),
                          _Chip(label: 'RESTAURANTS', icon: Icons.restaurant_rounded, active: _selectedType == 'restaurant', onTap: () => setState(() => _selectedType = _selectedType == 'restaurant' ? null : 'restaurant')),
                          _Chip(label: 'MARKETS', icon: Icons.shopping_basket_rounded, active: _selectedType == 'market', onTap: () => setState(() => _selectedType = _selectedType == 'market' ? null : 'market')),
                          _Chip(label: 'STORES', icon: Icons.store_rounded, active: _selectedType == 'store', onTap: () => setState(() => _selectedType = _selectedType == 'store' ? null : 'store')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Hint
              if (_selected == null)
                const Positioned(
                  top: 180,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GlassContainer(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      borderRadius: 16,
                      opacity: 0.08,
                      child: Text(
                        'HOLD ON MAP TO SUGGEST VENUE',
                        style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 2.5, fontWeight: FontWeight.w700, fontFamily: 'Philosopher'),
                      ),
                    ),
                  ),
                ),

              // Glassmorphic Bottom Sheet
              if (_selected != null)
                DraggableScrollableSheet(
                  initialChildSize: 0.35,
                  minChildSize: 0.35,
                  maxChildSize: 0.85,
                  builder: (context, scrollController) => GlassmorphicDetailsSheet(
                    location: _selected!,
                    userLocation: _userLocation,
                    scrollController: scrollController,
                    onClose: () => setState(() => _selected = null),
                    onNavigate: () => _openNavigation(_selected!),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF8E0A57) : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? const Color(0xFF8E0A57) : Colors.white.withValues(alpha: 0.15)),
          boxShadow: active ? [
            BoxShadow(
              color: const Color(0xFF8E0A57).withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 0,
            )
          ] : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: active ? Colors.white : Colors.white.withValues(alpha: 0.4)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontFamily: 'Philosopher',
                    color: active ? Colors.white : Colors.white.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }
}

class GlassmorphicDetailsSheet extends StatelessWidget {
  final HalalLocation location;
  final LatLng? userLocation;
  final ScrollController scrollController;
  final VoidCallback onClose;
  final VoidCallback onNavigate;

  const GlassmorphicDetailsSheet({
    super.key,
    required this.location,
    required this.userLocation,
    required this.scrollController,
    required this.onClose,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8E0A57).withValues(alpha: 0.2),
                blurRadius: 40,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(28),
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'Philosopher',
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (location.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8E0A57).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF8E0A57)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 14, color: Color(0xFFFF6EC7)),
                                SizedBox(width: 6),
                                Text(
                                  'VERIFIED HALAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFFF6EC7),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                    fontFamily: 'Philosopher',
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFFFF6EC7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location.address,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                        fontFamily: 'CenturyGothic',
                      ),
                    ),
                  ),
                ],
              ),
              if (location.description != null) ...[
                const SizedBox(height: 16),
                Text(
                  '"${location.description}"',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'CenturyGothic',
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E0A57),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    shadowColor: const Color(0xFF8E0A57).withValues(alpha: 0.6),
                    elevation: 12,
                  ),
                  icon: const Icon(Icons.navigation_rounded, color: Colors.white, size: 22),
                  label: const Text(
                    'GET DIRECTIONS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 14,
                      fontFamily: 'Philosopher',
                    ),
                  ),
                  onPressed: onNavigate,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'REVIEWS & RATINGS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 2,
                  fontFamily: 'Philosopher',
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<Review>>(
                stream: LocationService.getReviews(location.id ?? ''),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Center(
                        child: Text(
                          'No reviews yet',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontFamily: 'CenturyGothic',
                          ),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: snapshot.data!.take(3).map((review) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  review.userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    fontFamily: 'CenturyGothic',
                                  ),
                                ),
                              ),
                              RatingBarIndicator(
                                rating: review.rating,
                                itemBuilder: (context, _) => const Icon(Icons.star, color: Color(0xFF8E0A57)),
                                itemCount: 5,
                                itemSize: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            review.comment,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                              fontFamily: 'CenturyGothic',
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
