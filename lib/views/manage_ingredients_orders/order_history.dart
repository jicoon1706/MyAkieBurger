import 'package:flutter/material.dart';
import 'package:myakieburger/widgets/lists.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/providers/ingredients_order_controller.dart';
import 'package:myakieburger/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myakieburger/views/manage_ingredients_orders/order_details_popup.dart';
import 'package:myakieburger/widgets/custom_snackbar.dart';

class OrderHistory extends StatefulWidget {
  const OrderHistory({super.key});

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {
  final IngredientsOrderController _orderController =
      IngredientsOrderController();

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserOrders();
  }

  Future<void> _loadUserOrders() async {
    final franchiseeId = await getLoggedInUserId();
    print('🔍 Logged in franchiseeId: $franchiseeId'); // Add this

    if (franchiseeId == null) {
      CustomSnackbar.show(
        context,
        message: 'Error: Franchisee not found',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
      setState(() => _isLoading = false);
      return;
    }

    final orders = await _orderController.getFranchiseeOrders(franchiseeId);
    print('📦 Orders fetched: ${orders.length}'); // Add this
    print('📦 Orders data: $orders'); // Add this

    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Group orders by status
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
      backgroundColor: AppColors.primaryRed,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order History',
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
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUserOrders,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PENDING ORDERS
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
                        (
                          order,
                        ) => // Update the Lists widget in order_history.dart:
                        Lists(
                          name:
                              'Order #${order['order_number'] ?? order['supplyOrderId'] ?? 'Unknown'}',
                          date: _formatDate(order['created_at']),
                          useCalendarIcon: true,
                          onDownload: () {
                            showDialog(
                              context: context,
                              builder: (context) => OrderDetailsPopup(
                                order: order,
                                onOrderCancelled: () {
                                  // Refresh the order list after cancellation
                                  _loadUserOrders();
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // COMPLETED ORDERS
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
                        (
                          order,
                        ) => // Update the Lists widget in order_history.dart:
                        Lists(
                          name:
                              'Order #${order['order_number'] ?? order['supplyOrderId'] ?? 'Unknown'}',
                          date: _formatDate(order['created_at']),
                          useCalendarIcon: true,
                          onDownload: () {
                            showDialog(
                              context: context,
                              builder: (context) => OrderDetailsPopup(
                                order: order,
                                onOrderCancelled: () {
                                  // Refresh the order list after cancellation
                                  _loadUserOrders();
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // CANCELLED ORDERS
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
                        (
                          order,
                        ) => // Update the Lists widget in order_history.dart:
                        Lists(
                          name:
                              'Order #${order['order_number'] ?? order['supplyOrderId'] ?? 'Unknown'}',
                          date: _formatDate(order['created_at']),
                          useCalendarIcon: true,
                          onDownload: () {
                            showDialog(
                              context: context,
                              builder: (context) => OrderDetailsPopup(
                                order: order,
                                onOrderCancelled: () {
                                  // Refresh the order list after cancellation
                                  _loadUserOrders();
                                },
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

  /// Helper to format Firestore timestamp or string into a readable date
  String _formatDate(dynamic createdAt) {
    try {
      if (createdAt is Timestamp) {
        final date = createdAt.toDate();
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } else if (createdAt is String) {
        return createdAt;
      } else {
        return 'Unknown date';
      }
    } catch (e) {
      return 'Unknown date';
    }
  }
}
