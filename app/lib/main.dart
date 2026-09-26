import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart';
import 'logo.dart';
import 'api.dart';
import 'widgets.dart';
import 'auth.dart';
import 'notifications_service.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NotifService.init();
  Api.onSessionEnd = () async {
    await Session.clear();
    navKey.currentState?.pushAndRemoveUntil(
      fadeRoute<void>(const AuthScreen()),
      (route) => false,
    );
  };
  runApp(const AqApp());
}

class AqApp extends StatelessWidget {
  const AqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navKey,
      debugShowCheckedModeBanner: false,
      title: 'دليني',
      theme: AQ.theme(),
      locale: const Locale('ar'),
      supportedLocales: const <Locale>[Locale('ar')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}

/// لوحة ألوان عصرية داكنة بتدرجات الأزرق والبنفسجي (Modern UI 2024)
class ModernPalette {
  // خلفيات عميقة بتدرج ليلي
  static const Color bg = Color(0xFF07070F);
  static const Color bgSoft = Color(0xFF0E0E1A);
  static const Color surface = Color(0xFF14142A);
  static const Color surfaceHigh = Color(0xFF1E1E3A);
  static const Color surfaceGlass = Color(0xFF1A1A33);

  // ألوان أساسية بتدرج بنفسجي-سماوي
  static const Color primary = Color(0xFF7C5CFF);
  static const Color primarySoft = Color(0xFF9B8CFF);
  static const Color primaryDeep = Color(0xFF5B3FE0);
  static const Color accent = Color(0xFF00E5FF);
  static const Color accentSoft = Color(0xFF5CE1FF);
  static const Color accentDeep = Color(0xFF00B8D4);

  // لمسات ثانوية
  static const Color pink = Color(0xFFFF5C9E);
  static const Color mint = Color(0xFF4EF0B8);
  static const Color amber = Color(0xFFFFB84D);

  // نصوص
  static const Color textPrimary = Color(0xFFF8F8FF);
  static const Color textSecondary = Color(0xFFB0B0CC);
  static const Color textMuted = Color(0xFF6E6E8E);

  // حدود
  static const Color border = Color(0xFF26264A);
  static const Color borderSoft = Color(0xFF1C1C38);
  static const Color borderGlow = Color(0x337C5CFF);

  // تدرجات
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF7C5CFF), Color(0xFF00E5FF)],
  );

  static const LinearGradient primaryGradientSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF9B8CFF), Color(0xFF5CE1FF)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF00E5FF), Color(0xFF4EF0B8)],
  );

  static const LinearGradient pinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFFF5C9E), Color(0xFF7C5CFF)],
  );

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFF07070F), Color(0xFF12122A), Color(0xFF07070F)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1A1A33), Color(0xFF12122A)],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0x26FFFFFF), Color(0x0DFFFFFF)],
  );

  // ظلال عصرية
  static List<BoxShadow> softShadow({Color? color, double blur = 24}) {
    return <BoxShadow>[
      BoxShadow(
        color: (color ?? Colors.black).withOpacity(0.35),
        blurRadius: blur,
        offset: const Offset(0, 10),
      ),
    ];
  }

  static List<BoxShadow> glowShadow({
    Color color = primary,
    double blur = 28,
    double opacity = 0.45,
  }) {
    return <BoxShadow>[
      BoxShadow(
        color: color.withOpacity(opacity),
        blurRadius: blur,
        spreadRadius: 0,
        offset: const Offset(0, 8),
      ),
    ];
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final AnimationController _rotateController;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _boot();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _rotateController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final started = DateTime.now();
    await Session.load();
    Widget next = const AuthScreen();
    if (Session.token.isNotEmpty && Session.user != null) {
      final r = await Api.get('/api/auth/me');
      if (r.ok) {
        final u = asMap(r.map['user']);
        await Session.save(Session.token, u);
        next = homeFor(u);
      } else if (r.status == 0 && Session.user != null) {
        next = homeFor(Session.user!);
      } else {
        await Session.clear();
      }
    }
    final left = 2200 - DateTime.now().difference(started).inMilliseconds;
    if (left > 0) await Future<void>.delayed(Duration(milliseconds: left));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(fadeRoute<void>(next));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernPalette.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: ModernPalette.bgGradient),
        child: Stack(
          children: <Widget>[
            // شبكة خفيفة في الخلفية
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter()),
            ),
            // هالات ضوئية في الخلفية
            Positioned(
              top: -140,
              right: -100,
              child: _GlowOrb(
                color: ModernPalette.primary.withOpacity(0.45),
                size: 380,
              ),
            ),
            Positioned(
              bottom: -160,
              left: -120,
              child: _GlowOrb(
                color: ModernPalette.accent.withOpacity(0.35),
                size: 420,
              ),
            ),
            Positioned(
              top: 200,
              left: -80,
              child: _GlowOrb(
                color: ModernPalette.pink.withOpacity(0.18),
                size: 260,
              ),
            ),
            // المحتوى
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AnimatedBuilder(
                    animation: Listenable.merge(
                      <Listenable>[_glowController, _rotateController],
                    ),
                    builder: (context, child) {
                      final double t = _glowController.value;
                      return SizedBox(
                        width: 220,
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            // حلقة دوارة خارجية
                            Transform.rotate(
                              angle: _rotateController.value * 6.28318,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: SweepGradient(
                                    colors: <Color>[
                                      ModernPalette.primary.withOpacity(0.0),
                                      ModernPalette.primary.withOpacity(0.9),
                                      ModernPalette.accent.withOpacity(0.9),
                                      ModernPalette.primary.withOpacity(0.0),
                                    ],
                                    stops: const <double>[
                                      0.0,
                                      0.35,
                                      0.7,
                                      1.0,
                                    ],
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: ModernPalette.bg,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // هالة داخلية
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: <Color>[
                                    ModernPalette.primary
                                        .withOpacity(0.35 + 0.15 * t),
                                    ModernPalette.primary.withOpacity(0.0),
                                  ],
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: ModernPalette.primary
                                        .withOpacity(0.45 + 0.2 * t),
                                    blurRadius: 60 + 20 * t,
                                    spreadRadius: 4,
                                  ),
                                  BoxShadow(
                                    color: ModernPalette.accent
                                        .withOpacity(0.3 + 0.15 * t),
                                    blurRadius: 90 + 30 * t,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: child,
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Pulse(
                      amount: 0.05,
                      child: ScaleIn(child: DaliniLogo(size: 108)),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // اسم التطبيق مع تأثير لمعان
                  FadeSlide(
                    delay: const Duration(milliseconds: 500),
                    child: AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, _) {
                        return ShaderMask(
                          shaderCallback: (Rect bounds) {
                            final double s = _shimmerController.value;
                            return LinearGradient(
                              begin: Alignment(-1.0 + 2 * s, -0.3),
                              end: Alignment(1.0 + 2 * s, 0.3),
                              colors: const <Color>[
                                Color(0xFF7C5CFF),
                                Color(0xFF00E5FF),
                                Color(0xFFFFFFFF),
                                Color(0xFF00E5FF),
                                Color(0xFF7C5CFF),
                              ],
                              stops: const <double>[
                                0.0,
                                0.35,
                                0.5,
                                0.65,
                                1.0,
                              ],
                            ).createShader(bounds);
                          },
                          child: const Text(
                            'دليني',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              height: 1.1,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  const FadeSlide(
                    delay: Duration(milliseconds: 800),
                    child: Text(
                      'فنيّك الموثوق بلمسة واحدة',
                      style: TextStyle(
                        color: ModernPalette.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 56),
                  const FadeSlide(
                    delay: Duration(milliseconds: 1100),
                    child: _ModernLoader(),
                  ),
                ],
              ),
            ),
            // شعار سفلي
            const Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: FadeSlide(
                delay: Duration(milliseconds: 1400),
                child: Text(
                  'MODERN UI • 2024',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ModernPalette.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شبكة خفيفة للخلفية
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = ModernPalette.borderSoft.withOpacity(0.35)
      ..strokeWidth = 0.6;
    const double step = 42;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// هالة ضوئية دائرية للخلفية
class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withOpacity(0.0)],
          ),
        ),
      ),
    );
  }
}

/// مؤشر تحميل عصري بتدرج لوني
class _ModernLoader extends StatefulWidget {
  const _ModernLoader();

  @override
  State<_ModernLoader> createState() => _ModernLoaderState();
}

class _ModernLoaderState extends State<_ModernLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              // حلقة خارجية دوارة
              Transform.rotate(
                angle: _controller.value * 6.28318,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: <Color>[
                        ModernPalette.primary.withOpacity(0.0),
                        ModernPalette.primary,
                        ModernPalette.accent,
                        ModernPalette.primary.withOpacity(0.0),
                      ],
                      stops: const <double>[0.0, 0.4, 0.75, 1.0],
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: ModernPalette.bg,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              // نقطة نابضة في المنتصف
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: ModernPalette.primaryGradient,
                  boxShadow: ModernPalette.glowShadow(
                    color: ModernPalette.primary,
                    blur: 16,
                    opacity: 0.7,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// شريط تنقل سفلي عصري بأيقونات بسيطة
class ModernBottomNav extends StatelessWidget {
  const ModernBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ModernNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: ModernPalette.cardGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ModernPalette.border, width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: ModernPalette.primary.withOpacity(0.15),
            blurRadius: 36,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List<Widget>.generate(items.length, (int i) {
          final bool active = i == currentIndex;
          final ModernNavItem item = items[i];
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: active ? ModernPalette.primaryGradient : null,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: active
                      ? ModernPalette.glowShadow(
                          color: ModernPalette.primary,
                          blur: 18,
                          opacity: 0.5,
                        )
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      item.icon,
                      size: 22,
                      color: active
                          ? Colors.white
                          : ModernPalette.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active
                            ? Colors.white
                            : ModernPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class ModernNavItem {
  const ModernNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// بطاقة عصرية بحواف دائرية
class ModernCard extends StatelessWidget {
  const ModernCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.gradient,
    this.borderRadius = 24,
    this.glowColor,
    this.showBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final double borderRadius;
  final Color? glowColor;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? ModernPalette.cardGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(color: ModernPalette.border, width: 1)
            : null,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withOpacity(0.25),
              blurRadius: 28,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}