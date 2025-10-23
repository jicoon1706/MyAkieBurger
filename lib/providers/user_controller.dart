import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myakieburger/domains/user_model.dart';

class UserController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      print("❌ Error getting user: $e");
      return null;
    }
  }

  Future<void> registerFranchisee(UserModel user) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc('franchisee_${DateTime.now().millisecondsSinceEpoch}');
      await docRef.set(user.toMap());
      print("✅ Franchisee registered: ${user.name}");
    } catch (e) {
      print("❌ Error registering franchisee: $e");
      rethrow;
    }
  }

  // ✅ Update user profile info (username, email, contact)
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update({
        'username': user.username,
        'email': user.email,
        'contact': user.contact,
        'updated_at': DateTime.now().toIso8601String(),
      });
      print("✅ User profile updated: ${user.username}");
    } catch (e) {
      print("❌ Error updating user profile: $e");
      rethrow;
    }
  }

  // ✅ NEW: Update store information (stall name & region)
  Future<void> updateStoreInfo(String userId, {
    required String stallName,
    required String region,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'stall_name': stallName,
        'region': region,
        'updated_at': DateTime.now().toIso8601String(),
      });
      print("✅ Store info updated for user ID: $userId");
    } catch (e) {
      print("❌ Error updating store info: $e");
      rethrow;
    }
  }
}
