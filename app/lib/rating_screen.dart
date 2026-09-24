import 'package:flutter/material.dart';
import 'theme.dart';
import 'api.dart';
import 'widgets.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key, required this.requestId, required this.providerName});
  final String requestId;
  final String providerName;

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int stars = 5;
  final TextEditingController comment = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  Future<void> send() async {
    setState(() => busy = true);
    final r = await Api.post('/api/requests/${widget.requestId}/rate', <String, dynamic>{
      'stars': stars,
      'comment': comment.text.trim(),
    });
    if (!mounted) return;
    setState(() => busy = false);
    if (!r.ok) {
      showAqSnack(context, r.error ?? 'تعذر إرسال التقييم', error: true);
      return;
    }
    showAqSnack(context, 'شكراً لتقييمك!');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AQ.sand,
      body: Column(
        children: <Widget>[
          TabHeader(title: 'قيّم الفني', subtitle: widget.providerName),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AqCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: <Widget>[
                      const Text('كيف كانت خدمة الفني؟', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AQ.text)),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List<Widget>.generate(5, (i) => Pressable(
                          onTap: () => setState(() => stars = i + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                              size: 44,
                              color: i < stars ? AQ.gold : AQ.muted,
                            ),
                          ),
                        )),
                      ),
                      const SizedBox(height: 12),
                      Text('$stars من 5', style: const TextStyle(color: AQ.muted, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: comment,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: aqInput('أضف تعليقاً (اختياري)', Icons.comment_outlined),
                ),
                const SizedBox(height: 12),
                AqButton(label: 'إرسال التقييم', icon: Icons.send_rounded, busy: busy, onPressed: send),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
