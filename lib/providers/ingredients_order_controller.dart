// lib/providers/ingredients_order_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myakieburger/domains/ingredients_order_model.dart';

class IngredientsOrderController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save ingredient order to both global and user references
  Future<void> saveIngredientsOrder(IngredientsOrderModel order) async {
    try {
      // 1️⃣ Create document in global collection
      final orderRef = _firestore.collection('supply_orders_all').doc();
      final orderData = order.toMap();
      orderData['supplyOrderId'] = orderRef.id;

      await orderRef.set(orderData);

      // 2️⃣ Store reference under franchisee document
      final userRef = _firestore
          .collection('users')
          .doc(order.franchiseeId)
          .collection('references')
          .doc('supply_orders');

      await userRef.set({orderRef.id: orderRef.id}, SetOptions(merge: true));

      print("✅ Supply order saved for ${order.franchiseeName}");
    } catch (e) {
      print("❌ Error saving supply order: $e");
      rethrow;
    }
  }

  /// (Optional) Fetch orders for a franchisee
  Future<List<Map<String, dynamic>>> getFranchiseeOrders(
    String franchiseeId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('supply_orders_all')
          .where('franchiseeId', isEqualTo: franchiseeId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("❌ Error fetching franchisee orders: $e");
      return [];
    }
  }
}
