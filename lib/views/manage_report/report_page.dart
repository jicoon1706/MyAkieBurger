import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/widgets/lists.dart';
import 'package:myakieburger/routes.dart';
import 'package:myakieburger/services/auth_service.dart';
import 'package:myakieburger/views/manage_report/report_details_page.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _franchiseeId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final userId = await getLoggedInUserId();
    setState(() {
      _franchiseeId = userId;
    });
  }

  Stream<List<Map<String, dynamic>>> _streamReports(String franchiseeId) {
    try {
      print('🔍 Streaming reports for franchiseeId: $franchiseeId');

      return _firestore
          .collection('reports_all')
          .where('franchiseeId', isEqualTo: franchiseeId)
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snapshot) {
            print('✅ Stream updated: ${snapshot.docs.length} reports');
            return snapshot.docs.map((doc) => doc.data()).toList();
          });
    } catch (e) {
      print('❌ Error streaming reports: $e');
      return Stream.value([]);
    }
  }

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

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentRed,
        onPressed: () async {
          // Navigate and wait for result
          await Navigator.pushNamed(context, Routes.addReport);
          // No need to manually refresh - StreamBuilder handles it automatically!
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: _franchiseeId == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _streamReports(_franchiseeId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Error loading reports.',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final reports = snapshot.data ?? [];

                if (reports.isEmpty) {
                  return const Center(
                    child: Text(
                      'No reports found.',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8,
                  ),
                  child: ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      final date = report['report_date'] ?? 'Unknown Date';
                      final name = 'Sales Report';

                      return GestureDetector(
                        onTap: () {
                          // Navigate to Report Details Page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ReportDetailsPage(report: report),
                            ),
                          );
                        },
                        child: Lists(
                          name: name,
                          date: date,
                          onDownload: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Downloading report from $date...',
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
