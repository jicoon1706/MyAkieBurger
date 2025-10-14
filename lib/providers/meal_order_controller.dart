// lib/providers/meal_order_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:myakieburger/domains/meal_order_model.dart';

class MealOrderController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

 // lib/providers/meal_order_controller.dart

Future<void> saveMealOrder(String franchiseeId, MealOrderModel order) async {
  try {
    final orderRef = _firestore.collection('meal_orders_all').doc();

    final formattedDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(order.createdAt);

    await orderRef.set({
      'mealOrderId': orderRef.id,
      'franchiseeId': franchiseeId,
      'franchisee_name': order.franchiseeName,
      'total_amount': order.totalAmount.toDouble(), // ✅ Ensure double
      'meals': order.meals,
      'notes': order.notes,
      'created_at': formattedDate,
    });

    await _firestore
        .collection('users')
        .doc(franchiseeId)
        .collection('references')
        .doc('meal_orders')
        .set({orderRef.id: orderRef.id}, SetOptions(merge: true));

    print("✅ Meal order saved for $franchiseeId at $formattedDate");
  } catch (e) {
    print("❌ Error saving meal order: $e");
  }
}

// ✅ Fetch total weekly sales
Future<double> getWeeklySales(String franchiseeId) async {
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
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
      
      if (createdAt.isAfter(weekStart) && createdAt.isBefore(weekEnd)) {
        final amount = data['total_amount'];
        total += (amount is int) ? amount.toDouble() : (amount ?? 0.0);
      }
    }

    return total;
  } catch (e) {
    print("❌ Error fetching weekly sales: $e");
    return 0.0;
  }
}

// ✅ Fetch today's orders
Future<Map<String, dynamic>> getTodayOrders(String franchiseeId) async {
  final now = DateTime.now();
  final todayString = DateFormat('yyyy-MM-dd').format(now);
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

  try {
    final snapshot = await _firestore
        .collection('meal_orders_all')
        .where('franchiseeId', isEqualTo: franchiseeId)
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

        // Get first meal's name
        String itemName = 'Unknown Item';
        if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
          final firstMeal = (data['meals'] as List)[0];
          itemName = firstMeal['menu_name'] ?? 'Unknown Item';
        }

        // Get add-ons info
        String addonInfo = 'No Add-On';
        if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
          final firstMeal = (data['meals'] as List)[0];
          if (firstMeal['add_ons'] != null && 
              (firstMeal['add_ons'] as List).isNotEmpty) {
            final addOnCount = (firstMeal['add_ons'] as List).length;
            addonInfo = 'Add-On ${addOnCount}x';
          }
        }

        todayOrders.add({
          'item': itemName,
          'addon': addonInfo,
          'price': 'RM ${((amount is int) ? amount.toDouble() : (amount ?? 0.0)).toStringAsFixed(2)}',
          'time': DateFormat('h:mm a').format(createdAt),
        });
      }
    }

    return {
      'total': todayTotal, // Already a double
      'orders': todayOrders,
    };
  } catch (e) {
    print("❌ Error fetching today's orders: $e");
    return {'total': 0.0, 'orders': []};
  }
}
}
