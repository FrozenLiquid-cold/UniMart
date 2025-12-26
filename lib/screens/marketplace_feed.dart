import 'package:flutter/material.dart';
import '../data/item_store.dart';
import '../models/item.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'notifications_screen.dart';
import 'widgets/notifications_button.dart';
import 'chat_detail_screen.dart';
import 'item_detail_screen.dart';
import 'user_profile_screen.dart';

class MarketplaceFeed extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const MarketplaceFeed({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<MarketplaceFeed> createState() => _MarketplaceFeedState();
}

class _MarketplaceFeedState extends State<MarketplaceFeed> {
  static const _categories = [
    'All',
    'Books',
    'Electronics',
    'Transport',
    'Dorm',
    'Clothes',
    'Others',
  ];

  String _selectedCategory = 'All';
  late List<Item> _items;
  late final ItemStore _itemStore;
  late final ValueNotifier<List<Item>> _itemsNotifier;

  @override
  void initState() {
    super.initState();
    _itemStore = ItemStore.instance;
    _itemsNotifier = _itemStore.itemsNotifier;
    _items = List<Item>.from(_itemsNotifier.value);
    _itemsNotifier.addListener(_handleItemsChanged);

    // Listen to category changes
    _selectedCategory = 'All';
  }

  @override
  void didUpdateWidget(MarketplaceFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update ItemStore listener when category changes
    if (_selectedCategory != 'All') {
      _itemStore.listenToCategory(_selectedCategory);
    } else {
      _itemStore.initialize();
    }
  }

  @override
  void dispose() {
    _itemsNotifier.removeListener(_handleItemsChanged);
    super.dispose();
  }

  void _handleItemsChanged() {
    setState(() {
      _items = List<Item>.from(_itemsNotifier.value);
    });
  }

  List<Item> get _filteredItems {
    if (_selectedCategory == 'All') return _items;
    return _items.where((item) => item.category == _selectedCategory).toList();
  }

  Future<void> _toggleSave(String id) async {
    final user = AuthService.getUser();
    if (user == null) return;

    final userId = user['id'] as String;
    try {
      await FirestoreService.toggleSavePost(userId, id);
      // Update UI so save icons reflect latest savedPosts
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  Future<void> _toggleLike(String id) async {
    final user = AuthService.getUser();
    if (user == null) return;

    final userId = user['id'] as String;
    try {
      await FirestoreService.toggleLike(id, userId);
      // Item will be updated via stream automatically
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to like: $e')));
      }
    }
  }

  void _openItem(Item item) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)));
  }

  void _openChat(Seller seller) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ChatDetailScreen(seller: seller)));
  }

  void _openSellerProfile(Seller seller) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UserProfileScreen(seller: seller)),
    );
  }

  void _openNotifications() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDarkMode
        ? const Color(0xFF020617)
        : const Color(0xFFF8FAFC);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ItemCard(
                      item: item,
                      isDarkMode: widget.isDarkMode,
                      onSave: () => _toggleSave(item.id),
                      onLike: () => _toggleLike(item.id),
                      onItemTap: () => _openItem(item),
                      onChatTap: () => _openChat(item.seller),
                      onSellerTap: () => _openSellerProfile(item.seller),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: widget.isDarkMode ? 0.2 : 0.05,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UNiMart',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    'Your campus marketplace',
                    style: TextStyle(
                      color: widget.isDarkMode
                          ? Colors.white70
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              NotificationsButton(
                isDarkMode: widget.isDarkMode,
                onTap: _openNotifications,
              ),
              const SizedBox(width: 8),
              _HeaderButton(
                onTap: () {
                  widget.onThemeChanged(!widget.isDarkMode);
                },
                borderColor: widget.isDarkMode
                    ? const Color(0xFF334155)
                    : Colors.grey.shade200,
                backgroundColor: widget.isDarkMode
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                iconColor: widget.isDarkMode
                    ? const Color(0xFF22D3EE)
                    : const Color(0xFF2563EB),
                icon: widget.isDarkMode
                    ? Icons.wb_sunny_outlined
                    : Icons.nightlight_round,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                    // Update ItemStore listener
                    if (category == 'All') {
                      _itemStore.initialize();
                    } else {
                      _itemStore.listenToCategory(category);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                            )
                          : null,
                      color: isSelected
                          ? null
                          : (widget.isDarkMode
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: isSelected
                          ? [
                              const BoxShadow(
                                color: Color(0x4006B6D4),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (widget.isDarkMode
                                    ? Colors.white70
                                    : Colors.grey.shade800),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Item item;
  final bool isDarkMode;
  final VoidCallback onSave;
  final VoidCallback onLike;
  final VoidCallback onItemTap;
  final VoidCallback onChatTap;
  final VoidCallback onSellerTap;

  const _ItemCard({
    required this.item,
    required this.isDarkMode,
    required this.onSave,
    required this.onLike,
    required this.onItemTap,
    required this.onChatTap,
    required this.onSellerTap,
  });

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
  Widget build(BuildContext context) {
    final background = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final authUser = AuthService.getUser();
    String? currentUserId;
    if (authUser != null) {
      final Object? idValue = authUser['id'];
      if (idValue is String && idValue.isNotEmpty) {
        currentUserId = idValue;
      }
    }
    final bool isOwnItem =
        currentUserId != null && currentUserId == item.seller.id;

    // Determine whether this item is saved for the current user based on
    // their savedPosts array in the user document.
    List<String> savedIds = [];
    if (authUser != null) {
      final Object? savedValue = authUser['savedPosts'];
      if (savedValue is List) {
        savedIds = savedValue.whereType<String>().toList();
      }
    }
    final bool isSaved = savedIds.contains(item.id);

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.cyanAccent.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onItemTap,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(
                      item.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Center(child: Icon(Icons.image, size: 48)),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _Badge(text: item.category, isDarkMode: isDarkMode),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: _Badge(text: item.condition, isDarkMode: isDarkMode),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _SaveButton(saved: isSaved, onPressed: onSave),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onItemTap,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '\$${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: onSellerTap,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: _avatarImageProvider(
                            item.seller.avatar,
                          ),
                          child:
                              _avatarImageProvider(item.seller.avatar) == null
                              ? Icon(
                                  Icons.person,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.seller.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              Text(
                                item.postedAt,
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white54
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _LikeButton(
                        isDarkMode: isDarkMode,
                        isLiked: item.likedByMe,
                        likes: item.likes,
                        onTap: onLike,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.message_outlined,
                        label: item.commentsCount.toString(),
                        isDarkMode: isDarkMode,
                        onTap: onItemTap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isOwnItem ? null : onChatTap,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          shadowColor: const Color(
                            0xFF2563EB,
                          ).withValues(alpha: 0.4),
                        ),
                        child: const Text('Contact'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final bool isDarkMode;

  const _Badge({required this.text, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black.withValues(alpha: 0.5)
            : Colors.black54,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool saved;
  final VoidCallback onPressed;

  const _SaveButton({required this.saved, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          saved ? Icons.bookmark : Icons.bookmark_border,
          color: saved ? const Color(0xFF06B6D4) : Colors.black54,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF334155) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LikeButton extends StatelessWidget {
  final bool isDarkMode;
  final bool isLiked;
  final int likes;
  final VoidCallback onTap;

  const _LikeButton({
    required this.isDarkMode,
    required this.isLiked,
    required this.likes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkMode
        ? const Color(0xFF1E293B)
        : const Color(0xFFF8FAFC);
    final borderColor = isDarkMode
        ? const Color(0xFF334155)
        : Colors.grey.shade200;
    final textColor = isLiked
        ? Colors.redAccent
        : (isDarkMode ? Colors.white70 : Colors.grey.shade700);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: textColor,
            ),
            const SizedBox(width: 6),
            Text(
              likes.toString(),
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color borderColor;
  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;

  const _HeaderButton({
    required this.onTap,
    required this.borderColor,
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor),
        ),
      ),
    );
  }
}
