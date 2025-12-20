// lib/providers/ingredients_order_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myakieburger/domains/ingredients_order_model.dart';
import 'package:myakieburger/providers/ingredients_controller.dart';
import 'package:myakieburger/providers/ingredients_inventory_controller.dart';

class IngredientsOrderController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final IngredientsInventoryController _inventoryController = IngredientsInventoryController();
  final IngredientsController _ingredientsController = IngredientsController();

  /// 🆕 Approve order (Factory Admin) - Reduce factory inventory
  Future<void> approveOrder(Map<String, dynamic> order) async {
    final orderId = order['supplyOrderId'];
    final ingredients = order['ingredients'] as List<dynamic>? ?? [];

    if (orderId == null) {
      throw Exception('Missing Order ID for approval.');
    }

    await _firestore.runTransaction((transaction) async {
      final orderRef = _firestore.collection('supply_orders_all').doc(orderId);
      final orderSnapshot = await transaction.get(orderRef);

      if (!orderSnapshot.exists) {
        throw Exception("Order document does not exist.");
      }

      // 1. Update order status to Approved
      transaction.update(orderRef, {
        'status': 'Approved',
        'approved_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 2. Reduce factory inventory (stock is now allocated for delivery)
      await _inventoryController.reduceStockBatch(
        transaction,
        ingredients,
      );
    });

    print("✅ Order $orderId approved and factory inventory reduced.");
  }

  /// 🆕 Mark as Delivered (Delivery Agent) - Add to franchisee stock
  Future<void> markOrderAsDelivered(Map<String, dynamic> order) async {
    final orderId = order['supplyOrderId'];
    final franchiseeId = order['franchiseeId'];
    final ingredients = order['ingredients'] as List<dynamic>? ?? [];

    if (orderId == null || franchiseeId == null) {
      throw Exception('Missing Order ID or Franchisee ID.');
    }

    await _firestore.runTransaction((transaction) async {
      final orderRef = _firestore.collection('supply_orders_all').doc(orderId);
      final orderSnapshot = await transaction.get(orderRef);

      if (!orderSnapshot.exists) {
        throw Exception("Order document does not exist.");
      }

      // 1. Update order status to Delivered
      transaction.update(orderRef, {
        'status': 'Delivered',
        'delivered_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 2. Add ingredients to franchisee's stock
      await _ingredientsController.addReceivedIngredients(
        transaction,
        franchiseeId,
        ingredients,
      );
    });

    print("✅ Order $orderId delivered and franchisee stock updated.");
  }

  /// ❌ OLD METHOD - No longer used
  /// (Replaced by approveOrder + markOrderAsDelivered)
  @Deprecated('Use approveOrder and markOrderAsDelivered instead')
  Future<void> markOrderAsCompleted(Map<String, dynamic> order) async {
    // This method is deprecated - keeping for backward compatibility
    throw UnimplementedError('Use approveOrder and markOrderAsDelivered workflow instead');
  }

  Future<void> cancelOrderAndRestock(Map<String, dynamic> order) async {
    final orderId = order['supplyOrderId'];
    final ingredients = order['ingredients'] as List<dynamic>? ?? [];
    final status = order['status']?.toString().toLowerCase() ?? 'pending';

    if (orderId == null) {
      throw Exception('Missing Order ID for cancellation.');
    }

    await _firestore.runTransaction((transaction) async {
      final orderRef = _firestore.collection('supply_orders_all').doc(orderId);
      final orderSnapshot = await transaction.get(orderRef);

      if (!orderSnapshot.exists) {
        throw Exception("Order document does not exist.");
      }

      // 1. Update order status to Cancelled
      transaction.update(orderRef, {
        'status': 'Cancelled',
        'cancelled_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 2. Return stock to factory only if order was Approved
      // (Pending orders haven't reduced stock yet)
      if (status == 'approved') {
        await _inventoryController.returnCancelledStock(
          transaction,
          ingredients,
        );
      }
    });

    print("✅ Order $orderId cancelled" + (status == 'approved' ? " and stock returned." : "."));
  }

  Future<String> _generateOrderNumber() async {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final todayOrders = await _firestore
        .collection('supply_orders_all')
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    final sequenceNumber = (todayOrders.docs.length + 1).toString().padLeft(3, '0');

    return 'ORD-$dateStr-$sequenceNumber';
  }

  Future<void> saveIngredientsOrder(IngredientsOrderModel order) async {
    try {
      final orderRef = _firestore.collection('supply_orders_all').doc();
      final orderData = order.toMap();
      orderData['supplyOrderId'] = orderRef.id;
      orderData['order_number'] = await _generateOrderNumber();

      await orderRef.set(orderData);

      final userRef = _firestore
          .collection('users')
          .doc(order.franchiseeId)
          .collection('references')
          .doc('supply_orders');

      await userRef.set({orderRef.id: orderRef.id}, SetOptions(merge: true));

      print("✅ Supply order saved: ${orderData['order_number']} for ${order.franchiseeName}");
    } catch (e) {
      print("❌ Error saving supply order: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFranchiseeOrders(String franchiseeId) async {
    try {
      print('🔍 Fetching orders for franchiseeId: $franchiseeId');

      final snapshot = await _firestore
          .collection('supply_orders_all')
          .where('franchiseeId', isEqualTo: franchiseeId)
          .orderBy('created_at', descending: true)
          .get();

      print('📊 Documents found: ${snapshot.docs.length}');

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("❌ Error fetching franchisee orders: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      print('🔍 Fetching all supply orders...');
      final snapshot = await _firestore
          .collection('supply_orders_all')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          ...data,
          'username': data['username'] ?? data['franchisee_name'] ?? 'Unknown',
          'created_at': data['created_at'] is Timestamp
              ? (data['created_at'] as Timestamp).toDate().toIso8601String()
              : data['created_at'],
        };
      }).toList();
    } catch (e) {
      print("❌ Error fetching all supply orders: $e");
      return [];
    }
  }
}