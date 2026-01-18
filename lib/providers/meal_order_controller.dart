// lib/providers/meal_order_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:myakieburger/domains/meal_order_model.dart';
import 'package:myakieburger/providers/ingredients_controller.dart';
import 'package:myakieburger/providers/report_controller.dart';

class MealOrderController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final IngredientsController _ingredientsController = IngredientsController();
  final ReportController _reportController = ReportController();

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

  // Add these methods to your existing MealOrderController class
// Place them near the end of the class, before the closing brace

  /// 🔹 Delete a meal order and restore inventory
  Future<void> deleteMealOrder(String orderId, String franchiseeId, List<Map<String, dynamic>> meals) async {
    try {
      // 1. Restore the ingredients first
      await _ingredientsController.restoreIngredientsFromOrder(franchiseeId, meals);

      // 2. Delete the order from the main collection
      await _firestore.collection('meal_orders_all').doc(orderId).delete();

      // 3. (Optional) Cleanup reference in user subcollection
      await _firestore
          .collection('users')
          .doc(franchiseeId)
          .collection('references')
          .doc('meal_orders')
          .update({orderId: FieldValue.delete()})
          .catchError((e) => print("Ref cleanup skipped: $e")); // Ignore if ref doc doesn't exist

      print("🗑️ Meal order $orderId deleted and stock restored.");
    } catch (e) {
      print("❌ Error deleting meal order: $e");
      rethrow;
    }
  }

  /// 🔹 Get past sales data for AI forecasting (last 7 days)
  Future<List<Map<String, dynamic>>> getPastWeekSalesData(String franchiseeId) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));
      
      // Query meal_orders_all for the past 7 days for this franchisee
      final querySnapshot = await _firestore
          .collection('meal_orders_all')
          .where('franchiseeId', isEqualTo: franchiseeId)
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('⚠️ No past week sales data found for franchisee: $franchiseeId');
        return [];
      }

      // Extract and aggregate meal breakdown data
      final List<Map<String, dynamic>> allMeals = [];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final meals = data['meals'] as List<dynamic>? ?? [];
        
        for (var meal in meals) {
          allMeals.add({
            'category': meal['category'] ?? '',
            'menu_name': meal['menu_name'] ?? '',
            'quantity': meal['quantity'] ?? 1,
            'subtotal': meal['subtotal'] ?? 0.0,
          });
        }
      }

      // Aggregate by menu item
      final Map<String, Map<String, dynamic>> aggregatedData = {};
      
      for (var meal in allMeals) {
        final menuName = '${meal['category']}_${meal['menu_name']}';
        final quantity = meal['quantity'] as int;
        
        if (!aggregatedData.containsKey(menuName)) {
          aggregatedData[menuName] = {
            'menu_name': meal['menu_name'],
            'category': meal['category'],
            'total_quantity': 0,
            'units_sold': 0,
            'total_revenue': 0.0,
          };
        }
        
        aggregatedData[menuName]!['units_sold'] += quantity;
        aggregatedData[menuName]!['total_revenue'] += (meal['subtotal'] as double);
      }

      // Convert to list
      return aggregatedData.values.toList();
    } catch (e) {
      print('❌ Error getting past week sales data: $e');
      return [];
    }
  }

  /// 🔹 Get sales data from reports (alternative method)
  Future<List<Map<String, dynamic>>> getPastWeekReportsData(String franchiseeId) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));
      
      // Query reports_all for the past 7 days
      final querySnapshot = await _firestore
          .collection('reports_all')
          .where('franchiseeId', isEqualTo: franchiseeId)
          .orderBy('report_date', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      // Extract meal breakdown from all reports
      final List<Map<String, dynamic>> allMealData = [];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final mealBreakdown = data['meal_breakdown'] as List<dynamic>? ?? [];
        
        for (var meal in mealBreakdown) {
          allMealData.add({
            'menu_name': meal['menu_name'] ?? '',
            'category': meal['category'] ?? '',
            'units_sold': meal['units_sold'] ?? 0,
            'total_revenue': meal['total_revenue'] ?? 0.0,
            'report_date': data['report_date'] ?? '',
          });
        }
      }

      return allMealData;
    } catch (e) {
      print('❌ Error getting reports data: $e');
      return [];
    }
  }

  /// 🔹 Generate SIMPLE demand forecast based on past data (Alternative to your existing method)
  Future<Map<String, dynamic>> generateSimpleRealDemandForecast(
    String franchiseeId,
    String stallName,
  ) async {
    try {
      // Get past week sales data
      final pastSales = await getPastWeekSalesData(franchiseeId);
      
      if (pastSales.isEmpty) {
        // Fallback to reports data if no meal orders found
        final reportsData = await getPastWeekReportsData(franchiseeId);
        return _generateSimpleForecastFromData(reportsData, stallName);
      }
      
      return _generateSimpleForecastFromData(pastSales, stallName);
    } catch (e) {
      print('❌ Error generating simple real forecast: $e');
      return _generateSimpleFallbackForecast(stallName);
    }
  }

  /// 🔹 Generate simple forecast from actual data
  Map<String, dynamic> _generateSimpleForecastFromData(
    List<Map<String, dynamic>> salesData,
    String stallName,
  ) {
    // Aggregate data by menu item
    final Map<String, Map<String, dynamic>> aggregated = {};
    
    for (var sale in salesData) {
      final menuName = sale['menu_name']?.toString() ?? '';
      final category = sale['category']?.toString() ?? '';
      final key = '$category: $menuName';
      
      if (!aggregated.containsKey(key)) {
        aggregated[key] = {
          'menu_name': menuName,
          'category': category,
          'total_units': 0,
          'days_count': 0,
        };
      }
      
      final unitsSold = sale['units_sold'] is int 
          ? sale['units_sold'] as int
          : int.tryParse(sale['units_sold']?.toString() ?? '0') ?? 0;
      
      aggregated[key]!['total_units'] += unitsSold;
      aggregated[key]!['days_count'] += 1;
    }

    // Generate predictions (average daily sales × 7 days)
    final List<String> predictions = [];
    int totalPredictedUnits = 0;
    
    aggregated.forEach((key, data) {
      final totalUnits = data['total_units'] as int;
      final daysCount = data['days_count'] as int;
      
      // Calculate average daily sales
      final dailyAverage = daysCount > 0 ? (totalUnits / daysCount).round() : 0;
      
      // Predict for next 7 days (with 10% growth factor)
      final predictedUnits = (dailyAverage * 7 * 1.1).round();
      
      if (predictedUnits > 0) {
        predictions.add('$key: $predictedUnits units');
        totalPredictedUnits += predictedUnits;
      }
    });

    // Sort by predicted units (descending)
    predictions.sort((a, b) {
      final aUnits = int.tryParse(a.split(':').last.replaceAll('units', '').trim()) ?? 0;
      final bUnits = int.tryParse(b.split(':').last.replaceAll('units', '').trim()) ?? 0;
      return bUnits.compareTo(aUnits);
    });

    return {
      'stall_name': stallName,
      'forecast_period': 'Next 7 days',
      'total_predicted_units': totalPredictedUnits,
      'menu_predictions': predictions,
      'data_source': 'Real historical data',
      'based_on_days': salesData.isNotEmpty ? 'Last 7 days of sales' : 'No historical data',
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  /// 🔹 Simple fallback forecast if no data available
  Map<String, dynamic> _generateSimpleFallbackForecast(String stallName) {
    return {
      'stall_name': stallName,
      'forecast_period': 'Next 7 days',
      'total_predicted_units': 1050,
      'menu_predictions': [
        'Biasa (Chicken/Meat): 210 units',
        'Special (Chicken/Meat): 180 units',
        'Double (Chicken/Meat): 160 units',
        'D. Special (Chicken/Meat): 120 units',
        'Oblong (Chicken/Meat): 140 units',
        'Oblong Kambing: 80 units',
        'Hotdog: 90 units',
        'Benjo: 70 units',
      ],
      'data_source': 'Fallback estimate',
      'based_on_days': 'No historical data available',
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

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
  Future<Map<String, List<int>>> _getHistoricalSalesLastNDays(
    String franchiseeId,
    int days,
  ) async {
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

    // Initialize sales map for all menu items with empty list
    Map<String, List<int>> historicalSales = {};
    MealOrderController.allMenuItems.keys.forEach((menuName) {
      historicalSales[menuName] = [];
    });

    try {
      // Find the start date (N days ago at 00:00:00)
      final startDate = now.subtract(Duration(days: days));
      final startOfDay = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );

      final snapshot = await _firestore
          .collection('meal_orders_all')
          .where('franchiseeId', isEqualTo: franchiseeId)
          // Note: Firestore querying by date string requires a good index or proper timestamp range.
          // Since the existing code fetches ALL orders and filters client-side, we'll keep that
          // pattern for consistency, but log a warning about performance on large data.
          .get();

      print("⚠️ Performance Warning: Filtering historical sales client-side.");

      // Map to store aggregated quantity per menu item for the last N days
      Map<String, int> aggregateQuantity = {};
      MealOrderController.allMenuItems.keys.forEach((menuName) {
        aggregateQuantity[menuName] = 0;
      });

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAtStr = data['created_at'] as String;
        final createdAt = dateFormat.parse(createdAtStr);

        // Check if the order falls within the last N days
        if (createdAt.isAfter(startOfDay)) {
          final meals = data['meals'] as List<dynamic>? ?? [];

          for (var meal in meals) {
            final menuName = meal['menu_name'] as String? ?? 'Unknown';
            final category = meal['category'] as String? ?? '';
            final quantity = meal['quantity'] as int? ?? 1;

            // Group Chicken and Meat items together (same grouping logic as getItemsSoldByDate)
            String displayName = menuName;
            if ((category == 'Chicken' || category == 'Meat') &&
                MealOrderController.allMenuItems.keys.contains(
                  '$menuName (Chicken/Meat)',
                )) {
              displayName = '$menuName (Chicken/Meat)';
            }

            if (MealOrderController.allMenuItems.containsKey(displayName)) {
              aggregateQuantity[displayName] =
                  (aggregateQuantity[displayName] ?? 0) + quantity;
            }
          }
        }
      }

      // Convert aggregated quantity into the required Map<String, List<int>> format
      // where the list contains a single aggregated value (for simplicity of the MA implementation)
      aggregateQuantity.forEach((menuName, totalQty) {
        historicalSales[menuName] = [totalQty];
      });

      return historicalSales;
    } catch (e) {
      print("❌ Error fetching historical sales: $e");
      rethrow;
    }
  }

 // Replace your existing generateRealDemandForecast method with this updated version:

  /// 🔹 Generate real demand forecast for next 7 days using actual historical data
  Future<Map<String, dynamic>> generateRealDemandForecast(
    String franchiseeId,
    String stallName,
  ) async {
    try {
      // First, try to get data from the last 7 days of meal orders
      final pastWeekSales = await getPastWeekSalesData(franchiseeId);
      
      if (pastWeekSales.isNotEmpty) {
        print('📊 Using past week meal order data for forecasting');
        return _generateSimpleForecastFromData(pastWeekSales, stallName);
      }
      
      // If no meal orders, try to get data from reports
      final pastWeekReports = await getPastWeekReportsData(franchiseeId);
      
      if (pastWeekReports.isNotEmpty) {
        print('📊 Using past week reports data for forecasting');
        return _generateSimpleForecastFromData(pastWeekReports, stallName);
      }
      
      // If both are empty, use your existing sophisticated forecast method
      print('📊 No recent data found, using historical analysis method');
      return await _generateAdvancedHistoricalForecast(franchiseeId, stallName);
      
    } catch (e) {
      print('❌ Error in generateRealDemandForecast: $e');
      return _generateSimpleFallbackForecast(stallName);
    }
  }

  /// 🔹 Advanced historical forecast using your existing logic
  Future<Map<String, dynamic>> _generateAdvancedHistoricalForecast(
    String franchiseeId,
    String stallName,
  ) async {
    const int lookbackDays = 7;
    
    // Get historical sales data from your existing method
    final Map<String, Map<String, int>> historicalDataByCategory =
        await _getHistoricalSalesByCategoryLastNDays(
          franchiseeId,
          lookbackDays,
        );

    // Calculate predictions and format the output
    List<String> menuPredictions = [];
    Map<String, int> rawPredictions = {};

    // Define popularity weights for different menu items - Chicken typically sells more
    final Map<String, double> popularityWeights = {
      'Biasa Chicken': 1.0, // Most popular - Chicken
      'Biasa Meat': 0.6, // Meat sells less than Chicken
      'Special Chicken': 0.8,
      'Special Meat': 0.5,
      'Double Chicken': 0.6,
      'Double Meat': 0.4,
      'D. Special Chicken': 0.4,
      'D. Special Meat': 0.3,
      'Oblong Chicken': 0.3,
      'Oblong Meat': 0.2,
      'Smokey': 0.5,
      'Kambing': 0.5,
      'Oblong Kambing': 0.2,
      'Hotdog': 0.7,
      'Benjo': 0.7,
    };

    // Calculate for each menu item
    historicalDataByCategory.forEach((category, items) {
      items.forEach((itemName, totalQuantity) {
        int predictedQuantityFor7Days;

        if (totalQuantity > 0) {
          // Calculate average daily demand from historical data
          final averageDailyDemand = (totalQuantity / lookbackDays).round();

          // Apply popularity weight and growth factor (10% growth)
          final popularityWeight = popularityWeights[itemName] ?? 0.5;
          final weightedDailyDemand =
              (averageDailyDemand * popularityWeight * 1.1).round();

          // Ensure minimum prediction based on item type
          final minDaily = itemName.contains('Chicken')
              ? 8 // Chicken minimum
              : itemName.contains('Meat')
                  ? 5 // Meat minimum
                  : 4; // Others minimum

          final finalDailyDemand = weightedDailyDemand > minDaily
              ? weightedDailyDemand
              : minDaily;

          // Predict for next 7 days
          predictedQuantityFor7Days = finalDailyDemand * 7;
        } else {
          // No historical data - use base prediction with popularity weight
          const baseDailyPredictions = {
            'Biasa Chicken': 18,
            'Biasa Meat': 11,
            'Special Chicken': 15,
            'Special Meat': 9,
            'Double Chicken': 12,
            'Double Meat': 8,
            'D. Special Chicken': 10,
            'D. Special Meat': 6,
            'Oblong Chicken': 8,
            'Oblong Meat': 5,
            'Smokey': 12,
            'Kambing': 10,
            'Oblong Kambing': 6,
            'Hotdog': 14,
            'Benjo': 13,
          };

          final baseDaily = baseDailyPredictions[itemName] ?? 10;
          final popularityWeight = popularityWeights[itemName] ?? 0.5;
          final weightedDailyPrediction =
              (baseDaily * popularityWeight).round();

          predictedQuantityFor7Days = weightedDailyPrediction * 7;
        }

        // Ensure reasonable minimum and maximum
        if (predictedQuantityFor7Days < 35) {
          // 5 units/day minimum
          predictedQuantityFor7Days = 35;
        } else if (predictedQuantityFor7Days > 700) {
          // 100 units/day maximum
          predictedQuantityFor7Days = 700;
        }

        rawPredictions[itemName] = predictedQuantityFor7Days;

        // Determine the demand status based on the daily average
        final dailyAverage = predictedQuantityFor7Days ~/ 7;
        String demandStatus;
        if (dailyAverage >= 50) {
          demandStatus = '🔥 High Demand';
        } else if (dailyAverage >= 25) {
          demandStatus = '📈 Expected';
        } else if (dailyAverage >= 10) {
          demandStatus = '📊 Moderate';
        } else {
          demandStatus = '📉 Low';
        }

        // Format the prediction string for UI display
        menuPredictions.add(
          '$itemName: $predictedQuantityFor7Days units ($demandStatus)',
        );
      });
    });

    // Sort predictions by quantity descending
    menuPredictions.sort((a, b) {
      final qtyA =
          int.tryParse(a.split(':')[1].split('units')[0].trim()) ?? 0;
      final qtyB =
          int.tryParse(b.split(':')[1].split('units')[0].trim()) ?? 0;
      return qtyB.compareTo(qtyA);
    });

    return {
      'menu_predictions': menuPredictions,
      'raw_predictions': rawPredictions,
      'forecast_period': '7 days',
      'stall_name': stallName,
      'data_source': 'Historical analysis (advanced)',
      'based_on_days': 'Analysis of past data patterns',
      'generated_at': DateTime.now().toIso8601String(),
    };
  }
  
  /// 🔹 Get historical sales by category for the last N days from reports
Future<Map<String, Map<String, int>>> _getHistoricalSalesByCategoryLastNDays(
  String franchiseeId,
  int days,
) async {
  final now = DateTime.now();
  final startDate = now.subtract(Duration(days: days));
  
  // Initialize with all possible menu items
  Map<String, Map<String, int>> historicalData = {
    'Chicken': {
      'Biasa Chicken': 0,
      'Special Chicken': 0,
      'Double Chicken': 0,
      'D. Special Chicken': 0,
      'Oblong Chicken': 0,
    },
    'Meat': {
      'Biasa Meat': 0,
      'Special Meat': 0,
      'Double Meat': 0,
      'D. Special Meat': 0,
      'Oblong Meat': 0,
    },
    'Others': {
      'Smokey': 0,
      'Kambing': 0,
      'Oblong Kambing': 0,
      'Hotdog': 0,
      'Benjo': 0,
    },
  };

  try {
    // Get reports for this franchisee from the last N days
    final reportsSnapshot = await _firestore
        .collection('reports_all')
        .where('franchiseeId', isEqualTo: franchiseeId)
        .get();

    int reportsFound = 0;
    int totalQuantityFound = 0;
    
    for (var doc in reportsSnapshot.docs) {
      final data = doc.data();
      
      // Parse report date
      final reportDateStr = data['report_date'] as String?;
      if (reportDateStr == null) continue;
      
      final reportDate = DateFormat('dd/MM/yyyy').parse(reportDateStr);
      
      // Check if report is within the last N days
      if (reportDate.isAfter(startDate)) {
        reportsFound++;
        
        // Get meal breakdown from report
        final mealBreakdown = List<Map<String, dynamic>>.from(
          data['meal_breakdown'] ?? [],
        );
        
        print("🔍 DEBUG: Processing report from ${reportDateStr}");
        print("🔍 DEBUG: Total meals in breakdown: ${mealBreakdown.length}");
        
        // Process each meal in the report
        for (var meal in mealBreakdown) {
          final menuName = meal['menu_name'] as String? ?? 'Unknown';
          // Use 'units_sold' instead of 'quantity'
          final quantity = meal['units_sold'] as int? ?? 0;  // ← FIXED HERE
          final category = meal['category'] as String? ?? '';
          
          totalQuantityFound += quantity;
          
          print("📊 Found in report: $menuName x $quantity units (category: $category)");
          
          // Handle grouped menu items like "Biasa (Chicken/Meat)"
          if (menuName.contains('(Chicken/Meat)')) {
            final baseName = menuName.replaceAll(' (Chicken/Meat)', '').trim();
            
            // Distribute quantity between Chicken and Meat based on typical ratio
            // For example: 60% Chicken, 40% Meat (adjust based on your actual business)
            var chickenQuantity = (quantity * 0.6).round();
            var meatQuantity = (quantity * 0.4).round();
            
            // Adjust to ensure total matches
            final total = chickenQuantity + meatQuantity;
            if (total != quantity) {
              chickenQuantity = chickenQuantity + (quantity - total);
            }
            
            // Map to proper item names
            String chickenItemName, meatItemName;
            
            switch (baseName) {
              case 'Biasa':
                chickenItemName = 'Biasa Chicken';
                meatItemName = 'Biasa Meat';
                break;
              case 'Special':
                chickenItemName = 'Special Chicken';
                meatItemName = 'Special Meat';
                break;
              case 'Double':
                chickenItemName = 'Double Chicken';
                meatItemName = 'Double Meat';
                break;
              case 'D. Special':
                chickenItemName = 'D. Special Chicken';
                meatItemName = 'D. Special Meat';
                break;
              case 'Oblong':
                chickenItemName = 'Oblong Chicken';
                meatItemName = 'Oblong Meat';
                break;
              default:
                continue;
            }
            
            // Add to historical data
            historicalData['Chicken']![chickenItemName] = 
                (historicalData['Chicken']![chickenItemName] ?? 0) + chickenQuantity;
            historicalData['Meat']![meatItemName] = 
                (historicalData['Meat']![meatItemName] ?? 0) + meatQuantity;
            
            print("   → Split: $chickenItemName: $chickenQuantity, $meatItemName: $meatQuantity");
            
          } else {
            // Handle regular menu items
            String itemName;
            if (category == 'Chicken' || category == 'Meat') {
              itemName = '$menuName $category';
            } else {
              itemName = menuName;
            }
            
            // Add to historical data
            if (category == 'Chicken' && historicalData['Chicken']!.containsKey(itemName)) {
              historicalData['Chicken']![itemName] = 
                  (historicalData['Chicken']![itemName] ?? 0) + quantity;
            } else if (category == 'Meat' && historicalData['Meat']!.containsKey(itemName)) {
              historicalData['Meat']![itemName] = 
                  (historicalData['Meat']![itemName] ?? 0) + quantity;
            } else if (historicalData['Others']!.containsKey(itemName)) {
              historicalData['Others']![itemName] = 
                  (historicalData['Others']![itemName] ?? 0) + quantity;
            } else {
              print("⚠️ Unrecognized item in report: $itemName ($category)");
            }
          }
        }
      }
    }
    
    print("📊 Found $reportsFound reports in the last $days days");
    print("📈 Total quantity found in reports: $totalQuantityFound");
    print("📊 Historical data from reports: $historicalData");
    
    return historicalData;
  } catch (e) {
    print("❌ Error fetching historical sales from reports: $e");
    
    // Fallback: try to get from meal orders if reports not available
    return await _getHistoricalSalesFromMealOrders(franchiseeId, days);
  }
}

  /// 🔹 Fallback method to get historical sales from meal orders
  Future<Map<String, Map<String, int>>> _getHistoricalSalesFromMealOrders(
    String franchiseeId,
    int days,
  ) async {
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

    Map<String, Map<String, int>> historicalData = {
      'Chicken': {
        'Biasa Chicken': 0,
        'Special Chicken': 0,
        'Double Chicken': 0,
        'D. Special Chicken': 0,
        'Oblong Chicken': 0,
      },
      'Meat': {
        'Biasa Meat': 0,
        'Special Meat': 0,
        'Double Meat': 0,
        'D. Special Meat': 0,
        'Oblong Meat': 0,
      },
      'Others': {
        'Smokey': 0,
        'Kambing': 0,
        'Oblong Kambing': 0,
        'Hotdog': 0,
        'Benjo': 0,
      },
    };

    try {
      final startDate = now.subtract(Duration(days: days));
      final startOfDay = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );

      final snapshot = await _firestore
          .collection('meal_orders_all')
          .where('franchiseeId', isEqualTo: franchiseeId)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAtStr = data['created_at'] as String;
        final createdAt = dateFormat.parse(createdAtStr);

        if (createdAt.isAfter(startOfDay)) {
          final meals = data['meals'] as List<dynamic>? ?? [];

          for (var meal in meals) {
            final menuName = meal['menu_name'] as String? ?? 'Unknown';
            final category = meal['category'] as String? ?? '';
            final quantity = meal['quantity'] as int? ?? 1;

            String itemName;
            if (category == 'Chicken' || category == 'Meat') {
              itemName = '$menuName $category';
            } else {
              itemName = menuName;
            }

            if (category == 'Chicken' &&
                historicalData['Chicken']!.containsKey(itemName)) {
              historicalData['Chicken']![itemName] =
                  (historicalData['Chicken']![itemName] ?? 0) + quantity;
            } else if (category == 'Meat' &&
                historicalData['Meat']!.containsKey(itemName)) {
              historicalData['Meat']![itemName] =
                  (historicalData['Meat']![itemName] ?? 0) + quantity;
            } else if (historicalData['Others']!.containsKey(itemName)) {
              historicalData['Others']![itemName] =
                  (historicalData['Others']![itemName] ?? 0) + quantity;
            }
          }
        }
      }

      print("📊 Fallback: Historical data from meal orders: $historicalData");
      return historicalData;
    } catch (e) {
      print("❌ Error in fallback method: $e");
      rethrow;
    }
  }

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

  /// 🔹 Get total sales across ALL franchisees for a specific month
  Future<Map<String, dynamic>> getAllSalesByMonth(int month, int year) async {
    try {
      final snapshot = await _firestore.collection('meal_orders_all').get();
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
      double totalSales = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAtStr = data['created_at'] as String?;
        if (createdAtStr == null) continue;
        final createdAt = dateFormat.parse(createdAtStr);

        if (createdAt.month == month && createdAt.year == year) {
          final amount = data['total_amount'];
          totalSales += (amount is int) ? amount.toDouble() : (amount ?? 0.0);
        }
      }

      print("📊 Total sales for $month/$year: RM $totalSales");
      return {'totalSales': totalSales};
    } catch (e) {
      print("❌ Error fetching all sales by month: $e");
      return {'totalSales': 0.0};
    }
  }

  /// 🔹 Get total sales across ALL franchisees for a specific year
  Future<Map<String, dynamic>> getAllSalesByYear(int year) async {
    try {
      final snapshot = await _firestore.collection('meal_orders_all').get();
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
      double totalSales = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAtStr = data['created_at'] as String?;
        if (createdAtStr == null) continue;
        final createdAt = dateFormat.parse(createdAtStr);

        if (createdAt.year == year) {
          final amount = data['total_amount'];
          totalSales += (amount is int) ? amount.toDouble() : (amount ?? 0.0);
        }
      }

      print("📊 Total sales for $year: RM $totalSales");
      return {'totalSales': totalSales};
    } catch (e) {
      print("❌ Error fetching all sales by year: $e");
      return {'totalSales': 0.0};
    }
  }
}
