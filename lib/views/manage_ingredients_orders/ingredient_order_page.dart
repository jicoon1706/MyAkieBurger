import 'package:flutter/material.dart';
import 'package:myakieburger/widgets/custom_button.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/routes.dart';
import 'package:myakieburger/providers/ingredients_order_controller.dart';
import 'package:myakieburger/domains/ingredients_order_model.dart';
import 'package:myakieburger/services/auth_service.dart'; // for getLoggedInUserId()
import 'package:myakieburger/widgets/custom_snackbar.dart';
import 'package:myakieburger/providers/ingredients_inventory_controller.dart'; // Imports IngredientInventory and IngredientsInventoryController
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myakieburger/domains/ingredients_inventory_model.dart';
import 'package:myakieburger/widgets/custom_loading_dialog.dart';

// New class to combine ingredient inventory data with the current order quantity
class IngredientOrderItem {
  final String id;
  final String name;
  final String category;
  final int available;
  final int maxOrder;
  final double unitPrice;
  final String image;
  int quantity; // The quantity selected by the user for the order

  IngredientOrderItem({
    required this.id,
    required this.name,
    required this.category,
    required this.available,
    required this.maxOrder,
    required this.unitPrice,
    required this.image,
    this.quantity = 0, // Default to 0 when fetched from Firestore
  });

  factory IngredientOrderItem.fromInventory(IngredientInventory inventory) {
    return IngredientOrderItem(
      id: inventory.id,
      name: inventory.name,
      category: inventory.category,
      available: inventory.available,
      maxOrder: inventory.maxOrder,
      unitPrice: inventory.unitPrice,
      image: inventory.image,
      quantity: 0, // Initialize order quantity to 0
    );
  }
}

class IngredientOrderPage extends StatefulWidget {
  const IngredientOrderPage({super.key});

  @override
  State<IngredientOrderPage> createState() => _IngredientOrderPageState();
}

class _IngredientOrderPageState extends State<IngredientOrderPage> {
  // Removed the static _ingredients list

  // New state for ingredients fetched from Firestore, including order quantity
  List<IngredientOrderItem> _ingredientOrderItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  final IngredientsInventoryController _inventoryController =
      IngredientsInventoryController();

  final IngredientsOrderController _orderController =
      IngredientsOrderController();

  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchIngredients();
  }

  Future<void> _fetchIngredients() async {
    try {
      final ingredients = await _inventoryController.fetchIngredients();

      print("Loading ingredient items to UI...");

      setState(() {
        _ingredientOrderItems = ingredients
            .map((i) => IngredientOrderItem.fromInventory(i))
            .toList();
        _isLoading = false;
      });

      print("UI Loaded: ${_ingredientOrderItems.length} items");
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load ingredients: $e';
        _isLoading = false;
      });
    }
  }

  // --- Quantity Control Logic ---
  void _incrementQuantity(int index) {
    setState(() {
      final item = _ingredientOrderItems[index];
      // Check max order constraint and available stock
      if (item.quantity < item.maxOrder && item.quantity < item.available) {
        item.quantity++;
      } else if (item.quantity >= item.available) {
        // Optional: show a warning if trying to order more than available
        CustomSnackbar.show(
          context,
          message: 'Cannot order more than available stock (${item.available})',
          backgroundColor: Colors.orange,
          icon: Icons.warning_amber,
        );
      } else if (item.quantity >= item.maxOrder) {
        // Optional: show a warning if trying to order more than max allowed
        CustomSnackbar.show(
          context,
          message: 'Maximum order quantity reached (${item.maxOrder})',
          backgroundColor: Colors.orange,
          icon: Icons.warning_amber,
        );
      }
    });
  }

  void _decrementQuantity(int index) {
    setState(() {
      if (_ingredientOrderItems[index].quantity > 0) {
        _ingredientOrderItems[index].quantity--;
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // --- Order Submission Logic ---
  Future<void> _submitOrder() async {
    final franchiseeId = await getLoggedInUserId();
    if (franchiseeId == null) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Error: Franchisee not found. Please log in again.',
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
      }
      return;
    }

    final franchiseeName =
        'Akmal Burger Batu Pahat'; // Hardcoded for now, should be fetched from user profile

    // Filter items with quantity > 0
    List<IngredientOrderItem> itemsToOrder = _ingredientOrderItems
        .where((i) => i.quantity > 0)
        .toList();

    if (itemsToOrder.isEmpty) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Your order list is empty. Select ingredients to order.',
          backgroundColor:
              AppColors.quantity, // Using a relevant color from AppColors
          icon: Icons.info_outline,
        );
      }
      return;
    }

    List<Map<String, dynamic>> selectedIngredients = itemsToOrder
        .map(
          (i) => {
            'ingredient_id': i.id,
            'ingredient_name': i.name,
            'unit_price': i.unitPrice,
            'quantity': i.quantity,
            'subtotal': i.quantity * i.unitPrice,
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

    // Show loading dialog
    CustomLoadingDialog.show(context, message: 'Submitting Order...');

    try {
      // 1. Save the order
      await _orderController.saveIngredientsOrder(newOrder);

      // 2. Reduce stock in Firestore using a transaction (already implemented in controller)
      for (var item in itemsToOrder) {
        await _inventoryController.reduceStock(item.id, item.quantity);
      }

      // Close the loading dialog
      CustomLoadingDialog.hide(context);

      // 3. Success Feedback and UI reset
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Order submitted successfully and stock reduced!',
          backgroundColor: Colors.green,
          icon: Icons.check_circle_outline,
        );
        _notesController.clear();
        // Re-fetch data to update 'available' quantity and reset order quantity to 0
        _fetchIngredients();
      }
    } catch (e) {
      // Hide loading dialog safely
      CustomLoadingDialog.hide(context);

      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Failed to submit order: $e',
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
      }
    }
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
      body: Padding(padding: const EdgeInsets.all(16.0), child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              "Loading ingredients...",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.white, size: 50),
            SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(color: Colors.white)),
            SizedBox(height: 16),
            CustomButton(
              text: 'Retry Loading',
              onPressed: _fetchIngredients,
              backgroundColor: AppColors.lightRed,
            ),
          ],
        ),
      );
    }

    // Use the fetched list _ingredientOrderItems
    return SingleChildScrollView(
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
            itemCount: _ingredientOrderItems.length,
            itemBuilder: (context, index) {
              final ingredient = _ingredientOrderItems[index];
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
                        ingredient.name, // Use ingredient model
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
                          child: Image.asset(
                            ingredient.image, // Use ingredient model
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                          ),
                        ),
                      ),
                    ),

                    // Unit Price
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Text(
                        'RM ${ingredient.unitPrice.toStringAsFixed(2)}', // Use ingredient model
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),

                    // Available quantity
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'Available: ${ingredient.available}', // Use ingredient model
                        style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                      ),
                    ),

                    // Quantity controls
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
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
                            '${ingredient.quantity}', // Use ingredient model
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
                          'Max: ${ingredient.maxOrder}', // Use ingredient model (renamed from 'max' to 'maxOrder')
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

          // Notes Input Field
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
            onPressed: _submitOrder, // Call the new submission function
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
