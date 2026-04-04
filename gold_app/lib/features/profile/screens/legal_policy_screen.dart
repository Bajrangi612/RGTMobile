import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/gold_app_bar.dart';

class LegalPolicyScreen extends StatelessWidget {
  final String title;
  final String content;

  LegalPolicyScreen({
    super.key,
    required this.title,
    required this.content,
  }) ;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: GoldAppBar(title: title),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last updated: March 2024',
                style: AppTextStyles.caption,
              ).animate().fadeIn(),
              SizedBox(height: 24),
              Text(
                content,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.6, color: AppColors.pureWhite.withOpacity(0.9)),
              ).animate(delay: 100.ms).fadeIn(),
              SizedBox(height: 48),
            ],
          ),
        ),
      ),
    ) ;
  }

  static const String termsContent = '''
1. Acceptance of Terms
By accessing and using Royal Gold, you agree to be bound by these Terms of Service. These terms govern your use of our platform, including gold purchases, storage, and re-selling services.

2. Account Registration
You must be at least 18 years old to create an account. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.

3. Gold Transactions
All gold prices on our platform are live and based on prevailing market rates. Once a transaction is confirmed, it cannot be cancelled due to the high volatility of the commodity market.

4. KYC Requirements
Under regulatory compliance, users must complete Aadhaar KYC and link a valid bank account for transactions exceeding certain limits. We reserve the right to suspend accounts that fail verification.

5. Compliance
Royal Gold complies with local financial regulations and tax laws. Any fraudulent activity or misuse of the platform will result in immediate account termination and legal action.
''';

  static const String privacyContent = '''
1. Data Collection
We collect personal information such as your name, phone number, and KYC details (Aadhaar/PAN) to facilitate gold trading and comply with regulatory requirements.

2. Use of Information
Your data is used to verify your identity, process transactions, prevent fraud, and provide customer support. We do not sell your personal data to third parties.

3. Data Security
We implement industry-standard encryption and security protocols (SSL/TLS) to protect your sensitive information from unauthorized access or disclosure.

4. Biometric Data
If you enable Passkey, your biometric data (FaceID/Fingerprint) stays securely on your device and is never uploaded to our servers.

5. Third Party Services
We may share necessary data with banking partners and payment gateways to process your payments securely.
''';
}
