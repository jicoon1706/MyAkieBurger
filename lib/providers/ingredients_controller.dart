// lib/providers/ingredients_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:myakieburger/domains/ingredients_model.dart';

class IngredientsController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🆕 List of default ingredients to initialize for new franchisees
  static const List<Map<String, dynamic>> defaultIngredients = [
    {'name': 'Ayam (80g)', 'price': 1.5},
    {'name': 'Ayam Oblong', 'price': 2.0},
    {'name': 'Cheese', 'price': 0.8},
    {'name': 'Daging (80g)', 'price': 2.0},
    {'name': 'Daging Exotic', 'price': 2.5},
    {'name': 'Daging Kambing (70g)', 'price': 3.0},
    {'name': 'Daging Oblong', 'price': 2.5},
    {'name': 'Daging Smokey (100g)', 'price': 2.2},
    {'name': 'Kambing Oblong', 'price': 3.5},
    {'name': 'Roti (pieces)', 'price': 0.5},
    {'name': 'Roti Hotdog', 'price': 0.6},
    {'name': 'Roti Oblong', 'price': 0.7},
    {'name': 'Sosej', 'price': 1.0},
    {'name': 'Telur', 'price': 0.4},
  ];

  /// 🆕 Initialize ingredients for a new franchisee with readable document IDs
  Future<void> initializeIngredientsForNewFranchisee(
    String franchiseeId,
  ) async {
    try {
      final formattedDate = DateFormat(
        'dd/MM/yyyy HH:mm',
      ).format(DateTime.now());
      final batch = _firestore.batch();

      for (var ingredient in defaultIngredients) {
        final ingredientName = ingredient['name'] as String;

        // ✅ Use ingredient name as document ID
        final docRef = _firestore
            .collection('users')
            .doc(franchiseeId)
            .collection('ingredients')
            .doc(ingredientName); // 👈 Use name instead of auto-generated ID

        batch.set(docRef, {
          'name': ingredientName,
          'price': ingredient['price'],
          'received': 0,
          'used': 0,
          'damaged': 0,
          'eat': 0,
          'balance': 0,
          'updated_at': formattedDate,
        });
      }

      await batch.commit();
      print(
        '✅ Initialized ${defaultIngredients.length} ingredients for franchisee: $franchiseeId',
      );
    } catch (e) {
      print('🔥 Error initializing ingredients: $e');
      rethrow;
    }
  }

  /// 🔹 Recipe mapping: menu items to their ingredient requirements
  static const Map<String, Map<String, int>> recipeMap = {
    // ===== CHICKEN CATEGORY =====
    'Chicken_Biasa': {'Roti (pieces)': 1, 'Ayam (80g)': 1},
    'Chicken_Special': {'Roti (pieces)': 1, 'Ayam (80g)': 1, 'Telur': 1},
    'Chicken_Double': {'Roti (pieces)': 1, 'Ayam (80g)': 2},
    'Chicken_D. Special': {'Roti (pieces)': 1, 'Ayam (80g)': 2, 'Telur': 1},
    'Chicken_Oblong': {'Roti Oblong': 1, 'Ayam Oblong': 1},

    // ===== MEAT CATEGORY =====
    'Meat_Biasa': {'Roti (pieces)': 1, 'Daging (80g)': 1},
    'Meat_Special': {'Roti (pieces)': 1, 'Daging (80g)': 1, 'Telur': 1},
    'Meat_Double': {'Roti (pieces)': 1, 'Daging (80g)': 2},
    'Meat_D. Special': {'Roti (pieces)': 1, 'Daging (80g)': 2, 'Telur': 1},
    'Meat_Oblong': {'Roti Oblong': 1, 'Daging Oblong': 1},

    // ===== OTHERS CATEGORY =====
    'Others_Smokey': {'Roti (pieces)': 1, 'Daging Smokey (100g)': 1},
    'Others_Kambing': {'Roti (pieces)': 1, 'Daging Kambing (70g)': 1},
    'Others_Oblong Kambing': {'Roti Oblong': 1, 'Kambing Oblong': 1},
    'Others_Hotdog': {'Roti Hotdog': 1, 'Sosej': 1},
    'Others_Benjo': {'Roti (pieces)': 1, 'Telur': 1},
  };

  /// 🔹 Add-on ingredient mapping
  static const Map<String, String> addOnIngredientMap = {
    'Daging': 'Daging (80g)',
    'Ayam': 'Ayam (80g)',
    'Daging Smokey': 'Daging Smokey (100g)',
    'Daging Exotic': 'Daging Exotic',
    'Daging Kambing': 'Daging Kambing (70g)',
    'Daging Oblong': 'Daging Oblong', // Fixed: was mapping to Kambing Oblong
    'Ayam Oblong': 'Ayam Oblong', // Added: was missing
    'Kambing Oblong': 'Kambing Oblong',
    'Sosej': 'Sosej',
    'Cheese': 'Cheese',
    'Telur': 'Telur',
  };

  /// Normalize menu → recipeMap key safely
  static String normalizeKey(String input) {
    return input
        .trim()
        .replaceAll(' ', '_')
        .replaceAll('.', '')
        .replaceAll('-', '_')
        .toLowerCase();
  }

  /// Find matching recipe key safely
  static String? findMatchingRecipeKey(String category, String menuName) {
    final rawKey = '${category}_$menuName';
    final normalizedRaw = normalizeKey(rawKey);

    for (final key in recipeMap.keys) {
      if (normalizeKey(key) == normalizedRaw) {
        return key;
      }
    }

    return null;
  }

  Future<void> addReceivedIngredients(
    Transaction transaction,
    String franchiseeId,
    List<dynamic> orderedIngredients,
  ) async {
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    for (var item in orderedIngredients) {
      final ingredientName = item['ingredient_name'] as String;
      final quantity = item['quantity'] as int;
      final price = (item['unit_price'] as num).toDouble();

      if (quantity < 0) {
        print('⚠️ Skipping negative quantity for $ingredientName');
        continue;
      }

      // ✅ Use ingredient name directly as document ID
      final docRef = _firestore
          .collection('users')
          .doc(franchiseeId)
          .collection('ingredients')
          .doc(ingredientName); // 👈 Use name as ID

      final docSnapshot = await transaction.get(docRef);

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        final currentReceived = data['received'] ?? 0;
        final currentBalance = data['balance'] ?? 0;

        final newReceived = currentReceived + quantity;
        final newBalance = currentBalance + quantity;

        final safeReceived = newReceived < 0 ? 0 : newReceived;
        final safeBalance = newBalance < 0 ? 0 : newBalance;

        transaction.update(docRef, {
          'received': safeReceived,
          'balance': safeBalance,
          'price': price,
          'updated_at': formattedDate,
        });

        print(
          '✅ Franchisee $franchiseeId received $quantity of $ingredientName',
        );
      } else {
        // Create new ingredient with name as ID
        transaction.set(docRef, {
          'name': ingredientName,
          'price': price,
          'received': quantity < 0 ? 0 : quantity,
          'used': 0,
          'damaged': 0,
          'eat': 0,
          'balance': quantity < 0 ? 0 : quantity,
          'updated_at': formattedDate,
        });
        print(
          '➕ Franchisee $franchiseeId created new ingredient $ingredientName',
        );
      }
    }
  }

  /// 🔹 Update or create ingredient record
  /// 🔹 Update or create ingredient record
  Future<void> updateIngredient(
    String franchiseeId,
    IngredientModel ingredient,
  ) async {
    try {
      final formattedDate = DateFormat(
        'dd/MM/yyyy HH:mm',
      ).format(DateTime.now());

      // ✅ Ensure balance is never negative
      final safeBalance = ingredient.balance < 0 ? 0 : ingredient.balance;

      // ✅ Use ingredient name as document ID
      final ingredientRef = _firestore
          .collection('users')
          .doc(franchiseeId)
          .collection('ingredients')
          .doc(
            ingredient.name,
          ); // 👈 Changed from ingredient.id to ingredient.name

      await ingredientRef.set({
        'name': ingredient.name,
        'price': ingredient.price,
        'received': ingredient.received < 0 ? 0 : ingredient.received,
        'used': ingredient.used < 0 ? 0 : ingredient.used,
        'damaged': ingredient.damaged < 0 ? 0 : ingredient.damaged,
        'eat': ingredient.eat < 0 ? 0 : ingredient.eat,
        'balance': safeBalance,
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

  Future<void> deductIngredientsForOrder(
    String franchiseeId,
    List<Map<String, dynamic>> meals,
  ) async {
    try {
      final formattedDate = DateFormat(
        'dd/MM/yyyy HH:mm',
      ).format(DateTime.now());

      Map<String, int> totalIngredientsNeeded = {};

      for (var meal in meals) {
        final category = meal['category'] as String;
        final menuName = meal['menu_name'] as String;
        final quantity = meal['quantity'] as int;
        final addOns = meal['add_ons'] as List<dynamic>? ?? [];

        final recipeKey = IngredientsController.findMatchingRecipeKey(
          category,
          menuName,
        );
        final recipe = recipeKey != null ? recipeMap[recipeKey] : null;

        if (recipe != null) {
          recipe.forEach((ingredientName, amountPerItem) {
            totalIngredientsNeeded[ingredientName] =
                (totalIngredientsNeeded[ingredientName] ?? 0) +
                (amountPerItem * quantity);
          });
        } else {
          print('⚠️ No recipe found for $recipeKey');
        }

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

      final batch = _firestore.batch();

      for (var entry in totalIngredientsNeeded.entries) {
        final ingredientName = entry.key;
        final amountToDeduct = entry.value;

        // ✅ Use ingredient name as document ID
        final docRef = _firestore
            .collection('users')
            .doc(franchiseeId)
            .collection('ingredients')
            .doc(ingredientName); // 👈 Use name as ID

        final docSnapshot = await docRef.get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          final currentUsed = data['used'] ?? 0;
          final currentBalance = data['balance'] ?? 0;

          final newUsed = currentUsed + amountToDeduct;
          final newBalance = currentBalance - amountToDeduct;
          final safeBalance = newBalance < 0 ? 0 : newBalance;

          batch.update(docRef, {
            'used': newUsed,
            'balance': safeBalance,
            'updated_at': formattedDate,
          });

          print(
            '✅ Updated $ingredientName: used +$amountToDeduct, balance: $currentBalance → $safeBalance',
          );
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
