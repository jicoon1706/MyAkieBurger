// lib/domains/meal_order_model.dart
class MealOrderModel {
  final String franchiseeName;
  final double totalAmount;
  final List<Map<String, dynamic>> meals;
  final String notes;
  final DateTime createdAt;

  MealOrderModel({
    required this.franchiseeName,
    required this.totalAmount,
    required this.meals,
    required this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'franchisee_name': franchiseeName,
      'total_amount': totalAmount,
      'meals': meals,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
