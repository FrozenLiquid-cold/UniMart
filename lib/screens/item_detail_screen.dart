import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'chat_detail_screen.dart';
import 'user_profile_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final Item item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late Item _item;
  late bool _isSaved;
  late bool _isFollowing;
  final _commentController = TextEditingController();
  late bool _isOwnItem;
  String? _currentUserId;

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
    _item = widget.item;
    _isSaved = _item.saved;
    _isFollowing = _item.seller.isFollowing;
    final authUser = AuthService.getUser();
    String? currentUserId;
    if (authUser != null) {
      // Initialize saved state from the user's savedPosts array
      final Object? savedValue = authUser['savedPosts'];
      if (savedValue is List) {
        final savedIds = savedValue.whereType<String>().toList();
        if (savedIds.contains(_item.id)) {
          _isSaved = true;
        }
      }

      final Object? idValue = authUser['id'];
      if (idValue is String && idValue.isNotEmpty) {
        currentUserId = idValue;
      }
    }
    _currentUserId = currentUserId;
    _isOwnItem = currentUserId != null && currentUserId == _item.seller.id;
    if (!_isOwnItem && _currentUserId != null) {
      _loadFollowState();
    }
  }

  Future<void> _loadFollowState() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null || _isOwnItem) return;
    try {
      final isFollowing = await FirestoreService.isFollowing(
        currentUserId,
        _item.seller.id,
      );
      if (!mounted) return;
      setState(() {
        _isFollowing = isFollowing;
        _item = _item.copyWith(
          seller: _item.seller.copyWith(isFollowing: isFollowing),
        );
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleSaved() async {
    final authUser = AuthService.getUser();
    if (authUser == null) return;

    final String userId = authUser['id'] as String;
    final bool newIsSaved = !_isSaved;

    setState(() {
      _isSaved = newIsSaved;
      _item = _item.copyWith(saved: newIsSaved);
    });

    try {
      await FirestoreService.toggleSavePost(userId, _item.id);
    } catch (e) {
      if (!mounted) return;
      // Revert UI on failure
      setState(() {
        _isSaved = !newIsSaved;
        _item = _item.copyWith(saved: !newIsSaved);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  Future<void> _toggleFollowing() async {
    if (_isOwnItem || _currentUserId == null) return;

    final bool newIsFollowing = !_isFollowing;

    setState(() {
      _isFollowing = newIsFollowing;
      _item = _item.copyWith(
        seller: _item.seller.copyWith(isFollowing: newIsFollowing),
      );
    });

    try {
      await FirestoreService.toggleFollow(_currentUserId!, _item.seller.id);
    } catch (e) {
      if (!mounted) return;
      // Revert UI on failure
      setState(() {
        _isFollowing = !newIsFollowing;
        _item = _item.copyWith(
          seller: _item.seller.copyWith(isFollowing: !newIsFollowing),
        );
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update follow: $e')));
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      await FirestoreService.addComment(_item.id, text);
      _commentController.clear();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add comment: $e')));
    }
  }

  void _openChat() {
    if (_isOwnItem) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatDetailScreen(seller: _item.seller)),
    );
  }

  void _openSellerProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(seller: _item.seller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroImage(theme),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTitle(theme),
                              const SizedBox(height: 16),
                              _buildSellerCard(theme),
                              const SizedBox(height: 16),
                              _buildComments(theme),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          const Spacer(),
          IconButton(
            onPressed: _toggleSaved,
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isSaved ? const Color(0xFF06B6D4) : null,
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
        ],
      ),
    );
  }

  Widget _buildHeroImage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.4,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              top: 8,
              left: 8,
              right: 8,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              top: 16,
              left: 16,
              right: 16,
              bottom: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      _item.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Center(child: Icon(Icons.image, size: 48)),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _buildBadge(_item.category),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _buildBadge(_item.condition),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black87.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
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

  Widget _buildTitle(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _item.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _item.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '\$${_item.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Posted ${_item.postedAt}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard(ThemeData theme) {
    final avatarImage = _avatarImageProvider(_item.seller.avatar);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _openSellerProfile,
                  borderRadius: BorderRadius.circular(28),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: avatarImage,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        child: avatarImage == null
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
                              _item.seller.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!_isOwnItem)
                IconButton(
                  onPressed: _toggleFollowing,
                  icon: Icon(
                    _isFollowing ? Icons.how_to_reg : Icons.person_add_alt_1,
                    color: _isFollowing
                        ? const Color(0xFF06B6D4)
                        : theme.iconTheme.color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isOwnItem ? null : _openChat,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Message Seller'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComments(ThemeData theme) {
    return StreamBuilder<List<Comment>>(
      stream: FirestoreService.getCommentsStream(_item.id),
      builder: (context, snapshot) {
        final comments = snapshot.data ?? const <Comment>[];
        final isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            comments.isEmpty;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comments (${comments.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (comments.isEmpty)
                const Text('No comments yet. Be the first to ask something!'),
              if (!isLoading)
                ...comments.map((comment) {
                  final avatarImage = _avatarImageProvider(comment.userAvatar);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundImage: avatarImage,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          child: avatarImage == null
                              ? Icon(
                                  Icons.person,
                                  color: theme.colorScheme.onSurfaceVariant,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    comment.userName,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    comment.timestamp,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.textTheme.bodySmall?.color
                                          ?.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(comment.text),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _commentController.text.trim().isEmpty
                        ? null
                        : () => _addComment(),
                    icon: const Icon(Icons.send),
                    color: const Color(0xFF2563EB),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
