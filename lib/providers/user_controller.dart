// lib/controllers/user_controller.dart
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
}
