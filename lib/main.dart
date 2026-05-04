import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/signin_screen.dart';
import 'screens/main_screen.dart';
import 'screens/admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const HalalScannerApp());
}

class HalalScannerApp extends StatelessWidget {
  const HalalScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppAuthProvider(),
      child: MaterialApp(
        title: 'Halal Scanner',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF8E0A57),
            surface: Color(0xFF0A0A0A),
          ),
          scaffoldBackgroundColor: const Color(0xFF0A0A0A),
          fontFamily: 'Philosopher',
          textTheme: const TextTheme(
            bodyLarge: TextStyle(fontFamily: 'CenturyGothic'),
            bodyMedium: TextStyle(fontFamily: 'CenturyGothic'),
            bodySmall: TextStyle(fontFamily: 'CenturyGothic'),
          ),
        ),
        home: Consumer<AppAuthProvider>(
          builder: (context, auth, _) {
            if (auth.loading) {
              return const Scaffold(
                backgroundColor: Color(0xFF13010C),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF8E0A57)),
                ),
              );
            }
            if (auth.user == null) {
              return const SignInScreen();
            }
            if (auth.isAdmin) {
              return const AdminScreen();
            }
            return const MainScreen();
          },
        ),
      ),
    );
  }
}
