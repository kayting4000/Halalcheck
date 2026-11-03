import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Report a copyright infringement (DMCA takedown).
///
/// Route the submitted form to your registered DMCA agent email (see
/// docs/DMCA_POLICY.md). You must register a DMCA agent at
/// http://copyright.gov before going live.
class DmcaScreen extends StatefulWidget {
  const DmcaScreen({super.key});

  @override
  State<DmcaScreen> createState() => _DmcaScreenState();
}

class _DmcaScreenState extends State<DmcaScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields.')));
      return;
    }
    setState(() => _loading = true);
    // TODO: send the notice to your registered DMCA agent email.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Takedown notice submitted (connect to your DMCA agent email).')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Copyright Infringement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report copyrighted content (DMCA).', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Fill out the form below to submit a DMCA takedown notice. See docs/DMCA_POLICY.md for the full policy.', style: TextStyle(color: Colors.white54, height: 1.5)),
            const SizedBox(height: 20),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Your name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Your email', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _contentCtrl, maxLines: 5, decoration: const InputDecoration(labelText: 'Describe the infringing content (URL, name, etc.)', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            SizedBox(height: 48, child: ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Takedown Notice'))),
          ],
        ),
      ),
    );
  }
}