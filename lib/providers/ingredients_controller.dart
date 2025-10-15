import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:myakieburger/domains/ingredients_model.dart';

class IngredientsController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Update or create ingredient record
  Future<void> updateIngredient(String franchiseeId, IngredientModel ingredient) async {
    try {
      // Format the current date as DD/MM/YYYY HH:mm (24-hour format)
      final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

      final ingredientRef = _firestore
          .collection('users')
          .doc(franchiseeId)
          .collection('ingredients')
          .doc(ingredient.id);

      await ingredientRef.set({
        'name': ingredient.name,
        'price': ingredient.price,
        'received': ingredient.received,
        'used': ingredient.used,
        'damaged': ingredient.damaged,
        'eat': ingredient.eat,
        'balance': ingredient.balance,
        'updated_at': formattedDate,
      }, SetOptions(merge: true)); // ✅ merge: true to update or create safely
    } catch (e) {
      print('🔥 Error updating ingredient for $franchiseeId: $e');
      rethrow;
    }
  }

  /// 🔹 Fetch all ingredients for this franchisee
  Future<List<IngredientModel>> getIngredients(String franchiseeId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(franchiseeId)
          .collection('ingredients')
          .get();

      return querySnapshot.docs.map((doc) {
        return IngredientModel.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      print('🔥 Error fetching ingredients: $e');
      rethrow;
    }
  }
}
