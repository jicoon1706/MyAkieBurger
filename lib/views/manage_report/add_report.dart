import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/widgets/custom_snackbar.dart';
import 'package:myakieburger/services/auth_service.dart';
import 'package:myakieburger/providers/user_controller.dart';
import 'package:myakieburger/providers/meal_order_controller.dart';
import 'package:myakieburger/providers/ingredients_controller.dart';
import 'package:myakieburger/domains/user_model.dart';
import 'package:myakieburger/domains/ingredients_model.dart';
import 'package:intl/intl.dart';
import 'package:myakieburger/domains/report_model.dart';
import 'package:myakieburger/providers/report_controller.dart';

class AddReport extends StatefulWidget {
  const AddReport({super.key});

  @override
  State<AddReport> createState() => _AddReportState();
}

class _AddReportState extends State<AddReport> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _stallNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _regionNameController = TextEditingController();

  final UserController _userController = UserController();
  final MealOrderController _mealOrderController = MealOrderController();
  final IngredientsController _ingredientsController = IngredientsController();

  bool _isLoading = true;
  String? _userId;
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> menuItems = [];
  List<Map<String, dynamic>> addOns = [];
  int totalQuantity = 0;
  double totalSales = 0.0;

  List<Map<String, dynamic>> ingredients = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setTodayDate();
  }

  void _setTodayDate() {
    final now = DateTime.now();
    _selectedDate = now;
    _dateController.text = DateFormat('dd/MM/yyyy').format(now);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryRed,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });

      // Reload data for the new date
      await _loadItemsSold();
      await _loadIngredients();
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Get logged-in user ID from SharedPreferences
      final userId = await getLoggedInUserId();

      if (userId == null) {
        if (mounted) {
          CustomSnackbar.show(context, message: 'No user logged in');
          Navigator.pop(context);
        }
        return;
      }

      _userId = userId;

      // Fetch user data from Firestore
      final user = await _userController.getUserById(userId);

      if (user != null && mounted) {
        setState(() {
          _nameController.text = user.name;
          _usernameController.text = user.username;
          _stallNameController.text = user.stallName;
          _regionNameController.text = user.region;
        });

        // Load items sold and ingredients for today
        await _loadItemsSold();
        await _loadIngredients();
      } else {
        if (mounted) {
          CustomSnackbar.show(context, message: 'User data not found');
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      if (mounted) {
        CustomSnackbar.show(context, message: 'Error loading user data');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadItemsSold() async {
    if (_userId == null) return;

    try {
      final itemsData = await _mealOrderController.getItemsSoldByDate(
        _userId!,
        _selectedDate,
      );

      setState(() {
        menuItems = List<Map<String, dynamic>>.from(itemsData['menuItems']);
        addOns = List<Map<String, dynamic>>.from(itemsData['addOns']);
        totalQuantity = itemsData['totalQuantity'] as int;
        totalSales = itemsData['totalSales'] as double;
      });

      print(
        '✅ Loaded items sold: ${menuItems.length} menu items, ${addOns.length} add-ons',
      );
    } catch (e) {
      print('❌ Error loading items sold: $e');
      if (mounted) {
        CustomSnackbar.show(context, message: 'Error loading sales data');
      }
    }
  }

  Future<void> _loadIngredients() async {
    if (_userId == null) return;

    try {
      final ingredientsList = await _ingredientsController.getIngredients(
        _userId!,
      );

      setState(() {
        ingredients = ingredientsList.map((ingredient) {
          // Calculate received (stock) from balance + used
          final received = ingredient.balance + ingredient.used;

          return {
            'name': ingredient.name,
            'stock': received,
            'used': ingredient.used,
            'balance': ingredient.balance,
          };
        }).toList();

        _isLoading = false;
      });

      print('✅ Loaded ${ingredients.length} ingredients');
    } catch (e) {
      print('❌ Error loading ingredients: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        CustomSnackbar.show(context, message: 'Error loading ingredients data');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _stallNameController.dispose();
    _regionNameController.dispose();
    _dateController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

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
        // actions: [
        //   TextButton(
        //     onPressed: _isLoading
        //         ? null
        //         : () {
        //             // Save logic
        //             Navigator.pop(context);
        //             CustomSnackbar.show(
        //               context,
        //               message: 'Report saved successfully!',
        //             );
        //           },
        //     child: const Text(
        //       'Save',
        //       style: TextStyle(
        //         color: Colors.white,
        //         fontWeight: FontWeight.bold,
        //         fontSize: 16,
        //       ),
        //     ),
        //   ),
        // ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  _buildTextField('Name', _nameController, enabled: false),
                  const SizedBox(height: 12),

                  // Username
                  _buildTextField(
                    'Username',
                    _usernameController,
                    enabled: false,
                  ),
                  const SizedBox(height: 12),

                  // Stall Name
                  _buildTextField(
                    'Stall Name',
                    _stallNameController,
                    enabled: false,
                  ),
                  const SizedBox(height: 12),

                  // Region Name
                  _buildTextField(
                    'Region',
                    _regionNameController,
                    enabled: false,
                  ),
                  const SizedBox(height: 12),

                  // Date with Date Picker
                  _buildDateField('Date', _dateController),
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
                  if (menuItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'No menu items sold today',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    )
                  else
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

                  if (addOns.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'No add-ons sold today',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    _buildTable(
                      headers: ['', '', ''],
                      items: addOns,
                      isAddOn: true,
                    ),

                  const SizedBox(height: 16),

                  // Total Sales
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Sales',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          totalQuantity.toString(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          totalSales.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
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

                  if (ingredients.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'No ingredients data available',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    )
                  else
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
                      onPressed: () async {
                        if (_userId == null) return;

                        final reportId =
                            'report_${DateTime.now().millisecondsSinceEpoch}';
                        final now = DateTime.now();

                        final report = ReportModel(
                          reportId: reportId,
                          franchiseeId: _userId!,
                          franchiseeName: _nameController.text,
                          username: _usernameController.text, // 🆕 added here
                          stallName: _stallNameController.text,
                          region: _regionNameController.text,
                          reportDate: _selectedDate,
                          totalSales: totalSales,
                          totalOrders: 0,
                          totalMealsSold: totalQuantity,
                          averageOrderValue: totalQuantity > 0
                              ? totalSales / totalQuantity
                              : 0,
                          mealBreakdown: menuItems.map((m) {
                            return {
                              'menu_name': m['name'],
                              'units_sold': m['quantity'],
                              'unit_price': m['price'],
                              'total_revenue': m['total'],
                            };
                          }).toList(),
                          ingredientUsageSnapshot: ingredients
                              .map((i) => i)
                              .toList(),
                          relatedMealOrders: [],
                          comments: _commentsController.text,
                          createdAt: now,
                          updatedAt: now,
                        );

                        try {
                          final reportController = ReportController();
                          await reportController.saveReport(report);

                          if (mounted) {
                            Navigator.pop(context);
                            CustomSnackbar.show(
                              context,
                              message: 'Report submitted successfully!',
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            CustomSnackbar.show(
                              context,
                              message: 'Failed to submit report.',
                            );
                          }
                        }
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
  }) {
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
            color: enabled ? Colors.white : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
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

  Widget _buildDateField(String label, TextEditingController controller) {
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
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: controller,
              enabled: false,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                suffixIcon: Icon(Icons.calendar_today, color: Colors.grey),
              ),
              style: const TextStyle(color: Colors.black),
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
              final String name = item['name'] ?? '';
              final int quantity = item['quantity'] ?? 0;
              final num total = item['total'] ?? 0.0;

              // Price is now a double, format it properly
              final dynamic priceValue = item['price'];
              final String priceText = priceValue is num
                  ? 'RM ${priceValue.toStringAsFixed(2)}'
                  : (priceValue?.toString() ?? 'RM 0.00');

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
                            name,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            quantity.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            total.toStringAsFixed(2),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        priceText,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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
