import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/ice_page_header.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _State();
}

class _State extends State<MessagesScreen> {
  bool _loading = true;
  bool _notAvailable = false;
  List<dynamic> _threads = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _notAvailable = false; });
    try {
      final res = await ApiClient.instance.dio.get('/messages/');
      final data = res.data;
      List<dynamic> list = [];
      if (data is List) {
        list = data;
      } else if (data is Map) {
        list = (data['results'] as List?) ??
            (data['threads'] as List?) ?? [];
      }
      setState(() { _threads = list; _loading = false; });
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('404') || msg.contains('not found')) {
        setState(() { _notAvailable = true; _loading = false; });
      } else {
        setState(() { _notAvailable = true; _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IceColors.bg,
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'Messages',
                subtitle: 'Group conversations',
              ),
            ),
            if (_loading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child:
                        CircularProgressIndicator(color: IceColors.navyDeep),
                  ),
                ),
              )
            else if (_notAvailable || _threads.isEmpty)
              SliverToBoxAdapter(
                child: _notAvailable
                    ? const _ComingSoonState()
                    : const _EmptyState(),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _ThreadTile(
                    thread: _threads[i] as Map,
                    index: i,
                    onTap: () => _openThread(_threads[i] as Map),
                  ),
                  childCount: _threads.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  void _openThread(Map thread) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _ChatScreen(thread: thread),
    ));
  }
}

// ─── Thread Tile ──────────────────────────────────────────────────────────────

class _ThreadTile extends StatelessWidget {
  final Map thread;
  final int index;
  final VoidCallback onTap;
  const _ThreadTile({required this.thread, required this.index, required this.onTap});

  String get _groupName =>
      thread['group_name']?.toString() ??
      thread['name']?.toString() ??
      'Group Chat';

  String get _lastMessage =>
      thread['last_message']?.toString() ??
      thread['preview']?.toString() ?? '';

  String get _time {
    final raw = thread['last_message_time']?.toString() ??
        thread['updated_at']?.toString() ??
        '';
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inHours < 1) return '${diff.inMinutes}m';
      if (diff.inDays < 1) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  int get _unread =>
      thread['unread_count'] is int ? thread['unread_count'] as int : 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: IceColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: IceColors.border),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [IceColors.navy, IceColors.navyDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _groupName.isNotEmpty ? _groupName[0].toUpperCase() : 'G',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(_groupName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _unread > 0
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: IceColors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (_time.isNotEmpty)
                        Text(_time,
                            style: TextStyle(
                              fontSize: 11,
                              color: _unread > 0
                                  ? IceColors.navyDeep
                                  : IceColors.muted,
                              fontWeight: _unread > 0
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            )),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _lastMessage.isEmpty
                              ? 'No messages yet'
                              : _lastMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: _lastMessage.isEmpty
                                ? IceColors.muted
                                : IceColors.text.withAlpha(160),
                            fontWeight: _unread > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: IceColors.navyDeep,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_unread',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 40 * index))
        .fadeIn(duration: 250.ms)
        .slideX(begin: 0.05, duration: 250.ms);
  }
}

// ─── Chat Screen ──────────────────────────────────────────────────────────────

class _ChatScreen extends StatefulWidget {
  final Map thread;
  const _ChatScreen({required this.thread});

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  bool _loading = true;
  List<dynamic> _messages = [];
  final _scrollCtrl = ScrollController();
  final _msgCtrl = TextEditingController();
  bool _sending = false;

  String get _groupName =>
      widget.thread['group_name']?.toString() ??
      widget.thread['name']?.toString() ??
      'Chat';

  dynamic get _threadId =>
      widget.thread['id'] ?? widget.thread['group_id'];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio
          .get('/messages/$_threadId/');
      final data = res.data;
      List<dynamic> msgs = [];
      if (data is List) {
        msgs = data;
      } else if (data is Map) {
        msgs = (data['messages'] as List?) ?? [];
      }
      setState(() { _messages = msgs; _loading = false; });
      _scrollToBottom();
    } catch (_) {
      setState(() { _loading = false; });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() { _sending = true; });
    _msgCtrl.clear();
    try {
      await ApiClient.instance.dio.post(
        '/messages/$_threadId/',
        data: {'message': text},
      );
      await _fetch();
    } catch (_) {
      setState(() { _sending = false; });
    }
    setState(() { _sending = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IceColors.bg,
      appBar: AppBar(
        backgroundColor: IceColors.bg,
        elevation: 0,
        leading: const BackButton(color: IceColors.text),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [IceColors.navy, IceColors.navyDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _groupName.isNotEmpty ? _groupName[0].toUpperCase() : 'G',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_groupName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: IceColors.text,
                  )),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: IceColors.navyDeep))
                : _messages.isEmpty
                    ? const Center(
                        child: Text('No messages yet.',
                            style: TextStyle(color: IceColors.muted)))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _MessageBubble(
                          message: _messages[i] as Map,
                        ),
                      ),
          ),

          // Message input
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: IceColors.surface,
                border: Border(top: BorderSide(color: IceColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: IceColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: IceColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: IceColors.navyDeep),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _sending
                            ? IceColors.border
                            : IceColors.navyDeep,
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
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

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Map message;
  const _MessageBubble({required this.message});

  bool get _isSent =>
      message['is_mine'] == true || message['sender_type'] == 'me';

  String get _text =>
      message['message']?.toString() ?? message['text']?.toString() ?? '';

  String get _senderName =>
      message['sender_name']?.toString() ?? '';

  String get _time {
    final raw = message['created_at']?.toString() ??
        message['timestamp']?.toString() ?? '';
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            _isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isSent) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: IceColors.navyDeep.withAlpha(15),
              child: Text(
                _senderName.isNotEmpty ? _senderName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: IceColors.navyDeep,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isSent ? IceColors.navyDeep : IceColors.surface2,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(_isSent ? 16 : 4),
                  bottomRight: Radius.circular(_isSent ? 4 : 16),
                ),
                border: _isSent
                    ? null
                    : Border.all(color: IceColors.border),
              ),
              child: Column(
                crossAxisAlignment: _isSent
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!_isSent && _senderName.isNotEmpty) ...[
                    Text(_senderName,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: IceColors.navyDeep,
                        )),
                    const SizedBox(height: 2),
                  ],
                  Text(_text,
                      style: TextStyle(
                        fontSize: 14,
                        color: _isSent ? Colors.white : IceColors.text,
                      )),
                  if (_time.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(_time,
                        style: TextStyle(
                          fontSize: 10,
                          color: _isSent
                              ? Colors.white.withAlpha(140)
                              : IceColors.muted,
                        )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── States ───────────────────────────────────────────────────────────────────

class _ComingSoonState extends StatelessWidget {
  const _ComingSoonState();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 56, color: IceColors.muted),
            SizedBox(height: 16),
            Text(
              'Messaging coming soon',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: IceColors.text),
            ),
            SizedBox(height: 8),
            Text(
              'Group chat is being set up.\nCheck back soon!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: IceColors.muted),
            ),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mark_chat_unread_outlined,
                size: 48, color: IceColors.muted),
            SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: IceColors.muted),
            ),
            SizedBox(height: 8),
            Text(
              'Messages from your groups will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: IceColors.muted),
            ),
          ],
        ),
      );
}
