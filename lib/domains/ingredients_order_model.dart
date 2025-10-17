// lib/domains/ingredients_order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class IngredientsOrderModel {
  final String franchiseeId;
  final String franchiseeName;
  final List<Map<String, dynamic>> ingredients;
  final double totalAmount;
  final String status;
  final String? notes;
  final DateTime createdAt;

  IngredientsOrderModel({
    required this.franchiseeId,
    required this.franchiseeName,
    required this.ingredients,
    required this.totalAmount,
    this.status = 'pending',
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'franchiseeId': franchiseeId,
      'franchisee_name': franchiseeName,
      'ingredients': ingredients,
      'total_amount': totalAmount,
      'status': status,
      'notes': notes ?? '',
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
