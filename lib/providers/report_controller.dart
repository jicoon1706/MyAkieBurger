import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myakieburger/domains/report_model.dart';

class ReportController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Retrieve all reports
  Future<List<Map<String, dynamic>>> getAllReports() async {
    try {
      final snapshot = await _firestore
          .collection('reports_all')
          .orderBy('created_at', descending: true) // latest first
          .get();

      // Convert Firestore documents to a list of maps
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error fetching reports: $e');
      return [];
    }
  }

  // Existing saveReport() method
  Future<void> saveReport(ReportModel report) async {
    try {
      final reportRef =
          _firestore.collection('reports_all').doc(report.reportId);
      await reportRef.set(report.toMap());

      final userRef = _firestore
          .collection('users')
          .doc(report.franchiseeId)
          .collection('references')
          .doc('reports');

      await userRef.set({report.reportId: report.reportId}, SetOptions(merge: true));
      print('✅ Report saved successfully: ${report.reportId}');
    } catch (e) {
      print('❌ Error saving report: $e');
      rethrow;
    }
  }
}

