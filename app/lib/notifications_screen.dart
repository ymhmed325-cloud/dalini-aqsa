import 'package:flutter/material.dart';
import 'theme.dart';
import 'widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AQ.sand,
      body: ListView(
        padding: EdgeInsets.zero,
        children: const <Widget>[
          TabHeader(title: 'الإشعارات', subtitle: 'آخر التحديثات على طلباتك'),
          EmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'لا توجد إشعارات',
            subtitle: 'ستظهر هنا إشعارات العروض الجديدة وتغيّر حالة الطلب.',
          ),
        ],
      ),
    );
  }
}
