import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/routes.dart';
import 'package:myakieburger/domains/ingredients_model.dart';
import 'package:myakieburger/services/auth_service.dart';

class BalancedIngredients extends StatefulWidget {
  const BalancedIngredients({super.key});

  @override
  State<BalancedIngredients> createState() => _BalancedIngredientsState();
}

class _BalancedIngredientsState extends State<BalancedIngredients> {
  String? franchiseeId;
  bool isLoading = true;

  // 🔹 Minimum threshold map for each ingredient
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

  @override
  void initState() {
    super.initState();
    _loadFranchiseeId();
  }

  Future<void> _loadFranchiseeId() async {
    final id = await getLoggedInUserId();
    setState(() {
      franchiseeId = id;
      isLoading = false;
    });
  }

  // 🔹 Check if ingredient is low on stock
  bool _isLowStock(String ingredientName, int balance) {
    final threshold = ingredientMinimumThreshold[ingredientName] ?? 5;
    return balance <= threshold;
  }

  // 🔹 Get appropriate color based on stock level
  Color _getStockLevelColor(String ingredientName, int balance) {
    final threshold = ingredientMinimumThreshold[ingredientName] ?? 5;

    if (balance == 0) {
      return Colors.red[900]!; // Out of stock - darkest red
    } else if (balance <= threshold) {
      return Colors.red[600]!; // Low stock - red
    }
    return Colors.black87; // Normal stock
  }

  // 🔹 Get background color for low stock items
  Color? _getBackgroundColor(String ingredientName, int balance) {
    final threshold = ingredientMinimumThreshold[ingredientName] ?? 5;

    if (balance == 0) {
      return Colors.red[100]; // Out of stock background
    } else if (balance <= threshold) {
      return Colors.orange[50]; // Low stock background
    }
    return null; // Normal stock - no background
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryRed,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Balanced Ingredients',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, Routes.editIngredients);
            },
            child: const Text(
              'Edit',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : franchiseeId == null
          ? const Center(
              child: Text(
                'User not logged in.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(franchiseeId)
                      .collection('ingredients')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No ingredients found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;
                    final ingredients = docs
                        .map(
                          (doc) => IngredientModel.fromMap(
                            doc.id,
                            doc.data() as Map<String, dynamic>,
                          ),
                        )
                        .toList();

                    return Column(
                      children: [
                        // Legend/Info Section
                        // Container(
                        //   padding: const EdgeInsets.all(12),
                        //   margin: const EdgeInsets.all(12),
                        //   decoration: BoxDecoration(
                        //     color: Colors.grey[100],
                        //     borderRadius: BorderRadius.circular(8),
                        //     border: Border.all(color: Colors.grey[300]!),
                        //   ),
                        //   child: Row(
                        //     mainAxisAlignment: MainAxisAlignment.spaceAround,
                        //     children: [
                        //       _buildLegendItem(
                        //         Colors.red[900]!,
                        //         'Out of Stock',
                        //         Icons.close_rounded,
                        //       ),
                        //       _buildLegendItem(
                        //         Colors.red[600]!,
                        //         'Low Stock',
                        //         Icons.warning_amber_rounded,
                        //       ),
                        //       _buildLegendItem(
                        //         Colors.green[600]!,
                        //         'Normal',
                        //         Icons.check_circle_rounded,
                        //       ),
                        //     ],
                        //   ),
                        // ),

                        // Ingredients List
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: ingredients.length + 1,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1, color: Colors.black54),
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Ingredients Name',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'Balance',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final item = ingredients[index - 1];
                              final isLow = _isLowStock(
                                item.name,
                                item.balance,
                              );
                              final textColor = _getStockLevelColor(
                                item.name,
                                item.balance,
                              );
                              final bgColor = _getBackgroundColor(
                                item.name,
                                item.balance,
                              );

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          // Warning icon for low/out of stock
                                          if (isLow)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 8.0,
                                              ),
                                              child: Icon(
                                                item.balance == 0
                                                    ? Icons.error
                                                    : Icons
                                                          .warning_amber_rounded,
                                                color: textColor,
                                                size: 20,
                                              ),
                                            ),
                                          Expanded(
                                            child: Text(
                                              item.name,
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: textColor,
                                                fontWeight: isLow
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isLow
                                            ? textColor.withOpacity(0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: isLow
                                            ? Border.all(
                                                color: textColor,
                                                width: 1.5,
                                              )
                                            : null,
                                      ),
                                      child: Text(
                                        item.balance.toString(),
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: textColor,
                                          fontWeight: isLow
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }

  // 🔹 Build legend item widget
  Widget _buildLegendItem(Color color, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
