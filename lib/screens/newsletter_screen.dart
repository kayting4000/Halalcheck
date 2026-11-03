import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Newsletter sign-up screen.
///
/// NOTE: This in-app screen only records your subscription. To comply with
/// CAN-SPAM, you must wire this to a backend email service that:
///   - sends every newsletter email from a clear sender address,
///   - includes your physical postal address,
///   - includes a working unsubscribe link,
///   - honors opt-outs promptly (within 10 business days).
class NewsletterScreen extends StatefulWidget {
  const NewsletterScreen({super.key});

  @override
  State<NewsletterScreen> createState() => _NewsletterScreenState();
}

class _NewsletterScreenState extends State<NewsletterScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your email address.')));
      return;
    }
    // TODO: replace with a backend call (e.g., Firebase Functions + email service).
    setState(() => _loading = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscribed! (Connect a newsletter backend to activate.)')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Newsletter')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Subscribe to our newsletter', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('We will email you updates about new features, halal guides, and alerts. We will never sell your email.', style: TextStyle(color: Colors.white54, height: 1.5)),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email address', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _subscribe,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Subscribe'),
              ),
            ),
            const SizedBox(height: 12),
            const Text('By subscribing you agree to receive marketing emails. See our Privacy Policy.', style: TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}