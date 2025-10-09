import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/widgets/custom_snackbar.dart';

class AddReport extends StatefulWidget {
  const AddReport({super.key});

  @override
  State<AddReport> createState() => _AddReportState();
}

class _AddReportState extends State<AddReport> {
  final TextEditingController _franchiseeIdController = TextEditingController(
    text: 'F001',
  );
  final TextEditingController _staffNameController = TextEditingController(
    text: 'Chen',
  );
  final TextEditingController _dateController = TextEditingController(
    text: '24/05/2024',
  );
  final TextEditingController _commentsController = TextEditingController();

  final List<Map<String, dynamic>> menuItems = [
    {
      'name': 'Biasa (Ayam/Daging)',
      'price': 'RM 4.50',
      'quantity': 10,
      'total': 45.00,
    },
    {
      'name': 'Special (Ayam/Daging)',
      'price': 'RM 6.00',
      'quantity': 10,
      'total': 67.00,
    },
    {
      'name': 'Double (Ayam/Daging)',
      'price': 'RM 6.00',
      'quantity': 10,
      'total': 60.00,
    },
    {
      'name': 'Double Special (Ayam/Daging)',
      'price': 'RM 8.00',
      'quantity': 10,
      'total': 80.00,
    },
    {
      'name': 'Oblong (Ayam/Daging)',
      'price': 'RM 7.00',
      'quantity': 10,
      'total': 70.00,
    },
    {
      'name': 'Oblong Kambing',
      'price': 'RM 9.00',
      'quantity': 10,
      'total': 90.00,
    },
    {'name': 'Hotdog', 'price': 'RM 3.00', 'quantity': 10, 'total': 30.00},
    {'name': 'Hotdog', 'price': 'RM 3.00', 'quantity': 10, 'total': 30.00},
    {'name': 'Bendog', 'price': 'RM 8.00', 'quantity': 10, 'total': 80.00},
    {'name': 'Kambing', 'price': 'RM 5.50', 'quantity': 10, 'total': 55.00},
  ];

  final List<Map<String, dynamic>> addOns = [
    {'name': 'Daging/Ayam', 'price': 'RM 3.00', 'quantity': 10, 'total': 30.00},
    {
      'name': 'Daging Smokey',
      'price': 'RM 5.50',
      'quantity': 10,
      'total': 55.00,
    },
    {
      'name': 'Daging Kambing',
      'price': 'RM 4.00',
      'quantity': 10,
      'total': 40.00,
    },
    {
      'name': 'Daging Exotic',
      'price': 'RM 4.00',
      'quantity': 10,
      'total': 40.00,
    },
    {
      'name': 'Daging Oblong',
      'price': 'RM 5.00',
      'quantity': 10,
      'total': 50.00,
    },
    {'name': 'Ayam Oblong', 'price': 'RM 5.00', 'quantity': 10, 'total': 50.00},
    {
      'name': 'Kambing Oblong',
      'price': 'RM 7.50',
      'quantity': 10,
      'total': 75.00,
    },
    {'name': 'Sosej', 'price': 'RM 1.50', 'quantity': 10, 'total': 15.00},
    {'name': 'Telur', 'price': 'RM 1.20', 'quantity': 10, 'total': 12.00},
    {'name': 'Cheese', 'price': 'RM 1.60', 'quantity': 10, 'total': 16.00},
  ];

  final List<Map<String, dynamic>> ingredients = [
    {'name': 'Roti (pieces)', 'stock': 100, 'used': 70, 'balance': 30},
    {'name': 'Daging (80g)', 'stock': 100, 'used': 70, 'balance': 30},
    {'name': 'Ayam (80g)', 'stock': 100, 'used': 70, 'balance': 30},
    {'name': 'Daging Smoky (100g)', 'stock': 100, 'used': 70, 'balance': 30},
    {'name': 'Kambing (70g)', 'stock': 100, 'used': 70, 'balance': 30},
    {'name': 'Rusa', 'stock': 100, 'used': 70, 'balance': 30},
    {'name': 'Arnab', 'stock': 100, 'used': 70, 'balance': 30},
    {'name': 'Itik', 'stock': 100, 'used': 70, 'balance': 30},
    {'name': 'Roti Hotdog', 'stock': 100, 'used': 70, 'balance': 30},
    {'name': 'Sosej', 'stock': 100, 'used': 70, 'balance': 30},
    {'name': 'Roti Oblong', 'stock': 100, 'used': 70, 'balance': 30},
    {'name': 'Kambing Oblong', 'stock': 100, 'used': 70, 'balance': 30},
    {'name': 'Ayam Oblong', 'stock': 100, 'used': 70, 'balance': 30},
    {'name': 'Daging Oblong', 'stock': 100, 'used': 70, 'balance': 30},
    {'name': 'Cheese (pieces)', 'stock': 100, 'used': 70, 'balance': 30},
    {'name': 'Telur', 'stock': 100, 'used': 70, 'balance': 30},
    {'name': 'Benjo', 'stock': 100, 'used': 70, 'balance': 30},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryRed,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Franchisee Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Save logic
              Navigator.pop(context);
              CustomSnackbar.show(
                context,
                message: 'Report saved successfully!',
              );
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Franchisee ID
            _buildTextField('Franchisee ID', _franchiseeIdController),
            const SizedBox(height: 12),

            // Staff Name
            _buildTextField('Staff Name', _staffNameController),
            const SizedBox(height: 12),

            // Date
            _buildTextField('Date', _dateController),
            const SizedBox(height: 20),

            // Items Sold Section
            const Text(
              'Items Sold',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Menu Items Table
            _buildTable(
              headers: ['Menu', 'Sold (Units)', 'Total (RM)'],
              items: menuItems,
            ),

            const SizedBox(height: 16),

            // Add-On Section
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                'Add-On',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            _buildTable(headers: ['', '', ''], items: addOns, isAddOn: true),

            const SizedBox(height: 16),

            // Total Sales
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Sales',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '100',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '975.00',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Ingredients Details Section
            const Text(
              'Ingredients Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            _buildIngredientsTable(),

            const SizedBox(height: 20),

            // Comments Section
            const Text(
              'Comments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _commentsController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Enter comments...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  CustomSnackbar.show(
                    context,
                    message: 'Report submitted successfully!',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB83D2A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Submit Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTable({
    required List<String> headers,
    required List<Map<String, dynamic>> items,
    bool isAddOn = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Headers
          if (!isAddOn)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      headers[0],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      headers[1],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      headers[2],
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey[300]),
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            item['name'],
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item['quantity'].toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item['total'].toStringAsFixed(2),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    if (item['price'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item['price'],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Headers
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Ingredients',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Stock',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Used',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Balance',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Ingredients
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ingredients.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey[300]),
            itemBuilder: (context, index) {
              final item = ingredients[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        item['name'],
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item['stock'].toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item['used'].toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item['balance'].toString(),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
