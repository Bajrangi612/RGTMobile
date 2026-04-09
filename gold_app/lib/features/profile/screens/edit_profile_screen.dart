import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/gold_button.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_app_bar.dart';
import '../../auth/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _dobController;
  late TextEditingController _panController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name);
    _emailController = TextEditingController(text: user?.email);
    _addressController = TextEditingController(text: user?.address);
    _dobController = TextEditingController(text: user?.dob);
    _panController = TextEditingController(text: user?.panNo);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _panController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? initialDate;
    if (_dobController.text.isNotEmpty) {
      try {
        initialDate = DateFormat('dd/MM/yyyy').parse(_dobController.text);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.royalGold,
              onPrimary: AppColors.deepBlack,
              surface: AppColors.surface,
              onSurface: AppColors.pureWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final success = await ref.read(authProvider.notifier).updateProfile(
        name: _nameController.text,
        email: _emailController.text,
        address: _addressController.text,
        dob: _dobController.text,
        panNo: _panController.text,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
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
    final isVerified = user?.isFullyVerified ?? false;

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: GoldAppBar(title: 'Personal Information'),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GoldCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldTitle('Full Name'),
                      _buildTextField(_nameController, "Your Name", Icons.person_outline),
                      const SizedBox(height: 20),
                      
                      _buildFieldTitle('Email Address'),
                      _buildTextField(_emailController, "example@mail.com", Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 20),

                      _buildFieldTitle('Residential Address'),
                      _buildTextField(_addressController, "House No, Street, City, State, PIN", Icons.home_outlined, maxLines: 3),
                      const SizedBox(height: 20),

                      _buildFieldTitle('Date of Birth'),
                      _buildTextField(
                        _dobController, 
                        "DD/MM/YYYY", 
                        Icons.calendar_today_outlined, 
                        readOnly: true,
                        onTap: _selectDate,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                
                const SizedBox(height: 16),
                
                Text('IDENTITY DETAILS', style: AppTextStyles.caption.copyWith(letterSpacing: 1.5, color: AppColors.royalGold)),
                const SizedBox(height: 12),
                
                GoldCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldTitle('PAN Number'),
                      _buildTextField(
                        _panController, 
                        "ABCDE1234F", 
                        Icons.credit_card, 
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 40),
                
                GoldButton(
                  text: 'SAVE CHANGES',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _submit,
                  icon: Icons.check_circle_outline,
                ).animate(delay: 200.ms).fadeIn(),
                
                const SizedBox(height: 40),
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
    VoidCallback? onTap,
    TextInputType? keyboardType,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
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
