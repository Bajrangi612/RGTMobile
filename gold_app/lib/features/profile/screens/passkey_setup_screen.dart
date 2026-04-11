import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../../../widgets/gold_button.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_app_bar.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';



class PasskeySetupScreen extends ConsumerStatefulWidget {
  const PasskeySetupScreen({super.key});

  @override
  ConsumerState<PasskeySetupScreen> createState() => _PasskeySetupScreenState();
}

enum SetupStep { verifyOld, enterNew, confirmNew }

class _PasskeySetupScreenState extends ConsumerState<PasskeySetupScreen> {
  List<String> _pin = [];
  String _pendingNewPin = '';
  bool _isLoading = false;
  bool _isCheckingStatus = false;
  SetupStep _currentStep = SetupStep.enterNew;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isCheckingStatus = true);
    // Fetch latest user data to ensure PIN status and timestamp are fresh
    await ref.read(authProvider.notifier).getCurrentUser();
    if (mounted) {
      final user = ref.read(authProvider).user;
      setState(() {
        _isCheckingStatus = false;
        if (!_isInitialized) {
          _currentStep = (user?.pin != null) ? SetupStep.verifyOld : SetupStep.enterNew;
          _isInitialized = true;
        }
      });
    }
  }



  void _onNumberPressed(String number) {
    if (_pin.length < 4) {
      setState(() => _pin.add(number));
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin.removeLast());
    }
  }

  Future<void> _submitPin() async {
    if (_pin.length != 4) return;
    
    setState(() => _isLoading = true);
    
    if (_currentStep == SetupStep.verifyOld) {
      final success = await ref.read(authProvider.notifier).verifyPin(_pin.join());
      setState(() => _isLoading = false);
      if (success) {
        setState(() {
          _pin.clear();
          _currentStep = SetupStep.enterNew;
        });
      } else {
        setState(() => _pin.clear());
        if (mounted) context.showErrorSnackBar('Incorrect PIN. Please try again.');
      }
    } 
    else if (_currentStep == SetupStep.enterNew) {
      setState(() {
        _pendingNewPin = _pin.join();
        _pin.clear();
        _currentStep = SetupStep.confirmNew;
        _isLoading = false;
      });
    } 
    else if (_currentStep == SetupStep.confirmNew) {
      if (_pin.join() == _pendingNewPin) {
        final success = await ref.read(authProvider.notifier).setPin(_pin.join());
        setState(() => _isLoading = false);

        if (success && mounted) {
          final isSet = ref.read(authProvider).user?.pin != null;
          context.showSuccessSnackBar(isSet ? 'Security PIN updated successfully!' : 'Security PIN set successfully!');
          Navigator.of(context).pop();
        } else if (mounted) {
          context.showErrorSnackBar('Failed to update PIN. Please try again.');
        }
      } else {
        setState(() {
          _isLoading = false;
          _pin.clear();
          _pendingNewPin = '';
          _currentStep = SetupStep.enterNew;
        });
        if (mounted) context.showErrorSnackBar('PINs do not match. Try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isPinSet = user?.pin != null;
    final lastChanged = user?.pinUpdatedAt;

    // Debugging
    debugPrint('🛡️ [PasskeySetupScreen] PIN Set: $isPinSet, PIN: ${user?.pin}, PassKeySet: ${user?.passKeySet}');


    String title = '';
    String subtitle = '';
    String buttonText = '';

    if (_currentStep == SetupStep.verifyOld) {
      title = 'Enter Current PIN';
      subtitle = 'Enter your current 4-digit PIN to verify your identity.';
      buttonText = 'VERIFY PIN';
    } else if (_currentStep == SetupStep.enterNew) {
      title = isPinSet ? 'Set New PIN' : 'Security PIN';
      subtitle = isPinSet 
          ? 'Enter your new 4-digit PIN for sensitive transactions.'
          : 'Set a 4-digit PIN to secure your\nSell Back and other sensitive actions.';
      buttonText = 'NEXT';
    } else {
      title = 'Confirm New PIN';
      subtitle = 'Re-enter your new 4-digit PIN to confirm.';
      buttonText = 'CONFIRM PIN';
    }

    if (_isCheckingStatus) {
      return Scaffold(
        backgroundColor: AppColors.deepBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.royalGold),
              const SizedBox(height: 16),
              Text('Checking security status...', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: GoldAppBar(title: isPinSet ? 'Change Security PIN' : 'Security Setup'),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Icon(Icons.lock_person_rounded, size: 64, color: AppColors.royalGold)
                  .animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text(title, style: AppTextStyles.h2),
              if (isPinSet && lastChanged != null && _currentStep == SetupStep.verifyOld) ...[
                const SizedBox(height: 8),
                Text(
                  'Last changed on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(lastChanged))}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.grey.withValues(alpha: 0.7)),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),
              
              // PIN Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final hasValue = _pin.length > index;
                  return Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasValue ? AppColors.royalGold : Colors.transparent,
                      border: Border.all(
                        color: hasValue ? AppColors.royalGold : AppColors.grey.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                  ).animate(target: hasValue ? 1 : 0).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2));
                }),
              ),
              
              const SizedBox(height: 24),
              
              // Numeric Keypad

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    _buildKeypadRow(['1', '2', '3']),
                    const SizedBox(height: 24),
                    _buildKeypadRow(['4', '5', '6']),
                    const SizedBox(height: 24),
                    _buildKeypadRow(['7', '8', '9']),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(width: 80),
                        _buildKey('0'),
                        _buildIconButton(Icons.backspace_outlined, _onBackspace),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GoldButton(
                      text: buttonText,
                      isLoading: _isLoading,
                      onPressed: _pin.length == 4 ? _submitPin : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildKey(String key) {
    return InkWell(
      onTap: () => _onNumberPressed(key),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: Text(
          key,
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.normal),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: Icon(icon, color: AppColors.pureWhite, size: 28),
      ),
    );
  }
}
