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

/// Clear the logged-in user's ID (for logout)
Future<void> clearLoggedInUserId() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('franchiseeId');
    print('✅ User ID cleared');
  } catch (e) {
    print('❌ Error clearing user ID: $e');
  }
}


