import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String reportId;
  final String franchiseeId;
  final String franchiseeName;
  final String username; // 🆕 Added username
  final String stallName;
  final String region;
  final DateTime reportDate;
  final double totalSales;
  final int totalOrders;
  final int totalMealsSold;
  final double averageOrderValue;
  final List<Map<String, dynamic>> mealBreakdown;
  final List<Map<String, dynamic>> ingredientUsageSnapshot;
  final List<String> relatedMealOrders;
  final String comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReportModel({
    required this.reportId,
    required this.franchiseeId,
    required this.franchiseeName,
    required this.username, // 🆕
    required this.stallName,
    required this.region,
    required this.reportDate,
    required this.totalSales,
    required this.totalOrders,
    required this.totalMealsSold,
    required this.averageOrderValue,
    required this.mealBreakdown,
    required this.ingredientUsageSnapshot,
    required this.relatedMealOrders,
    required this.comments,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

    return {
      'report_id': reportId,
      'franchiseeId': franchiseeId,
      'franchisee_name': franchiseeName,
      'username': username, // 🆕
      'stall_name': stallName,
      'region': region,
      'report_date': DateFormat('dd/MM/yyyy').format(reportDate),
      'total_sales': totalSales,
      'total_orders': totalOrders,
      'total_meals_sold': totalMealsSold,
      'average_order_value': averageOrderValue,
      'meal_breakdown': mealBreakdown,
      'ingredient_usage_snapshot': ingredientUsageSnapshot,
      'related_meal_orders': relatedMealOrders,
      'comments': comments,
      'created_at': Timestamp.fromDate(createdAt), // ✅ Store as Timestamp
      'updated_at': Timestamp.fromDate(updatedAt), // ✅ Store as Timestamp
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> data) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();

      // Handle Timestamp
      if (value is Timestamp) {
        return value.toDate();
      }

      // Handle string (for backwards compatibility)
      if (value is String) {
        try {
          // Try parsing formatted date
          return DateFormat('dd/MM/yyyy HH:mm:ss').parse(value);
        } catch (_) {
          // Fallback to ISO format
          return DateTime.tryParse(value) ?? DateTime.now();
        }
      }

      return DateTime.now();
    }

    return ReportModel(
      reportId: data['report_id'] ?? '',
      franchiseeId: data['franchiseeId'] ?? '',
      franchiseeName: data['franchisee_name'] ?? '',
      username: data['username'] ?? '',
      stallName: data['stall_name'] ?? '',
      region: data['region'] ?? '',
      reportDate: DateFormat(
        'dd/MM/yyyy',
      ).parse(data['report_date'] ?? '01/01/2025'),
      totalSales: (data['total_sales'] ?? 0).toDouble(),
      totalOrders: data['total_orders'] ?? 0,
      totalMealsSold: data['total_meals_sold'] ?? 0,
      averageOrderValue: (data['average_order_value'] ?? 0).toDouble(),
      mealBreakdown: List<Map<String, dynamic>>.from(
        data['meal_breakdown'] ?? [],
      ),
      ingredientUsageSnapshot: List<Map<String, dynamic>>.from(
        data['ingredient_usage_snapshot'] ?? [],
      ),
      relatedMealOrders: List<String>.from(data['related_meal_orders'] ?? []),
      comments: data['comments'] ?? '',
      createdAt: parseDateTime(data['created_at']),
      updatedAt: parseDateTime(data['updated_at']),
    );
  }
}
