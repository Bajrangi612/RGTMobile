import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_colors.dart';

class GoldImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const GoldImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildError(context);
    }

    // Check if it's a local asset
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildError(context),
      );
    }

    // Check if it's a network URL
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => placeholder ?? _buildPlaceholder(context),
        errorWidget: (context, url, error) => errorWidget ?? _buildError(context),
      );
    }

    // Fallback for simple paths that might be assets without prefix
    if (imageUrl.contains('.png') || imageUrl.contains('.jpg') || imageUrl.contains('.webp')) {
       // Try as asset if it has an extension but no http
       return Image.asset(
        'assets/images/$imageUrl',
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildError(context),
      );
    }

    return _buildError(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.royalGold.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: ClipOval(
        child: Image.asset(
          'assets/images/default_gold_coin.png',
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.monetization_on_rounded,
            size: (width ?? 40) * 0.8,
            color: AppColors.royalGold.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
