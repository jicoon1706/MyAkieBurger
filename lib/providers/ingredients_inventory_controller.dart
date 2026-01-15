import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myakieburger/domains/ingredients_inventory_model.dart';
import 'package:intl/intl.dart';

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
        .map((doc) => IngredientInventory.fromFirestore(doc.data(), doc.id))
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

  /// Reduce stock in batch (for approving orders)
  Future<void> reduceStockBatch(List<dynamic> ingredients) async {
    final batch = _db.batch(); // ✅ Changed from _firestore to _db
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    for (var item in ingredients) {
      final ingredientName = item['ingredient_name'] as String;
      final quantity = item['quantity'] as int;

      // ✅ Changed from _firestore to _db
      final docRef = _db.collection('factory_inventory').doc(ingredientName);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        final currentAvailable = data['available'] ?? 0;

        final newAvailable = currentAvailable - quantity;
        final safeAvailable = newAvailable < 0 ? 0 : newAvailable;

        batch.update(docRef, {
          'available': safeAvailable,
          'updated_at': formattedDate,
        });

        print('✅ Factory: $ingredientName reduced by $quantity');
      }
    }

    await batch.commit();
  }

  /// Return cancelled stock to the Global Inventory
  Future<void> returnCancelledStock(List<dynamic> ingredients) async {
    final batch = _db.batch();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    for (var item in ingredients) {
      // ✅ FIX: Use 'ingredient_id' to match the document ID used in reduceStock
      // Fallback to name if ID is missing (though ID should exist from the order)
      final ingredientId = item['ingredient_id'] as String?;
      final ingredientName = item['ingredient_name'] as String;
      final quantity = item['quantity'] as int;

      if (ingredientId == null) {
        print(
          "⚠️ Warning: Missing ingredient ID for $ingredientName during restock",
        );
        continue;
      }

      // ✅ FIX: Target the 'ingredients' collection (where stock was originally taken from)
      // NOT 'factory_inventory'
      final docRef = _db.collection('ingredients').doc(ingredientId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        final currentAvailable = data['available'] ?? 0;

        final newAvailable = currentAvailable + quantity;

        batch.update(docRef, {
          'available': newAvailable,
          'updated_at': formattedDate, // Optional: if you store string dates
          // 'updated_at': FieldValue.serverTimestamp(), // Better for Firestore
        });

        print(
          '✅ Global Inventory: $ingredientName ($ingredientId) restored by $quantity. New Total: $newAvailable',
        );
      } else {
        print(
          "❌ Error: Ingredient document $ingredientId not found in global inventory.",
        );
      }
    }

    await batch.commit();
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
