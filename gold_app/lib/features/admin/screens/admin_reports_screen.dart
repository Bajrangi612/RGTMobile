import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Platform Reports', style: AppTextStyles.h4),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.royalGold),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: AppColors.royalGold.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Advanced Analytics Coming Soon', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pureWhite.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}
