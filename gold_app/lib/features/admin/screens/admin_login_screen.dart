import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/gold_button.dart';
import '../../../widgets/gold_card.dart';
import '../providers/admin_provider.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _pinController = TextEditingController();

  Future<void> _handleLogin() async {
    final success = await ref.read(adminProvider.notifier).login(_pinController.text);
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text('Admin Access', style: AppTextStyles.h4),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.royalGold),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, color: AppColors.royalGold, size: 60)
                    .animate().scale(duration: 400.ms),
                const SizedBox(height: 24),
                Text('Authorization Required', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Text('Enter Admin PIN to continue', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
                const SizedBox(height: 40),
                
                GoldCard(
                  child: Column(
                    children: [
                      TextField(
                        controller: _pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.h2.copyWith(letterSpacing: 20, color: AppColors.royalGold),
                        decoration: InputDecoration(
                          hintText: '••••',
                          hintStyle: AppTextStyles.h2.copyWith(color: Colors.white10),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (adminState.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(adminState.error!, style: const TextStyle(color: AppColors.error)),
                        ),
                      GoldButton(
                        text: 'Unlock Portal',
                        isLoading: adminState.isLoading,
                        onPressed: _handleLogin,
                      ),
                    ],
                  ),
                ).animate().slideY(begin: 0.1, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
