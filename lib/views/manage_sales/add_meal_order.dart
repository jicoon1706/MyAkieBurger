import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/services/auth_service.dart';
import 'package:myakieburger/providers/user_controller.dart';
import 'package:myakieburger/domains/user_model.dart';
import 'package:myakieburger/providers/meal_order_controller.dart';
import 'package:myakieburger/domains/meal_order_model.dart';
import 'package:myakieburger/widgets/custom_snackbar.dart';
import 'package:myakieburger/providers/ingredients_controller.dart';
import 'package:myakieburger/domains/ingredients_model.dart';

class AddMealOrder extends StatefulWidget {
  const AddMealOrder({super.key});

  @override
  State<AddMealOrder> createState() => _AddMealOrderState();
}

class _AddMealOrderState extends State<AddMealOrder> {
  String selectedCategory = 'Chicken';
  String? franchiseeId;
  String? franchiseeName;
  bool isLoadingUser = true;
  List<OrderItem> orderItems = [];
  OrderItem? pendingItem;
  final TextEditingController notesController = TextEditingController();

  // 🔹 New: Store ingredient stock levels
  Map<String, int> ingredientStock = {};
  bool isLoadingIngredients = true;

  // 🔹 Minimum threshold map (same as in BalancedIngredients)
  static const Map<String, int> ingredientMinimumThreshold = {
    'Roti (pieces)': 10,
    'Roti Oblong': 8,
    'Roti Hotdog': 8,
    'Ayam (80g)': 15,
    'Ayam Oblong': 10,
    'Daging (80g)': 15,
    'Daging Oblong': 10,
    'Daging Smokey (100g)': 10,
    'Daging Exotic': 8,
    'Daging Kambing': 8,
    'Daging Kambing (70g)': 8,
    'Kambing Oblong': 8,
    'Sosej': 12,
    'Cheese': 10,
    'Telur': 20,
  };

  final List<String> categories = ['Chicken', 'Meat', 'Others'];

  final List<MenuItem> menuItems = [
    // 🐔 Chicken
    MenuItem('Biasa', 'Chicken', 4.50),
    MenuItem('Special', 'Chicken', 5.70),
    MenuItem('Double', 'Chicken', 6.80),
    MenuItem('D. Special', 'Chicken', 8.00),
    MenuItem('Oblong', 'Chicken', 7.00),

    // 🥩 Meat
    MenuItem('Biasa', 'Meat', 4.50),
    MenuItem('Special', 'Meat', 5.70),
    MenuItem('Double', 'Meat', 6.80),
    MenuItem('D. Special', 'Meat', 8.00),
    MenuItem('Oblong', 'Meat', 7.00),

    // 🍔 Others
    MenuItem('Smokey', 'Others', 8.00),
    MenuItem('Kambing', 'Others', 5.50),
    MenuItem('Oblong Kambing', 'Others', 9.00),
    MenuItem('Hotdog', 'Others', 3.00),
    MenuItem('Benjo', 'Others', 3.00),
  ];

  final List<AddOn> addOns = [
    AddOn('None', 'No Add-On', 0.00),
    AddOn('Daging', 'Daging', 3.00),
    AddOn('Ayam', 'Ayam', 3.00),
    AddOn('Daging Smokey', 'Daging Smokey', 5.50),
    AddOn('Daging Exotic', 'Daging Exotic', 4.00),
    AddOn('Daging Kambing', 'Daging Kambing', 4.00),
    AddOn('Daging Oblong', 'Daging Oblong', 5.00),
    AddOn('Ayam Oblong', 'Ayam Oblong', 5.00),
    AddOn('Kambing Oblong', 'Kambing Oblong', 7.50),
    AddOn('Sosej', 'Sosej', 1.50),
    AddOn('Cheese', 'Cheese', 1.50),
    AddOn('Telur', 'Telur', 1.20),
  ];

  @override
  void initState() {
    super.initState();
    _loadFranchiseeInfo();
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _loadFranchiseeInfo() async {
    try {
      final userId = await getLoggedInUserId();

      if (userId != null) {
        final userController = UserController();
        final user = await userController.getUserById(userId);

        if (user != null) {
          setState(() {
            franchiseeId = user.id;
            franchiseeName = user.stallName;
            isLoadingUser = false;
          });
          print('✅ Franchisee loaded: ${user.stallName} (ID: ${user.id})');

          // 🔹 Load ingredient stock levels
          await _loadIngredientStock(user.id);
        } else {
          setState(() {
            isLoadingUser = false;
            isLoadingIngredients = false;
          });
          print('⚠️ User not found in database');
        }
      } else {
        setState(() {
          isLoadingUser = false;
          isLoadingIngredients = false;
        });
        print('⚠️ No logged-in user ID found');
      }
    } catch (e) {
      setState(() {
        isLoadingUser = false;
        isLoadingIngredients = false;
      });
      print('❌ Error loading franchisee info: $e');
    }
  }

  // 🔹 New: Load ingredient stock from Firestore
  Future<void> _loadIngredientStock(String userId) async {
    try {
      final controller = IngredientsController();
      final ingredients = await controller.getIngredients(userId);

      setState(() {
        ingredientStock = {
          for (var ingredient in ingredients)
            ingredient.name: ingredient.balance,
        };
        isLoadingIngredients = false;
      });

      print('✅ Loaded ${ingredientStock.length} ingredient stock levels');
    } catch (e) {
      setState(() {
        isLoadingIngredients = false;
      });
      print('❌ Error loading ingredient stock: $e');
    }
  }

  // 🔹 New: Check if menu item has sufficient stock
  bool _hasStock(String category, String menuName) {
    final recipeKey = IngredientsController.findMatchingRecipeKey(
      category,
      menuName,
    );
    if (recipeKey == null) return true; // If no recipe found, allow ordering

    final recipe = IngredientsController.recipeMap[recipeKey];
    if (recipe == null) return true;

    // Check if all required ingredients are available
    for (var entry in recipe.entries) {
      final ingredientName = entry.key;
      final requiredAmount = entry.value;
      final availableStock = ingredientStock[ingredientName] ?? 0;

      if (availableStock < requiredAmount) {
        return false; // Out of stock
      }
    }

    return true; // All ingredients available
  }

  // 🔹 New: Check if menu item is low on stock
  bool _isLowStock(String category, String menuName) {
    final recipeKey = IngredientsController.findMatchingRecipeKey(
      category,
      menuName,
    );
    if (recipeKey == null) return false;

    final recipe = IngredientsController.recipeMap[recipeKey];
    if (recipe == null) return false;

    // Check if any required ingredient is low
    for (var entry in recipe.entries) {
      final ingredientName = entry.key;
      final availableStock = ingredientStock[ingredientName] ?? 0;
      final threshold = ingredientMinimumThreshold[ingredientName] ?? 5;

      if (availableStock > 0 && availableStock <= threshold) {
        return true; // Low stock
      }
    }

    return false;
  }

  // 🔹 New: Check add-on stock availability
  bool _hasAddOnStock(String addOnName) {
    if (addOnName == 'None') return true;

    final ingredientName = IngredientsController.addOnIngredientMap[addOnName];
    if (ingredientName == null) return true;

    final availableStock = ingredientStock[ingredientName] ?? 0;
    return availableStock > 0;
  }

  // 🔹 New: Check if add-on is low stock
  bool _isAddOnLowStock(String addOnName) {
    if (addOnName == 'None') return false;

    final ingredientName = IngredientsController.addOnIngredientMap[addOnName];
    if (ingredientName == null) return false;

    final availableStock = ingredientStock[ingredientName] ?? 0;
    final threshold = ingredientMinimumThreshold[ingredientName] ?? 5;

    return availableStock > 0 && availableStock <= threshold;
  }

  void selectMenuItem(String itemName) {
    final category = _getCategoryForItem(itemName);

    // 🔹 Check stock before allowing selection
    if (!_hasStock(category, itemName)) {
      CustomSnackbar.show(
        context,
        message: 'Sorry, $itemName is out of stock',
        backgroundColor: Colors.red,
        icon: Icons.inventory_2_outlined,
      );
      return;
    }

    final menuItem = menuItems.firstWhere((item) => item.name == itemName);
    setState(() {
      pendingItem = OrderItem(itemName, 1, [], menuItem.price);
    });
  }

  void addAddOn(String addOnName) {
    if (pendingItem != null && addOnName != 'None') {
      // 🔹 Check add-on stock before adding
      if (!_hasAddOnStock(addOnName)) {
        CustomSnackbar.show(
          context,
          message: 'Sorry, $addOnName is out of stock',
          backgroundColor: Colors.red,
          icon: Icons.inventory_2_outlined,
        );
        return;
      }

      setState(() {
        if (!pendingItem!.addOns.contains(addOnName)) {
          pendingItem!.addOns.add(addOnName);
        }
      });
    }
  }

  void removeAddOn(String addOnName) {
    if (pendingItem != null) {
      setState(() {
        pendingItem!.addOns.remove(addOnName);
      });
    }
  }

  double calculateItemPrice(OrderItem item) {
    double total = item.basePrice;
    for (String addOnName in item.addOns) {
      final addOn = addOns.firstWhere((a) => a.name == addOnName);
      total += addOn.price;
    }
    return total * item.quantity;
  }

  double calculateTotalPrice() {
    double total = 0.0;
    for (var item in orderItems) {
      total += calculateItemPrice(item);
    }
    return total;
  }

  void confirmOrder() {
    if (pendingItem != null) {
      setState(() {
        final existingIndex = orderItems.indexWhere(
          (item) =>
              item.name == pendingItem!.name &&
              item.addOns.toString() == pendingItem!.addOns.toString(),
        );
        if (existingIndex >= 0) {
          orderItems[existingIndex].quantity++;
        } else {
          orderItems.add(
            OrderItem(
              pendingItem!.name,
              pendingItem!.quantity,
              List.from(pendingItem!.addOns),
              pendingItem!.basePrice,
            ),
          );
        }
        pendingItem = null;
      });
    }
  }

  void cancelPendingItem() {
    setState(() {
      pendingItem = null;
    });
  }

  void removeFromOrder(int index) {
    setState(() {
      if (orderItems[index].quantity > 1) {
        orderItems[index].quantity--;
      } else {
        orderItems.removeAt(index);
      }
    });
  }

  void increaseQuantity(int index) {
    setState(() {
      orderItems[index].quantity++;
    });
  }

  Future<void> _completeOrder() async {
    if (franchiseeId == null) {
      CustomSnackbar.show(
        context,
        message: 'Error: User not logged in. Please restart the app.',
        backgroundColor: Colors.red,
        icon: Icons.download,
      );
      return;
    }

    if (orderItems.isEmpty) {
      CustomSnackbar.show(
        context,
        message: 'Please add at least one item to your order',
        backgroundColor: Colors.orange,
        icon: Icons.download,
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      );

      final controller = MealOrderController();

      final meals = orderItems.map((item) {
        return {
          'category': _getCategoryForItem(item.name),
          'menu_name': item.name,
          'base_price': item.basePrice.toDouble(),
          'add_ons': item.addOns.map((a) {
            final addOnData = addOns.firstWhere(
              (x) => x.name == a,
              orElse: () => AddOn(a, a, 0.0),
            );

            final unitPrice = addOnData.price.toDouble();
            return {
              'name': a,
              'unit_price': unitPrice,
              'quantity': 1,
              'subtotal': (unitPrice * 1).toDouble(),
            };
          }).toList(),
          'quantity': item.quantity,
          'subtotal': calculateItemPrice(item).toDouble(),
        };
      }).toList();

      final newOrder = MealOrderModel(
        franchiseeName: franchiseeName ?? 'Unknown Stall',
        totalAmount: calculateTotalPrice(),
        meals: meals,
        notes: notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      await controller.saveMealOrder(franchiseeId!, newOrder);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Order completed successfully!.',
          backgroundColor: Colors.green,
          icon: Icons.check,
        );
      }

      // Close the order sheet and return true to indicate success
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      // Close loading dialog if still showing
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Error: $e',
          backgroundColor: Colors.red,
          icon: Icons.close,
        );
      }
      print('❌ Error completing order: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = calculateTotalPrice();

    if (isLoadingUser || isLoadingIngredients) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.primaryRed,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (franchiseeId == null) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.primaryRed,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              const Text(
                'User Not Logged In',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please log in again to continue',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(color: AppColors.primaryRed),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 60,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Pending item preview
          if (pendingItem != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFB83D2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fastfood, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Customizing: ${pendingItem!.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'RM ${calculateItemPrice(pendingItem!).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: cancelPendingItem,
                        icon: const Icon(Icons.close, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  if (pendingItem!.addOns.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: pendingItem!.addOns.map((addOnName) {
                        final addOn = addOns.firstWhere(
                          (a) => a.name == addOnName,
                        );
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$addOnName (+${addOn.price.toStringAsFixed(2)})',
                                style: const TextStyle(
                                  color: Color(0xFFB83D2A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => removeAddOn(addOnName),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Color(0xFFB83D2A),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: confirmOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Add to Order',
                        style: TextStyle(
                          color: Color(0xFFB83D2A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (pendingItem == null) ...[
            // Category tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: categories.map((category) {
                  final isSelected = selectedCategory == category;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFFB83D2A),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          category,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF8B2E1F)
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Menu items section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Menu Items',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Menu items scroll horizontally
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: menuItems
                    .where((item) => item.category == selectedCategory)
                    .length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final filteredItems = menuItems
                      .where((item) => item.category == selectedCategory)
                      .toList();
                  final item = filteredItems[index];

                  // 🔹 Check stock levels
                  final hasStock = _hasStock(item.category, item.name);
                  final isLowStock = _isLowStock(item.category, item.name);

                  return Opacity(
                    opacity: hasStock ? 1.0 : 0.5, // 🔹 Dim out of stock items
                    child: GestureDetector(
                      onTap: hasStock
                          ? () => selectMenuItem(item.name)
                          : null, // 🔹 Disable if no stock
                      child: Stack(
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 55,
                                width: 55,
                                decoration: BoxDecoration(
                                  color: !hasStock
                                      ? Colors
                                            .grey[400] // 🔹 Grey for out of stock
                                      : isLowStock
                                      ? Colors
                                            .orange // 🔹 Orange for low stock
                                      : Colors
                                            .white, // 🔹 White for normal stock
                                  borderRadius: BorderRadius.circular(12),
                                  border: isLowStock && hasStock
                                      ? Border.all(
                                          color: Colors.orange[700]!,
                                          width: 2,
                                        )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  hasStock ? Icons.fastfood : Icons.block,
                                  color: !hasStock
                                      ? Colors.white
                                      : isLowStock
                                      ? Colors.orange[900]
                                      : const Color(0xFFB83D2A),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: 70,
                                child: Text(
                                  item.displayName,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    height: 1.1,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'RM ${item.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          // 🔹 Stock status badge
                          if (!hasStock)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'OUT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          else if (isLowStock)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[700],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'LOW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Current Order List
            if (orderItems.isNotEmpty && pendingItem == null)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFB83D2A),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.receipt_long,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Current Order',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'RM ${totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: orderItems.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final item = orderItems[index];
                            final itemPrice = calculateItemPrice(item);
                            return Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.fastfood,
                                    color: Colors.orange,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item.name} (${_getCategoryForItem(item.name)})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (item.addOns.isNotEmpty)
                                        Text(
                                          '+ ${item.addOns.join(', ')}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      Text(
                                        'RM ${itemPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFB83D2A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => removeFromOrder(index),
                                  icon: const Icon(Icons.remove_circle),
                                  color: AppColors.quantity,
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => increaseQuantity(index),
                                  icon: const Icon(Icons.add_circle),
                                  color: AppColors.quantity,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (orderItems.isEmpty && pendingItem == null) const Spacer(),

            // Order Notes Section
            if (pendingItem == null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.note_alt_outlined,
                          color: Color(0xFFB83D2A),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Order Notes (Optional)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB83D2A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'e.g., Extra spicy, no onions, etc.',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFB83D2A),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ],
                ),
              ),

            // Complete Order button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: orderItems.isEmpty ? null : _completeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB83D2A),
                    disabledBackgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    orderItems.isEmpty
                        ? 'No Items Added'
                        : 'Complete Order (${orderItems.length} items) - RM ${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Add-ons selection
          if (pendingItem != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Select Add-Ons (Optional)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: addOns.length,
                  itemBuilder: (context, index) {
                    final addOn = addOns[index];
                    final isSelected = pendingItem!.addOns.contains(addOn.name);
                    final isNone = addOn.name == 'None';

                    // 🔹 Check add-on stock
                    final hasStock = _hasAddOnStock(addOn.name);
                    final isLowStock = _isAddOnLowStock(addOn.name);

                    return Opacity(
                      opacity: (hasStock || isNone)
                          ? 1.0
                          : 0.5, // 🔹 Dim out of stock
                      child: GestureDetector(
                        onTap: (hasStock || isNone)
                            ? () {
                                if (isNone) {
                                  setState(() {
                                    pendingItem!.addOns.clear();
                                  });
                                } else {
                                  if (isSelected) {
                                    removeAddOn(addOn.name);
                                  } else {
                                    addAddOn(addOn.name);
                                  }
                                }
                              }
                            : null, // 🔹 Disable if no stock
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                Container(
                                  height: 65,
                                  width: 65,
                                  decoration: BoxDecoration(
                                    color: !hasStock && !isNone
                                        ? Colors
                                              .grey[400] // 🔹 Grey for out of stock
                                        : isLowStock && !isNone
                                        ? Colors
                                              .orange // 🔹 Orange for low stock
                                        : isSelected
                                        ? Colors.white
                                        : const Color(0xFFB83D2A),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isLowStock && hasStock && !isNone
                                          ? Colors.orange[700]!
                                          : Colors.white,
                                      width: isSelected ? 3 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    !hasStock && !isNone
                                        ? Icons.block
                                        : isSelected || isNone
                                        ? Icons.check_circle
                                        : Icons.add_circle_outline,
                                    color: !hasStock && !isNone
                                        ? Colors.white
                                        : isLowStock && !isNone
                                        ? Colors.orange[900]
                                        : isSelected
                                        ? const Color(0xFFB83D2A)
                                        : Colors.white,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Flexible(
                                  child: Text(
                                    addOn.displayName,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      height: 1.1,
                                      color: Colors.white,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (!isNone)
                                  Text(
                                    '+${addOn.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            // 🔹 Stock status badge for add-ons
                            if (!hasStock && !isNone)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'OUT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            else if (isLowStock && !isNone)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[700],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'LOW',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  String _getCategoryForItem(String itemName) {
    final menuItem = menuItems.firstWhere(
      (item) => item.name == itemName,
      orElse: () => MenuItem('Unknown', 'Unknown', 0.0),
    );
    return menuItem.category;
  }
}

class OrderItem {
  String name;
  int quantity;
  List<String> addOns;
  double basePrice;

  OrderItem(this.name, this.quantity, this.addOns, this.basePrice);
}

class MenuItem {
  final String name;
  final String category;
  final double price;
  String get displayName => name;

  MenuItem(this.name, this.category, this.price);
}

class AddOn {
  final String name;
  final String displayName;
  final double price;

  AddOn(this.name, this.displayName, this.price);
}
