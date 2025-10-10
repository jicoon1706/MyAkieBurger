import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/widgets/lists.dart'; // Adjust import path as needed

class ListOfIngredients extends StatefulWidget {
  const ListOfIngredients({super.key});

  @override
  State<ListOfIngredients> createState() => _ListOfIngredientsState();
}

class _ListOfIngredientsState extends State<ListOfIngredients> {
  // Sample report data
  final List<Map<String, dynamic>> ingredientsOrders = [
    {'name': 'Azlan', 'date': '01/10/2024', 'useProfileIcon': true},
    {'name': 'Akmal', 'date': '05/10/2024', 'useProfileIcon': true},
    {'name': 'Ali', 'date': '08/10/2024', 'useProfileIcon': true},
  ];

  void _handleDownload(String reportName) {
    // Implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading $reportName...'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.accentRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Franchisee Ingredients Orders',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ingredientsOrders.length,
        itemBuilder: (context, index) {
          final order = ingredientsOrders[index];
          return Lists(
            name: order['name'],
            date: order['date'],
            useProfileIcon:
                order['useProfileIcon'] ?? false, // 👈 ADD THIS LINE
            onDownload: () => _handleDownload(order['name']),
          );
        },
      ),
    );
  }
}
