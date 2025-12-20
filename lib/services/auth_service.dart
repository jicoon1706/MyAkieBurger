// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';

/// Get the currently logged-in user's ID from SharedPreferences
Future<String?> getLoggedInUserId() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('franchiseeId');
    return userId;
  } catch (e) {
    print('❌ Error getting logged-in user ID: $e');
    return null;
  }
}

/// Save the logged-in user's ID to SharedPreferences
Future<void> saveLoggedInUserId(String userId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('franchiseeId', userId);
    print('✅ User ID saved: $userId');
  } catch (e) {
    print('❌ Error saving user ID: $e');
  }
}

/// 🆕 Save the logged-in user's role to SharedPreferences
Future<void> saveUserRole(String role) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', role);
    print('✅ User role saved: $role');
  } catch (e) {
    print('❌ Error saving user role: $e');
  }
}

/// 🆕 Get the logged-in user's role from SharedPreferences
Future<String?> getUserRole() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole');
    return role;
  } catch (e) {
    print('❌ Error getting user role: $e');
    return null;
  }
}

/// 🆕 Save complete user session (ID + Role)
Future<void> saveUserSession(String userId, String role) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('franchiseeId', userId);
    await prefs.setString('userRole', role);
    print('✅ User session saved: ID=$userId, Role=$role');
  } catch (e) {
    print('❌ Error saving user session: $e');
  }
}

/// Clear the logged-in user's ID and role (for logout)
Future<void> clearLoggedInUserId() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('franchiseeId');
    await prefs.remove('userRole'); // 🆕 Also remove role
    print('✅ User ID and role cleared');
  } catch (e) {
    print('❌ Error clearing user ID: $e');
  }
}