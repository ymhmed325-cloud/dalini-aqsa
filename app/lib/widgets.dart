import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';
import 'api.dart';

// ---------- انتقال الصفحات ----------
Route<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondary) => page,
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(-0.05, 0), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

// ---------- رسم الزخارف ----------
Path starPath(Offset c, double outer, double inner) {
  final p = Path();
  for (int k = 0; k < 16; k++) {
    final r = k.isEven ? outer : inner;
    final ang = math.pi * 2 * k / 16 - math.pi / 2;
    final pt = Offset(c.dx + r * math.cos(ang), c.dy + r * math.sin(ang));
    if (k == 0) {
      p.moveTo(pt.dx, pt.dy);
    } else {
      p.lineTo(pt.dx, pt.dy);
    }
  }
  p.close();
  return p;
}

class PatternPainter extends CustomPainter {
  PatternPainter({required this.color, required this.drift});
  final Color color;
  final double drift;
  static const double cell = 48;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.save();
    canvas.translate(-cell * drift, 0);
    final cols = (size.width / cell).ceil() + 2;
    final rows = (size.height / (cell * 0.86)).ceil() + 1;
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        final c = Offset(i * cell + (j.isOdd ? cell / 2 : 0), j * cell * 0.86);
        canvas.drawPath(starPath(c, cell * 0.44, cell * 0.22), paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PatternPainter old) => old.drift != drift || old.color != color;
}

class StarPainter extends CustomPainter {
  const StarPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final outer = size.shortestSide / 2;
    canvas.drawPath(starPath(c, outer, outer * 0.74), Paint()..color = color);
  }

  @override
  bool shouldRepaint(StarPainter old) => old.color != color;
}

// ---------- الشعار ----------
class AqLogo extends StatelessWidget {
  const AqLogo({super.key, this.size = 84});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: <Color>[AQ.goldSoft, AQ.gold], begin: Alignment.topRight, end: Alignment.bottomLeft),
        boxShadow: <BoxShadow>[BoxShadow(color: aa(AQ.gold, 0.45), blurRadius: size * 0.3, spreadRadius: 1)],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(size: Size(size * 0.86, size * 0.86), painter: StarPainter(color: aa(AQ.ink, 0.92))),
          Text('د', style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w900, color: AQ.gold, height: 1.1)),
        ],
      ),
    );
  }
}

// ---------- الترويسة المتحركة ----------
class AqHeader extends StatefulWidget {
  const AqHeader({super.key, required this.child, this.height = 220, this.radius = 34});
  final Widget child;
  final double height;
  final double radius;

  @override
  State<AqHeader> createState() => _AqHeaderState();
}

class _AqHeaderState extends State<AqHeader> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 26))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.vertical(bottom: Radius.circular(widget.radius));
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: br,
        gradient: const LinearGradient(colors: <Color>[AQ.ink, AQ.teal], begin: Alignment.topRight, end: Alignment.bottomLeft),
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => CustomPaint(painter: PatternPainter(color: aa(AQ.gold, 0.17), drift: _c.value)),
              ),
            ),
            Positioned.fill(child: widget.child),
          ],
        ),
      ),
    );
  }
}

class TabHeader extends StatelessWidget {
  const TabHeader({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AqHeader(
      height: 150,
      radius: 28,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FadeSlide(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900))),
              if (subtitle != null)
                FadeSlide(
                  delay: const Duration(milliseconds: 120),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(subtitle!, style: const TextStyle(color: AQ.goldSoft, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- حركات ----------
class FadeSlide extends StatefulWidget {
  const FadeSlide({super.key, required this.child, this.delay = Duration.zero, this.offset = const Offset(0, 0.14)});
  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  State<FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<FadeSlide> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  Timer? _t;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _t = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: SlideTransition(position: Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(_a), child: widget.child),
    );
  }
}

class ScaleIn extends StatelessWidget {
  const ScaleIn({super.key, required this.child, this.ms = 900});
  final Widget child;
  final int ms;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: ms),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Opacity(opacity: math.min(1.0, math.max(0.0, v * 2)), child: Transform.scale(scale: v, child: child)),
      child: child,
    );
  }
}

class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child, this.amount = 0.07});
  final Widget child;
  final double amount;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.scale(scale: 1 + widget.amount * Curves.easeInOut.transform(_c.value), child: child),
      child: widget.child,
    );
  }
}

class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.96});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool down = false;

  void _set(bool v) {
    if (mounted) setState(() => down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(scale: down ? widget.scale : 1.0, duration: const Duration(milliseconds: 110), curve: Curves.easeOut, child: widget.child),
    );
  }
}

class PulseBox extends StatefulWidget {
  const PulseBox({super.key, this.height = 90});
  final double height;

  @override
  State<PulseBox> createState() => _PulseBoxState();
}

class _PulseBoxState extends State<PulseBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.9).animate(_c),
      child: Container(
        height: widget.height,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: aa(AQ.teal, 0.10), borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      child: Column(children: List<Widget>.generate(count, (i) => const PulseBox())),
    );
  }
}

class EmptyState extends StatefulWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 50, 32, 30),
      child: Column(
        children: <Widget>[
          AnimatedBuilder(
            animation: _c,
            builder: (context, child) => Transform.translate(offset: Offset(0, -10 * Curves.easeInOut.transform(_c.value)), child: child),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(shape: BoxShape.circle, color: aa(AQ.gold, 0.18)),
              child: Icon(widget.icon, size: 46, color: AQ.gold),
            ),
          ),
          const SizedBox(height: 18),
          Text(widget.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AQ.text)),
          const SizedBox(height: 6),
          Text(widget.subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AQ.muted, height: 1.5)),
        ],
      ),
    );
  }
}

// ---------- عناصر واجهة ----------
class AqCard extends StatelessWidget {
  const AqCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.color = Colors.white});
  final Widget child;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[BoxShadow(color: aa(AQ.ink, 0.07), blurRadius: 22, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }
}

class AqButton extends StatelessWidget {
  const AqButton({super.key, required this.label, required this.onPressed, this.busy = false, this.icon, this.gold = false, this.danger = false});
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;
  final bool gold;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = danger
        ? <Color>[AQ.danger, const Color(0xFF9E2B20)]
        : gold
            ? <Color>[AQ.gold, const Color(0xFFA9822F)]
            : <Color>[AQ.tealLight, AQ.teal];
    final enabled = onPressed != null && !busy;
    return Pressable(
      onTap: enabled ? onPressed : null,
      child: AnimatedOpacity(
        opacity: onPressed == null ? 0.5 : 1,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: colors, begin: Alignment.topRight, end: Alignment.bottomLeft),
            boxShadow: <BoxShadow>[BoxShadow(color: aa(colors.last, 0.35), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: busy
                ? const SizedBox(key: ValueKey<String>('busy'), width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : Row(
                    key: const ValueKey<String>('label'),
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (icon != null) ...<Widget>[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)],
                      Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

InputDecoration aqInput(String label, IconData icon, {Widget? suffix, String? hint}) {
  OutlineInputBorder b(Color c, double w) => OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, color: AQ.teal),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: b(aa(AQ.teal, 0.2), 1),
    enabledBorder: b(aa(AQ.teal, 0.2), 1),
    focusedBorder: b(AQ.teal, 1.8),
  );
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: aa(c, 0.13), borderRadius: BorderRadius.circular(20)),
      child: Text(kStatusAr[status] ?? status, style: TextStyle(color: c, fontSize: 12.5, fontWeight: FontWeight.w800)),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        children: <Widget>[
          Container(width: 5, height: 20, decoration: BoxDecoration(color: AQ.gold, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AQ.text)),
        ],
      ),
    );
  }
}

void showAqSnack(BuildContext context, String msg, {bool error = false}) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
    behavior: SnackBarBehavior.floating,
    backgroundColor: error ? AQ.danger : AQ.ink,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    margin: const EdgeInsets.all(16),
  ));
}

Future<bool> confirmDialog(BuildContext context, String title, String message, {String confirmLabel = 'تأكيد', bool danger = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      content: Text(message, style: const TextStyle(height: 1.5)),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('تراجع')),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel, style: TextStyle(color: danger ? AQ.danger : AQ.teal, fontWeight: FontWeight.w900)),
        ),
      ],
    ),
  );
  return r ?? false;
}

// ---------- شريط التنقل ----------
class NavItem {
  const NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class AqNavBar extends StatelessWidget {
  const AqNavBar({super.key, required this.items, required this.index, required this.onTap});
  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: <BoxShadow>[BoxShadow(color: aa(AQ.ink, 0.10), blurRadius: 24, offset: const Offset(0, -6))],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: List<Widget>.generate(items.length, (i) {
            final sel = i == index;
            return Expanded(
              child: Pressable(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(color: sel ? aa(AQ.teal, 0.11) : Colors.transparent, borderRadius: BorderRadius.circular(18)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(items[i].icon, color: sel ? AQ.teal : AQ.muted, size: 24),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        child: sel
                            ? Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(items[i].label, style: const TextStyle(color: AQ.teal, fontWeight: FontWeight.w900, fontSize: 13.5)),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
