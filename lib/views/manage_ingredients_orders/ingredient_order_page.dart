import 'package:flutter/material.dart';

class IngredientOrderPage extends StatefulWidget {
  const IngredientOrderPage({super.key});

  @override
  State<IngredientOrderPage> createState() => _IngredientOrderPageState();
}

class _IngredientOrderPageState extends State<IngredientOrderPage> {
  int _selectedIndex = 1; // Orders tab is selected

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
  ];

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

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate based on selected tab
    if (index == 0) {
      Navigator.pop(context); // Go back to home
    }
    // TODO: Add navigation for other tabs
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B2E1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B2E1F),
        elevation: 0,
        leading: const SizedBox(), // No back button
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
                icon: const Icon(Icons.history, color: Color(0xFF8B2E1F)),
                onPressed: () {
                  // TODO: Navigate to order history
                },
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
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
                      style: TextStyle(fontSize: 10, color: Colors.grey[700]),
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
                              color: Color(0xFFB83D2A),
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
                              color: Color(0xFFB83D2A),
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
                        'Max:${ingredient['max']}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFB83D2A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 28),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description, size: 28),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add, size: 32),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2, size: 28),
            label: 'Balance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit, size: 28),
            label: 'Edit',
          ),
        ],
      ),
    );
  }
}
