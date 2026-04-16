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
                style: AppTextStyles.bodyMedium.copyWith(height: 1.6, color: AppColors.pureWhite.withValues(alpha: 0.9)),
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
By accessing RGT, you agree to these Patron Terms of Use. These terms govern your retail purchase and pickup of physical 24K gold coins through our official platform.

2. User Verification
To ensure a secure shopping environment, patrons must complete account verification using valid identity documents. RGT reserves the right to authenticate accounts before facilitating high-value retail purchases.

3. Retail Purchases
All gold prices on the platform are live retail rates. Given the dynamic nature of physical gold markets, confirmed retail orders are final. Purchases are for physical assets only and does not constitute any form of financial instrument or investment.

4. Fulfillment & Pickup
RGT operates on a "Store Pickup" model. All purchased coins must be collected personally from an authorized RGT Office. Patrons must present a valid ID and purchase confirmation at the time of pickup.

5. Platform Compliance
RGT complies with retail commerce regulations and local tax laws (GST). Any attempt to misuse the platform for unauthorized purposes will result in immediate account termination.
''';

  static const String privacyContent = '''
1. Identity Stewardship
We collect personal information such as your name, phone number, and identity documentation solely to verify patrons and fulfill physical retail orders at our RGT Offices.

2. Data Usage
Your information is used to authenticate your account, prevent retail fraud, and generate digital invoices. We do not sell or lease your identity information to third parties.

3. Security Protocol
We implement industry-standard AES-256 encryption to protect your identity documents. Sensitive data is stored in isolated environments strictly for record-keeping and auditing purposes.

4. Biometric Protection
If you enable biometric login, your data (FaceID/Fingerprint) stays exclusively on your secure device hardware. RGT never transmits, stores, or accesses your biometric data on its servers.

5. Verified Partners
We share necessary information with PCI-DSS compliant payment processing partners (Razorpay/Cashfree) to facilitate secure retail transactions.
''';
}
