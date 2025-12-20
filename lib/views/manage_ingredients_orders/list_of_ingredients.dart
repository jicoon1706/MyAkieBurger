import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/widgets/lists.dart';
import 'package:myakieburger/providers/ingredients_order_controller.dart';
import 'package:intl/intl.dart';
import 'package:myakieburger/routes.dart';
import 'package:myakieburger/views/manage_ingredients_orders/order_details_popup.dart';
import 'package:myakieburger/widgets/custom_snackbar.dart';
import 'package:myakieburger/services/auth_service.dart'; // 🆕 Import auth service

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
  String _userRole = 'Factory Admin'; // 🆕 Default role

  @override
  void initState() {
    super.initState();
    _loadUserRole(); // 🆕 Load role first
    _fetchOrders();
  }

  /// 🆕 Load user role from SharedPreferences
  Future<void> _loadUserRole() async {
    final role = await getUserRole();
    setState(() {
      _userRole = role ?? 'Factory Admin'; // Default to Factory Admin if null
    });
    print('✅ Current user role: $_userRole');
  }

  /// 🆕 Get primary color based on user role
  Color get _primaryColor {
    return _userRole == 'Delivery Agent'
        ? AppColors.dAgent
        : AppColors.factoryBlue;
  }

  /// 🆕 Get accent/lighter color based on user role
  Color get _accentColor {
    return _userRole == 'Delivery Agent'
        ? AppColors.bgDAgent
        : AppColors.lightBlueAccent;
  }

  /// 🆕 Check if current user is Factory Admin
  bool get _isFactoryAdmin {
    return _userRole == 'Factory Admin';
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
      backgroundColor: _accentColor, // 🎨 Dynamic color
      icon: Icons.download,
    );
  }

  @override
  Widget build(BuildContext context) {
     // 🆕 Filter based on user role
  List<Map<String, dynamic>> pendingOrders;
  List<Map<String, dynamic>> completedOrders;
  
  if (_userRole == 'Factory Admin') {
    // Factory Admin: Pending = "Pending", Completed = "Approved" + "Delivered"
    pendingOrders = _orders
        .where((o) => (o['status'] ?? '').toLowerCase() == 'pending')
        .toList();
    completedOrders = _orders
        .where((o) {
          final status = (o['status'] ?? '').toLowerCase();
          return status == 'approved' || status == 'delivered';
        })
        .toList();
  } else if (_userRole == 'Delivery Agent') {
    // Delivery Agent: Pending = "Approved", Completed = "Delivered"
    pendingOrders = _orders
        .where((o) => (o['status'] ?? '').toLowerCase() == 'approved')
        .toList();
    completedOrders = _orders
        .where((o) => (o['status'] ?? '').toLowerCase() == 'delivered')
        .toList();
  } else {
    // Default (shouldn't happen)
    pendingOrders = _orders
        .where((o) => (o['status'] ?? '').toLowerCase() == 'pending')
        .toList();
    completedOrders = _orders
        .where((o) => (o['status'] ?? '').toLowerCase() == 'delivered')
        .toList();
  }
  
  final cancelledOrders = _orders
      .where((o) => (o['status'] ?? '').toLowerCase() == 'cancelled')
      .toList();

    return Scaffold(
      backgroundColor: _primaryColor, // 🎨 Dynamic color
      appBar: AppBar(
        backgroundColor: _primaryColor, // 🎨 Dynamic color
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 4.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: Icon(
                Icons.logout_outlined,
                color: _primaryColor,
              ), // 🎨 Dynamic color
              onPressed: () async {
                await clearLoggedInUserId(); // 🆕 Clear session on logout
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routes.login,
                  (route) => false,
                );
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
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : _orders.isEmpty
          ? const Center(
              child: Text(
                'No orders found.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : RefreshIndicator(
              color: _primaryColor, // 🎨 Dynamic color
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
                                isFactoryAdminView:
                                    _isFactoryAdmin, // 🎨 Dynamic based on role
                                isDeliveryAgentView:
                                    _userRole ==
                                    'Delivery Agent', // 🆕 Add this
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
                                isFactoryAdminView:
                                    _isFactoryAdmin, // 🎨 Dynamic based on role
                                isDeliveryAgentView:
                                    _userRole ==
                                    'Delivery Agent', // 🆕 Add this
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
                                isFactoryAdminView:
                                    _isFactoryAdmin, // 🎨 Dynamic based on role
                                isDeliveryAgentView:
                                    _userRole ==
                                    'Delivery Agent', // 🆕 Add this
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
