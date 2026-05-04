import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/halal_location.dart';
import '../services/location_service.dart';
import '../widgets/app_theme.dart';

class SuggestLocationScreen extends StatefulWidget {
  final double lat, lng;
  const SuggestLocationScreen({super.key, required this.lat, required this.lng});

  @override
  State<SuggestLocationScreen> createState() => _SuggestLocationScreenState();
}

class _SuggestLocationScreenState extends State<SuggestLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'restaurant';
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('Please sign in to suggest a venue', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await LocationService.submitLocation(
        HalalLocation(
          name: _nameCtrl.text.trim(),
          lat: widget.lat,
          lng: widget.lng,
          type: _type,
          isVerified: false,
          address: _addressCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          submittedBy: user.uid,
          status: 'pending',
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timed out. Check your internet or Firestore rules.'),
      );
      if (mounted) {
        _showSnack('Venue submitted for review!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        // Show full error so we can diagnose (permission-denied = Firestore rules issue)
        final msg = e.toString().contains('permission-denied')
            ? 'Permission denied. Check Firestore rules — allow authenticated users to create locations.'
            : e.toString().contains('timed out')
                ? 'Timed out. Check internet connection or Firestore rules.'
                : 'Error: ${e.toString()}';
        _showSnack(msg, isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade800 : AppColors.magenta,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Suggest Venue',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.magenta.withValues(alpha: 0.15),
              ),
            ),
          ),
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 110, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coordinates card
                  _GlassCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.magenta.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.pin_drop_rounded, color: AppColors.magentaLight, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SELECTED LOCATION', style: TextStyle(fontSize: 9, color: Colors.white38, letterSpacing: 2, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.lat.toStringAsFixed(5)}, ${widget.lng.toStringAsFixed(5)}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const _Label('VENUE NAME'),
                  const SizedBox(height: 8),
                  _GlassField(
                    controller: _nameCtrl,
                    hint: 'e.g. Al-Barakah Restaurant',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Venue name is required' : null,
                  ),
                  const SizedBox(height: 16),

                  const _Label('ADDRESS'),
                  const SizedBox(height: 8),
                  _GlassField(
                    controller: _addressCtrl,
                    hint: 'Full address of the venue',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                  ),
                  const SizedBox(height: 16),

                  const _Label('DESCRIPTION (OPTIONAL)'),
                  const SizedBox(height: 8),
                  _GlassField(
                    controller: _descCtrl,
                    hint: 'Any additional info about this venue...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  const _Label('VENUE TYPE'),
                  const SizedBox(height: 8),
                  _GlassCard(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _type,
                        dropdownColor: const Color(0xFF1A0A14),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.magentaLight),
                        items: const [
                          DropdownMenuItem(value: 'restaurant', child: Row(children: [Icon(Icons.restaurant_rounded, color: AppColors.magentaLight, size: 18), SizedBox(width: 10), Text('Restaurant')])),
                          DropdownMenuItem(value: 'market', child: Row(children: [Icon(Icons.shopping_basket_rounded, color: AppColors.magentaLight, size: 18), SizedBox(width: 10), Text('Market')])),
                          DropdownMenuItem(value: 'store', child: Row(children: [Icon(Icons.store_rounded, color: AppColors.magentaLight, size: 18), SizedBox(width: 10), Text('Store')])),
                        ],
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: _loading
                        ? Center(
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.magenta.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(child: CircularProgressIndicator(color: AppColors.magentaLight, strokeWidth: 2)),
                            ),
                          )
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.magenta,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 8,
                              shadowColor: AppColors.magenta.withValues(alpha: 0.5),
                            ),
                            icon: const Icon(Icons.send_rounded, color: Colors.white),
                            label: const Text(
                              'SUBMIT FOR REVIEW',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 14),
                            ),
                            onPressed: _submit,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 2, fontWeight: FontWeight.w700),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _GlassField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.magentaLight, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            errorStyle: const TextStyle(color: Colors.redAccent),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }
}
