import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

enum StatusType { 
  pending, 
  confirmed, 
  verified, 
  rejected, 
  processing, 
  qualityChecking,
  ready, 
  delivered, 
  resold, 
  cancelled 
}

class StatusBadge extends StatelessWidget {
  final StatusType status;
  final String? label;
  final bool small;

  StatusBadge({
    super.key,
    required this.status,
    this.label,
    this.small = false,
  });

  Color get color {
    switch (status) {
      case StatusType.pending:
      case StatusType.confirmed:
      case StatusType.processing:
      case StatusType.qualityChecking:
        return AppColors.pending;
      case StatusType.ready:
        return AppColors.royalGold; // Distinct gold for ready
      case StatusType.verified:
      case StatusType.delivered:
        return AppColors.success;
      case StatusType.rejected:
      case StatusType.cancelled:
        return AppColors.error;
      case StatusType.resold:
        return Colors.purpleAccent;
    }
  }

  IconData get icon {
    switch (status) {
      case StatusType.pending:
      case StatusType.confirmed:
        return Icons.schedule;
      case StatusType.verified:
        return Icons.verified;
      case StatusType.rejected:
        return Icons.cancel;
      case StatusType.processing:
      case StatusType.qualityChecking:
        return Icons.hourglass_top;
      case StatusType.ready:
        return Icons.store_mall_directory_rounded;
      case StatusType.delivered:
        return Icons.check_circle;
      case StatusType.resold:
        return Icons.currency_exchange_rounded;
      case StatusType.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String get badgeLabel {
    if (label != null) return label!;
    switch (status) {
      case StatusType.pending:
        return 'Payment Pending';
      case StatusType.confirmed:
        return 'Confirmed';
      case StatusType.verified:
        return 'Payment Successful';
      case StatusType.rejected:
        return 'Rejected';
      case StatusType.processing:
        return 'Processing';
      case StatusType.qualityChecking:
        return 'Quality Checking';
      case StatusType.ready:
        return 'Ready to Pickup';
      case StatusType.delivered:
        return 'Collected';
      case StatusType.resold:
        return 'Resold';
      case StatusType.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: small ? 12 : 14),
          SizedBox(width: small ? 4 : 6),
          Text(
            badgeLabel,
            style: (small ? AppTextStyles.caption : AppTextStyles.labelSmall)
                .copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// Helper to convert string status to StatusType
StatusType statusFromString(String status) {
  switch (status.toUpperCase()) {
    case 'ORDER_PLACED':
      return StatusType.pending;
    case 'ORDER_CONFIRMED':
      return StatusType.confirmed;
    case 'PREPARING_ORDER':
      return StatusType.processing;
    case 'QUALITY_CHECKING':
      return StatusType.qualityChecking;
    case 'READY_FOR_PICKUP':
      return StatusType.ready;
    case 'DELIVERED':
    case 'PICKED_UP':
      return StatusType.delivered;
    case 'SELL_BACK_APPLIED':
      return StatusType.processing;
    case 'APPROVED':
      return StatusType.confirmed;
    case 'PAYMENT_SETTLED':
    case 'SOLD_BACK':
    case 'RESOLD':
      return StatusType.resold;
    case 'ORDER_CANCELLED':
    case 'CANCELLED':
      return StatusType.cancelled;
    default:
      return StatusType.pending;
  }
}
