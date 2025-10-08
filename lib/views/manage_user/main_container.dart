// lib/main_container.dart
import 'package:flutter/material.dart';
import 'package:myakieburger/views/manage_daily_sales/franchisee_homepage.dart';
import 'package:myakieburger/views/manage_ingredients_orders/ingredient_order_page.dart';
import 'package:myakieburger/views/manage_ingredients_tracking/balanced_ingredients.dart';
import 'package:myakieburger/views/manage_report/report_page.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    FranchiseeHomepage(),
    IngredientOrderPage(),
    SizedBox(), // For Add modal
    BalancedIngredients(),
    ReportPage(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // Handle ADD button (show modal)
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add New Order / Ingredient",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B2E1F),
                ),
                child: const Text("Add Ingredient"),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B2E1F),
                ),
                child: const Text("Add Order"),
              ),
            ],
          ),
        ),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFB83D2A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 28),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description, size: 28),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 32),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2, size: 28),
            label: 'Balance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit, size: 28),
            label: 'Edit',
          ),
        ],
      ),
    );
  }
}
