import 'dart:convert';
import 'package:myakieburger/providers/ingredients_controller.dart';
import 'package:myakieburger/providers/meal_order_controller.dart';
import 'package:myakieburger/services/auth_service.dart'; // Make sure to import this
import 'dart:math';

class StallAIService {
  // A hypothetical AI service endpoint.
  static const String _aiEndpoint =
      'https://api.your-ai-service.com/generate-insights';

  // Dependency Injection
  final IngredientsController _ingredientsController;
  final MealOrderController _mealOrderController;

  StallAIService(
    this._ingredientsController,
    this._mealOrderController, // Added MealOrderController dependency
  );

  /// Map AI forecast names → actual recipe keys
  static const Map<String, List<String>> forecastToRecipe = {
    // Chicken items
    "Biasa Chicken": ["Chicken_Biasa"],
    "Special Chicken": ["Chicken_Special"],
    "Double Chicken": ["Chicken_Double"],
    "D. Special Chicken": ["Chicken_D. Special"],
    "Oblong Chicken": ["Chicken_Oblong"],

    // Meat items (you might want to add these if they appear in forecast)
    "Biasa Meat": ["Meat_Biasa"],
    "Special Meat": ["Meat_Special"],
    "Double Meat": ["Meat_Double"],
    "D. Special Meat": ["Meat_D. Special"],
    "Oblong Meat": ["Meat_Oblong"],

    // Other items
    "Smokey": ["Others_Smokey"],
    "Kambing": ["Others_Kambing"],
    "Oblong Kambing": ["Others_Oblong Kambing"],
    "Hotdog": ["Others_Hotdog"],
    "Benjo": ["Others_Benjo"],
  };

  // In StallAIService, update the _generateMockDemandForecast method:

  Future<Map<String, dynamic>> _generateRealDemandForecast(
    String franchiseeId,
    String stallName,
  ) async {
    try {
      print('📊 Fetching REAL historical data for forecasting...');

      // Use the REAL data method
      final forecast = await _mealOrderController.generateRealDemandForecast(
        franchiseeId,
        stallName,
      );

      print('✅ Forecast generated from real data');

      // Ensure the forecast has all required fields
      return {
        ...forecast,
        'stall_name': forecast['stall_name'] ?? stallName,
        'franchisee_id': franchiseeId, // Add franchisee ID to the result
        'forecast_period': forecast['forecast_period'] ?? 'Next 7 days',
        'menu_predictions': forecast['menu_predictions'] ?? [],
        'data_source': forecast['data_source'] ?? 'Real historical data',
        'based_on_days': forecast['based_on_days'] ?? 'Last 7 days analysis',
        'generated_at':
            forecast['generated_at'] ?? DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error generating real forecast: $e, falling back to mock');

      // Fallback to simple mock data if real data fails
      await Future.delayed(const Duration(seconds: 1));

      return {
        'stall_name': stallName,
        'franchisee_id': franchiseeId,
        'forecast_period': 'Next 7 days',
        'total_predicted_units': 1050,
        'menu_predictions': [
          'Biasa (Chicken/Meat): 210 units',
          'Special (Chicken/Meat): 180 units',
          'Double (Chicken/Meat): 160 units',
          'D. Special (Chicken/Meat): 120 units',
          'Oblong (Chicken/Meat): 140 units',
          'Oblong Kambing: 80 units',
          'Hotdog: 90 units',
          'Benjo: 70 units',
        ],
        'data_source': 'Fallback (error in real data)',
        'generated_at': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<Map<String, dynamic>> _generateMockDemandForecast(
    String franchiseeId,
    String stallName,
  ) async {
    // Just call the renamed method
    return await _generateRealDemandForecast(franchiseeId, stallName);
  }

  List<String> _calculateProcurementNeeds(
    List<String> menuPredictions,
    List<Map<String, dynamic>> currentInventory,
  ) {
    print("🔍 Calculating procurement needs...");
    print("📊 Menu predictions received: $menuPredictions");

    // 1️⃣ Build predicted sales per recipeKey
    Map<String, int> predictedSales = {};

    for (var prediction in menuPredictions) {
      print("📝 Processing prediction: $prediction");
      final parts = prediction.split(':');
      if (parts.length < 2) continue;

      final menuType = parts[0].trim();
      final cleanMenuType = menuType.split('(')[0].trim();

      final quantityText = parts[1].trim();
      final quantityMatch = RegExp(r'(\d+)\s*units').firstMatch(quantityText);
      final quantity = quantityMatch != null
          ? int.tryParse(quantityMatch.group(1)!) ?? 0
          : 0;

      print("📊 Clean menu type: $cleanMenuType, Quantity: $quantity");

      // Map AI forecast → recipe keys
      if (StallAIService.forecastToRecipe.containsKey(cleanMenuType)) {
        for (var recipeKey in StallAIService.forecastToRecipe[cleanMenuType]!) {
          predictedSales[recipeKey] =
              (predictedSales[recipeKey] ?? 0) + quantity;
          print("✅ Mapped $cleanMenuType to $recipeKey, Quantity: $quantity");
        }
      } else {
        print("⚠️ No recipe mapping found for: $cleanMenuType");
      }
    }

    print("📊 Predicted sales by recipe: $predictedSales");

    // 2️⃣ ✅ Compute total ingredients needed
    Map<String, int> totalIngredientsNeeded = {};

    predictedSales.forEach((recipeKey, qty) {
      final recipe = IngredientsController.recipeMap[recipeKey];
      if (recipe == null) {
        print("❌ Recipe not found for key: $recipeKey");
        return;
      }

      print("📋 Recipe for $recipeKey (qty: $qty): $recipe");
      recipe.forEach((ingredient, amountPerUnit) {
        final totalForIngredient = amountPerUnit * qty;
        totalIngredientsNeeded[ingredient] =
            (totalIngredientsNeeded[ingredient] ?? 0) + totalForIngredient;
        print(
          "➕ Adding $ingredient: $amountPerUnit x $qty = $totalForIngredient",
        );
      });
    });

    print("📊 Total ingredients needed: $totalIngredientsNeeded");

    // 3️⃣ Map current inventory
    Map<String, int> currentStock = {};
    for (var item in currentInventory) {
      final name = item['name']?.toString() ?? '';
      final balance = (item['balance'] is num)
          ? (item['balance'] as num).toInt()
          : int.tryParse(item['balance']?.toString() ?? '0') ?? 0;
      currentStock[name] = balance;
      print("📦 Inventory: $name = $balance");
    }

    // 4️⃣ Generate actionable procurement list
    List<String> procurementList = [];

    // Calculate for each ingredient
    totalIngredientsNeeded.forEach((ingredient, required) {
      final balance = currentStock[ingredient] ?? 0;
      final toBuy = required - balance;

      print(
        "🧮 $ingredient calculation: Needed $required - Stock $balance = ToBuy $toBuy",
      );

      if (toBuy > 0) {
        procurementList.add(
          '$ingredient: BUY $toBuy units (Needed: $required, Stock: $balance)',
        );
        print("🛒 Need to buy $ingredient: $toBuy units");
      } else if (balance >= required) {
        print("✅ Sufficient $ingredient: Stock $balance >= Needed $required");
      } else {
        print(
          "❌ Negative toBuy for $ingredient: $toBuy (check inventory data)",
        );
      }
    });

    if (procurementList.isEmpty) {
      return ['All ingredients are sufficient for the predicted demand.'];
    }

    print("📋 Final procurement list: $procurementList");

    // Debug: Show detailed calculation
    print("\n🔍 DEBUG CALCULATION:");
    print("Predicted items:");
    predictedSales.forEach((recipeKey, qty) {
      print("  $recipeKey: $qty units");
    });

    print("\nIngredient breakdown:");
    totalIngredientsNeeded.forEach((ingredient, required) {
      print("  $ingredient: $required units");
    });

    return procurementList;
  }

  Future<Map<String, dynamic>> generateDigitalTwinInsights({
    required int predictedSales,
    required List<Map<String, dynamic>> ingredients,
    required String stallName,
    required String franchiseeId,
  }) async {
    try {
      print("🚀 Starting AI forecast for franchisee: $franchiseeId");
      print("🏪 Stall Name: $stallName");
      print("📦 Ingredients data received: ${ingredients.length} items");

      // Log each ingredient for debugging
      ingredients.forEach((item) {
        print("   - ${item['name']}: ${item['balance']}");
      });

      // Get the forecast using the franchisee ID
      final aiResult = await _generateRealDemandForecast(
        franchiseeId,
        stallName,
      );

      print("📊 AI Forecast result for $franchiseeId:");
      print("   Data Source: ${aiResult['data_source']}");
      print("   Based On: ${aiResult['based_on_days']}");
      print(
        "   Menu Predictions: ${aiResult['menu_predictions']?.length ?? 0} items",
      );

      final List<String> menuPredictions = List<String>.from(
        aiResult['menu_predictions'] ?? [],
      );

      print("📋 Menu predictions count: ${menuPredictions.length}");

      if (menuPredictions.isEmpty) {
        print("⚠️ No menu predictions found for franchisee: $franchiseeId");
      } else {
        print("📋 First few predictions:");
        for (int i = 0; i < min(3, menuPredictions.length); i++) {
          print("   ${i + 1}. ${menuPredictions[i]}");
        }
      }

      // Calculate procurement needs based on the user's actual inventory
      final List<String> calculatedProcurementList = _calculateProcurementNeeds(
        menuPredictions,
        ingredients,
      );

      // Add franchisee info to the result
      aiResult['franchisee_id'] = franchiseeId;
      aiResult['stall_name'] = stallName;
      aiResult['procurement_list'] = calculatedProcurementList;

      print(
        "✅ AI Forecast completed successfully for franchisee: $franchiseeId",
      );

      return aiResult;
    } catch (e) {
      print('❌ AI Service Error for franchisee $franchiseeId: $e');
      return _generateLocalFallbackInsights(
        predictedSales,
        ingredients,
        franchiseeId,
        stallName,
      );
    }
  }

  Map<String, dynamic> _generateLocalFallbackInsights(
    int predictedSales,
    List<Map<String, dynamic>> ingredients,
    String franchiseeId,
    String stallName,
  ) {
    final warnings = <String>[];
    final recommendations = <String>[];

    // Example simple fallback logic:
    final totalStock = ingredients.fold<num>(
      0,
      (s, i) =>
          s +
          (i['balance'] is num
              ? i['balance']
              : (int.tryParse(i['balance']?.toString() ?? '0') ?? 0)),
    );

    if (totalStock < predictedSales * 1) {
      warnings.add('Total stock seems low for predicted sales.');
      recommendations.add('Consider purchasing more high-turn items.');
    }

    String riskLevel;
    if (warnings.isEmpty) {
      riskLevel = 'Low';
    } else if (warnings.length <= 2) {
      riskLevel = 'Moderate (Local Fallback)';
    } else {
      riskLevel = 'High (Local Fallback)';
    }

    return {
      'predicted_sales': predictedSales,
      'franchisee_id': franchiseeId,
      'stall_name': stallName,
      'warnings': warnings,
      'recommendations': recommendations,
      'risk_level': riskLevel,
      'source': 'Local Fallback',
      'data_source': 'Fallback (no historical data)',
      'menu_predictions': [
        'Biasa (Chicken/Meat): 210 units',
        'Special (Chicken/Meat): 180 units',
        'Double (Chicken/Meat): 160 units',
        'D. Special (Chicken/Meat): 120 units',
        'Oblong (Chicken/Meat): 140 units',
        'Oblong Kambing: 80 units',
        'Hotdog: 90 units',
        'Benjo: 70 units',
      ],
    };
  }
}
