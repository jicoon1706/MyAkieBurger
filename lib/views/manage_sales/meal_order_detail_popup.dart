import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/providers/meal_order_controller.dart'; // Import Controller
import 'package:myakieburger/widgets/custom_loading_dialog.dart'; // Import Loading Dialog
import 'package:myakieburger/widgets/custom_snackbar.dart'; // Import Snackbar

class MealOrderDetailPopup extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const MealOrderDetailPopup({super.key, required this.orderData});

  @override
  State<MealOrderDetailPopup> createState() => _MealOrderDetailPopupState();
}

class _MealOrderDetailPopupState extends State<MealOrderDetailPopup> {
  final MealOrderController _controller = MealOrderController();

  Future<void> _handleDelete() async {
    final orderId = widget.orderData['mealOrderId'];
    final franchiseeId = widget.orderData['franchiseeId'];

    // Cast meals list safely
    final rawMeals = widget.orderData['meals'] as List<dynamic>? ?? [];
    final List<Map<String, dynamic>> meals = rawMeals
        .map((m) => Map<String, dynamic>.from(m))
        .toList();

    if (orderId == null || franchiseeId == null) {
      CustomSnackbar.show(
        context,
        message: "Error: Invalid Order Data",
        backgroundColor: Colors.red,
      );
      return;
    }

    // Show Confirmation Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order?'),
        content: const Text(
          'This will delete the order record and RESTORE the ingredients to your inventory. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      CustomLoadingDialog.show(context, message: "Deleting Order...");

      try {
        await _controller.deleteMealOrder(orderId, franchiseeId, meals);

        if (mounted) {
          CustomLoadingDialog.hide(context);
          CustomSnackbar.show(
            context,
            message: "Order deleted and stock restored!",
            backgroundColor: Colors.green,
          );
          // Return true to indicate an update happened
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          CustomLoadingDialog.hide(context);
          CustomSnackbar.show(
            context,
            message: "Failed to delete: $e",
            backgroundColor: Colors.red,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... existing variable extractions ...
    final meals = widget.orderData['meals'] as List<dynamic>? ?? [];
    final totalAmount = widget.orderData['total_amount'] ?? 0.0;
    final notes = widget.orderData['notes'] as String? ?? '';
    final createdAt = widget.orderData['created_at'] as String? ?? '';
    final orderId = widget.orderData['mealOrderId'] ?? 'N/A';
    final franchiseeName = widget.orderData['franchisee_name'] ?? 'N/A';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryRed,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          orderId.length > 20
                              ? '${orderId.substring(0, 20)}...'
                              : orderId,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 🗑️ DELETE BUTTON
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    tooltip: "Delete Order",
                    onPressed: _handleDelete,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    // Return false (no change) when simply closing
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            // Content (Same as before)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ... existing UI code for Info Section, Meals, Notes ...
                    _buildInfoSection('Order Information', [
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Order Date',
                        createdAt,
                      ),
                      _buildInfoRow(Icons.store, 'Franchisee', franchiseeName),
                    ]),
                    const SizedBox(height: 20),
                    _buildInfoSection('Items Ordered', []),
                    const SizedBox(height: 8),
                    if (meals.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'No items found',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    else
                      ...meals.map(
                        (meal) => _buildMealItem(meal),
                      ), // Requires moving _buildMealItem to this class or helper

                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.note_alt_outlined,
                                  size: 20,
                                  color: Colors.orange[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Order Notes',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              notes,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(thickness: 2),
                    const SizedBox(height: 8),

                    // Total Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'RM ${((totalAmount is int) ? totalAmount.toDouble() : totalAmount).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(
                          context,
                          false,
                        ), // Return false on close
                        icon: const Icon(Icons.check),
                        label: const Text('Close'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Copy helper widgets (_buildInfoSection, _buildInfoRow, _buildMealItem) from previous code here
  // ...
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealItem(dynamic meal) {
    // ... (Keep the exact code for _buildMealItem from your previous snippet)
    final menuName = meal['menu_name'] ?? 'Unknown';
    final category = meal['category'] ?? '';
    final quantity = meal['quantity'] ?? 1;
    final subtotal = meal['subtotal'] ?? 0.0;
    final addOns = meal['add_ons'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fastfood,
                  color: AppColors.primaryRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$quantity × $menuName',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                'RM ${((subtotal is int) ? subtotal.toDouble() : subtotal).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          if (addOns.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: addOns.map((addOn) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const SizedBox(width: 22),
                        Expanded(
                          child: Text(
                            '• ${addOn['quantity']} × ${addOn['name']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          '+RM ${(addOn['subtotal'] as num).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
