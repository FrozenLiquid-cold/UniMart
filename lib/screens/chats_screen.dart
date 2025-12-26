import 'dart:async';
import 'package:flutter/material.dart';
import '../data/item_store.dart';
import '../models/item.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatConversation {
  final String chatId;
  final Seller seller;
  final String lastMessage;
  final String lastTimestamp;

  const _ChatConversation({
    required this.chatId,
    required this.seller,
    required this.lastMessage,
    required this.lastTimestamp,
  });
}

class _ChatsScreenState extends State<ChatsScreen> {
  late final TextEditingController _searchController;
  late final ItemStore _itemStore;
  late final ValueNotifier<List<Item>> _itemsNotifier;
  List<Item> _items = [];
  String? _currentUserId;
  List<_ChatConversation> _conversations = [];
  StreamSubscription<List<Map<String, dynamic>>>? _chatsSubscription;

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
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {});
    });
    _itemStore = ItemStore.instance;
    _itemsNotifier = _itemStore.itemsNotifier;
    _items = List<Item>.from(_itemsNotifier.value);
    _itemsNotifier.addListener(_handleItemsChanged);

    final authUser = AuthService.getUser();
    String? currentUserId;
    if (authUser != null) {
      final Object? idValue = authUser['id'];
      if (idValue is String && idValue.isNotEmpty) {
        currentUserId = idValue;
      }
    }
    _currentUserId = currentUserId;

    if (_currentUserId != null) {
      _chatsSubscription = FirestoreService.getUserChatsStream(_currentUserId!)
          .listen((chats) {
            _loadConversations(chats);
          });
    }
  }

  @override
  void dispose() {
    _itemsNotifier.removeListener(_handleItemsChanged);
    _chatsSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleItemsChanged() {
    setState(() {
      _items = List<Item>.from(_itemsNotifier.value);
    });
  }

  List<Seller> _uniqueSellers() {
    final authUser = AuthService.getUser();
    String? currentUserId;
    if (authUser != null) {
      final Object? idValue = authUser['id'];
      if (idValue is String && idValue.isNotEmpty) {
        currentUserId = idValue;
      }
    }
    final seen = <String>{};
    final sellers = <Seller>[];
    for (final item in _items) {
      final sellerId = item.seller.id;
      if (currentUserId != null && sellerId == currentUserId) {
        continue;
      }
      if (seen.add(sellerId)) {
        sellers.add(item.seller);
      }
    }
    return sellers;
  }

  Future<void> _loadConversations(List<Map<String, dynamic>> chats) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;

    final List<_ChatConversation> results = [];

    for (final chat in chats) {
      final participantsField = chat['participants'];
      if (participantsField is! List) continue;
      final ids = participantsField.whereType<String>().toList();
      if (!ids.contains(currentUserId)) continue;
      final otherUserId = ids.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      if (otherUserId.isEmpty) continue;

      final seller = await FirestoreService.getSellerById(otherUserId);
      if (seller == null) continue;

      final lastMessage = chat['lastMessage'] as String? ?? '';
      final lastTimestamp = chat['lastTimestamp'] as String? ?? '';

      results.add(
        _ChatConversation(
          chatId: chat['id'] as String? ?? '',
          seller: seller,
          lastMessage: lastMessage,
          lastTimestamp: lastTimestamp,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _conversations = results;
    });
  }

  List<_ChatConversation> _filteredConversations() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _conversations;
    return _conversations
        .where((chat) => chat.seller.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sellers = _uniqueSellers();
    final conversations = _filteredConversations();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            _buildSearchField(theme),
            _buildActiveFriends(sellers, theme),
            Expanded(
              child: conversations.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = conversations[index];
                        final seller = conversation.seller;
                        final avatarImage = _avatarImageProvider(seller.avatar);
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChatDetailScreen(seller: seller),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.4)
                                      : const Color(0x11000000),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: avatarImage,
                                  child: avatarImage == null
                                      ? Icon(
                                          Icons.person,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        seller.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        conversation.lastMessage.isEmpty
                                            ? 'No messages yet'
                                            : '${conversation.lastMessage} · ${conversation.lastTimestamp}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.outline,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: theme.colorScheme.outline,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : const Color(0x11000000),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        'Messages',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search messages',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
          prefixIcon: Icon(Icons.search, color: theme.colorScheme.outline),
          filled: true,
          fillColor: theme.cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFriends(List<Seller> sellers, ThemeData theme) {
    if (sellers.isEmpty) {
      return const SizedBox.shrink();
    }
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? Colors.grey[900] : Colors.grey[100],
      child: SizedBox(
        height: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Active Friends',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: sellers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final seller = sellers[index];
                  final avatarImage = _avatarImageProvider(seller.avatar);
                  return Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            backgroundImage: avatarImage,
                            child: avatarImage == null
                                ? Icon(
                                    Icons.person,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 64,
                        child: Text(
                          seller.name.split(' ').first,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Text(
        'No conversations found',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }
}
