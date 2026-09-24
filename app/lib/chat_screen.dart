import 'dart:async';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'api.dart';
import 'widgets.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.requestId, required this.otherName});
  final String requestId;
  final String otherName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController input = TextEditingController();
  final ScrollController scroll = ScrollController();
  List<Map<String, dynamic>> messages = <Map<String, dynamic>>[];
  bool loading = true;
  bool sending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 5), (t) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final r = await Api.get('/api/requests/${widget.requestId}/messages');
    if (!mounted) return;
    setState(() {
      loading = false;
      if (r.ok) messages = asList(r.map['messages']);
    });
  }

  Future<void> _send() async {
    final text = input.text.trim();
    if (text.isEmpty) return;
    setState(() => sending = true);
    final r = await Api.post('/api/requests/${widget.requestId}/messages', <String, dynamic>{'text': text});
    if (!mounted) return;
    setState(() => sending = false);
    if (!r.ok) {
      showAqSnack(context, r.error ?? 'تعذر الإرسال', error: true);
      return;
    }
    input.clear();
    setState(() => messages = [...messages, asMap(r.map['message'])]);
  }

  @override
  Widget build(BuildContext context) {
    final myId = Session.user?['id'];
    return Scaffold(
      backgroundColor: AQ.sand,
      appBar: AppBar(
        backgroundColor: AQ.navy,
        foregroundColor: Colors.white,
        title: Text(widget.otherName, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: AQ.gold))
                : messages.isEmpty
                    ? const EmptyState(icon: Icons.chat_bubble_outline_rounded, title: 'لا توجد رسائل', subtitle: 'اكتب رسالتك الأولى')
                    : ListView.builder(
                        controller: scroll,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (c, i) {
                          final m = messages[i];
                          final isMe = m['sender_id'] == myId;
                          return Align(
                            alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isMe ? AQ.navy : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(s(m['text']), style: TextStyle(color: isMe ? Colors.white : AQ.text, height: 1.4)),
                                  const SizedBox(height: 4),
                                  Text(timeAgo(m['created_at']), style: TextStyle(color: isMe ? AQ.goldSoft : AQ.muted, fontSize: 10.5)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة...',
                        filled: true,
                        fillColor: AQ.sand,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: sending ? null : _send,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(color: AQ.navy, shape: BoxShape.circle),
                      child: sending
                          ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2.4, color: AQ.gold))
                          : const Icon(Icons.send_rounded, color: AQ.gold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
