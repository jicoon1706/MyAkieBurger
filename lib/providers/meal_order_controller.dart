// lib/providers/meal_order_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:myakieburger/domains/meal_order_model.dart';
import 'package:myakieburger/providers/ingredients_controller.dart';

class MealOrderController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final IngredientsController _ingredientsController = IngredientsController();

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
        'created_at': formattedDate, // readable version
        'created_at_timestamp':
            FieldValue.serverTimestamp(), // sortable version
      });

      await _firestore
          .collection('users')
          .doc(franchiseeId)
          .collection('references')
          .doc('meal_orders')
          .set({orderRef.id: orderRef.id}, SetOptions(merge: true));

      // 🔹 Deduct ingredients automatically
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

  // 🔹 Fetch total weekly sales
  Future<double> getWeeklySales(String franchiseeId) async {
    final now = DateTime.now();
    // Set weekStart to Monday 00:00:00
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
      0,
      0,
      0,
    );
    // Set weekEnd to Sunday 23:59:59
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

        // Debug print
        print("📅 Order date: $createdAt");
        print("📅 Week start: $weekStart");
        print("📅 Week end: $weekEnd");
        print(
          "📅 Is within week: ${createdAt.isAfter(weekStart.subtract(const Duration(seconds: 1))) && createdAt.isBefore(weekEnd.add(const Duration(seconds: 1)))}",
        );

        // Use isAfter/isBefore with inclusive comparison
        if (createdAt.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            createdAt.isBefore(weekEnd.add(const Duration(seconds: 1)))) {
          final amount = data['total_amount'];
          final amountDouble = (amount is int)
              ? amount.toDouble()
              : (amount ?? 0.0);
          total += amountDouble;
          print("✅ Added to total: RM $amountDouble (Total now: RM $total)");
        } else {
          print("❌ Order not in current week");
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

          // Calculate total items and build display string
          String itemSummary = '';
          String addonSummary = '';
          int totalAddOns = 0;

          if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
            final meals = data['meals'] as List;
            Map<String, int> itemCounts = {};

            // Count items by name
            for (var meal in meals) {
              final menuName = meal['menu_name'] ?? 'Unknown';
              final qty = (meal['quantity'] ?? 1) as int;
              itemCounts[menuName] = (itemCounts[menuName] ?? 0) + qty;

              // Count add-ons
              if (meal['add_ons'] != null) {
                totalAddOns += (meal['add_ons'] as List).length;
              }
            }

            // Build item summary (e.g., "2 Biasa, 1 Smokey")
            itemSummary = itemCounts.entries
                .map((e) => '${e.value} ${e.key}')
                .join(', ');

            // Build add-on summary
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
            'fullOrderData': data, // Store full order data for popup
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
