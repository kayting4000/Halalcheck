import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_container.dart';
import 'signup_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AppAuthProvider>();
      await auth.loginWithEmail(email, password);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Invalid email or password');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AppAuthProvider>().continueAsGuest();
    } catch (e) {
      if (mounted) setState(() => _error = 'Guest sign-in failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AppAuthProvider>();
      await auth.login();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Google sign-in failed');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13010C),
      body: Stack(
        children: [
          // Background gradient circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8E0A57).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8E0A57).withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8E0A57), Color(0xFFFF6EC7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8E0A57).withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.easeOutBack)
                        .shimmer(delay: 600.ms, duration: 1500.ms),
                    const SizedBox(height: 40),
                    // Title
                    const Text(
                      'HALAL SCANNER',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                        fontFamily: 'Philosopher',
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 12),
                    Text(
                      'Verify Halal Products & Find Venues',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                        fontFamily: 'CenturyGothic',
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 60),
                    // Sign In Card
                    GlassContainer(
                      padding: const EdgeInsets.all(32),
                      borderRadius: 24,
                      child: Column(
                        children: [
                          Text(
                            'SIGN IN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.8),
                              letterSpacing: 3,
                              fontFamily: 'Philosopher',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Welcome back! Please sign in to continue',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.5),
                              fontFamily: 'CenturyGothic',
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Email Field
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white, fontFamily: 'CenturyGothic'),
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF8E0A57), width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Password Field
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white, fontFamily: 'CenturyGothic'),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF8E0A57), width: 2),
                              ),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 24),
                          // Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8E0A57),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                shadowColor: const Color(0xFF8E0A57).withValues(alpha: 0.6),
                                elevation: 12,
                              ),
                              onPressed: _loading ? null : _signIn,
                              child: _loading
                                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  : const Text(
                                      'SIGN IN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                        fontSize: 14,
                                        fontFamily: 'Philosopher',
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'OR',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Google Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _loading ? null : _signInWithGoogle,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Image.network(
                                      'https://www.google.com/favicon.ico',
                                      width: 20,
                                      height: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'SIGN IN WITH GOOGLE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                      fontSize: 14,
                                      fontFamily: 'Philosopher',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Continue as Guest
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                                ),
                              ),
                              onPressed: _loading ? null : _continueAsGuest,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_outline_rounded, color: Colors.white.withValues(alpha: 0.5), size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    'CONTINUE AS GUEST',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                      fontSize: 13,
                                      fontFamily: 'Philosopher',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Sign Up Link
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SignUpScreen()),
                              );
                            },
                            child: Text(
                              'Don\'t have an account? Sign Up',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontFamily: 'CenturyGothic',
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 800.ms)
                        .slideY(begin: 0.2, end: 0)
                        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
                    const SizedBox(height: 40),
                    // Footer
                    Text(
                      'By signing in, you agree to our Terms & Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.3),
                        fontFamily: 'CenturyGothic',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
