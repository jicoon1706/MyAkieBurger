import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/widgets/custom_snackbar.dart';

class EditIngredients extends StatefulWidget {
  const EditIngredients({super.key});

  @override
  State<EditIngredients> createState() => _EditIngredientsState();
}

class _EditIngredientsState extends State<EditIngredients> {
  final List<Map<String, dynamic>> ingredients = [
    {
      'name': 'Roti (pieces)',
      'received': 999,
      'balanced': 30,
      'damaged': 50,
      'eat': 0,
      'used': 70,
    },
    {
      'name': 'Daging (80g)',
      'received': 100,
      'balanced': 30,
      'damaged': 0,
      'eat': 60,
      'used': 70,
    },
    {
      'name': 'Ayam (80g)',
      'received': 100,
      'balanced': 30,
      'damaged': 0,
      'eat': 0,
      'used': 70,
    },
    {
      'name': 'Daging Smoky (100g)',
      'received': 100,
      'balanced': 30,
      'damaged': 0,
      'eat': 0,
      'used': 70,
    },
    {
      'name': 'Kambing (70g)',
      'received': 100,
      'balanced': 30,
      'damaged': 0,
      'eat': 0,
      'used': 70,
    },
    {
      'name': 'Rusa',
      'received': 100,
      'balanced': 30,
      'damaged': 0,
      'eat': 0,
      'used': 70,
    },
    {
      'name': 'Arnab',
      'received': 100,
      'balanced': 30,
      'damaged': 0,
      'eat': 0,
      'used': 70,
    },
    {
      'name': 'Itik',
      'received': 100,
      'balanced': 30,
      'damaged': 0,
      'eat': 0,
      'used': 70,
    },
    {
      'name': 'Roti Hotdog',
      'received': 100,
      'balanced': 30,
      'damaged': 0,
      'eat': 0,
      'used': 70,
    },
    {
      'name': 'Sosej',
      'received': 100,
      'balanced': 30,
      'damaged': 0,
      'eat': 0,
      'used': 70,
    },
    {
      'name': 'Roti Oblong',
      'received': 100,
      'balanced': 30,
      'damaged': 0,
      'eat': 0,
      'used': 70,
    },
    {
      'name': 'Kambing Oblong',
      'received': 100,
      'balanced': 30,
      'damaged': 10,
      'eat': 10,
      'used': 70,
    },
    {
      'name': 'Ayam Oblong',
      'received': 100,
      'balanced': 30,
      'damaged': 10,
      'eat': 10,
      'used': 70,
    },
    {
      'name': 'Daging Oblong',
      'received': 100,
      'balanced': 30,
      'damaged': 0,
      'eat': 0,
      'used': 70,
    },
    {
      'name': 'Cheese (pieces)',
      'received': 100,
      'balanced': 30,
      'damaged': 2,
      'eat': 0,
      'used': 70,
    },
    {
      'name': 'Telur',
      'received': 100,
      'balanced': 30,
      'damaged': 0,
      'eat': 4,
      'used': 70,
    },
    {
      'name': 'Benjo',
      'received': 100,
      'balanced': 30,
      'damaged': 0,
      'eat': 30,
      'used': 70,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryRed,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Ingredients',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                CustomSnackbar.show(
                  context,
                  message: 'Changes saved successfully!',
                );
              },

              label: const Text(
                'Confirm',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.primaryRed,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Column headers with icons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 105,
                    child: Row(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 18,
                          color: Colors.black87,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Ingredients',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildHeaderCell(
                    Icons.arrow_downward_rounded,
                    'Received',
                    Colors.blue[600]!,
                  ),
                  _buildHeaderCell(
                    Icons.balance,
                    'Balanced',
                    Colors.purple[600]!,
                  ),
                  _buildHeaderCell(
                    Icons.warning_rounded,
                    'Damaged',
                    Colors.red[600]!,
                  ),
                  _buildHeaderCell(
                    Icons.restaurant,
                    'Eat',
                    Colors.orange[600]!,
                  ),
                  _buildHeaderCell(
                    Icons.check_circle,
                    'Used',
                    Colors.green[600]!,
                  ),
                ],
              ),
            ),

            // Scrollable ingredients list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: ingredients.length,
                itemBuilder: (context, index) {
                  final item = ingredients[index];
                  final isEven = index % 2 == 0;

                  return Container(
                    decoration: BoxDecoration(
                      color: isEven ? Colors.white : Colors.grey[50],
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                          width: 0.5,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 105,
                          child: Text(
                            item['name'],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildValueCell(
                          item['received'],
                          Colors.blue[600]!,
                          Icons.arrow_downward_rounded,
                        ),
                        _buildValueCell(
                          item['balanced'],
                          Colors.purple[600]!,
                          Icons.balance,
                        ),
                        _buildValueCell(
                          item['damaged'],
                          Colors.red[600]!,
                          Icons.warning_rounded,
                        ),
                        _buildValueCell(
                          item['eat'],
                          Colors.orange[600]!,
                          Icons.restaurant,
                        ),
                        _buildValueCell(
                          item['used'],
                          Colors.green[600]!,
                          Icons.check_circle,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(IconData icon, String label, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCell(int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 2,
          horizontal: 2,
        ), // 👈 add spacing
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: value > 0 ? color.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            value.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: value > 0 ? color : Colors.grey[400],
              fontWeight: value > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
