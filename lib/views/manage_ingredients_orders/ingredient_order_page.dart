import 'package:flutter/material.dart';
import 'package:myakieburger/widgets/custom_button.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/routes.dart';
import 'package:myakieburger/providers/ingredients_order_controller.dart';
import 'package:myakieburger/domains/ingredients_order_model.dart';
import 'package:myakieburger/services/auth_service.dart'; // for getLoggedInUserId()

class IngredientOrderPage extends StatefulWidget {
  const IngredientOrderPage({super.key});

  @override
  State<IngredientOrderPage> createState() => _IngredientOrderPageState();
}

class _IngredientOrderPageState extends State<IngredientOrderPage> {
  final List<Map<String, dynamic>> _ingredients = [
    {
      'name': 'Roti (pieces)',
      'available': 1000,
      'quantity': 10,
      'max': 45,
      'image': 'assets/roti.png',
    },
    {
      'name': 'Daging (80g)',
      'available': 1000,
      'quantity': 10,
      'max': 135,
      'image': 'assets/daging.png',
    },
    {
      'name': 'Ayam (80g)',
      'available': 1000,
      'quantity': 10,
      'max': 45,
      'image': 'assets/ayam.png',
    },
    {
      'name': 'Daging Smoky (100g)',
      'available': 1000,
      'quantity': 10,
      'max': 45,
      'image': 'assets/daging_smoky.png',
    },
    {
      'name': 'Kambing (70g)',
      'available': 1000,
      'quantity': 10,
      'max': 45,
      'image': 'assets/kambing.png',
    },
    {
      'name': 'Rusa',
      'available': 1000,
      'quantity': 10,
      'max': 45,
      'image': 'assets/rusa.png',
    },
    {
      'name': 'Arnab',
      'available': 1000,
      'quantity': 10,
      'max': 45,
      'image': 'assets/arnab.png',
    },
    {
      'name': 'Itik',
      'available': 1000,
      'quantity': 10,
      'max': 45,
      'image': 'assets/itik.png',
    },
    {
      'name': 'Roti Hotdog',
      'available': 1000,
      'quantity': 10,
      'max': 45,
      'image': 'assets/roti_hotdog.png',
    },
    {
      'name': 'Roti (pieces)',
      'available': 1000,
      'quantity': 10,
      'max': 45,
      'image': 'assets/roti.png',
    },
    {
      'name': 'Daging (80g)',
      'available': 1000,
      'quantity': 10,
      'max': 135,
      'image': 'assets/daging.png',
    },
    {
      'name': 'Ayam (80g)',
      'available': 1000,
      'quantity': 10,
      'max': 45,
      'image': 'assets/ayam.png',
    },
    {
      'name': 'Daging Smoky (100g)',
      'available': 1000,
      'quantity': 10,
      'max': 45,
      'image': 'assets/daging_smoky.png',
    },
    {
      'name': 'Kambing (70g)',
      'available': 1000,
      'quantity': 10,
      'max': 45,
      'image': 'assets/kambing.png',
    },
    {
      'name': 'Rusa',
      'available': 1000,
      'quantity': 10,
      'max': 45,
      'image': 'assets/rusa.png',
    },
  ];

  final IngredientsOrderController _orderController =
      IngredientsOrderController();

  final TextEditingController _notesController = TextEditingController();

  void _incrementQuantity(int index) {
    setState(() {
      if (_ingredients[index]['quantity'] < _ingredients[index]['max']) {
        _ingredients[index]['quantity']++;
      }
    });
  }

  void _decrementQuantity(int index) {
    setState(() {
      if (_ingredients[index]['quantity'] > 0) {
        _ingredients[index]['quantity']--;
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryRed,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        leading: const SizedBox(),
        title: const Text(
          'Ingredient Order',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 4.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.history, color: AppColors.lightRed),
                onPressed: () {
                  Navigator.pushNamed(context, Routes.orderHistory);
                },
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Ingredient Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemCount: _ingredients.length,
                itemBuilder: (context, index) {
                  final ingredient = _ingredients[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ingredient name
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            ingredient['name'],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Image
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.fastfood,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        ),

                        // Available quantity
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Available: ${ingredient['available']}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),

                        // Quantity controls
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Minus button
                              GestureDetector(
                                onTap: () => _decrementQuantity(index),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: AppColors.quantity,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.remove,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),

                              // Quantity
                              Text(
                                '${ingredient['quantity']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              // Plus button
                              GestureDetector(
                                onTap: () => _incrementQuantity(index),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: AppColors.quantity,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Max quantity
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: Text(
                              'Max: ${ingredient['max']}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // 🟢 Notes Input Field
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Notes (optional)',
                  hintText: 'Write any special request or notes here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Order Button
              CustomButton(
                text: 'Submit Order',
                onPressed: () async {
                  final franchiseeId = await getLoggedInUserId();
                  if (franchiseeId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error: Franchisee not found'),
                      ),
                    );
                    return;
                  }

                  final franchiseeName = 'Akmal Burger Batu Pahat';
                  final selectedIngredients = _ingredients
                      .where((i) => i['quantity'] > 0)
                      .map(
                        (i) => {
                          'ingredient_id': i['name'].toLowerCase().replaceAll(
                            ' ',
                            '_',
                          ),
                          'ingredient_name': i['name'],
                          'unit_price': 1.50, // TODO: dynamic pricing
                          'quantity': i['quantity'],
                          'subtotal': i['quantity'] * 1.50,
                        },
                      )
                      .toList();

                  final totalAmount = selectedIngredients.fold<double>(
                    0,
                    (sum, item) => sum + (item['subtotal'] ?? 0),
                  );

                  final newOrder = IngredientsOrderModel(
                    franchiseeId: franchiseeId,
                    franchiseeName: franchiseeName,
                    ingredients: selectedIngredients,
                    totalAmount: totalAmount,
                    notes: _notesController.text.trim().isEmpty
                        ? 'No notes provided'
                        : _notesController.text.trim(),
                  );

                  await _orderController.saveIngredientsOrder(newOrder);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order submitted successfully!'),
                    ),
                  );

                  _notesController.clear();
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
