import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/routes.dart';
import 'package:myakieburger/providers/meal_order_controller.dart';
import 'package:myakieburger/services/auth_service.dart';

class FranchiseeHomepage extends StatefulWidget {
  const FranchiseeHomepage({super.key});

  @override
  State<FranchiseeHomepage> createState() => _FranchiseeHomepageState();
}

class _FranchiseeHomepageState extends State<FranchiseeHomepage> {
  final MealOrderController _controller = MealOrderController();

  double _totalSales = 0;
  String _weekRange = '';
  String? _franchiseeId;
  double _todayTotal = 0;
  List<Map<String, dynamic>> _todayOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  // Fix in franchisee_homepage.dart

  Future<void> _loadSalesData() async {
    final franchiseeId = await getLoggedInUserId();
    if (franchiseeId == null) return;

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final totalSales = await _controller.getWeeklySales(franchiseeId);
    final todayData = await _controller.getTodayOrders(franchiseeId);

    setState(() {
      _franchiseeId = franchiseeId;
      _totalSales = totalSales;
      // ✅ Fix: Convert to double safely
      final total = todayData['total'];
      _todayTotal = (total is int) ? total.toDouble() : (total ?? 0.0);
      _todayOrders = List<Map<String, dynamic>>.from(todayData['orders'] ?? []);
      _weekRange =
          "${DateFormat('dd/MM').format(weekStart)} - ${DateFormat('dd/MM').format(weekEnd)}";
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayDate = DateFormat('dd/MM').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.primaryRed,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 4.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: Icon(Icons.person, color: AppColors.primaryRed),
              onPressed: () {
                Navigator.pushNamed(context, Routes.franchiseeProfile);
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: 16.0,
              left: 4.0,
            ), // 👈 moves icon left
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(Icons.show_chart, color: AppColors.primaryRed),
                onPressed: () {
                  Navigator.pushNamed(context, Routes.analysisPage);
                },
              ),
            ),
          ),
        ],
      ),

      // 🧱 Body with uniform padding
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🧾 Total Sales Card (Dynamic)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _weekRange.isEmpty
                        ? 'Total Sales (Loading...)'
                        : 'Total Sales ($_weekRange)',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RM ${_totalSales.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Today's Order Section
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 👇 Auto display today’s date
                        Text(
                          "Today's Order $todayDate",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Sales Orders',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'RM ${_todayTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // 🧾 Order List
                        Expanded(
                          child: _todayOrders.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No orders for today',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _todayOrders.length,
                                  itemBuilder: (context, index) {
                                    final order = _todayOrders[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          // Burger Icon
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.fastfood,
                                              size: 35,
                                              color: AppColors.primaryRed,
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Order Details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  order['item'] ??
                                                      'Unknown Item',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  order['addon'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Price and Time
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                order['price'] ?? 'RM 0.00',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                order['time'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
