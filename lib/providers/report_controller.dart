import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myakieburger/domains/report_model.dart';

class ReportController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveReport(ReportModel report) async {
    try {
      // 1️⃣ Save globally to reports_all/{reportId}
      final reportRef = _firestore
          .collection('reports_all')
          .doc(report.reportId);
      await reportRef.set(report.toMap());

      // 2️⃣ Save reference under user's references/reports document
      final userRef = _firestore
          .collection('users')
          .doc(report.franchiseeId)
          .collection('references')
          .doc('reports'); // ✅ Same structure as supply_orders

      // Store the reportId as a key-value entry (merge to avoid overwrite)
      await userRef.set({
        report.reportId: report.reportId,
      }, SetOptions(merge: true));

      print('✅ Report saved successfully: ${report.reportId}');
    } catch (e) {
      print('❌ Error saving report: $e');
      rethrow;
    }
  }
}
