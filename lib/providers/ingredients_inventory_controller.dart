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

  /// 🌟 New: Reduce stock for multiple items in a batch/transaction
  Future<void> reduceStockBatch(
    Transaction transaction,
    List<dynamic> orderedIngredients,
  ) async {
    for (var item in orderedIngredients) {
      final ingredientName = item['ingredient_name'] as String;
      final quantity = item['quantity'] as int;
      
      // Look up the ingredient in the global 'ingredients' collection by name
      final ingredientQuery = await _db
          .collection('ingredients')
          .where('name', isEqualTo: ingredientName)
          .limit(1)
          .get();

      if (ingredientQuery.docs.isNotEmpty) {
        final docRef = ingredientQuery.docs.first.reference;
        final data = ingredientQuery.docs.first.data();
        final currentStock = data['available'] ?? 0;
        
        if (currentStock < quantity) {
          throw Exception("Factory: Not enough stock for $ingredientName. Available: $currentStock, Ordered: $quantity");
        }

        // Add update operation to the existing transaction
        transaction.update(docRef, {
          'available': currentStock - quantity,
          'updated_at': FieldValue.serverTimestamp(),
        });
        print('⬇️ Factory inventory reduced: $ingredientName by $quantity');
      } else {
        print('⚠️ Factory inventory item $ingredientName not found. Skipping reduction.');
      }
    }
  }

  Future<void> returnCancelledStock(
    Transaction transaction,
    List<dynamic> orderedIngredients,
  ) async {
    for (var item in orderedIngredients) {
      final ingredientName = item['ingredient_name'] as String;
      final quantity = item['quantity'] as int;

      // Look up the ingredient in the global 'ingredients' collection by name
      final ingredientQuery = await _db
          .collection('ingredients')
          .where('name', isEqualTo: ingredientName)
          .limit(1)
          .get();

      if (ingredientQuery.docs.isNotEmpty) {
        final docRef = ingredientQuery.docs.first.reference;
        final data = ingredientQuery.docs.first.data();
        final currentStock = data['available'] ?? 0;
        
        // Add quantity back to available stock
        final newStock = currentStock + quantity;

        // Add update operation to the existing transaction
        transaction.update(docRef, {
          'available': newStock,
          'updated_at': FieldValue.serverTimestamp(),
        });
        print('⬆️ Factory inventory restocked: $ingredientName by $quantity');
      } else {
        print('⚠️ Factory inventory item $ingredientName not found. Cannot restock.');
      }
    }
  }


  Future<void> updateIngredientDetails(
    String ingredientId,
    int available,
    int maxOrder,
    double unitPrice,
  ) async {
    final ref = _db.collection('ingredients').doc(ingredientId);

    // Prepare update data
    Map<String, dynamic> updateData = {
      'available': available,
      'max_order': maxOrder,
      'unit_price': unitPrice,
      'updated_at': FieldValue.serverTimestamp(),
    };

    // Use update to only modify the specified fields
    await ref.update(updateData);
    print("Updated ingredient $ingredientId: $updateData");
  }

  /// Add ingredient to Firestore (admin usage)
  Future<void> addIngredient(IngredientInventory ingredient) async {
    await _db
        .collection('ingredients')
        .doc(ingredient.id)
        .set(ingredient.toFirestore());
  }
}
