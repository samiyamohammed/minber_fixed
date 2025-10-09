// lib/models/user_model.dart

import 'dart:convert';

// Helper function to decode a string to a map
Map<String, dynamic> userModelAsMap(String str) => json.decode(str);
// Helper function to encode a user model to a JSON string
String userModelToJson(UserModel data) => json.encode(data.toMap());

class UserModel {
  final String id;
  final String username;
  final String email;
  final bool isEmailVerified;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.isEmailVerified,
    required this.createdAt,
  });

  // ✅ FACTORY to create a UserModel from the nested 'user' object in your API response
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["id"] ?? '',
      username: json["username"] ?? 'No Name',
      email: json["email"] ?? 'No Email',
      isEmailVerified: json["isEmailVerified"] ?? false,
      createdAt: DateTime.tryParse(json["createdAt"] ?? '') ?? DateTime.now(),
    );
  }

  // Method to convert the model to a map, useful for saving to SharedPreferences
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
