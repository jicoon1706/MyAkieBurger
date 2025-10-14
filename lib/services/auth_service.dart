// lib/services/auth_service.dart (example)
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveLoggedInUser(String franchiseeId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('franchiseeId', franchiseeId);
}

Future<String?> getLoggedInUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('franchiseeId');
}
