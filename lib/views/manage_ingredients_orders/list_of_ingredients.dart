import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/widgets/lists.dart';
import 'package:myakieburger/providers/ingredients_order_controller.dart';
import 'package:intl/intl.dart';
import 'package:myakieburger/views/manage_ingredients_orders/order_details_popup.dart';

class ListOfIngredients extends StatefulWidget {
  const ListOfIngredients({super.key});

  @override
  State<ListOfIngredients> createState() => _ListOfIngredientsState();
}

class _ListOfIngredientsState extends State<ListOfIngredients> {
  final IngredientsOrderController _orderController =
      IngredientsOrderController();

  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      // Fetch all supply orders
      final snapshot = await _orderController.getAllOrders(); // 👈 New method
      setState(() {
        orders = snapshot;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching orders: $e');
      setState(() => isLoading = false);
    }
  }

  void _handleDownload(String orderNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading $orderNumber...'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.accentRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Ingredients Orders',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? const Center(
              child: Text(
                'No orders found',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final date = order['created_at'] != null
                    ? DateFormat(
                        'dd/MM/yyyy',
                      ).format(DateTime.parse(order['created_at']))
                    : '-';

                // In list_of_ingredients.dart (Admin view)
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => OrderDetailsPopup(
                        order: order,
                        isAdminView: true, // 👈 Enable admin mode
                        onOrderCancelled: () {
                          _fetchOrders(); // Refresh the list
                        },
                      ),
                    );
                  },
                  child: Lists(
                    name: order['username'] ?? 'Unknown',
                    date: date,
                    useProfileIcon: true,
                    onDownload: () =>
                        _handleDownload(order['order_number'] ?? ''),
                  ),
                );
              },
            ),
    );
  }
}
