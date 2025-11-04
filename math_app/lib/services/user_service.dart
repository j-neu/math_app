import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class UserService {
  static const String _usersKey = 'users';

  /// Get all saved user profiles
  Future<List<UserProfile>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersJson = prefs.getString(_usersKey);

    print('UserService.getAllUsers() - Raw JSON from SharedPreferences: $usersJson');

    if (usersJson == null || usersJson.isEmpty) {
      print('UserService.getAllUsers() - No users found in storage');
      return [];
    }

    final List<dynamic> usersList = jsonDecode(usersJson);
    final users = usersList
        .map((json) => UserProfile.fromJson(json as Map<String, dynamic>))
        .toList();

    print('UserService.getAllUsers() - Loaded ${users.length} users');
    for (var user in users) {
      print('  - ${user.name} (id: ${user.id}, diagnosticProgress: ${user.diagnosticProgress}, skillTags: ${user.skillTags.length})');
    }

    return users;
  }

  /// Save a new user profile
  Future<void> saveUser(UserProfile user) async {
    print('UserService.saveUser() - Saving user: ${user.name} (id: ${user.id}, diagnosticProgress: ${user.diagnosticProgress})');

    final users = await getAllUsers();

    // Check if user with this ID already exists
    final existingIndex = users.indexWhere((u) => u.id == user.id);

    if (existingIndex != -1) {
      // Update existing user
      print('UserService.saveUser() - Updating existing user at index $existingIndex');
      users[existingIndex] = user;
    } else {
      // Add new user
      print('UserService.saveUser() - Adding new user');
      users.add(user);
    }

    await _saveAllUsers(users);
    print('UserService.saveUser() - User saved successfully');
  }

  /// Update an existing user profile
  Future<void> updateUser(UserProfile user) async {
    final users = await getAllUsers();
    final index = users.indexWhere((u) => u.id == user.id);

    if (index != -1) {
      users[index] = user;
      await _saveAllUsers(users);
    }
  }

  /// Delete a user profile
  Future<void> deleteUser(String userId) async {
    final users = await getAllUsers();
    users.removeWhere((u) => u.id == userId);
    await _saveAllUsers(users);
  }

  /// Get a user by ID
  Future<UserProfile?> getUserById(String id) async {
    final users = await getAllUsers();
    try {
      return users.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear all users (for debugging/reset)
  Future<void> clearAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usersKey);
  }

  /// Save all users to SharedPreferences
  Future<void> _saveAllUsers(List<UserProfile> users) async {
    print('UserService._saveAllUsers() - Saving ${users.length} users to SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    final usersJson = jsonEncode(users.map((u) => u.toJson()).toList());
    print('UserService._saveAllUsers() - JSON to save: $usersJson');
    final success = await prefs.setString(_usersKey, usersJson);
    print('UserService._saveAllUsers() - Save success: $success');

    // Verify it was saved
    final verification = prefs.getString(_usersKey);
    print('UserService._saveAllUsers() - Verification read: ${verification?.substring(0, 100)}...');
  }

  /// Generate a unique ID for a new user
  String generateUserId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
