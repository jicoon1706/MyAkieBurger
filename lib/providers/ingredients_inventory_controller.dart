import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myakieburger/domains/ingredients_inventory_model.dart';

class IngredientsInventoryController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get all global ingredients
  Future<List<IngredientInventory>> fetchIngredients() async {
    final snapshot = await _db.collection('ingredients').get();

print("Fetched ${snapshot.docs.length} ingredients from Firestore");

for (var doc in snapshot.docs) {
  print("Ingredient: ${doc.id} → ${doc.data()}");
}


    return snapshot.docs
        .map((doc) =>
            IngredientInventory.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Reduce stock after order submission
  Future<void> reduceStock(String ingredientId, int qtyTaken) async {
    final ref = _db.collection('ingredients').doc(ingredientId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      if (!snapshot.exists) {
        throw Exception("Ingredient does not exist");
      }

      final currentStock = snapshot['available'] ?? 0;

      if (currentStock < qtyTaken) {
        throw Exception("Not enough stock available");
      }

      transaction.update(ref, {'available': currentStock - qtyTaken});
    });
  }

  /// Add ingredient to Firestore (admin usage)
  Future<void> addIngredient(IngredientInventory ingredient) async {
    await _db
        .collection('ingredients')
        .doc(ingredient.id)
        .set(ingredient.toFirestore());
  }
}
