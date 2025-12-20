// lib/views/manage_ingredients_orders/dagent_homepage.dart
import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/routes.dart';
import 'package:myakieburger/providers/ingredients_order_controller.dart';
import 'package:myakieburger/widgets/custom_snackbar.dart';
import 'package:myakieburger/services/auth_service.dart';

class DeliveryAgentHomepage extends StatefulWidget {
  const DeliveryAgentHomepage({super.key});

  @override
  State<DeliveryAgentHomepage> createState() => _DeliveryAgentHomepageState();
}

class _DeliveryAgentHomepageState extends State<DeliveryAgentHomepage> {
  final IngredientsOrderController _orderController =
      IngredientsOrderController();

  bool _isLoading = true;
  int _pendingDeliveries = 0;
  int _completedToday = 0;
  int _totalDelivered = 0;
  List<Map<String, dynamic>> _recentOrders = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final allOrders = await _orderController.getAllOrders();

      // Calculate statistics
      final approved = allOrders
          .where((o) => (o['status'] ?? '').toLowerCase() == 'approved')
          .toList();

      final delivered = allOrders
          .where((o) => (o['status'] ?? '').toLowerCase() == 'delivered')
          .toList();

      // Count deliveries completed today
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayDelivered = delivered.where((o) {
        final deliveredAt = o['delivered_at'];
        if (deliveredAt != null) {
          final date = deliveredAt.toDate();
          return date.isAfter(todayStart);
        }
        return false;
      }).length;

      setState(() {
        _pendingDeliveries = approved.length;
        _completedToday = todayDelivered;
        _totalDelivered = delivered.length;
        _recentOrders = approved.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dAgent,
      appBar: AppBar(
        backgroundColor: AppColors.dAgent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 4.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: Icon(Icons.admin_panel_settings, color: AppColors.dAgent),
              onPressed: () {
                Navigator.pushNamed(context, Routes.DAProfile);
              },
            ),
          ),
        ),
        title: const Text(
          'Home',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              color: AppColors.dAgent,
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.bgDAgent,
                              AppColors.bgDAgent.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.local_shipping,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Ready for Delivery',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '$_pendingDeliveries',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _pendingDeliveries == 1
                                  ? 'Order awaiting delivery'
                                  : 'Orders awaiting delivery',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quick Actions
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.list_alt,
                              label: 'View All Orders',
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  Routes.listOfIngredients,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.history,
                              label: 'Delivery History',
                              onTap: () {
                                CustomSnackbar.show(
                                  context,
                                  message:
                                      'Check completed orders in the Orders tab',
                                  backgroundColor: AppColors.bgDAgent,
                                  icon: Icons.info,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Recent Pending Deliveries
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pending Deliveries',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_recentOrders.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                // Navigate to orders tab
                              },
                              child: Text(
                                'View All',
                                style: TextStyle(color: AppColors.bgDAgent),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_recentOrders.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox,
                                color: Colors.white.withOpacity(0.5),
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No pending deliveries',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'All orders have been delivered!',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._recentOrders.map((order) => _buildOrderItem(order)),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    final orderNumber =
        order['order_number'] ?? order['supplyOrderId'] ?? 'N/A';
    final franchiseeName = order['franchisee_name'] ?? 'Unknown Franchisee';
    final totalAmount = order['total_amount'] ?? 0.0;
    final createdAt = _formatDate(order['created_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.bgDAgent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.shopping_bag, color: AppColors.dAgent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #$orderNumber',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  franchiseeName,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      createdAt,
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.pending_actions, size: 14, color: Colors.blue),
                    SizedBox(width: 4),
                    Text(
                      'Approved',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'RM ${totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.dAgent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    try {
      if (date == null) return '-';
      if (date is String) {
        final parsedDate = DateTime.parse(date);
        return '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
      }
      final timestamp = date;
      final dateTime = timestamp.toDate();
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (_) {
      return '-';
    }
  }
}
