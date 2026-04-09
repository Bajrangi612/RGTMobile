import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_colors.dart';

class LiveCountdown extends StatefulWidget {
  final DateTime targetDate;
  final TextStyle? style;

  const LiveCountdown({
    super.key, 
    required this.targetDate,
    this.style,
  });

  @override
  State<LiveCountdown> createState() => _LiveCountdownState();
}

class _LiveCountdownState extends State<LiveCountdown> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _startTimer();
  }

  void _calculateRemaining() {
    final now = DateTime.now();
    _remaining = widget.targetDate.isAfter(now) 
        ? widget.targetDate.difference(now) 
        : Duration.zero;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        _calculateRemaining();
        if (_remaining.isNegative || _remaining == Duration.zero) {
          _timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return 'Arrived';

    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return '${days}d: ${hours}h: ${minutes}m: ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(_remaining),
      style: widget.style ?? AppTextStyles.h2.copyWith(color: AppColors.deepBlack),
    );
  }
}
