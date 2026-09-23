import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// عنوان الخادم. يُضبط عند البناء: --dart-define=API_URL=https://...
const String kApiUrl = String.fromEnvironment('API_URL', defaultValue: 'https://dalini-aqsa-gv2p.onrender.com');

String s(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  final t = v.toString();
  return t.isEmpty ? fallback : t;
}

Map<String, dynamic> asMap(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> asList(dynamic v) =>
    v is List ? v.map((e) => asMap(e)).toList() : <Map<String, dynamic>>[];

String money(dynamic v) {
  final n = int.tryParse(s(v)) ?? 0;
  final str = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
    buf.write(str[i]);
  }
  return '${buf.toString()} د.ع';
}

String timeAgo(dynamic iso) {
  final d = DateTime.tryParse(s(iso));
  if (d == null) return '';
  final diff = DateTime.now().difference(d.toLocal());
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'قبل ${diff.inHours} ساعة';
  return 'قبل ${diff.inDays} يوم';
}

class Service {
  const Service(this.id, this.name, this.icon, this.color);
  final String id;
  final String name;
  final IconData icon;
  final Color color;
}

const List<Service> kServices = <Service>[
  Service('electricity', 'كهرباء', Icons.bolt, Color(0xFFD99A1E)),
  Service('plumbing', 'سباكة', Icons.water_drop, Color(0xFF2B7CC7)),
  Service('ac', 'تكييف', Icons.ac_unit, Color(0xFF17A2B8)),
  Service('appliances', 'صيانة أجهزة', Icons.build, Color(0xFF7A5BC7)),
  Service('cleaning', 'تنظيف', Icons.cleaning_services, Color(0xFF2E9E5B)),
  Service('cars', 'سيارات', Icons.directions_car, Color(0xFFC0503A)),
];

Service serviceOf(String id) => kServices.firstWhere((x) => x.id == id, orElse: () => kServices.first);

const Map<String, String> kStatusAr = <String, String>{
  'matching': 'بانتظار العروض',
  'offer': 'وصلت عروض',
  'accepted': 'تم القبول',
  'on_way': 'الفني في الطريق',
  'arrived': 'وصل الفني',
  'in_progress': 'قيد التنفيذ',
  'completed': 'مكتمل',
  'cancelled': 'ملغي',
};

const Map<String, String> kActionAr = <String, String>{
  'on_way': 'أنا في الطريق',
  'arrived': 'وصلت إلى الموقع',
  'in_progress': 'بدء التنفيذ',
  'completed': 'إتمام العمل',
};

Color statusColor(String st) {
  switch (st) {
    case 'matching':
      return const Color(0xFF8A7A3B);
    case 'offer':
      return const Color(0xFFC9861E);
    case 'accepted':
    case 'on_way':
    case 'arrived':
      return const Color(0xFF0F766E);
    case 'in_progress':
      return const Color(0xFF2B7CC7);
    case 'completed':
      return const Color(0xFF2E9E5B);
    default:
      return const Color(0xFFC0392B);
  }
}

class ApiResult {
  const ApiResult(this.ok, this.status, this.body, this.error);
  final bool ok;
  final int status;
  final dynamic body;
  final String? error;
  Map<String, dynamic> get map => asMap(body);
}

class Session {
  static const FlutterSecureStorage _store = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
  static String token = '';
  static Map<String, dynamic>? user;

  static Future<void> load() async {
    try {
      token = await _store.read(key: 'aq_token') ?? '';
      final u = await _store.read(key: 'aq_user');
      user = (u == null || u.isEmpty) ? null : asMap(jsonDecode(u));
    } catch (_) {
      token = '';
      user = null;
    }
  }

  static Future<void> save(String t, Map<String, dynamic> u) async {
    token = t;
    user = u;
    try {
      await _store.write(key: 'aq_token', value: t);
      await _store.write(key: 'aq_user', value: jsonEncode(u));
    } catch (_) {}
  }

  static Future<void> clear() async {
    token = '';
    user = null;
    try {
      await _store.delete(key: 'aq_token');
      await _store.delete(key: 'aq_user');
    } catch (_) {}
  }
}

class Api {
  /// يُستدعى عند انتهاء الجلسة أو تسجيل الخروج (يعيد المستخدم لشاشة الدخول).
  static Future<void> Function()? onSessionEnd;

  static Future<ApiResult> get(String path) => call('GET', path);
  static Future<ApiResult> post(String path, [Map<String, dynamic>? body]) => call('POST', path, body: body ?? <String, dynamic>{});

  static Future<ApiResult> call(String method, String path, {Map<String, dynamic>? body, bool auth = true}) async {
    final uri = Uri.parse('$kApiUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth && Session.token.isNotEmpty) headers['Authorization'] = 'Bearer ${Session.token}';
    Object? lastErr;
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        late http.Response r;
        const limit = Duration(seconds: 45);
        if (method == 'GET') {
          r = await http.get(uri, headers: headers).timeout(limit);
        } else if (method == 'PUT') {
          r = await http.put(uri, headers: headers, body: jsonEncode(body ?? <String, dynamic>{})).timeout(limit);
        } else {
          r = await http.post(uri, headers: headers, body: jsonEncode(body ?? <String, dynamic>{})).timeout(limit);
        }
        dynamic decoded;
        try {
          decoded = jsonDecode(utf8.decode(r.bodyBytes));
        } catch (_) {
          decoded = null;
        }
        final ok = r.statusCode >= 200 && r.statusCode < 300;
        String? err;
        if (!ok) {
          err = (decoded is Map && decoded['error'] != null) ? decoded['error'].toString() : 'تعذر إتمام العملية (${r.statusCode})';
        }
        if (r.statusCode == 401 && auth && Session.token.isNotEmpty) {
          Session.token = '';
          final f = onSessionEnd;
          if (f != null) f();
        }
        return ApiResult(ok, r.statusCode, decoded, err);
      } on TimeoutException catch (e) {
        lastErr = e;
        break;
      } on SocketException catch (e) {
        lastErr = e;
      } on http.ClientException catch (e) {
        lastErr = e;
      } catch (e) {
        lastErr = e;
        break;
      }
      if (attempt < 2) await Future<void>.delayed(const Duration(seconds: 2));
    }
    String msg = 'حدث خطأ غير متوقع، حاول مرة أخرى';
    if (lastErr is TimeoutException) {
      msg = 'انتهت مهلة الاتصال، حاول مرة أخرى';
    } else if (lastErr is SocketException || lastErr is http.ClientException) {
      msg = 'تعذر الاتصال بالخادم، تحقق من الإنترنت';
    }
    return ApiResult(false, 0, null, msg);
  }
}
