import 'package:flutter/material.dart';
import 'dart:ui';
import '../core/theme/app_colors.dart';

class GoldCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool hasGoldBorder;
  final bool hasGlow;
  final VoidCallback? onTap;
  final double borderRadius;

  GoldCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.hasGoldBorder = false,
    this.hasGlow = false,
    this.onTap,
    this.borderRadius = 20,
  }) ;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            if (hasGlow)
              BoxShadow(
                color: AppColors.royalGold.withOpacity(0.1),
                blurRadius: 40,
                spreadRadius: -10,
                offset: const Offset(0, 20),
              ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              padding: padding ?? const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: hasGoldBorder
                      ? AppColors.royalGold.withOpacity(0.3)
                      : AppColors.pureWhite.withOpacity(0.1),
                  width: hasGoldBorder ? 1.5 : 1,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius - 2),
                  border: Border.all(
                    color: hasGoldBorder 
                        ? AppColors.royalGold.withOpacity(0.1) 
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                padding: padding ?? const EdgeInsets.all(22),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
