import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/widgets/lists.dart';
import 'package:myakieburger/providers/ingredients_order_controller.dart';
import 'package:intl/intl.dart';
import 'package:myakieburger/routes.dart';
import 'package:myakieburger/views/manage_ingredients_orders/order_details_popup.dart';
import 'package:myakieburger/widgets/custom_snackbar.dart';

class ListOfIngredients extends StatefulWidget {
  const ListOfIngredients({super.key});

  @override
  State<ListOfIngredients> createState() => _ListOfIngredientsState();
}

class _ListOfIngredientsState extends State<ListOfIngredients> {
  final IngredientsOrderController _orderController =
      IngredientsOrderController();

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final snapshot = await _orderController.getAllOrders();
      setState(() {
        _orders = snapshot;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching orders: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(dynamic date) {
    try {
      if (date == null) return '-';
      if (date is String) return date;
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(date.toString()));
    } catch (_) {
      return '-';
    }
  }

  void _handleDownload(String orderNumber) {
    CustomSnackbar.show(
      context,
      message: 'Downloading invoice $orderNumber......',
      backgroundColor: Colors.blueAccent,
      icon: Icons.download,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingOrders = _orders
        .where((o) => (o['status'] ?? '') == 'Pending')
        .toList();
    final completedOrders = _orders
        .where((o) => (o['status'] ?? '') == 'Completed')
        .toList();
    final cancelledOrders = _orders
        .where((o) => (o['status'] ?? '') == 'Cancelled')
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 4.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: Icon(Icons.logout_outlined, color: AppColors.factoryBlue),
              onPressed: () {
                Navigator.pushNamed(context, Routes.login);
              },
            ),
          ),
        ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _orders.isEmpty
          ? const Center(
              child: Text(
                'No orders found.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchOrders,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🟡 Pending Section
                    if (pendingOrders.isNotEmpty) ...[
                      const Text(
                        '⏳ Pending Orders',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...pendingOrders.map(
                        (order) => Lists(
                          name: 'Order #${order['order_number'] ?? 'Unknown'}',
                          date: _formatDate(order['created_at']),
                          useProfileIcon: true,
                          onDownload: () {
                            showDialog(
                              context: context,
                              builder: (context) => OrderDetailsPopup(
                                order: order,
                                isFactoryAdminView: true,
                                onOrderCancelled: _fetchOrders,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 🟢 Completed Section
                    if (completedOrders.isNotEmpty) ...[
                      const Text(
                        '✅ Completed Orders',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...completedOrders.map(
                        (order) => Lists(
                          name: 'Order #${order['order_number'] ?? 'Unknown'}',
                          date: _formatDate(order['created_at']),
                          useProfileIcon: true,
                          onDownload: () {
                            showDialog(
                              context: context,
                              builder: (context) => OrderDetailsPopup(
                                order: order,
                                isFactoryAdminView: true,
                                onOrderCancelled: _fetchOrders,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 🔴 Cancelled Section
                    if (cancelledOrders.isNotEmpty) ...[
                      const Text(
                        '❌ Cancelled Orders',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...cancelledOrders.map(
                        (order) => Lists(
                          name: 'Order #${order['order_number'] ?? 'Unknown'}',
                          date: _formatDate(order['created_at']),
                          useProfileIcon: true,
                          onDownload: () {
                            showDialog(
                              context: context,
                              builder: (context) => OrderDetailsPopup(
                                order: order,
                                isFactoryAdminView: true,
                                onOrderCancelled: _fetchOrders,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
