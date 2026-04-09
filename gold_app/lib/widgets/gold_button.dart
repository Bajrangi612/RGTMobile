import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class GoldButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final double? width;
  final IconData? icon;
  final Color? color;

  GoldButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.width,
    this.icon,
    this.color,
  }) ;

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isDisabled => widget.onPressed == null || widget.isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _isDisabled ? null : (_) => _controller.forward(),
      onTapUp: _isDisabled ? null : (_) => _controller.reverse(),
      onTapCancel: _isDisabled ? null : () => _controller.reverse(),
      onTap: _isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: widget.width ?? double.infinity,
          height: 52,
          decoration: widget.isOutlined
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: _isDisabled
                        ? AppColors.grey.withValues(alpha: 0.3)
                        : (widget.color != null ? widget.color!.withValues(alpha: 0.6) : AppColors.royalGold.withValues(alpha: 0.6)),
                    width: 1.2,
                  ),
                ) : BoxDecoration(
                  gradient: _isDisabled ? null : (widget.color != null ? null : AppColors.goldGradient),
                  color: _isDisabled ? AppColors.grey.withValues(alpha: 0.2) : (widget.color ?? null),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: _isDisabled
                      ? null
                      : [
                          BoxShadow(
                            color: (widget.color ?? AppColors.royalGold).withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isOutlined
                            ? AppColors.royalGold
                            : Colors.white,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: widget.isOutlined
                              ? AppColors.royalGold
                              : Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.text,
                        style: AppTextStyles.button.copyWith(
                          color: widget.isOutlined
                              ? (_isDisabled ? AppColors.grey : AppColors.royalGold)
                              : (_isDisabled ? Colors.white70 : Colors.white),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
