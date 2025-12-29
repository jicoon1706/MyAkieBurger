import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/widgets/custom_snackbar.dart';
import 'package:myakieburger/domains/ingredients_model.dart';
import 'package:myakieburger/providers/ingredients_controller.dart';
import 'package:myakieburger/services/auth_service.dart';
import 'package:myakieburger/widgets/custom_loading_dialog.dart';

class EditIngredients extends StatefulWidget {
  const EditIngredients({super.key});

  @override
  State<EditIngredients> createState() => _EditIngredientsState();
}

class _EditIngredientsState extends State<EditIngredients> {
  final IngredientsController _controller = IngredientsController();
  String? franchiseeId;
  bool isLoading = true;
  List<IngredientModel> ingredients = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _saveAll() async {
    if (franchiseeId == null) return;

    // Show loading dialog
    CustomLoadingDialog.show(context, message: 'Updating Ingredients...');

    try {
      for (var item in ingredients) {
        await _controller.updateIngredient(franchiseeId!, item);
      }

      // Close the loading dialog
      CustomLoadingDialog.hide(context);

      if (mounted) {
        Navigator.pop(context);
        CustomSnackbar.show(
          context,
          message: 'Ingredients updated successfully!',
        );
      }
    } catch (e) {
      // Hide loading dialog on error
      CustomLoadingDialog.hide(context);

      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Failed to update ingredients: $e',
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
      }
    }
  }

  Future<void> _initializeData() async {
    final id = await getLoggedInUserId();
    if (id != null) {
      final fetched = await _controller.getIngredients(id);
      setState(() {
        franchiseeId = id;
        ingredients = fetched;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _recalculateBalanced(int index) {
  final item = ingredients[index];
  final received = item.received;
  final damaged = item.damaged;
  final eat = item.eat;
  final used = item.used;

  // Fixed formula: received - damaged - eat - used = balanced
  // Ensure balance cannot be negative
  final balanced = received - damaged - eat - used;
  setState(() {
    ingredients[index] = IngredientModel(
      id: item.id,
      name: item.name,
      price: item.price,
      received: item.received,
      used: item.used,
      damaged: item.damaged,
      eat: item.eat,
      balance: balanced < 0 ? 0 : balanced, // ✅ Already preventing negative
      updatedAt: item.updatedAt,
    );
  });
}

  void _editValue(BuildContext context, int index, String fieldName) {
  final controller = TextEditingController(
    text: _getFieldValue(index, fieldName).toString(),
  );

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          'Edit ${fieldName[0].toUpperCase()}${fieldName.substring(1)}',
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Enter new value',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newValue = int.tryParse(controller.text) ?? 0;
              
              // ✅ Prevent negative values
              if (newValue < 0) {
                CustomSnackbar.show(
                  context,
                  message: 'Value cannot be negative!',
                  backgroundColor: Colors.red,
                  icon: Icons.error_outline,
                );
                return;
              }

              // ✅ Check if the new value would cause negative balance
              final item = ingredients[index];
              int potentialBalance = 0;
              
              switch (fieldName) {
                case 'received':
                  potentialBalance = newValue - item.damaged - item.eat - item.used;
                  break;
                case 'damaged':
                  potentialBalance = item.received - newValue - item.eat - item.used;
                  break;
                case 'eat':
                  potentialBalance = item.received - item.damaged - newValue - item.used;
                  break;
                case 'used':
                  potentialBalance = item.received - item.damaged - item.eat - newValue;
                  break;
              }

              // ✅ Warn if balance would be negative
              if (potentialBalance < 0) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Warning'),
                    content: Text(
                      'This change would result in a negative balance (${potentialBalance}).\n\n'
                      'The balance will be set to 0. Do you want to continue?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx); // Close warning dialog
                          setState(() {
                            ingredients[index] = _updateField(index, fieldName, newValue);
                          });
                          _recalculateBalanced(index);
                          Navigator.pop(context); // Close edit dialog
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
                );
                return;
              }

              // Normal save
              setState(() {
                ingredients[index] = _updateField(index, fieldName, newValue);
              });
              _recalculateBalanced(index);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

  int _getFieldValue(int index, String fieldName) {
    final item = ingredients[index];
    switch (fieldName) {
      case 'received':
        return item.received;
      case 'damaged':
        return item.damaged;
      case 'eat':
        return item.eat;
      case 'used':
        return item.used;
      default:
        return 0;
    }
  }

  IngredientModel _updateField(int index, String fieldName, int newValue) {
    final item = ingredients[index];
    return IngredientModel(
      id: item.id,
      name: item.name,
      price: item.price,
      received: fieldName == 'received' ? newValue : item.received,
      used: fieldName == 'used' ? newValue : item.used,
      damaged: fieldName == 'damaged' ? newValue : item.damaged,
      eat: fieldName == 'eat' ? newValue : item.eat,
      balance: item.balance,
      updatedAt: item.updatedAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
      );
    }

    if (franchiseeId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'User not logged in.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

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
              onPressed: _saveAll,
              icon: const Icon(
                Icons.check,
                color: AppColors.primaryRed,
                size: 18,
              ),
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
        child: ingredients.isEmpty
            ? const Center(child: Text('No ingredients found.'))
            : Column(
                children: [
                  _buildHeaderRow(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: ingredients.length,
                      itemBuilder: (context, index) {
                        final item = ingredients[index];
                        final isEven = index % 2 == 0;
                        return Container(
                          color: isEven ? Colors.white : Colors.grey[50],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 105,
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              _buildEditableCell(
                                index,
                                'received',
                                Colors.blue[600]!,
                              ),
                              _buildValueCell(
                                item.balance,
                                Colors.purple[600]!,
                              ),
                              _buildEditableCell(
                                index,
                                'damaged',
                                Colors.red[600]!,
                              ),
                              _buildEditableCell(
                                index,
                                'eat',
                                Colors.orange[600]!,
                              ),
                              _buildEditableCell(
                                index,
                                'used',
                                Colors.green[600]!,
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

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 105,
            child: Text(
              'Ingredients',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Colors.black87,
              ),
            ),
          ),
          _buildHeaderCell('Received', Colors.blue[600]!),
          _buildHeaderCell('Balanced', Colors.purple[600]!),
          _buildHeaderCell('Damaged', Colors.red[600]!),
          _buildHeaderCell('Eat', Colors.orange[600]!),
          _buildHeaderCell('Used', Colors.green[600]!),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.edit, size: 14, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
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

  Widget _buildEditableCell(int index, String fieldName, Color color) {
    final value = _getFieldValue(index, fieldName);
    return Expanded(
      child: GestureDetector(
        onTap: () => _editValue(context, index, fieldName),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValueCell(int value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            value.toString(),
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
