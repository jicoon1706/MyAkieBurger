import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/views/manage_sales/admin_homepage.dart';
import 'package:myakieburger/views/manage_user/franchisees_list.dart';
import 'package:myakieburger/views/manage_report/franchisee_reports.dart';
import 'package:myakieburger/views/manage_ingredients_orders/list_of_ingredients.dart';

class AdminMainContainer extends StatefulWidget {
  const AdminMainContainer({super.key});

  @override
  State<AdminMainContainer> createState() => _AdminMainContainerState();
}

class _AdminMainContainerState extends State<AdminMainContainer> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AdminHomepage(),
    const FranchiseesList(), // Franchisees List
    // const ListOfIngredients(), // Ingredient Orders
    const FranchiseeReports(), // Reports
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.lightPurple,
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
            icon: Icon(Icons.store, size: 28),
            label: 'Franchisees',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.description, size: 28),
          //   label: 'Orders',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment, size: 28),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
