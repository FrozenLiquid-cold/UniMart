import 'dart:async';
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final Seller seller;

  const ChatDetailScreen({super.key, required this.seller});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  List<ChatMessage> _messages = [];

  final _controller = TextEditingController();

  bool _isSelfChat = false;
  String? _currentUserId;
  late final String _otherUserId;
  StreamSubscription<List<ChatMessage>>? _subscription;

  ImageProvider? _avatarImageProvider(String avatar) {
    if (avatar.isEmpty) return null;
    final lower = avatar.toLowerCase();
    if (!avatar.startsWith('http://') && !avatar.startsWith('https://')) {
      return null;
    }
    if (lower.endsWith('.svg') || lower.contains('/svg')) {
      return null;
    }
    return NetworkImage(avatar);
  }

  @override
  void initState() {
    super.initState();
    _otherUserId = widget.seller.id;
    final authUser = AuthService.getUser();
    String? currentUserId;
    if (authUser != null) {
      final Object? idValue = authUser['id'];
      if (idValue is String && idValue.isNotEmpty) {
        currentUserId = idValue;
      }
    }
    _currentUserId = currentUserId;
    _isSelfChat = currentUserId != null && currentUserId == _otherUserId;

    if (!_isSelfChat && _currentUserId != null) {
      _subscription =
          FirestoreService.getChatMessagesStream(
            _currentUserId!,
            _otherUserId,
          ).listen((messages) {
            if (!mounted) return;
            setState(() {
              _messages = messages;
            });
          });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_isSelfChat || _currentUserId == null) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final senderId = _currentUserId!;
    final receiverId = _otherUserId;
    _controller.clear();

    try {
      await FirestoreService.sendChatMessage(senderId, receiverId, text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final seller = widget.seller;
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.75;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(seller),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final alignment = message.isOwn
                      ? Alignment.centerRight
                      : Alignment.centerLeft;
                  final colors = message.isOwn
                      ? const [Color(0xFF06B6D4), Color(0xFF2563EB)]
                      : [
                          Theme.of(context).cardColor,
                          Theme.of(context).cardColor,
                        ];

                  return Align(
                    alignment: alignment,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: message.isOwn
                              ? LinearGradient(colors: colors)
                              : null,
                          color: message.isOwn ? null : colors.first,
                          borderRadius: BorderRadius.circular(24).copyWith(
                            bottomLeft: Radius.circular(message.isOwn ? 24 : 4),
                            bottomRight: Radius.circular(
                              message.isOwn ? 4 : 24,
                            ),
                          ),
                          boxShadow: [
                            if (message.isOwn)
                              const BoxShadow(
                                color: Color(0x4006B6D4),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: message.isOwn
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: TextStyle(
                                color: message.isOwn
                                    ? Colors.white
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              message.timestamp,
                              style: TextStyle(
                                color: message.isOwn
                                    ? Colors.white70
                                    : Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color
                                          ?.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Seller seller) {
    final avatarImage = _avatarImageProvider(seller.avatar);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: avatarImage,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  child: avatarImage == null
                      ? Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seller.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Active now',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {},
                constraints: const BoxConstraints.tightFor(width: 40),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.call_outlined),
              ),
              IconButton(
                onPressed: () {},
                constraints: const BoxConstraints.tightFor(width: 40),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.videocam_outlined),
              ),
              IconButton(
                onPressed: () {},
                constraints: const BoxConstraints.tightFor(width: 40),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isSelfChat,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _controller.text.trim().isEmpty || _isSelfChat
                ? null
                : _sendMessage,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(14),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Icon(Icons.send, size: 20),
          ),
        ],
      ),
    );
  }
}
