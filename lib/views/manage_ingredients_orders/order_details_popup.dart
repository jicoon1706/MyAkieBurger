// lib/manage_ingredients_order/widgets/order_details_popup.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/widgets/custom_snackbar.dart';
import 'package:myakieburger/providers/ingredients_order_controller.dart';

class OrderDetailsPopup extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onOrderCancelled;
  final bool isFactoryAdminView;
  final bool isDeliveryAgentView;

  const OrderDetailsPopup({
    super.key,
    required this.order,
    this.onOrderCancelled,
    this.isFactoryAdminView = false,
    this.isDeliveryAgentView = false,
  });

  @override
  State<OrderDetailsPopup> createState() => _OrderDetailsPopupState();
}

class _OrderDetailsPopupState extends State<OrderDetailsPopup> {
  bool _isCancelling = false;
  bool _isUpdating = false;

  Color get _primaryColor {
    if (widget.isDeliveryAgentView) {
      return AppColors.dAgent;
    } else if (widget.isFactoryAdminView) {
      return AppColors.factoryBlue;
    } else {
      return AppColors.primaryRed;
    }
  }

  Color get _accentColor {
    if (widget.isDeliveryAgentView) {
      return AppColors.bgDAgent;
    } else if (widget.isFactoryAdminView) {
      return AppColors.lightBlueAccent;
    } else {
      return AppColors.accentRed;
    }
  }

  String get _userRoleName {
    if (widget.isDeliveryAgentView) {
      return 'Delivery Agent';
    } else if (widget.isFactoryAdminView) {
      return 'Factory Admin';
    } else {
      return 'Franchisee';
    }
  }

  // 🆕 Approve order (Factory Admin only)
  Future<void> _handleApproveOrder() async {
    setState(() => _isUpdating = true);

    try {
      final orderId = widget.order['supplyOrderId'];
      if (orderId == null) {
        throw Exception('Order ID not found');
      }

      // Update status to Approved and reduce factory inventory
      await IngredientsOrderController().approveOrder(widget.order);

      if (!mounted) return;

      Navigator.pop(context);

      CustomSnackbar.show(
        context,
        message: 'Order approved! Factory inventory reduced. Ready for delivery.',
        backgroundColor: Colors.green,
        icon: Icons.check_circle_outline,
      );

      widget.onOrderCancelled?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdating = false);

      CustomSnackbar.show(
        context,
        message: 'Error approving order: $e',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  // 🆕 Mark as Delivered (Delivery Agent only)
  Future<void> _handleMarkDelivered() async {
    setState(() => _isUpdating = true);

    try {
      // Add franchisee stock when delivered
      await IngredientsOrderController().markOrderAsDelivered(widget.order);

      if (!mounted) return;

      Navigator.pop(context);

      CustomSnackbar.show(
        context,
        message: 'Order delivered! Franchisee stock updated.',
        backgroundColor: Colors.green,
        icon: Icons.check_circle_outline,
      );

      widget.onOrderCancelled?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdating = false);

      CustomSnackbar.show(
        context,
        message: 'Error marking as delivered: $e',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    try {
      final orderId = widget.order['supplyOrderId'];
      if (orderId == null) {
        throw Exception('Order ID not found');
      }

      await IngredientsOrderController().cancelOrderAndRestock(widget.order);

      if (mounted) {
        Navigator.pop(context);
        CustomSnackbar.show(
          context,
          message: 'Order cancelled successfully. Factory inventory restored.',
          backgroundColor: Colors.green,
          icon: Icons.check_circle_outline,
        );
        widget.onOrderCancelled?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
        CustomSnackbar.show(
          context,
          message: 'Failed to cancel order: $e',
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.order['status'] ?? 'Unknown';
    final orderNumber =
        widget.order['order_number'] ?? widget.order['supplyOrderId'] ?? 'N/A';
    final totalAmount = widget.order['total_amount'] ?? 0.0;
    final ingredients = widget.order['ingredients'] as List<dynamic>? ?? [];
    final paymentMethod = widget.order['payment_method'] ?? 'N/A';
    final createdAt = _formatDate(widget.order['created_at']);

    // 🆕 Determine button states based on status
    final isPending = status.toLowerCase() == 'pending';
    final isApproved = status.toLowerCase() == 'approved';
    final isDelivered = status.toLowerCase() == 'delivered';
    final isCancelled = status.toLowerCase() == 'cancelled';

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
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: const BorderRadius.only(
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
                        Text(
                          'Order Details ($_userRoleName)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          orderNumber,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(status),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(status),
                              color: _getStatusColor(status),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Order Information
                    _buildInfoSection('Order Information', [
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Order Date',
                        createdAt,
                      ),
                      _buildInfoRow(
                        Icons.payment,
                        'Payment Method',
                        paymentMethod,
                      ),
                      _buildInfoRow(
                        Icons.store,
                        'Franchisee',
                        widget.order['franchisee_name'] ?? 'N/A',
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Ingredients List
                    _buildInfoSection('Items Ordered', []),
                    const SizedBox(height: 8),

                    if (ingredients.isEmpty)
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
                      ...ingredients.map((item) => _buildIngredientItem(item)),

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
                          'RM ${totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _accentColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons
                    if (widget.isDeliveryAgentView)
                      _buildDeliveryAgentActions(status, isApproved, isDelivered)
                    else if (widget.isFactoryAdminView)
                      _buildAdminActions(status, isPending, isApproved, isDelivered)
                    else
                      _buildFranchiseeActions(isPending, isApproved),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 Delivery Agent Actions
  Widget _buildDeliveryAgentActions(String status, bool isApproved, bool isDelivered) {
    if (isApproved) {
      // Show "Mark as Delivered" button for Approved orders
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUpdating ? null : () => _handleMarkDelivered(),
              icon: _isUpdating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.local_shipping),
              label: const Text('Mark as Delivered'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isUpdating ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Close'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                side: BorderSide(color: Colors.grey[400]!),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Delivered/Cancelled orders - just close button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.check),
          label: const Text('Close'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }
  }

  // 🆕 Factory Admin Actions
  Widget _buildAdminActions(String status, bool isPending, bool isApproved, bool isDelivered) {
    if (isPending) {
      // Pending orders - Show Approve and Cancel buttons
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUpdating ? null : () => _handleApproveOrder(),
                  icon: _isUpdating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: const Text('Approve Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUpdating ? null : _cancelOrder,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Order'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUpdating ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Close'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Approved/Delivered/Cancelled - just close button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.check),
          label: const Text('Close'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }
  }

  // Franchisee Actions
  Widget _buildFranchiseeActions(bool isPending, bool isApproved) {
    if (isPending) {
      // Pending orders - allow cancellation
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isCancelling ? null : _cancelOrder,
              icon: _isCancelling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel),
              label: Text(_isCancelling ? 'Cancelling...' : 'Cancel Order'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isCancelling ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Close'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Approved/Delivered/Cancelled - show download and close
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                CustomSnackbar.show(
                  context,
                  message: 'Downloading invoice...',
                  backgroundColor: Colors.blueAccent,
                  icon: Icons.download,
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Download'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _accentColor,
                side: BorderSide(color: _accentColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check),
              label: const Text('Close'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

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

  Widget _buildIngredientItem(dynamic item) {
    final name = item['ingredient_name'] ?? 'Unknown';
    final quantity = item['quantity'] ?? 0;
    final unitPrice = item['unit_price'] ?? 0.0;
    final subtotal = item['subtotal'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_2,
              color: _accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$quantity × RM ${unitPrice.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            'RM ${subtotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'approved':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle;
      case 'approved':
        return Icons.verified;
      case 'pending':
        return Icons.access_time;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _formatDate(dynamic createdAt) {
    try {
      if (createdAt is Timestamp) {
        final date = createdAt.toDate();
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } else if (createdAt is String) {
        return createdAt;
      } else {
        return 'Unknown date';
      }
    } catch (e) {
      return 'Unknown date';
    }
  }
}