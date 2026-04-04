import 'package:flutter/material.dart';
import 'dart:ui';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class GoldAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBack;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double elevation;

   GoldAppBar({
    super.key,
    this.title,
    this.showBack = true,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.elevation = 0,
  }) ;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: elevation,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: showBack
          ? (leading ??
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.glassWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.royalGold,
                    size: 16,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              )) : leading,
      title: title != null
          ? Text(
              title!,
              style: AppTextStyles.h4,
            )
          : null,
      actions: actions,
    );
  }
}
