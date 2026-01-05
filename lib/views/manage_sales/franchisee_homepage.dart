import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/routes.dart';
import 'package:myakieburger/providers/meal_order_controller.dart';
import 'package:myakieburger/providers/ingredients_controller.dart';
import 'package:myakieburger/services/auth_service.dart';
import 'package:myakieburger/views/manage_sales/meal_order_detail_popup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FranchiseeHomepage extends StatefulWidget {
  const FranchiseeHomepage({super.key});

  @override
  State<FranchiseeHomepage> createState() => FranchiseeHomepageState();
}

class FranchiseeHomepageState extends State<FranchiseeHomepage> {
  final MealOrderController _controller = MealOrderController();
  final IngredientsController _ingredientsController =
      IngredientsController(); // <--- NEW CONTROLLER INSTANCE
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Add Firestore instance

  String _stallName = 'Loading...'; // Initialize as loading
  String _franchiseeName = '';

  double _totalSales = 0;
  String _weekRange = '';
  String? _franchiseeId;
  double _todayTotal = 0;
  List<Map<String, dynamic>> _todayOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load user data first, then sales data
    _loadUserData().then((_) {
      _loadSalesData();
    });
  }

  Future<void> _loadUserData() async {
    try {
      // Get franchisee ID from auth service
      final franchiseeId = await getLoggedInUserId();

      if (franchiseeId == null) {
        print('❌ No franchisee ID found in auth service');
        return;
      }

      // Fetch user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(franchiseeId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();

        if (mounted) {
          setState(() {
            _franchiseeId = franchiseeId;
            _franchiseeName = userData?['franchisee_name'] ?? 'Unknown';
            _stallName = userData?['stall_name'] ?? 'My Akie Burger Stall';
          });
        }

        print('✅ User data loaded:');
        print('   - Franchisee ID: $_franchiseeId');
        print('   - Franchisee Name: $_franchiseeName');
        print('   - Stall Name: $_stallName');
      } else {
        print('⚠️ User document not found for ID: $franchiseeId');
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
    }
  }

  Future<void> _loadSalesData() async {
    if (_franchiseeId == null) {
      print('⚠️ Cannot load sales data: franchiseeId is null');
      return;
    }

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final totalSales = await _controller.getWeeklySales(_franchiseeId!);
    final todayData = await _controller.getTodayOrders(_franchiseeId!);

    if (mounted) {
      setState(() {
        _totalSales = totalSales;
        final total = todayData['total'];
        _todayTotal = (total is int) ? total.toDouble() : (total ?? 0.0);
        _todayOrders = List<Map<String, dynamic>>.from(
          todayData['orders'] ?? [],
        );
        _weekRange =
            "${DateFormat('dd/MM').format(weekStart)} - ${DateFormat('dd/MM').format(weekEnd)}";
        _isLoading = false;
      });
    }
  }

  // Public method to refresh data (called from parent)
  Future<void> refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadSalesData();
  }

  void _showOrderDetails(Map<String, dynamic> orderData) {
    showDialog(
      context: context,
      builder: (context) => MealOrderDetailPopup(orderData: orderData),
    );
  }

  // Pull-to-refresh handler
  Future<void> _onRefresh() async {
    await _loadSalesData();
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
            padding: const EdgeInsets.only(right: 16.0, left: 4.0),
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

      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Colors.white,
        backgroundColor: AppColors.primaryRed,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Total Sales Card
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

                          // Order List
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
                                      return GestureDetector(
                                        onTap: () {
                                          if (order['fullOrderData'] != null) {
                                            _showOrderDetails(
                                              order['fullOrderData'],
                                            );
                                          }
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.05,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
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
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      order['addon'] ?? '',
                                                      style: TextStyle(
                                                        fontSize: 13,
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    order['time'] ?? '',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
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
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _showAIForecast,
      //   icon: const Icon(Icons.psychology_alt),
      //   label: const Text('AI Forecast', style: TextStyle(fontWeight: FontWeight.bold)),
      //   backgroundColor: Colors.black,
      //   foregroundColor: Colors.white,
      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      //   elevation: 4,
      // ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
