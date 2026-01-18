import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // 1. Import Intl for date formatting

class AdminHomepage extends StatefulWidget {
  const AdminHomepage({super.key});

  @override
  State<AdminHomepage> createState() => _AdminHomepageState();
}

class _AdminHomepageState extends State<AdminHomepage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  int _totalFranchisees = 0;
  double _currentMonthSales = 0.0; // 2. Variable for sales
  String _currentMonthName = ''; // 3. Variable for month name
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Set current month name immediately (e.g., "May 2025")
    _currentMonthName = DateFormat('MMMM yyyy').format(DateTime.now());
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    // Run both fetch operations in parallel
    await Future.wait([_loadFranchiseesCount(), _loadCurrentMonthSales()]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFranchiseesCount() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Franchisee')
          .get();
      _totalFranchisees = snapshot.docs.length;
    } catch (e) {
      print('❌ Error loading franchisees: $e');
    }
  }

  // 4. New method to calculate sales
  Future<void> _loadCurrentMonthSales() async {
    try {
      final now = DateTime.now();
      double total = 0.0;

      // Fetch all reports (filtering by string date on client side is safer given the format)
      final snapshot = await _firestore.collection('reports_all').get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final dateStr = data['report_date'] as String?;
        final sales = (data['total_sales'] as num?)?.toDouble() ?? 0.0;

        if (dateStr != null) {
          try {
            // Parse 'dd/MM/yyyy'
            final reportDate = DateFormat('dd/MM/yyyy').parse(dateStr);

            // Check if report belongs to current Month and Year
            if (reportDate.month == now.month && reportDate.year == now.year) {
              total += sales;
            }
          } catch (e) {
            print('Skipping invalid date: $dateStr');
          }
        }
      }

      _currentMonthSales = total;
    } catch (e) {
      print('❌ Error loading sales: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.admin,
      appBar: AppBar(
        backgroundColor: AppColors.admin,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 4.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(
                Icons.admin_panel_settings,
                color: AppColors.admin,
              ),
              onPressed: () {
                Navigator.pushNamed(context, Routes.adminProfile);
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
                icon: const Icon(Icons.show_chart, color: AppColors.admin),
                onPressed: () {
                  Navigator.pushNamed(context, Routes.adminSalesInsights);
                },
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.lightPurple),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Sales Overview
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.lightPurple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Sales ($_currentMonthName)', // 5. Dynamic Month
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'RM ${_currentMonthSales.toStringAsFixed(2)}', // 6. Dynamic Total
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Optional: You can calculate growth percentage if you fetch previous month data
                          const Text(
                            'Current Month Performance',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Total Franchisees Card
                    _buildStatCard(
                      icon: Icons.store,
                      label: 'Total Franchisees',
                      value: _totalFranchisees.toString(),
                      color: const Color(0xFF6C63FF),
                      onTap: () {
                        // Navigate to franchisees list if route exists
                        // Navigator.pushNamed(context, Routes.franchiseesList);
                      },
                    ),
                  ],
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
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
