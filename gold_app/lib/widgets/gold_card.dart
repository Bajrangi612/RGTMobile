import 'package:flutter/material.dart';
import 'dart:ui';
import '../core/theme/app_colors.dart';

class GoldCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool hasGoldBorder;
  final bool hasGlow;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool isVibrant;
  final LinearGradient? gradient;
  final double blurSigma;

  GoldCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.hasGoldBorder = false,
    this.hasGlow = false,
    this.onTap,
    this.borderRadius = 20,
    this.isVibrant = false,
    this.gradient,
    this.blurSigma = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            if (hasGlow || isVibrant)
              BoxShadow(
                color: (gradient?.colors.first ?? AppColors.royalGold)
                    .withValues(alpha: isVibrant ? 0.15 : 0.08),
                blurRadius: 40,
                spreadRadius: isVibrant ? 2 : -10,
                offset: const Offset(0, 15),
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              padding: const EdgeInsets.all(1), // Outer glass border
              decoration: BoxDecoration(
                color: isVibrant 
                    ? Colors.transparent 
                    : AppColors.surface.withValues(alpha: 0.65),
                gradient: gradient,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: isVibrant
                      ? (gradient?.colors.last.withValues(alpha: 0.3) ?? AppColors.royalGold.withValues(alpha: 0.4))
                      : (hasGoldBorder
                          ? AppColors.royalGold.withValues(alpha: 0.3)
                          : AppColors.pureWhite.withValues(alpha: 0.08)),
                  width: (hasGoldBorder || isVibrant) ? 1.5 : 0.8,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius - 2),
                  border: Border.all(
                    color: isVibrant
                        ? Colors.white.withValues(alpha: 0.1)
                        : (hasGoldBorder 
                            ? AppColors.royalGold.withValues(alpha: 0.05) 
                            : Colors.transparent),
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
