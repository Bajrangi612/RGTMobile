import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/gold_app_bar.dart';
import '../../../widgets/gold_button.dart';
import '../../../widgets/gold_card.dart';
import '../../auth/providers/auth_provider.dart';

class BankDetailsScreen extends ConsumerStatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  ConsumerState<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends ConsumerState<BankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _holderController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountController;
  late TextEditingController _ifscController;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _holderController = TextEditingController(text: user?.bankHolderName);
    _bankNameController = TextEditingController(text: user?.bankName);
    _accountController = TextEditingController(text: user?.bankAccountNo);
    _ifscController = TextEditingController(text: user?.bankIfsc);
  }

  @override
  void dispose() {
    _holderController.dispose();
    _bankNameController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final user = ref.read(authProvider).user;
    if (user == null) return;

    try {
      final success = await ref.read(authProvider.notifier).updateProfile(
        name: user.name, // Pass existing name
        bankHolderName: _holderController.text,
        bankName: _bankNameController.text,
        bankAccountNo: _accountController.text,
        bankIfsc: _ifscController.text.toUpperCase(),
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank details updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(authProvider).error ?? 'Update failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isVerified = user?.bankStatus == 'verified';
    final canEdit = !isVerified || _isEditing;

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: GoldAppBar(
        title: 'Bank Details',
        actions: [
          if (isVerified && !_isEditing)
            IconButton(
              icon: Icon(Icons.edit, color: AppColors.royalGold),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REFUND ACCOUNT',
                  style: AppTextStyles.caption.copyWith(letterSpacing: 1.5, color: AppColors.royalGold),
                ),
                const SizedBox(height: 12),
                
                GoldCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldTitle('Account Holder Name'),
                      _buildTextField(_holderController, "As per Bank Records", Icons.person_outline, readOnly: !canEdit),
                      const SizedBox(height: 20),

                      _buildFieldTitle('Bank Name'),
                      _buildTextField(_bankNameController, "e.g. HDFC Bank", Icons.account_balance_outlined, readOnly: !canEdit),
                      const SizedBox(height: 20),

                      _buildFieldTitle('Account Number'),
                      _buildTextField(_accountController, "0000 0000 0000 0000", Icons.numbers_rounded, keyboardType: TextInputType.number, readOnly: !canEdit),
                      const SizedBox(height: 20),

                      _buildFieldTitle('IFSC Code'),
                      _buildTextField(_ifscController, "HDFC0001234", Icons.code_rounded, textCapitalization: TextCapitalization.characters, readOnly: !canEdit),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                if (isVerified) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user, color: AppColors.success, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Your bank account is verified. For security, these details cannot be changed. Please contact support if you need to update them.',
                            style: TextStyle(color: AppColors.success, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),
                ],

                const SizedBox(height: 40),
                
                if (canEdit)
                  GoldButton(
                    text: 'SAVE BANK DETAILS',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _submit,
                    icon: Icons.save_rounded,
                  ).animate(delay: 200.ms).fadeIn(),
                
                const SizedBox(height: 20),
                Text(
                  'Note: Please ensure the bank details are accurate. Refunds will be processed to this account only.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.grey, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(title, style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey)),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String hint, 
    IconData icon, {
    bool readOnly = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: AppTextStyles.bodyMedium.copyWith(color: readOnly ? AppColors.grey : AppColors.pureWhite),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.royalGold.withValues(alpha: 0.7), size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.royalGold, width: 1),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }
}
