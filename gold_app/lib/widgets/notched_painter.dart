import 'package:flutter/material.dart';

class NotchedPainter extends CustomPainter {
  final Color color;
  final double notchRadius;

  NotchedPainter({
    required this.color,
    this.notchRadius = 38.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const double cornerRadius = 24.0;

    // Start from top-left corner
    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    // To the start of the notch
    final double notchStart = (size.width / 2) - (notchRadius * 2);
    path.lineTo(notchStart, 0);

    // Draw the notch (smooth curve)
    path.quadraticBezierTo(
      (size.width / 2) - notchRadius,
      0,
      (size.width / 2) - notchRadius,
      notchRadius * 0.4,
    );

    path.arcToPoint(
      Offset((size.width / 2) + notchRadius, notchRadius * 0.4),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    path.quadraticBezierTo(
      (size.width / 2) + notchRadius,
      0,
      (size.width / 2) + (notchRadius * 2),
      0,
    );

    // To the top-right corner
    path.lineTo(size.width - cornerRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

    // Complete the box
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Draw shadow
    canvas.drawShadow(path, Colors.black.withOpacity(0.12), 12, true);
    
    // Draw background
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
