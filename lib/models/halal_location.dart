import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class HalalLocation {
  final String? id;
  final String name;
  final double lat;
  final double lng;
  final String type; // restaurant | market | store
  final bool isVerified;
  final String address;
  final String? description;
  final String submittedBy;
  final Timestamp? createdAt;
  final String status; // pending | verified | denied
  final String? denyReason;

  HalalLocation({
    this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.type,
    required this.isVerified,
    required this.address,
    this.description,
    required this.submittedBy,
    this.createdAt,
    this.status = 'pending',
    this.denyReason,
  });

  factory HalalLocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HalalLocation(
      id: doc.id,
      name: data['name'] ?? '',
      lat: (data['lat'] ?? 0).toDouble(),
      lng: (data['lng'] ?? 0).toDouble(),
      type: data['type'] ?? 'restaurant',
      isVerified: data['isVerified'] ?? false,
      address: data['address'] ?? '',
      description: data['description'],
      submittedBy: data['submittedBy'] ?? '',
      createdAt: data['createdAt'],
      status: data['status'] ?? (data['isVerified'] == true ? 'verified' : 'pending'),
      denyReason: data['denyReason'],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'lat': lat,
        'lng': lng,
        'type': type,
        'isVerified': isVerified,
        'address': address,
        'description': description,
        'submittedBy': submittedBy,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'status': status,
        'denyReason': denyReason,
      };
}

class Review {
  final String? id;
  final String locationId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final Timestamp? createdAt;

  Review({
    this.id,
    required this.locationId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      locationId: data['locationId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'User',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: data['createdAt'],
    );
  }
}

class AnalysisResult {
  final String status; // halal | haram | doubtful
  final String reason;
  final List<IngredientResult> ingredients;
  final String purityReport;

  AnalysisResult({
    required this.status,
    required this.reason,
    required this.ingredients,
    required this.purityReport,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      status: json['status'] ?? 'doubtful',
      reason: json['reason'] ?? '',
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((i) => IngredientResult.fromJson(i))
          .toList(),
      purityReport: json['purityReport'] ?? '',
    );
  }

  factory AnalysisResult.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return AnalysisResult.fromJson(json);
  }
}

class IngredientResult {
  final String name;
  final String status;

  IngredientResult({required this.name, required this.status});

  factory IngredientResult.fromJson(Map<String, dynamic> json) {
    return IngredientResult(
      name: json['name'] ?? '',
      status: json['status'] ?? 'doubtful',
    );
  }
}

class AppUser {
  final String email;
  final String role;

  AppUser({required this.email, required this.role});

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(email: data['email'] ?? '', role: data['role'] ?? 'user');
  }

  Map<String, dynamic> toMap() => {'email': email, 'role': role};
}
