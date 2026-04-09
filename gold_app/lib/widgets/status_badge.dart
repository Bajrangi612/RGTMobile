import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

enum StatusType { pending, confirmed, verified, rejected, processing, ready, delivered, resold, cancelled }

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

  Color get _color {
    switch (status) {
      case StatusType.pending:
      case StatusType.confirmed:
      case StatusType.processing:
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

  IconData get _icon {
    switch (status) {
      case StatusType.pending:
      case StatusType.confirmed:
        return Icons.schedule;
      case StatusType.verified:
        return Icons.verified;
      case StatusType.rejected:
        return Icons.cancel;
      case StatusType.processing:
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

  String get _label {
    if (label != null) return label!;
    switch (status) {
      case StatusType.pending:
        return 'Pending';
      case StatusType.confirmed:
        return 'Confirmed';
      case StatusType.verified:
        return 'Verified';
      case StatusType.rejected:
        return 'Rejected';
      case StatusType.processing:
        return 'Processing';
      case StatusType.ready:
        return 'Ready to Pickup';
      case StatusType.delivered:
        return 'Delivered';
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
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: small ? 12 : 14),
          SizedBox(width: small ? 4 : 6),
          Text(
            _label,
            style: (small ? AppTextStyles.caption : AppTextStyles.labelSmall)
                .copyWith(color: _color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// Helper to convert string status to StatusType
StatusType statusFromString(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
    case 'created':
      return StatusType.confirmed;
    case 'verified':
      return StatusType.verified;
    case 'rejected':
      return StatusType.rejected;
    case 'processing':
    case 'paid':
      return StatusType.processing;
    case 'ready':
      return StatusType.ready;
    case 'picked':
    case 'delivered':
      return StatusType.delivered;
    case 'resold':
      return StatusType.resold;
    case 'cancelled':
      return StatusType.cancelled;
    default:
      return StatusType.pending;
  }
}
