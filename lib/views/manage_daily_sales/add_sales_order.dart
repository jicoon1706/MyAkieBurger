import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';

class AddSalesOrder extends StatefulWidget {
  const AddSalesOrder({super.key});

  @override
  State<AddSalesOrder> createState() => _AddSalesOrderState();
}

class _AddSalesOrderState extends State<AddSalesOrder> {
  String selectedCategory = 'Chicken';
  List<OrderItem> orderItems = [];

  final List<String> categories = ['Chicken', 'Meat', 'Benjo', 'Others'];

  final List<MenuItem> menuItems = [
    MenuItem('Biasa', 'Chicken'),
    MenuItem('Special', 'Chicken'),
    MenuItem('Double', 'Chicken'),
    MenuItem('D. Special', 'Chicken'),
    MenuItem('Oblong', 'Chicken'),
    MenuItem('Hotdog', 'Chicken'),
    MenuItem('H. Special', 'Chicken'),
  ];

  final List<AddOn> addOns = [
    AddOn('Daging', 'Daging'),
    AddOn('Ayam', 'Ayam'),
    AddOn('D. Smokey', 'D. Smokey'),
    AddOn('Exotic', 'Exotic'),
    AddOn('Daging Oblong', 'Daging\nOblong'),
    AddOn('Ayam Oblong', 'Ayam\nOblong'),
    AddOn('Sosej', 'Sosej'),
  ];

  void addToOrder(String itemName) {
    setState(() {
      final existingIndex = orderItems.indexWhere(
        (item) => item.name == itemName,
      );
      if (existingIndex >= 0) {
        orderItems[existingIndex].quantity++;
      } else {
        orderItems.add(OrderItem(itemName, 1));
      }
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

          // Order list
          if (orderItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: orderItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.orange[100],
                          child: const Icon(
                            Icons.fastfood,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (item.addOns.isNotEmpty)
                                Text(
                                  item.addOns.join(', '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => removeFromOrder(index),
                          icon: const Icon(
                            Icons.remove_circle,
                            color: AppColors.quantity,
                          ),
                          iconSize: 28,
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
                          icon: const Icon(
                            Icons.add_circle,
                            color: AppColors.quantity,
                          ),
                          iconSize: 28,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // Category tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

          // Menu items grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.68, // smaller ratio = taller cells
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => addToOrder(item.name),
                      child: Container(
                        height: 52, // ⬆️ increased box height
                        width: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.fastfood,
                          color: Color(0xFFB83D2A),
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Text(
                        item.displayName,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Add-On section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add-On',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Add-ons grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.68,
              ),
              itemCount: addOns.length,
              itemBuilder: (context, index) {
                final addOn = addOns[index];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Add-on tap logic
                      },
                      child: Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_circle_outline,
                          color: Color(0xFFB83D2A),
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Text(
                        addOn.displayName,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const Spacer(),

          // Add Order button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Add order logic
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB83D2A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Add Order',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderItem {
  String name;
  int quantity;
  List<String> addOns;

  OrderItem(this.name, this.quantity, [this.addOns = const []]);
}

class MenuItem {
  final String name;
  final String category;
  String get displayName => name;

  MenuItem(this.name, this.category);
}

class AddOn {
  final String name;
  final String displayName;

  AddOn(this.name, this.displayName);
}
