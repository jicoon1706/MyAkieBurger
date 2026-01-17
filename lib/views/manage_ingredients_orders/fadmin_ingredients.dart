import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/providers/ingredients_inventory_controller.dart';

class FadminIngredients extends StatefulWidget {
  const FadminIngredients({super.key});

  @override
  State<FadminIngredients> createState() => _FadminIngredientsState();
}

class _FadminIngredientsState extends State<FadminIngredients> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'patty', 'addon', 'other'];

  final IngredientsInventoryController _inventoryController =
      IngredientsInventoryController();

  Future<void> _onRefresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.factoryBlue,
      appBar: AppBar(
        backgroundColor: AppColors.factoryBlue,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Factory Ingredients',
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
                icon: const Icon(Icons.refresh, color: AppColors.factoryBlue),
                onPressed: () => setState(() {}),
                tooltip: 'Refresh',
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Colors.white,
        backgroundColor: AppColors.factoryBlue,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Category Filter Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter by Category',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((category) {
                          final isSelected = _selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.factoryBlue
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                              backgroundColor: Colors.grey[800],
                              selectedColor: Colors.white,
                              checkmarkColor: AppColors.factoryBlue,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Ingredients Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ingredient Inventory',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Ingredients List
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('ingredients')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 60,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading ingredients',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No ingredients found',
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }

                          // Filter ingredients by category
                          final allIngredients = snapshot.data!.docs;
                          final filteredIngredients = _selectedCategory == 'All'
                              ? allIngredients
                              : allIngredients.where((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  return data['category'] == _selectedCategory;
                                }).toList();

                          if (filteredIngredients.isEmpty) {
                            return Center(
                              child: Text(
                                'No $_selectedCategory ingredients',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: filteredIngredients.length,
                            itemBuilder: (context, index) {
                              final doc = filteredIngredients[index];
                              final data = doc.data() as Map<String, dynamic>;

                              final name = data['name'] ?? 'Unknown';
                              final category = data['category'] ?? 'other';
                              final available = data['available'] ?? 0;
                              final maxOrder = data['max_order'] ?? 0;
                              final unitPrice = (data['unit_price'] ?? 0.0)
                                  .toDouble();
                              final image = data['image'] ?? '';

                              // Stock status
                              final stockPercentage = maxOrder > 0
                                  ? (available / maxOrder)
                                  : 0.0;
                              Color stockColor;
                              String stockStatus;

                              if (stockPercentage > 0.5) {
                                stockColor = Colors.green;
                                stockStatus = 'In Stock';
                              } else if (stockPercentage > 0.2) {
                                stockColor = Colors.orange;
                                stockStatus = 'Low Stock';
                              } else {
                                stockColor = Colors.red;
                                stockStatus = 'Critical';
                              }

                              return GestureDetector(
                                onTap: () {
                                  _showIngredientDetails(
                                    context,
                                    doc.id,
                                    name,
                                    category,
                                    available,
                                    maxOrder,
                                    unitPrice,
                                    image,
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Image
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          shape: BoxShape.circle,
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            image,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.inventory_2,
                                                    size: 35,
                                                    color:
                                                        AppColors.factoryBlue,
                                                  );
                                                },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors
                                                        .lightBlueAccent
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    category.toUpperCase(),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppColors.factoryBlue,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  Icons.circle,
                                                  size: 8,
                                                  color: stockColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  stockStatus,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: stockColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Stock and Price
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'RM ${unitPrice.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$available units',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIngredientDetails(
    BuildContext context,
    String id,
    String name,
    String category,
    int available,
    int maxOrder,
    double unitPrice,
    String image,
  ) {
    // Controllers for the editable fields
    final availableController = TextEditingController(
      text: available.toString(),
    );
    final maxOrderController = TextEditingController(text: maxOrder.toString());
    final unitPriceController = TextEditingController(
      text: unitPrice.toStringAsFixed(2),
    );

    // Stock status calculation (kept for UI presentation)
    final stockPercentage = maxOrder > 0 ? (available / maxOrder) : 0.0;
    Color stockColor;
    String stockStatus;
    IconData statusIcon;

    if (stockPercentage > 0.5) {
      stockColor = Colors.green;
      stockStatus = 'In Stock';
      statusIcon = Icons.check_circle;
    } else if (stockPercentage > 0.2) {
      stockColor = Colors.orange;
      stockStatus = 'Low Stock';
      statusIcon = Icons.warning;
    } else {
      stockColor = Colors.red;
      stockStatus = 'Critical';
      statusIcon = Icons.error;
    }

    // Function to handle the actual update
    Future<void> _handleUpdate() async {
      try {
        final newAvailable = int.tryParse(availableController.text) ?? 0;
        final newMaxOrder = int.tryParse(maxOrderController.text) ?? 0;
        final newUnitPrice = double.tryParse(unitPriceController.text) ?? 0.0;

        if (newAvailable < 0 || newMaxOrder <= 0 || newUnitPrice <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error: All values must be positive numbers."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Call the controller function to update Firestore
        await _inventoryController.updateIngredientDetails(
          id,
          newAvailable,
          newMaxOrder,
          newUnitPrice,
        );

        // Close the dialog and refresh the list
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${name} updated successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          _onRefresh(); // Trigger list reload
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to update: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.factoryBlue,
                AppColors.factoryBlue.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ingredient Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // White content container
              Flexible(
                // Use Flexible around the scroll view to prevent unbounded height
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Image with elevated shadow (unchanged)
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.factoryBlue.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              image,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.inventory_2,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Name and Category (unchanged)
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightBlueAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.factoryBlue,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- EDITABLE FIELDS ---

                        // 1. Available Units Field
                        _buildEditableField(
                          'Available Units',
                          availableController,
                          TextInputType.number,
                          'Current Stock',
                          Icons.warehouse,
                        ),
                        const SizedBox(height: 16),

                        // 2. Max Capacity Field
                        _buildEditableField(
                          'Max Capacity',
                          maxOrderController,
                          TextInputType.number,
                          'Max Order Limit',
                          Icons.storage,
                        ),
                        const SizedBox(height: 16),

                        // 3. Unit Price Field
                        _buildEditableField(
                          'Unit Price (RM)',
                          unitPriceController,
                          const TextInputType.numberWithOptions(decimal: true),
                          'Price per unit',
                          Icons.currency_exchange,
                        ),
                        const SizedBox(height: 24),

                        // Stock Status Card (unchanged)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                stockColor.withOpacity(0.1),
                                stockColor.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: stockColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: stockColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  statusIcon,
                                  color: stockColor,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stockStatus,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: stockColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      // Displaying the *original* available value here,
                                      // but the new value will update on refresh.
                                      '$available units (Original)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons (Updated onPressed for EDIT)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  side: const BorderSide(
                                    color: AppColors.factoryBlue,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'CANCEL',
                                  style: TextStyle(
                                    color: AppColors.factoryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    _handleUpdate, // CALL THE UPDATE FUNCTION
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.factoryBlue,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'SAVE CHANGES', // Changed text for clarity
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // NEW HELPER WIDGET FOR EDITABLE FIELDS
  // --------------------------------------------------------------------------
  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    TextInputType keyboardType,
    String hintText,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppColors.factoryBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.factoryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
