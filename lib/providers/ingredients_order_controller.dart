// lib/providers/ingredients_order_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myakieburger/domains/ingredients_order_model.dart';
import 'package:myakieburger/providers/ingredients_controller.dart';
import 'package:myakieburger/providers/ingredients_inventory_controller.dart';
import 'package:intl/intl.dart';

class IngredientsOrderController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final IngredientsInventoryController _inventoryController =
      IngredientsInventoryController();
  final IngredientsController _ingredientsController = IngredientsController();

  /// 🆕 Mark as Delivered (Delivery Agent) - FIXED VERSION
  Future<void> markOrderAsDelivered(Map<String, dynamic> order) async {
    try {
      final orderId = order['supplyOrderId'];
      final franchiseeId = order['franchiseeId'];
      final ingredients = order['ingredients'] as List<dynamic>? ?? [];

      if (orderId == null || franchiseeId == null) {
        throw Exception('Missing Order ID or Franchisee ID.');
      }

      print('🚚 Marking order as delivered: $orderId for franchisee: $franchiseeId');
      print('📦 Ingredients to add: ${ingredients.length}');

      final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

      // ✅ CRITICAL FIX: Do all reads BEFORE starting the transaction
      Map<String, DocumentSnapshot> ingredientDocs = {};
      
      for (var item in ingredients) {
        final ingredientName = item['ingredient_name'] as String;
        final docRef = _firestore
            .collection('users')
            .doc(franchiseeId)
            .collection('ingredients')
            .doc(ingredientName);
        
        final docSnapshot = await docRef.get();
        ingredientDocs[ingredientName] = docSnapshot;
        print('📖 Pre-read ingredient: $ingredientName, exists: ${docSnapshot.exists}');
      }

      // ✅ Now start the transaction with all data already loaded
      await _firestore.runTransaction((transaction) async {
        // 1. Update order status to Delivered
        final orderRef = _firestore.collection('supply_orders_all').doc(orderId);
        
        transaction.update(orderRef, {
          'status': 'Delivered',
          'delivered_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        print('✅ Order status updated to Delivered');

        // 2. Update franchisee's ingredients using pre-loaded data
        for (var item in ingredients) {
          final ingredientName = item['ingredient_name'] as String;
          final quantity = item['quantity'] as int;
          final price = (item['unit_price'] as num).toDouble();

          if (quantity < 0) {
            print('⚠️ Skipping negative quantity for $ingredientName');
            continue;
          }

          final docRef = _firestore
              .collection('users')
              .doc(franchiseeId)
              .collection('ingredients')
              .doc(ingredientName);

          final docSnapshot = ingredientDocs[ingredientName]!;

          if (docSnapshot.exists) {
            final data = docSnapshot.data()! as Map<String, dynamic>;
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

            print('✅ Updated $ingredientName: received +$quantity (balance: $currentBalance → $safeBalance)');
          } else {
            // Create new ingredient
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
            
            print('➕ Created new ingredient: $ingredientName');
          }
        }
      });

      print('✅ Transaction completed successfully');
    } catch (e, stackTrace) {
      print('🔥 Error marking order as delivered: $e');
      print('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 🆕 Approve order (Factory Admin)
  Future<void> approveOrder(Map<String, dynamic> order) async {
    try {
      final orderId = order['supplyOrderId'];
      final ingredients = order['ingredients'] as List<dynamic>? ?? [];

      if (orderId == null) {
        throw Exception('Missing Order ID for approval.');
      }

      print('✅ Approving order: $orderId');

      await _firestore.runTransaction((transaction) async {
        final orderRef = _firestore.collection('supply_orders_all').doc(orderId);

        // Update order status to Approved
        transaction.update(orderRef, {
          'status': 'Approved',
          'approved_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        print('✅ Order approved');
      });

      // Reduce factory inventory AFTER transaction (separate operation)
      await _inventoryController.reduceStockBatch(ingredients);
      print('✅ Factory inventory reduced');
      
    } catch (e) {
      print('🔥 Error approving order: $e');
      rethrow;
    }
  }

  /// Cancel order and restore stock
  Future<void> cancelOrderAndRestock(Map<String, dynamic> order) async {
    try {
      final orderId = order['supplyOrderId'];
      final ingredients = order['ingredients'] as List<dynamic>? ?? [];
      final status = order['status']?.toString().toLowerCase() ?? 'pending';

      if (orderId == null) {
        throw Exception('Missing Order ID for cancellation.');
      }

      print('❌ Cancelling order: $orderId with status: $status');

      await _firestore.runTransaction((transaction) async {
        final orderRef = _firestore.collection('supply_orders_all').doc(orderId);

        // Update order status to Cancelled
        transaction.update(orderRef, {
          'status': 'Cancelled',
          'cancelled_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      });

      // ✅ FIX: Restore stock for BOTH 'approved' AND 'pending' orders
      // because stock was reduced immediately upon creation.
      if (status == 'approved' || status == 'pending') {
        await _inventoryController.returnCancelledStock(ingredients);
        print('✅ Global inventory restored for cancelled order');
      }

      print('✅ Order cancelled successfully');
    } catch (e) {
      print('🔥 Error cancelling order: $e');
      rethrow;
    }
  }
  
  Future<String> _generateOrderNumber() async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final todayOrders = await _firestore
        .collection('supply_orders_all')
        .where(
          'created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    final sequenceNumber = (todayOrders.docs.length + 1).toString().padLeft(
      3,
      '0',
    );

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

      print(
        "✅ Supply order saved: ${orderData['order_number']} for ${order.franchiseeName}",
      );
    } catch (e) {
      print("❌ Error saving supply order: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFranchiseeOrders(
    String franchiseeId,
  ) async {
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
