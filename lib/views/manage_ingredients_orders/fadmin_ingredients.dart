import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppColors {
  static const Color factoryBlue = Color(0xFF0D47A1);
  static const Color lightBlueAccent = Color(0xFF64B5F6);
  static const Color white = Colors.white;
}

class FadminIngredients extends StatefulWidget {
  const FadminIngredients({super.key});

  @override
  State<FadminIngredients> createState() => _FadminIngredientsState();
}

class _FadminIngredientsState extends State<FadminIngredients> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'patty', 'addon', 'other'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Factory Ingredients Inventory",
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.factoryBlue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.factoryBlue,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
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
                              ? AppColors.white
                              : AppColors.factoryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      backgroundColor: AppColors.white,
                      selectedColor: AppColors.lightBlueAccent,
                      checkmarkColor: AppColors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Ingredients List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('ingredients').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.factoryBlue,
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
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ingredients found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter ingredients by category
                final allIngredients = snapshot.data!.docs;
                final filteredIngredients = _selectedCategory == 'All'
                    ? allIngredients
                    : allIngredients.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['category'] == _selectedCategory;
                      }).toList();

                if (filteredIngredients.isEmpty) {
                  return Center(
                    child: Text(
                      'No $_selectedCategory ingredients',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredIngredients.length,
                  itemBuilder: (context, index) {
                    final doc = filteredIngredients[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final name = data['name'] ?? 'Unknown';
                    final category = data['category'] ?? 'other';
                    final available = data['available'] ?? 0;
                    final maxOrder = data['max_order'] ?? 0;
                    final unitPrice = (data['unit_price'] ?? 0.0).toDouble();
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

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
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
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Image
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.fastfood,
                                        size: 40,
                                        color: Colors.grey,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.lightBlueAccent
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            category.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.factoryBlue,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'RM ${unitPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.inventory,
                                          size: 16,
                                          color: stockColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$available / $maxOrder',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: stockColor,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: stockColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            stockStatus,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: stockColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Arrow Icon
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.factoryBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.fastfood,
                        size: 60,
                        color: Colors.grey,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('ID', id),
            _buildDetailRow('Category', category.toUpperCase()),
            _buildDetailRow('Available Stock', '$available units'),
            _buildDetailRow('Max Order', '$maxOrder units'),
            _buildDetailRow('Unit Price', 'RM ${unitPrice.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CLOSE',
              style: TextStyle(
                color: AppColors.factoryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
