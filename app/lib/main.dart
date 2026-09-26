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

/// لوحة ألوان عصرية داكنة بتدرجات الأزرق والبنفسجي
class ModernPalette {
  static const Color bg = Color(0xFF0A0A14);
  static const Color bgSoft = Color(0xFF12121F);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceHigh = Color(0xFF23233D);
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primarySoft = Color(0xFF8B7CF6);
  static const Color accent = Color(0xFF00D2FF);
  static const Color accentSoft = Color(0xFF4FACFE);
  static const Color textPrimary = Color(0xFFF5F5FA);
  static const Color textSecondary = Color(0xFFA0A0B8);
  static const Color border = Color(0xFF2A2A45);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF6C5CE7), Color(0xFF00D2FF)],
  );

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFF0A0A14), Color(0xFF14142B), Color(0xFF0A0A14)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1E1E38), Color(0xFF16162A)],
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _boot();
  }

  @override
  void dispose() {
    _glowController.dispose();
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
            // هالات ضوئية في الخلفية
            Positioned(
              top: -120,
              right: -80,
              child: _GlowOrb(
                color: ModernPalette.primary.withOpacity(0.35),
                size: 320,
              ),
            ),
            Positioned(
              bottom: -140,
              left: -100,
              child: _GlowOrb(
                color: ModernPalette.accent.withOpacity(0.28),
                size: 360,
              ),
            ),
            // المحتوى
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      final t = _glowController.value;
                      return Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: <Color>[
                              ModernPalette.primary.withOpacity(0.35 + 0.15 * t),
                              ModernPalette.primary.withOpacity(0.0),
                            ],
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: ModernPalette.primary
                                  .withOpacity(0.35 + 0.2 * t),
                              blurRadius: 60 + 20 * t,
                              spreadRadius: 4,
                            ),
                            BoxShadow(
                              color: ModernPalette.accent
                                  .withOpacity(0.25 + 0.15 * t),
                              blurRadius: 80 + 30 * t,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: const Pulse(
                      amount: 0.05,
                      child: ScaleIn(child: DaliniLogo(size: 118)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const FadeSlide(
                    delay: Duration(milliseconds: 500),
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return ModernPalette.primaryGradient.createShader(bounds);
                      },
                      child: Text(
                        'دليني',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const FadeSlide(
                    delay: Duration(milliseconds: 800),
                    child: Text(
                      'فنيّك الموثوق بلمسة واحدة',
                      style: TextStyle(
                        color: ModernPalette.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 52),
                  const FadeSlide(
                    delay: Duration(milliseconds: 1100),
                    child: _ModernLoader(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
class _ModernLoader extends StatelessWidget {
  const _ModernLoader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
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
          const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.transparent),
            ),
          ),
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                ModernPalette.accentSoft,
              ),
            ),
          ),
        ],
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
            color: Colors.black.withOpacity(0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: ModernPalette.primary.withOpacity(0.12),
            blurRadius: 30,
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
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: active ? ModernPalette.primaryGradient : null,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: active
                      ? <BoxShadow>[
                          BoxShadow(
                            color: ModernPalette.primary.withOpacity(0.45),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
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
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? ModernPalette.cardGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: ModernPalette.border, width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
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