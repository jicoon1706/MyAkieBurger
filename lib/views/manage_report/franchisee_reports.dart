import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/widgets/lists.dart';
import 'package:myakieburger/providers/report_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myakieburger/widgets/custom_snackbar.dart';

import 'package:myakieburger/views/manage_report/report_details_page.dart';

class FranchiseeReports extends StatefulWidget {
  const FranchiseeReports({super.key});

  @override
  State<FranchiseeReports> createState() => _FranchiseeReportsState();
}

class _FranchiseeReportsState extends State<FranchiseeReports> {
  final ReportController _reportController = ReportController();
  List<Map<String, dynamic>> reports = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      final snapshot = await _reportController.getAllReports();
      setState(() {
        reports = snapshot;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching reports: $e');
      setState(() => isLoading = false);
    }
  }

  void _handleDownload(String reportId) {
    CustomSnackbar.show(
      context,
      message: 'Downloading $reportId...',
      backgroundColor: AppColors.lightPurple,
      icon: Icons.download,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.admin,
      appBar: AppBar(
        backgroundColor: AppColors.admin,
        elevation: 0,
        automaticallyImplyLeading: false,
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
          ? const Center(
              child: Text(
                'No reports found',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                final createdAt = report['created_at'];
                String date = '-';

                if (createdAt != null) {
                  DateTime createdDate;

                  if (createdAt is Timestamp) {
                    createdDate = createdAt.toDate(); // ✅ Firestore Timestamp
                  } else if (createdAt is String) {
                    createdDate =
                        DateTime.tryParse(createdAt) ?? DateTime.now();
                  } else {
                    createdDate = DateTime.now();
                  }

                  date = DateFormat('dd/MM/yyyy').format(createdDate);
                }

                return GestureDetector(
                  // 👈 Wrap the Lists widget in a GestureDetector
                  onTap: () {
                    // Navigate to Report Details Page, passing the entire report map
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportDetailsPage(
                          report: report,
                          isAdminView: true,
                        ),
                      ),
                    );
                  },
                  child: Lists(
                    name: report['stall_name'] ?? 'Unknown',
                    date: date,
                    useProfileIcon: true,
                  ),
                );
              },
            ),
    );
  }
}
