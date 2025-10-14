import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myakieburger/providers/user_controller.dart';
import 'package:myakieburger/domains/user_model.dart';
import 'package:myakieburger/providers/meal_order_controller.dart';
import 'package:myakieburger/domains/meal_order_model.dart';

class AddMealOrder extends StatefulWidget {
  const AddMealOrder({super.key});

  @override
  State<AddMealOrder> createState() => _AddMealOrderState();
}

class _AddMealOrderState extends State<AddMealOrder> {
  String selectedCategory = 'Chicken';
  String? franchiseeId;
  String? franchiseeName;
  List<OrderItem> orderItems = [];
  OrderItem? pendingItem;
  final TextEditingController notesController = TextEditingController();

  final List<String> categories = ['Chicken', 'Meat', 'Exotic', 'Others'];

  final List<MenuItem> menuItems = [
    // 🐔 Chicken
    MenuItem('Biasa', 'Chicken', 4.00),
    MenuItem('Special', 'Chicken', 5.20),
    MenuItem('Double', 'Chicken', 6.00),
    MenuItem('D. Special', 'Chicken', 7.20),
    MenuItem('Oblong', 'Chicken', 6.50),

    // 🥩 Meat
    MenuItem('Biasa', 'Meat', 4.00),
    MenuItem('Special', 'Meat', 5.20),
    MenuItem('Double', 'Meat', 6.00),
    MenuItem('D. Special', 'Meat', 7.20),
    MenuItem('Oblong', 'Meat', 6.50),

    // 🐗 Exotic (was Benjo)
    MenuItem('Rusa', 'Exotic', 5.00),
    MenuItem('Arnab', 'Exotic', 5.00),
    MenuItem('Kambing', 'Exotic', 5.00),
    MenuItem('Burung Unta', 'Exotic', 5.00),

    // 🍔 Others
    MenuItem('Oblong Kambing', 'Others', 8.50),
    MenuItem('Hotdog', 'Others', 2.50),
    MenuItem('Hotdog Special', 'Others', 3.70),
    MenuItem('Benjo', 'Others', 2.80),
  ];

  final List<AddOn> addOns = [
    AddOn('None', 'No Add-On', 0.00),
    AddOn('Daging', 'Daging', 2.40),
    AddOn('Ayam', 'Ayam', 2.40),
    AddOn('Sosej', 'Sosej', 1.50),
    AddOn('Cheese', 'Cheese', 1.50),
    AddOn('Telur', 'Telur', 1.20),
  ];

  @override
  void initState() {
    super.initState();
    _loadFranchiseeInfo(); // ✅ Load user info when widget is initialized
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _loadFranchiseeInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('franchiseeId');
    if (savedId != null) {
      final userController = UserController();
      final user = await userController.getUserById(savedId);
      if (user != null) {
        setState(() {
          franchiseeId = user.id;
          franchiseeName = user.stallName;
        });
      }
    }
  }

  void selectMenuItem(String itemName) {
    final menuItem = menuItems.firstWhere((item) => item.name == itemName);
    setState(() {
      pendingItem = OrderItem(itemName, 1, [], menuItem.price);
    });
  }

  void addAddOn(String addOnName) {
    if (pendingItem != null && addOnName != 'None') {
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

  @override
  Widget build(BuildContext context) {
    final totalPrice = calculateTotalPrice();

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
                  return GestureDetector(
                    onTap: () => selectMenuItem(item.name),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 55,
                          width: 55,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.fastfood,
                            color: Color(0xFFB83D2A),
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
                    Row(
                      children: [
                        Icon(
                          Icons.note_alt_outlined,
                          color: const Color(0xFFB83D2A),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
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
                  onPressed: orderItems.isEmpty || franchiseeId == null
                      ? null
                      : () async {
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

                          await controller.saveMealOrder(
                            franchiseeId!,
                            newOrder,
                          );
                          Navigator.pop(context);
                        },

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

                    return GestureDetector(
                      onTap: () {
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
                      },
                      child: Column(
                        children: [
                          Container(
                            height: 65,
                            width: 65,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFFB83D2A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white,
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
                              isSelected || isNone
                                  ? Icons.check_circle
                                  : Icons.add_circle_outline,
                              color: isSelected
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
