import 'package:flutter/material.dart';
import 'theme.dart';

class DaliniLogo extends StatelessWidget {
  const DaliniLogo({super.key, this.size = 84});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size, height: size * 0.88,
    child: CustomPaint(painter: _P()),
  );
}

class _P extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height, cx = w / 2;
    final t = h * 0.08, b = h * 0.86, r = w * 0.42;
    final p = Path()
      ..moveTo(cx, b)
      ..cubicTo(cx - r * 0.95, h * 0.52, cx - r, t + r * 0.55, cx, t)
      ..cubicTo(cx + r, t + r * 0.55, cx + r * 0.95, h * 0.52, cx, b)
      ..close();
    c.drawPath(p, Paint()..color = AQ.navy);
    final cc = Offset(cx, t + r * 0.62), cr = r * 0.62;
    c.drawCircle(cc, cr, Paint()..color = AQ.gold);
    final hw = cr * 1.1, hh = cr * 0.85;
    final ht = cc.dy - cr * 0.42, hl = cc.dx - hw / 2;
    final wh = Paint()..color = AQ.white;
    final roof = Path()
      ..moveTo(hl - hw * 0.06, ht + hh * 0.42)
      ..lineTo(cx, ht - hh * 0.1)
      ..lineTo(hl + hw + hw * 0.06, ht + hh * 0.42)
      ..close();
    c.drawPath(roof, wh);
    c.drawRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(hl, ht + hh * 0.42, hw, hh * 0.58),
      bottomLeft: const Radius.circular(2),
      bottomRight: const Radius.circular(2),
    ), wh);
    c.drawRect(Rect.fromLTWH(cx - hw * 0.11, ht + hh - hh * 0.3, hw * 0.22, hh * 0.3),
      Paint()..color = AQ.navy);
  }
  @override
  bool shouldRepaint(covariant _P old) => false;
}
