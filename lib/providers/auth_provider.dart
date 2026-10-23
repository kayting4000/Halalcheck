import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/halal_location.dart';

const String _adminEmail = 'habibunnajalkaytin@gmail.com';

class AppAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? user;
  AppUser? profile;
  bool loading = true;
  bool _isLocalGuest = false;

  AppAuthProvider() {
    _auth.authStateChanges().listen((u) async {
      user = u;
      if (u != null) {
        _isLocalGuest = false;
        try {
          profile = await _syncUser(u);
        } catch (e) {
          profile = AppUser(
            email: u.email ?? '',
            role: u.email == _adminEmail ? 'admin' : 'user',
          );
        }
      } else if (!_isLocalGuest) {
        profile = null;
      }
      loading = false;
      notifyListeners();
    });
  }

  bool get isAdmin => profile?.role == 'admin' || user?.email == _adminEmail;

  bool get isGuest => _isLocalGuest || (user != null && user!.isAnonymous);

  Future<void> login() async {
    _isLocalGuest = false;
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _auth.signInWithCredential(credential);
  }

  Future<void> loginWithEmail(String email, String password) async {
    _isLocalGuest = false;
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail(String email, String password) async {
    _isLocalGuest = false;
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> continueAsGuest() async {
    try {
      await _auth.signInAnonymously();
      _isLocalGuest = true;
    } catch (_) {
      // If Firebase anonymous auth is disabled on the backend,
      // fallback to offline local guest session so user is never locked out
      _isLocalGuest = true;
      user = null;
      profile = AppUser(
        email: 'Guest User',
        role: 'user',
      );
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLocalGuest = false;
    user = null;
    profile = null;
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _auth.signOut();
    } catch (_) {}
    notifyListeners();
  }

  Future<AppUser> _syncUser(User u) async {
    try {
      final ref = _db.collection('users').doc(u.uid);
      final snap = await ref.get().timeout(const Duration(seconds: 4));
      if (!snap.exists) {
        final newUser = AppUser(
          email: u.email ?? '',
          role: u.email == _adminEmail ? 'admin' : 'user',
        );
        try {
          await ref.set(newUser.toMap()).timeout(const Duration(seconds: 3));
        } catch (_) {}
        return newUser;
      }
      final existing = AppUser.fromMap(snap.data()!);
      if (u.email == _adminEmail && existing.role != 'admin') {
        final fixed = AppUser(email: existing.email, role: 'admin');
        try {
          await ref.set(fixed.toMap(), SetOptions(merge: true)).timeout(const Duration(seconds: 3));
        } catch (_) {}
        return fixed;
      }
      return existing;
    } catch (e) {
      return AppUser(
        email: u.email ?? '',
        role: u.email == _adminEmail ? 'admin' : 'user',
      );
    }
  }
}
