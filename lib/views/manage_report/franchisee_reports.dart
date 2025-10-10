import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/widgets/lists.dart'; // Adjust import path as needed

class FranchiseeReports extends StatefulWidget {
  const FranchiseeReports({super.key});

  @override
  State<FranchiseeReports> createState() => _FranchiseeReportsState();
}

class _FranchiseeReportsState extends State<FranchiseeReports> {
  // Sample report data
  final List<Map<String, dynamic>> reports = [
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
          'Franchisee Reports',
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
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return Lists(
            name: report['name'],
            date: report['date'],
            useProfileIcon:
                report['useProfileIcon'] ?? false, // 👈 ADD THIS LINE
            onDownload: () => _handleDownload(report['name']),
          );
        },
      ),
    );
  }
}
