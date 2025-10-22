// lib/providers/ingredients_order_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myakieburger/domains/ingredients_order_model.dart';
 
class IngredientsOrderController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate readable order number (e.g., ORD-20251020-001)
  Future<String> _generateOrderNumber() async {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    
    // Get count of orders today to generate sequence number
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

  /// Save ingredient order to both global and user references
  Future<void> saveIngredientsOrder(IngredientsOrderModel order) async {
    try {
      // 1️⃣ Create document in global collection
      final orderRef = _firestore.collection('supply_orders_all').doc();
      final orderData = order.toMap();
      orderData['supplyOrderId'] = orderRef.id;
      
      // 2️⃣ Generate and add order number
      orderData['order_number'] = await _generateOrderNumber();

      await orderRef.set(orderData);
 
      // 3️⃣ Store reference under franchisee document
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

  /// Fetch orders for a franchisee
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
      
      if (snapshot.docs.isEmpty) {
        print('⚠️ No documents match the query');
      }

      return snapshot.docs.map((doc) {
        print('📄 Document data: ${doc.data()}');
        return doc.data();
      }).toList();
    } catch (e) {
      print("❌ Error fetching franchisee orders: $e");
      return [];
    }
  }

  /// Fetch all ingredient supply orders
Future<List<Map<String, dynamic>>> getAllOrders() async {
  try {
    print('🔍 Fetching all supply orders...');
    final snapshot = await _firestore
        .collection('supply_orders_all')
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      // Ensure compatibility with 'username' field
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