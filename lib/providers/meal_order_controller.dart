// lib/providers/meal_order_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:myakieburger/domains/meal_order_model.dart';
import 'package:myakieburger/providers/ingredients_controller.dart';

class MealOrderController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final IngredientsController _ingredientsController = IngredientsController();

  /// 🔹 All menu items template with prices
  static const Map<String, double> allMenuItems = {
    'Biasa (Chicken/Meat)': 4.50,
    'Special (Chicken/Meat)': 5.70,
    'Double (Chicken/Meat)': 6.80,
    'D. Special (Chicken/Meat)': 8.00,
    'Oblong (Chicken/Meat)': 7.00,
    'Smokey': 8.00,
    'Kambing': 5.50,
    'Oblong Kambing': 9.00,
    'Hotdog': 3.00,
    'Benjo': 3.00,
  };

  /// 🔹 All add-ons template with prices
  static const Map<String, double> allAddOns = {
    'Daging': 3.00,
    'Ayam': 3.00,
    'Daging Smokey': 5.50,
    'Daging Exotic': 4.00,
    'Daging Kambing': 4.00,
    'Daging Oblong': 5.00,
    'Ayam Oblong': 5.00,
    'Kambing Oblong': 7.50,
    'Sosej': 1.50,
    'Cheese': 1.50,
    'Telur': 1.20,
  };

  /// 🔹 Save meal order and deduct ingredients
  Future<void> saveMealOrder(String franchiseeId, MealOrderModel order) async {
    try {
      final orderRef = _firestore.collection('meal_orders_all').doc();

      final formattedDate = DateFormat(
        'dd/MM/yyyy HH:mm:ss',
      ).format(order.createdAt);

      await orderRef.set({
        'mealOrderId': orderRef.id,
        'franchiseeId': franchiseeId,
        'franchisee_name': order.franchiseeName,
        'total_amount': order.totalAmount.toDouble(),
        'meals': order.meals,
        'notes': order.notes,
        'created_at': formattedDate,
        'created_at_timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection('users')
          .doc(franchiseeId)
          .collection('references')
          .doc('meal_orders')
          .set({orderRef.id: orderRef.id}, SetOptions(merge: true));

      await _ingredientsController.deductIngredientsForOrder(
        franchiseeId,
        order.meals,
      );

      print("✅ Meal order saved for $franchiseeId at $formattedDate");
      print("✅ Ingredients deducted successfully");
    } catch (e) {
      print("❌ Error saving meal order: $e");
      rethrow;
    }
  }

  /// 🔹 Get items sold by date (menu items and add-ons)
  Future<Map<String, dynamic>> getItemsSoldByDate(
    String franchiseeId,
    DateTime date,
  ) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

    try {
      final snapshot = await _firestore
          .collection('meal_orders_all')
          .where('franchiseeId', isEqualTo: franchiseeId)
          .get();

      // Maps to store aggregated data with quantity and total
      Map<String, Map<String, dynamic>> menuItemsMap = {};
      Map<String, Map<String, dynamic>> addOnsMap = {};
      double totalSales = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAtStr = data['created_at'] as String;
        final createdAt = dateFormat.parse(createdAtStr);
        final orderDateString = DateFormat('yyyy-MM-dd').format(createdAt);

        // Only process orders from the specified date
        if (orderDateString == dateString) {
          final amount = data['total_amount'];
          totalSales += (amount is int) ? amount.toDouble() : (amount ?? 0.0);

          final meals = data['meals'] as List<dynamic>? ?? [];

          for (var meal in meals) {
            final menuName = meal['menu_name'] as String? ?? 'Unknown';
            final category = meal['category'] as String? ?? '';
            final dbPrice =
                meal['price'] as num? ?? 0.0; // Price from DB (might be 0)
            final quantity = meal['quantity'] as int? ?? 1;

            // Group Chicken and Meat items together
            String displayName = menuName;

            if ((category == 'Chicken' || category == 'Meat') &&
                (menuName == 'Biasa' ||
                    menuName == 'Special' ||
                    menuName == 'Double' ||
                    menuName == 'D. Special' ||
                    menuName == 'Oblong')) {
              displayName = '$menuName (Chicken/Meat)';
            }

            // 🔥 FIX: Get the correct price from template, not from database
            double correctPrice =
                allMenuItems[displayName] ?? dbPrice.toDouble();

            // Aggregate menu items
            if (menuItemsMap.containsKey(displayName)) {
              menuItemsMap[displayName]!['quantity'] =
                  (menuItemsMap[displayName]!['quantity'] as int) + quantity;
              menuItemsMap[displayName]!['total'] =
                  (menuItemsMap[displayName]!['total'] as double) +
                  (correctPrice * quantity);
            } else {
              menuItemsMap[displayName] = {
                'name': displayName,
                'price': correctPrice, // Use template price
                'quantity': quantity,
                'total': correctPrice * quantity,
              };
            }

            print(
              "📦 Menu: $displayName | Qty: $quantity | Price: $correctPrice | Total: ${correctPrice * quantity}",
            );

            // Aggregate add-ons
            final addOns = meal['add_ons'] as List<dynamic>? ?? [];
            for (var addOn in addOns) {
              final addOnName = addOn['name'] as String? ?? 'Unknown';
              final dbAddOnPrice = addOn['price'] as num? ?? 0.0;
              final addOnQty = addOn['quantity'] as int? ?? 1;

              // 🔥 FIX: Get the correct add-on price from template
              double correctAddOnPrice =
                  allAddOns[addOnName] ?? dbAddOnPrice.toDouble();

              if (addOnsMap.containsKey(addOnName)) {
                addOnsMap[addOnName]!['quantity'] =
                    (addOnsMap[addOnName]!['quantity'] as int) + addOnQty;
                addOnsMap[addOnName]!['total'] =
                    (addOnsMap[addOnName]!['total'] as double) +
                    (correctAddOnPrice * addOnQty);
              } else {
                addOnsMap[addOnName] = {
                  'name': addOnName,
                  'price': correctAddOnPrice, // Use template price
                  'quantity': addOnQty,
                  'total': correctAddOnPrice * addOnQty,
                };
              }

              print(
                "🔧 AddOn: $addOnName | Qty: $addOnQty | Price: $correctAddOnPrice | Total: ${correctAddOnPrice * addOnQty}",
              );
            }
          }
        }
      }

      // Create complete menu items list (including items with 0 quantity)
      List<Map<String, dynamic>> menuItems = [];
      allMenuItems.forEach((itemName, itemPrice) {
        if (menuItemsMap.containsKey(itemName)) {
          final item = menuItemsMap[itemName]!;
          menuItems.add({
            'name': item['name'],
            'price': itemPrice, // Always use template price
            'quantity': item['quantity'],
            'total': (item['total'] as double),
          });
        } else {
          // Add item with 0 quantity
          menuItems.add({
            'name': itemName,
            'price': itemPrice, // Always use template price
            'quantity': 0,
            'total': 0.0,
          });
        }
      });

      // Create complete add-ons list (including add-ons with 0 quantity)
      List<Map<String, dynamic>> addOns = [];
      allAddOns.forEach((addOnName, addOnPrice) {
        if (addOnsMap.containsKey(addOnName)) {
          final addOn = addOnsMap[addOnName]!;
          addOns.add({
            'name': addOn['name'],
            'price': addOnPrice, // Always use template price
            'quantity': addOn['quantity'],
            'total': (addOn['total'] as double),
          });
        } else {
          // Add add-on with 0 quantity
          addOns.add({
            'name': addOnName,
            'price': addOnPrice, // Always use template price
            'quantity': 0,
            'total': 0.0,
          });
        }
      });

      // Calculate total quantity (only sold items)
      int totalQuantity = menuItems.fold(
        0,
        (sum, item) => sum + (item['quantity'] as int),
      );

      print("📊 Items sold on $dateString:");
      print("   Menu Items: ${menuItems.length} types");
      print("   Add-Ons: ${addOns.length} types");
      print("   Total Quantity: $totalQuantity");
      print("   Total Sales: RM ${totalSales.toStringAsFixed(2)}");

      return {
        'menuItems': menuItems,
        'addOns': addOns,
        'totalQuantity': totalQuantity,
        'totalSales': totalSales,
        'date': dateString,
      };
    } catch (e) {
      print("❌ Error fetching items sold by date: $e");

      // Return complete list with all items at 0 on error
      List<Map<String, dynamic>> menuItems = [];
      allMenuItems.forEach((itemName, itemPrice) {
        menuItems.add({
          'name': itemName,
          'price': itemPrice,
          'quantity': 0,
          'total': 0.0,
        });
      });

      List<Map<String, dynamic>> addOns = [];
      allAddOns.forEach((addOnName, addOnPrice) {
        addOns.add({
          'name': addOnName,
          'price': addOnPrice,
          'quantity': 0,
          'total': 0.0,
        });
      });

      return {
        'menuItems': menuItems,
        'addOns': addOns,
        'totalQuantity': 0,
        'totalSales': 0.0,
        'date': dateString,
      };
    }
  }

  // 🔹 Fetch total weekly sales
  Future<double> getWeeklySales(String franchiseeId) async {
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
      0,
      0,
      0,
    );
    final weekEnd = weekStart.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );

    try {
      final snapshot = await _firestore
          .collection('meal_orders_all')
          .where('franchiseeId', isEqualTo: franchiseeId)
          .get();

      double total = 0.0;
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAtStr = data['created_at'] as String;
        final createdAt = dateFormat.parse(createdAtStr);

        if (createdAt.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            createdAt.isBefore(weekEnd.add(const Duration(seconds: 1)))) {
          final amount = data['total_amount'];
          final amountDouble = (amount is int)
              ? amount.toDouble()
              : (amount ?? 0.0);
          total += amountDouble;
        }
      }

      print("📊 Final weekly total: RM $total");
      return total;
    } catch (e) {
      print("❌ Error fetching weekly sales: $e");
      return 0.0;
    }
  }

  /// 🔹 Fetch today's orders with full order data
  Future<Map<String, dynamic>> getTodayOrders(String franchiseeId) async {
    final now = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(now);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

    try {
      final snapshot = await _firestore
          .collection('meal_orders_all')
          .where('franchiseeId', isEqualTo: franchiseeId)
          .orderBy('created_at_timestamp', descending: true)
          .get();

      double todayTotal = 0.0;
      List<Map<String, dynamic>> todayOrders = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAtStr = data['created_at'] as String;
        final createdAt = dateFormat.parse(createdAtStr);
        final dateString = DateFormat('yyyy-MM-dd').format(createdAt);

        if (dateString == todayString) {
          final amount = data['total_amount'];
          todayTotal += (amount is int) ? amount.toDouble() : (amount ?? 0.0);

          String itemSummary = '';
          String addonSummary = '';
          int totalAddOns = 0;

          if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
            final meals = data['meals'] as List;
            Map<String, int> itemCounts = {};

            for (var meal in meals) {
              final menuName = meal['menu_name'] ?? 'Unknown';
              final qty = (meal['quantity'] ?? 1) as int;
              itemCounts[menuName] = (itemCounts[menuName] ?? 0) + qty;

              if (meal['add_ons'] != null) {
                totalAddOns += (meal['add_ons'] as List).length;
              }
            }

            itemSummary = itemCounts.entries
                .map((e) => '${e.value} ${e.key}')
                .join(', ');

            if (totalAddOns > 0) {
              addonSummary = '$totalAddOns Add-On${totalAddOns > 1 ? 's' : ''}';
            } else {
              addonSummary = 'No Add-Ons';
            }
          } else {
            itemSummary = 'No Items';
            addonSummary = 'No Add-Ons';
          }

          todayOrders.add({
            'item': itemSummary,
            'addon': addonSummary,
            'price':
                'RM ${((amount is int) ? amount.toDouble() : (amount ?? 0.0)).toStringAsFixed(2)}',
            'time': DateFormat('h:mm a').format(createdAt),
            'fullOrderData': data,
          });
        }
      }

      return {'total': todayTotal, 'orders': todayOrders};
    } catch (e) {
      print("❌ Error fetching today's orders: $e");
      return {'total': 0.0, 'orders': []};
    }
  }
}

extension MealOrderAnalysis on MealOrderController {
  /// 🔹 Get total sales for a specific month of a given year
  Future<Map<String, dynamic>> getSalesByMonth(
    String franchiseeId,
    int month,
    int year,
  ) async {
    try {
      final monthStart = DateTime(year, month, 1);
      final nextMonth = (month == 12)
          ? DateTime(year + 1, 1, 1)
          : DateTime(year, month + 1, 1);
      final monthEnd = nextMonth.subtract(const Duration(seconds: 1));

      final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
      double totalSales = 0.0;
      List<Map<String, dynamic>> orders = [];

      final snapshot = await _firestore
          .collection('meal_orders_all')
          .where('franchiseeId', isEqualTo: franchiseeId)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAtStr = data['created_at'] as String;
        final createdAt = dateFormat.parse(createdAtStr);

        if (createdAt.isAfter(
              monthStart.subtract(const Duration(seconds: 1)),
            ) &&
            createdAt.isBefore(monthEnd.add(const Duration(seconds: 1)))) {
          final amount = data['total_amount'];
          final amountDouble = (amount is int)
              ? amount.toDouble()
              : (amount ?? 0.0);
          totalSales += amountDouble;
          orders.add({...data, 'parsed_date': createdAt});
        }
      }

      print(
        "📅 $year-$month → Total Sales: RM ${totalSales.toStringAsFixed(2)}",
      );
      return {'totalSales': totalSales, 'orders': orders};
    } catch (e) {
      print("❌ Error fetching month sales: $e");
      return {'totalSales': 0.0, 'orders': []};
    }
  }

  /// 🔹 Get total sales for a specific year
  Future<Map<String, dynamic>> getSalesByYear(
    String franchiseeId,
    int year,
  ) async {
    try {
      final yearStart = DateTime(year, 1, 1);
      final yearEnd = DateTime(year, 12, 31, 23, 59, 59);
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
      double totalSales = 0.0;
      List<Map<String, dynamic>> orders = [];

      final snapshot = await _firestore
          .collection('meal_orders_all')
          .where('franchiseeId', isEqualTo: franchiseeId)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAtStr = data['created_at'] as String;
        final createdAt = dateFormat.parse(createdAtStr);

        if (createdAt.isAfter(yearStart.subtract(const Duration(seconds: 1))) &&
            createdAt.isBefore(yearEnd.add(const Duration(seconds: 1)))) {
          final amount = data['total_amount'];
          final amountDouble = (amount is int)
              ? amount.toDouble()
              : (amount ?? 0.0);
          totalSales += amountDouble;
          orders.add({...data, 'parsed_date': createdAt});
        }
      }

      print("📅 $year → Total Sales: RM ${totalSales.toStringAsFixed(2)}");
      return {'totalSales': totalSales, 'orders': orders};
    } catch (e) {
      print("❌ Error fetching year sales: $e");
      return {'totalSales': 0.0, 'orders': []};
    }
  }
}
