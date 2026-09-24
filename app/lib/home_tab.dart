import 'package:flutter/material.dart';
import 'theme.dart';
import 'api.dart';
import 'widgets.dart';

// الرئيسية الجديدة: شريط بحث + بانر بغداد + شبكة 8 خدمات + خدمات قريبة
class NewHomeTab extends StatelessWidget {
  const NewHomeTab({super.key, required this.onNew});
  final Future<void> Function([String?]) onNew;

  @override
  Widget build(BuildContext context) {
    final name = s(Session.user?['name'], 'بك');
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        _Hero(name: name),
        Transform.translate(
          offset: const Offset(0, -22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SearchBar(onTap: () => onNew()),
          ),
        ),
        const SectionTitle('الخدمات'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: kServices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (c, i) => _ServiceTile(
              service: kServices[i],
              onTap: () => onNew(kServices[i].id),
            ),
          ),
        ),
        const SectionTitle('خدمات قريبة منك'),
        const _NearbyPlaceholder(),
        const SizedBox(height: 30),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return AqHeader(
      height: 230,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                  const Spacer(),
                  const Icon(Icons.menu, color: Colors.white, size: 26),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: const <Widget>[
                  Icon(Icons.place, color: AQ.gold, size: 20),
                  SizedBox(width: 6),
                  Text('بغداد', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                ],
              ),
              const Spacer(),
              const Text('عندك مشكلة؟', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
              const Text('دلّيني على الحل', style: TextStyle(color: AQ.goldSoft, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AqCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 8),
          const Icon(Icons.search, color: AQ.muted, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('احجيلي شنو المشكلة...', style: TextStyle(color: AQ.muted, fontSize: 14.5)),
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: AQ.navy, shape: BoxShape.circle),
            child: const Icon(Icons.mic, color: AQ.gold, size: 22),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, required this.onTap});
  final Service service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: aa(service.color, 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(service.icon, color: service.color, size: 30),
            const SizedBox(height: 6),
            Text(service.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AQ.text)),
          ],
        ),
      ),
    );
  }
}

class _NearbyPlaceholder extends StatelessWidget {
  const _NearbyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AqCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const <Widget>[
            Icon(Icons.engineering_rounded, color: AQ.gold, size: 36),
            SizedBox(height: 10),
            Text('لا يوجد فنيون متاحون الآن', style: TextStyle(fontWeight: FontWeight.w900, color: AQ.text)),
            SizedBox(height: 4),
            Text('عندما يظهر فني قريب منك، ستجد بطاقته هنا مع تقييمه ومسافته.', textAlign: TextAlign.center, style: TextStyle(color: AQ.muted, fontSize: 12.5, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
