import 'package:flutter/material.dart';
import 'package:myakieburger/views/manage_sales/add_sales_order.dart';
import 'package:myakieburger/views/manage_user/franchisee_homepage.dart';
import 'package:myakieburger/views/manage_ingredients_orders/ingredient_order_page.dart';
import 'package:myakieburger/views/manage_ingredients_tracking/balanced_ingredients.dart';
import 'package:myakieburger/views/manage_report/report_page.dart';
import 'package:myakieburger/views/manage_sales/add_sales_order.dart';

class FranchiseeMainContainer extends StatefulWidget {
  const FranchiseeMainContainer({super.key});

  @override
  State<FranchiseeMainContainer> createState() =>
      _FranchiseeMainContainerState();
}

class _FranchiseeMainContainerState extends State<FranchiseeMainContainer> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const FranchiseeHomepage(),
    const IngredientOrderPage(),
    const AddSalesOrder(), // For Add button
    const BalancedIngredients(),
    const ReportPage(),
  ];

  void _onTabTapped(int index) {
    // Special case for Add button (middle one)
    if (index == 2) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => const AddSalesOrder(),
      );
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B2E1F),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFB83D2A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
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
            icon: Icon(Icons.add_circle, size: 36),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2, size: 28),
            label: 'Balance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit, size: 28),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
