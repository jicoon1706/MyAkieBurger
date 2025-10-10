import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/routes.dart';

class FranchiseeHomepage extends StatefulWidget {
  const FranchiseeHomepage({super.key});

  @override
  State<FranchiseeHomepage> createState() => _FranchiseeHomepageState();
}

class _FranchiseeHomepageState extends State<FranchiseeHomepage> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _orders = [
    {
      'item': '2 Hotdog',
      'addon': 'No Add-On',
      'price': 'RM 20.00',
      'time': '4:45 PM',
    },
    {
      'item': '2 Biasa Ayam',
      'addon': 'No Add-On',
      'price': 'RM 21.00',
      'time': '3:45 PM',
    },
    {
      'item': '2 Special Daging',
      'addon': 'Add-On 1x Cheese',
      'price': 'RM 15.00',
      'time': '2:45 PM',
    },
    {
      'item': '2 Hotdog',
      'addon': 'No Add-On',
      'price': 'RM 20.00',
      'time': '1:45 PM',
    },
  ];

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate based on selected tab
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        // Orders - Navigate to Ingredient Order Page
        Navigator.pushNamed(context, '/ingredient_order_page');
        break;
      case 2:
        // Add button
        // TODO: Implement add functionality
        break;
      case 3:
        // Balance - Navigate to Balanced Ingredients
        Navigator.pushNamed(context, '/balanced_ingredients');
        break;
      case 4:
        // Edit - Navigate to Edit Ingredients
        Navigator.pushNamed(context, '/edit_ingredients');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryRed,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 4.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: AppColors.primaryRed),
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
                children: const [
                  Text(
                    'Total Sales (06/07 - 12/07)',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'RM1500.00',
                    style: TextStyle(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Order 12/5",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Sales Orders',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        'RM 500',
                        style: TextStyle(
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
                    child: ListView.builder(
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order['item'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      order['addon'],
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
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    order['price'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    order['time'],
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
