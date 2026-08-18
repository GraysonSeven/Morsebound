import 'dart:math';

import 'package:flutter/material.dart';

class SignalBackdrop extends StatelessWidget {
  const SignalBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF061218)),
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _SignalBackdropPainter()),
          ),
        ),
        child,
      ],
    );
  }
}

class _SignalBackdropPainter extends CustomPainter {
  const _SignalBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFF4B7C86).withValues(alpha: 0.07)
      ..strokeWidth = 1;

    const spacing = 52.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final origin = Offset(size.width * 0.12, size.height * 0.26);
    final ring = Paint()
      ..color = const Color(0xFF55D6BE).withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final maxR = min(size.width, size.height) * 0.42;
    for (final factor in [0.32, 0.58, 0.84]) {
      canvas.drawCircle(origin, maxR * factor, ring);
    }

    final route = Paint()
      ..color = const Color(0xFF55D6BE).withValues(alpha: 0.11)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final points = [
      Offset(size.width * 0.08, size.height * 0.70),
      Offset(size.width * 0.27, size.height * 0.58),
      Offset(size.width * 0.45, size.height * 0.66),
      Offset(size.width * 0.66, size.height * 0.47),
      Offset(size.width * 0.90, size.height * 0.55),
    ];

    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], route);
    }

    for (final point in points) {
      canvas.drawCircle(
        point,
        4.5,
        Paint()
          ..color = const Color(0xFF8FFFEA).withValues(alpha: 0.24),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
