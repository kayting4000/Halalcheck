import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/halal_location.dart';

class LocationService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'locations';

  static Stream<List<HalalLocation>> getVerifiedLocations() {
    return _db
        .collection(_col)
        .where('isVerified', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map(HalalLocation.fromFirestore).toList());
  }

  static Stream<List<HalalLocation>> getPendingLocations() {
    return _db
        .collection(_col)
        .where('isVerified', isEqualTo: false)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.map(HalalLocation.fromFirestore).toList());
  }

  static Stream<List<HalalLocation>> getDeniedLocations() {
    return _db
        .collection(_col)
        .where('status', isEqualTo: 'denied')
        .snapshots()
        .map((s) => s.docs.map(HalalLocation.fromFirestore).toList());
  }

  static Future<void> submitLocation(HalalLocation loc) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Must be signed in');
    await _db.collection(_col).add({
      ...loc.toMap(),
      'isVerified': false,
      'status': 'pending',
      'submittedBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> verifyLocation(String id) async {
    await _db.collection(_col).doc(id).update({
      'isVerified': true,
      'status': 'verified',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> denyLocation(String id, String reason) async {
    await _db.collection(_col).doc(id).update({
      'isVerified': false,
      'status': 'denied',
      'denyReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteLocation(String id) async {
    await _db.collection(_col).doc(id).delete();
  }

  static Stream<List<Review>> getReviews(String locationId) {
    return _db
        .collection(_col)
        .doc(locationId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Review.fromFirestore).toList());
  }

  static Future<void> addReview(
      String locationId, double rating, String comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Must be signed in to review');
    await _db
        .collection(_col)
        .doc(locationId)
        .collection('reviews')
        .add({
      'locationId': locationId,
      'userId': user.uid,
      'userName':
          user.displayName ?? user.email?.split('@')[0] ?? 'User',
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
