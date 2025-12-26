import 'package:flutter/material.dart';
import '../data/item_store.dart';
import '../models/item.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'chat_detail_screen.dart';
import 'item_detail_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final Seller seller;

  const UserProfileScreen({super.key, required this.seller});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late bool _isFollowing;
  late bool _isOwnProfile;
  late int _followers;
  String? _currentUserId;
  late List<Item> _listings;
  late final ItemStore _itemStore;
  late final ValueNotifier<List<Item>> _itemsNotifier;

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
    _isFollowing = widget.seller.isFollowing;
    _followers = widget.seller.followers;
    final authUser = AuthService.getUser();
    String? currentUserId;
    if (authUser != null) {
      final Object? idValue = authUser['id'];
      if (idValue is String && idValue.isNotEmpty) {
        currentUserId = idValue;
      }
    }
    _currentUserId = currentUserId;
    _isOwnProfile = currentUserId != null && currentUserId == widget.seller.id;
    _itemStore = ItemStore.instance;
    _itemsNotifier = _itemStore.itemsNotifier;
    _listings = _filterListings(_itemsNotifier.value);
    _itemsNotifier.addListener(_handleItemsChanged);
    _loadProfileData();
  }

  @override
  void dispose() {
    _itemsNotifier.removeListener(_handleItemsChanged);
    super.dispose();
  }

  List<Item> _filterListings(List<Item> items) {
    return items
        .where((item) => item.seller.id == widget.seller.id)
        .toList(growable: false);
  }

  void _handleItemsChanged() {
    setState(() {
      _listings = _filterListings(_itemsNotifier.value);
    });
  }

  Future<void> _loadProfileData() async {
    final currentUserId = _currentUserId;
    try {
      final followers = await FirestoreService.getFollowersList(
        widget.seller.id,
      );
      bool isFollowing = false;
      if (currentUserId != null && currentUserId != widget.seller.id) {
        isFollowing = await FirestoreService.isFollowing(
          currentUserId,
          widget.seller.id,
        );
      }
      if (!mounted) return;
      setState(() {
        _followers = followers.length;
        _isFollowing = isFollowing;
      });
    } catch (_) {
      // If loading fails, keep existing values
    }
  }

  Future<void> _toggleFollow() async {
    if (_isOwnProfile || _currentUserId == null) return;

    final bool newIsFollowing = !_isFollowing;
    final int delta = newIsFollowing ? 1 : (_followers > 0 ? -1 : 0);

    setState(() {
      _isFollowing = newIsFollowing;
      _followers = _followers + delta;
    });

    try {
      await FirestoreService.toggleFollow(_currentUserId!, widget.seller.id);
    } catch (e) {
      if (!mounted) return;
      // Revert UI on failure
      setState(() {
        _isFollowing = !newIsFollowing;
        _followers = _followers - delta;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update follow: $e')));
    }
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(seller: widget.seller),
      ),
    );
  }

  void _openListing(Item item) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.seller.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            onPressed: _isOwnProfile ? null : _openChat,
            icon: const Icon(Icons.chat_bubble_outline),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(theme),
            const SizedBox(height: 24),
            _buildListings(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0x11000000),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundImage: _avatarImageProvider(widget.seller.avatar),
                child: _avatarImageProvider(widget.seller.avatar) == null
                    ? Icon(
                        Icons.person,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.seller.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Trusted campus seller',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _isOwnProfile ? null : () => _toggleFollow(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFollowing
                      ? theme.colorScheme.secondaryContainer
                      : theme.colorScheme.primary,
                  foregroundColor: _isFollowing
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(_isFollowing ? 'Following' : 'Follow'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statCard('Listings', _listings.length.toString(), theme),
              _statCard('Followers', _followers.toString(), theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, ThemeData theme) {
    final muted = theme.brightness == Brightness.dark
        ? Colors.white60
        : const Color(0xFF94A3B8);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
      ],
    );
  }

  Widget _buildListings(ThemeData theme) {
    if (_listings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text('No listings yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Check back later to see what they post.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Listings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_listings.length} items',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._listings.map(
          (item) => GestureDetector(
            onTap: () => _openListing(item),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white10
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(24),
                    ),
                    child: Image.network(
                      item.image,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                '\$${item.price.toStringAsFixed(0)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFF2563EB),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
