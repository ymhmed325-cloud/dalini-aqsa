import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart';
import 'api.dart';
import 'widgets.dart';
import 'auth.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Api.onSessionEnd = () async {
    await Session.clear();
    navKey.currentState?.pushAndRemoveUntil(fadeRoute<void>(const AuthScreen()), (route) => false);
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
      title: 'دليني الأقصى',
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

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
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
        // لا اتصال: ندخل بالبيانات المحفوظة والخادم قد يكون نائماً
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
      body: AqHeader(
        height: double.infinity,
        radius: 0,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Pulse(amount: 0.05, child: ScaleIn(child: AqLogo(size: 118))),
              const SizedBox(height: 26),
              const FadeSlide(
                delay: Duration(milliseconds: 500),
                child: Text('دليني الأقصى', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 8),
              const FadeSlide(
                delay: Duration(milliseconds: 800),
                child: Text('فنيّك الموثوق بلمسة واحدة', style: TextStyle(color: AQ.goldSoft, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 46),
              const FadeSlide(
                delay: Duration(milliseconds: 1100),
                child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.4, color: AQ.gold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
