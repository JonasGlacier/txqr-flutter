import 'package:flutter/material.dart';

/// Paints a translucent overlay with a clear cutout window and animated border.
class QrScannerOverlay extends StatelessWidget {
  final double scanWindowSize;
  final double progress; // 0.0 – 1.0
  final bool isDetected;

  const QrScannerOverlay({
    super.key,
    this.scanWindowSize = 280,
    this.progress = 0,
    this.isDetected = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _OverlayPainter(
        scanWindowSize: scanWindowSize,
        progress: progress,
        isDetected: isDetected,
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double scanWindowSize;
  final double progress;
  final bool isDetected;

  _OverlayPainter({
    required this.scanWindowSize,
    required this.progress,
    required this.isDetected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 40);
    final halfWindow = scanWindowSize / 2;
    final windowRect = Rect.fromCenter(
      center: center,
      width: scanWindowSize,
      height: scanWindowSize,
    );

    // Dark overlay with a hole
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(windowRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );

    // Corner brackets
    const bracketLen = 32.0;
    const bracketStroke = 4.0;
    final bracketPaint = Paint()
      ..color = isDetected ? Colors.green : Colors.red
      ..strokeWidth = bracketStroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final left = center.dx - halfWindow;
    final top = center.dy - halfWindow;
    final right = center.dx + halfWindow;
    final bottom = center.dy + halfWindow;

    // Top-left
    canvas.drawLine(Offset(left, top + bracketLen), Offset(left, top), bracketPaint);
    canvas.drawLine(Offset(left, top), Offset(left + bracketLen, top), bracketPaint);
    // Top-right
    canvas.drawLine(Offset(right - bracketLen, top), Offset(right, top), bracketPaint);
    canvas.drawLine(Offset(right, top), Offset(right, top + bracketLen), bracketPaint);
    // Bottom-left
    canvas.drawLine(Offset(left, bottom - bracketLen), Offset(left, bottom), bracketPaint);
    canvas.drawLine(Offset(left, bottom), Offset(left + bracketLen, bottom), bracketPaint);
    // Bottom-right
    canvas.drawLine(Offset(right - bracketLen, bottom), Offset(right, bottom), bracketPaint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - bracketLen), bracketPaint);

    // Progress arc
    if (progress > 0) {
      final arcRect = windowRect.inflate(12);
      final progressPaint = Paint()
        ..color = Colors.indigoAccent
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        arcRect,
        -1.5708, // -pi/2 (start at top)
        progress * 6.2832, // progress * 2*pi
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDetected != isDetected;
  }
}
