import 'package:flutter/material.dart';
import 'theme.dart';

const List<String> kCities = <String>[
  'بغداد', 'البصرة', 'الموصل', 'أربيل', 'النجف', 'كربلاء', 'كركوك', 'السليمانية'
];

Future<String?> pickCity(BuildContext ctx, String current) => showModalBottomSheet<String>(
      context: ctx,
      backgroundColor: AQ.sand,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (c) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(width: 44, height: 5, decoration: BoxDecoration(color: aa(AQ.ink, 0.18), borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            const Text('اختر المدينة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AQ.text)),
            const SizedBox(height: 12),
            ...kCities.map((city) => ListTile(
                  leading: Icon(Icons.location_city, color: city == current ? AQ.gold : AQ.muted),
                  title: Text(city, style: const TextStyle(fontWeight: FontWeight.w800, color: AQ.text)),
                  trailing: city == current ? const Icon(Icons.check_circle, color: AQ.gold) : null,
                  onTap: () => Navigator.pop(c, city),
                )),
          ],
        ),
      ),
    );
