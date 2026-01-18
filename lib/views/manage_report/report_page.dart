import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/widgets/lists.dart';
import 'package:myakieburger/routes.dart';
import 'package:myakieburger/services/auth_service.dart';
import 'package:myakieburger/views/manage_report/report_details_page.dart';
import 'package:myakieburger/widgets/custom_snackbar.dart';

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

  // 🔹 Logic to delete the report from Firestore
  Future<void> _deleteReport(String reportId) async {
    try {
      // 1. Delete from the main 'reports_all' collection
      await _firestore.collection('reports_all').doc(reportId).delete();

      // 2. Remove the reference from the user's document (optional but good for cleanup)
      if (_franchiseeId != null) {
        await _firestore
            .collection('users')
            .doc(_franchiseeId)
            .collection('references')
            .doc('reports')
            .update({
              reportId: FieldValue.delete(), // Removes the specific field
            })
            .catchError((e) {
              // Ignore error if the reference document doesn't exist or field is missing
              print("Note: Reference cleanup skipped or failed: $e");
            });
      }

      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Report deleted successfully',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Error deleting report: $e',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    }
  }

  // 🔹 Show confirmation dialog
  void _showDeleteConfirmation(String reportId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Report'),
          content: const Text(
            'Are you sure you want to delete this report? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cancel
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _deleteReport(reportId); // Perform delete
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
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
          await Navigator.pushNamed(context, Routes.addReport);
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
                      final reportId = report['report_id']; // Get the ID
                      final name = 'Sales Report';

                      return GestureDetector(
                        // 🔹 Trigger delete popup on long press
                        onLongPress: () {
                          if (reportId != null) {
                            _showDeleteConfirmation(reportId);
                          }
                        },
                        // Navigate to details on tap
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReportDetailsPage(
                                report: report,
                                isAdminView: false,
                              ),
                            ),
                          );
                        },
                        child: Lists(name: name, date: date),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
