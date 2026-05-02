import 'package:flutter/material.dart';
import '../../data/models/coupon_enums.dart';

class CouponStatusChip extends StatelessWidget {
  const CouponStatusChip({super.key, required this.status, this.small = false});

  final CouponStatus status;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: status.color,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class CouponTypeBadge extends StatelessWidget {
  const CouponTypeBadge({super.key, required this.type, this.small = false});

  final CouponType type;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: type.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: small ? 10 : 12, color: type.color),
          const SizedBox(width: 4),
          Text(
            type.shortLabel,
            style: TextStyle(
              color: type.color,
              fontSize: small ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
