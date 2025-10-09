import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/widgets/lists.dart';
import 'package:myakieburger/routes.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final List<Map<String, String>> reports = [
    {'date': '24/05/2024', 'name': 'Sales Report'},
    {'date': '23/05/2024', 'name': 'Sales Report'},
    {'date': '22/05/2024', 'name': 'Sales Report'},
    {'date': '21/05/2024', 'name': 'Sales Report'},
    {'date': '20/05/2024', 'name': 'Sales Report'},
    {'date': '19/05/2024', 'name': 'Sales Report'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryRed,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Sales Report',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),

      // Floating button
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentRed,
        onPressed: () {
         Navigator.pushNamed(context, Routes.addReport);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];

            return Lists(
              name: report['name']!,
              date: report['date']!,
              onDownload: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Downloading report from ${report['date']}...',
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
