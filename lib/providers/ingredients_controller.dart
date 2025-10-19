// lib/providers/ingredients_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:myakieburger/domains/ingredients_model.dart';

class IngredientsController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

   /// 🔹 Recipe mapping: menu items to their ingredient requirements
  static const Map<String, Map<String, int>> recipeMap = {
    // ===== CHICKEN CATEGORY =====
    'Chicken_Biasa': {
      'Roti (pieces)': 1,
      'Ayam (80g)': 1,
    },
    'Chicken_Special': {
      'Roti (pieces)': 1,
      'Ayam (80g)': 1,
      'Telur': 1,
    },
    'Chicken_Double': {
      'Roti (pieces)': 1,
      'Ayam (80g)': 2,
    },
    'Chicken_D. Special': {
      'Roti (pieces)': 1,
      'Ayam (80g)': 2,
      'Telur': 1,
    },
    'Chicken_Oblong': {
      'Roti Oblong': 1,
      'Ayam Oblong': 1,
    },

    // ===== MEAT CATEGORY =====
    'Meat_Biasa': {
      'Roti (pieces)': 1,
      'Daging (80g)': 1,
    },
    'Meat_Special': {
      'Roti (pieces)': 1,
      'Daging (80g)': 1,
      'Telur': 1,
    },
    'Meat_Double': {
      'Roti (pieces)': 1,
      'Daging (80g)': 2,
    },
    'Meat_D. Special': {
      'Roti (pieces)': 1,
      'Daging (80g)': 2,
      'Telur': 1,
    },
    'Meat_Oblong': {
      'Roti Oblong': 1,
      'Daging Oblong': 1,
    },

    // ===== OTHERS CATEGORY =====
    'Others_Smokey': {
      'Roti (pieces)': 1,
      'Daging Smokey (100g)': 1,
    },
    'Others_Kambing': {
      'Roti (pieces)': 1,
      'Daging Kambing': 1,
    },
    'Others_Oblong Kambing': {
      'Roti Oblong': 1,
      'Kambing Oblong': 1,
    },
    'Others_Hotdog': {
      'Roti Hotdog': 1,
      'Sosej': 1,
    },
    'Others_Benjo': {
      'Roti (pieces)': 1,
      'Telur': 1,
    },
  };

  /// 🔹 Add-on ingredient mapping
  static const Map<String, String> addOnIngredientMap = {
    'Daging': 'Daging (80g)',
    'Ayam': 'Ayam (80g)',
    'Daging Smokey': 'Daging Smokey (100g)',
    'Daging Exotic': 'Daging Exotic',
    'Daging Kambing': 'Daging Kambing (70g)',
    'Daging Oblong': 'Daging Oblong',        // Fixed: was mapping to Kambing Oblong
    'Ayam Oblong': 'Ayam Oblong',            // Added: was missing
    'Kambing Oblong': 'Kambing Oblong',
    'Sosej': 'Sosej',
    'Cheese': 'Cheese',
    'Telur': 'Telur',
  };

  /// 🔹 Update or create ingredient record
  Future<void> updateIngredient(
      String franchiseeId, IngredientModel ingredient) async {
    try {
      final formattedDate =
          DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

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
      }, SetOptions(merge: true));
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

  /// 🔹 Deduct ingredients based on meal order
  Future<void> deductIngredientsForOrder(
    String franchiseeId,
    List<Map<String, dynamic>> meals,
  ) async {
    try {
      final formattedDate =
          DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

      // Aggregate all ingredient requirements
      Map<String, int> totalIngredientsNeeded = {};

      for (var meal in meals) {
        final category = meal['category'] as String;
        final menuName = meal['menu_name'] as String;
        final quantity = meal['quantity'] as int;
        final addOns = meal['add_ons'] as List<dynamic>? ?? [];

        // Get base recipe
        final recipeKey = '${category}_$menuName';
        final recipe = recipeMap[recipeKey];

        if (recipe != null) {
          // Add base ingredients
          recipe.forEach((ingredientName, amountPerItem) {
            totalIngredientsNeeded[ingredientName] =
                (totalIngredientsNeeded[ingredientName] ?? 0) +
                    (amountPerItem * quantity);
          });
        } else {
          print('⚠️ No recipe found for $recipeKey');
        }

        // Add add-on ingredients
        for (var addOn in addOns) {
          final addOnName = addOn['name'] as String;
          final addOnQuantity = addOn['quantity'] as int? ?? 1;

          final ingredientName = addOnIngredientMap[addOnName];
          if (ingredientName != null) {
            totalIngredientsNeeded[ingredientName] =
                (totalIngredientsNeeded[ingredientName] ?? 0) +
                    (addOnQuantity * quantity);
          }
        }
      }

      // Now deduct from Firestore
      final batch = _firestore.batch();

      for (var entry in totalIngredientsNeeded.entries) {
        final ingredientName = entry.key;
        final amountToDeduct = entry.value;

        final ingredientQuery = await _firestore
            .collection('users')
            .doc(franchiseeId)
            .collection('ingredients')
            .where('name', isEqualTo: ingredientName)
            .limit(1)
            .get();

        if (ingredientQuery.docs.isNotEmpty) {
          final doc = ingredientQuery.docs.first;
          final data = doc.data();

          final currentUsed = data['used'] ?? 0;
          final currentBalance = data['balance'] ?? 0;

          final newUsed = currentUsed + amountToDeduct;
          final newBalance = currentBalance - amountToDeduct;

          batch.update(doc.reference, {
            'used': newUsed,
            'balance': newBalance,
            'updated_at': formattedDate,
          });

          print(
              '✅ Updated $ingredientName: used +$amountToDeduct, balance -$amountToDeduct');
        } else {
          print('⚠️ Ingredient "$ingredientName" not found in database');
        }
      }

      await batch.commit();
      print('✅ All ingredients deducted successfully');
    } catch (e) {
      print('🔥 Error deducting ingredients: $e');
      rethrow;
    }
  }
}