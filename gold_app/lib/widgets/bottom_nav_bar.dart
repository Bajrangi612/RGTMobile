import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';
import 'notched_painter.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double barHeight = 65.0;
    const double fabSize = 58.0;

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // 1. Notched Background
        CustomPaint(
          size: Size(MediaQuery.of(context).size.width, barHeight + MediaQuery.of(context).padding.bottom),
          painter: NotchedPainter(
            color: AppColors.surface, // Dynamic theme surface
            notchRadius: 38,
          ),
        ),

        // 2. Navigation Items
        SafeArea(
          child: SizedBox(
            height: barHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Left Items
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  isActive: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                _NavItem(
                  icon: Icons.search_rounded,
                  isActive: currentIndex == 4, // Mapping to a new search/catalog tab
                  onTap: () => onTap(4),
                ),
                
                // Central Gap for FAB
                const SizedBox(width: 60),

                // Right Items
                _NavItem(
                  icon: Icons.card_giftcard_rounded,
                  isActive: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  isActive: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
        ),

        // 3. Central FAB (Home) - Elevated with Animation
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 20,
          child: GestureDetector(
            onTap: () => onTap(0),
            child: Container(
              width: fabSize,
              height: fabSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF26C6DA), Color(0xFF00ACC1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF26C6DA).withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.home_filled,
                color: Colors.white,
                size: 30,
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.08, 1.08),
              duration: 2.seconds,
              curve: Curves.easeInOut,
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Icon(
          icon,
          color: isActive ? AppColors.royalGold : AppColors.grey.withValues(alpha: 0.5),
          size: 28,
        )
        .animate(target: isActive ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.2, 1.2),
          duration: 300.ms,
          curve: Curves.easeOutBack,
        )
        .shimmer(
          delay: 400.ms,
          duration: 1200.ms,
          color: AppColors.royalGold.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
