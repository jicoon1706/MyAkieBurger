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
  OrderItem? pendingItem; // For item waiting for add-ons

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
    AddOn('None', 'No Add-On'),
    AddOn('Daging', 'Daging'),
    AddOn('Ayam', 'Ayam'),
    AddOn('D. Smokey', 'D. Smokey'),
    AddOn('Exotic', 'Exotic'),
    AddOn('Daging Oblong', 'Daging\nOblong'),
    AddOn('Ayam Oblong', 'Ayam\nOblong'),
    AddOn('Sosej', 'Sosej'),
  ];

  void selectMenuItem(String itemName) {
    setState(() {
      pendingItem = OrderItem(itemName, 1, []);
    });
  }

  void addAddOn(String addOnName) {
    if (pendingItem != null) {
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

          // Pending item preview (when selecting add-ons)
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
                      Text(
                        'Customizing: ${pendingItem!.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
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
                      children: pendingItem!.addOns.map((addOn) {
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
                                addOn,
                                style: const TextStyle(
                                  color: Color(0xFFB83D2A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => removeAddOn(addOn),
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

            // 🔹 Menu items scroll horizontally
            SizedBox(
              height: 80, // enough height for the icon + label
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: menuItems.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = menuItems[index];
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
                          width: 70, // ensures text wraps nicely
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
                      ],
                    ),
                  );
                },
              ),
            ),

            // 🔽 Move Current Order List here (below menu)
            if (orderItems.isNotEmpty && pendingItem == null)
              Container(
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
                      child: const Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Current Order',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: orderItems.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = orderItems[index];
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
                                      '+ ${item.addOns.join(', ')}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
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
                  ],
                ),
              ),

            const Spacer(),

            // Complete Order button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: orderItems.isEmpty
                      ? null
                      : () {
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
                        : 'Complete Order (${orderItems.length} items)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],

          // When customizing item, show add-ons as active
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
                    childAspectRatio: 0.85,
                  ),
                  itemCount: addOns.length,
                  itemBuilder: (context, index) {
                    final addOn = addOns[index];
                    final isSelected = pendingItem!.addOns.contains(addOn.name);
                    return GestureDetector(
                      onTap: () {
                        if (isSelected) {
                          removeAddOn(addOn.name);
                        } else {
                          addAddOn(addOn.name);
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
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.add_circle_outline,
                              color: isSelected
                                  ? const Color(0xFFB83D2A)
                                  : Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Flexible(
                            child: Text(
                              addOn.displayName,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.1,
                                color: Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
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
