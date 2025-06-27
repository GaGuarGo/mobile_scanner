// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class FaceOverlayPainter extends CustomPainter {
  final Color borderColor;
  final Rect faceRect; // The painter now accepts the Rect

  FaceOverlayPainter({
    this.borderColor = Colors.white,
    required this.faceRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint background = Paint()..color = Colors.black.withOpacity(0.6);

    // The painter no longer calculates the rect, it just uses the one provided.
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(faceRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, background);

    final Paint border = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawOval(faceRect, border);
  }

  @override
  bool shouldRepaint(covariant FaceOverlayPainter oldDelegate) {
    // Repaint if the border color or the rect size changes
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.faceRect != faceRect;
  }
}
