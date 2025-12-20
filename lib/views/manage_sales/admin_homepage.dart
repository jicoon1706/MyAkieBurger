// admin_homepage.dart
import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHomepage extends StatefulWidget {
  const AdminHomepage({super.key});

  @override
  State<AdminHomepage> createState() => _AdminHomepageState();
}

class _AdminHomepageState extends State<AdminHomepage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🆕 Add these state variables
  int _totalFranchisees = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFranchiseesCount(); // 🆕 Load data on init
  }

  // 🆕 Add this method to fetch franchisees count
  Future<void> _loadFranchiseesCount() async {
    try {
      final franchiseesSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Franchisee')
          .get();

      setState(() {
        _totalFranchisees = franchiseesSnapshot.docs.length;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading franchisees: $e');
      setState(() => _isLoading = false);
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
              icon: Icon(Icons.admin_panel_settings, color: AppColors.admin),
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
                icon: Icon(Icons.show_chart, color: AppColors.admin),
                onPressed: () {
                  Navigator.pushNamed(context, Routes.adminAnalysisPage);
                },
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading // 🆕 Show loading state
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
                        children: const [
                          Text(
                            'Total Sales (May 2025)',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'RM 15,240.00',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '↑ 12.5% from last month',
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
                        // Navigate to franchisees list if needed
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
