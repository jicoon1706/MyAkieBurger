import 'package:flutter/material.dart';
import 'package:myakieburger/widgets/lists.dart';
import 'package:myakieburger/theme/app_colors.dart';

class OrderHistory extends StatefulWidget {
  const OrderHistory({super.key});

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {
  // Sample order data
  final List<Map<String, dynamic>> orders = [
    {'date': '24/05/2024', 'id': 'ORD001'},
    {'date': '23/05/2024', 'id': 'ORD002'},
    {'date': '22/05/2024', 'id': 'ORD003'},
    {'date': '21/05/2024', 'id': 'ORD004'},
    {'date': '20/05/2024', 'id': 'ORD005'},
    {'date': '19/05/2024', 'id': 'ORD006'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryRed,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order History',
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
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Lists(
            name: 'Order Details',
            date: order['date'],
            useCalendarIcon:
                true, // 👈 now shows calendar icon instead of image
            onDownload: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Downloading order ${order['id']}...'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
