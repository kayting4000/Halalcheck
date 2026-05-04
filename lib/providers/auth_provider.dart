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

  AppAuthProvider() {
    _auth.authStateChanges().listen((u) async {
      user = u;
      if (u != null) {
        try {
          profile = await _syncUser(u);
        } catch (e) {
          // If Firestore fails, create profile from user data
          profile = AppUser(
            email: u.email ?? '',
            role: u.email == _adminEmail ? 'admin' : 'user',
          );
        }
      } else {
        profile = null;
      }
      loading = false;
      notifyListeners();
    });
  }

  bool get isAdmin => profile?.role == 'admin' || user?.email == _adminEmail;

  Future<void> login() async {
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
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> continueAsGuest() async {
    await _auth.signInAnonymously();
  }

  bool get isGuest => user != null && user!.isAnonymous;

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<AppUser> _syncUser(User u) async {
    try {
      final ref = _db.collection('users').doc(u.uid);
      final snap = await ref.get();
      if (!snap.exists) {
        final newUser = AppUser(
          email: u.email ?? '',
          role: u.email == _adminEmail ? 'admin' : 'user',
        );
        await ref.set(newUser.toMap());
        return newUser;
      }
      final existing = AppUser.fromMap(snap.data()!);
      if (u.email == _adminEmail && existing.role != 'admin') {
        final fixed = AppUser(email: existing.email, role: 'admin');
        await ref.set(fixed.toMap(), SetOptions(merge: true));
        return fixed;
      }
      return existing;
    } catch (e) {
      // Return basic user if Firestore fails
      return AppUser(
        email: u.email ?? '',
        role: u.email == _adminEmail ? 'admin' : 'user',
      );
    }
  }
}
