import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

enum StatusType { pending, verified, rejected, processing, shipped, delivered, cancelled }

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
      case StatusType.processing:
        return AppColors.pending;
      case StatusType.verified:
      case StatusType.delivered:
        return AppColors.success;
      case StatusType.rejected:
      case StatusType.cancelled:
        return AppColors.error;
      case StatusType.shipped:
        return AppColors.info;
    }
  }

  IconData get _icon {
    switch (status) {
      case StatusType.pending:
        return Icons.schedule;
      case StatusType.verified:
        return Icons.verified;
      case StatusType.rejected:
        return Icons.cancel;
      case StatusType.processing:
        return Icons.hourglass_top;
      case StatusType.shipped:
        return Icons.local_shipping;
      case StatusType.delivered:
        return Icons.check_circle;
      case StatusType.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String get _label {
    if (label != null) return label!;
    switch (status) {
      case StatusType.pending:
        return 'Pending';
      case StatusType.verified:
        return 'Verified';
      case StatusType.rejected:
        return 'Rejected';
      case StatusType.processing:
        return 'Processing';
      case StatusType.shipped:
        return 'Shipped';
      case StatusType.delivered:
        return 'Delivered';
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
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _color.withOpacity(0.3),
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
      return StatusType.pending;
    case 'verified':
      return StatusType.verified;
    case 'rejected':
      return StatusType.rejected;
    case 'processing':
    case 'confirmed':
      return StatusType.processing;
    case 'shipped':
      return StatusType.shipped;
    case 'delivered':
      return StatusType.delivered;
    case 'cancelled':
      return StatusType.cancelled;
    default:
      return StatusType.pending;
  }
}
