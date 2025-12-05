// lib/services/stall_ai_service.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class StallAIService {

  
  /// Calculate digital twin insights based on predicted sales and ingredient stock
  Future<Map<String, dynamic>> generateDigitalTwinInsights({
    required int predictedSales,
    required List<Map<String, dynamic>> ingredients, // [{'name': 'Ayam', 'balance': 12, 'unit_per_meal': 1}, ...]
    required String stallName,
  }) async {
    // Warnings: ingredients with balance < 10
    final warnings = <String>[];
    for (var ingredient in ingredients) {
      final balance = ingredient['balance'] as int? ?? 0;
      final name = ingredient['name'] as String? ?? 'Unknown';
      if (balance < 10) {
        warnings.add('$name balance is low ($balance units)');
      }
    }

    // Recommendations: calculate needed quantities based on predicted sales
    final recommendations = <String>[];
    for (var ingredient in ingredients) {
      final unitPerMeal = ingredient['unit_per_meal'] as int? ?? 1;
      final name = ingredient['name'] as String? ?? 'Unknown';
      final balance = ingredient['balance'] as int? ?? 0;

      final requiredQuantity = predictedSales * unitPerMeal;
      final toBuy = (requiredQuantity - balance) > 0 ? (requiredQuantity - balance) : 0;

      recommendations.add('$name: prepare/buy $toBuy units for predicted sales of $predictedSales meals');
    }

    // Risk Level: based on lowest balance percentage
    String riskLevel;
    if (warnings.isEmpty) {
      riskLevel = 'Low';
    } else if (warnings.length <= 2) {
      riskLevel = 'Medium';
    } else {
      riskLevel = 'High';
    }

    return {
      'predicted_sales': predictedSales,
      'warnings': warnings,
      'recommendations': recommendations,
      'risk_level': riskLevel,
    };
  }
}