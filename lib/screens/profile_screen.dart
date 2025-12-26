import 'package:flutter/material.dart';
import '../data/item_store.dart';
import '../models/item.dart';
import '../services/auth_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import 'edit_profile_screen.dart';
import 'item_detail_screen.dart';
import 'profile_settings_screen.dart';

enum _ProfileTab { posts, saved, followers, following }

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onSignOut;

  const ProfileScreen({super.key, this.onSignOut});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  _ProfileTab _activeTab = _ProfileTab.posts;
  late Map<String, String> _profileData;
  late final ItemStore _itemStore;
  late final ValueNotifier<List<Item>> _itemsNotifier;
  List<Item> _userPosts = [];
  List<Item> _savedPosts = [];
  int _followersCount = 0;
  int _followingCount = 0;
  List<Map<String, String>> _followersPeople = [];
  List<Map<String, String>> _followingPeople = [];
  bool _isLoadingFollowers = false;
  bool _isLoadingFollowing = false;
  List<String> _followingIds = [];

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

  Map<String, String> get _defaultProfile => {
    'id': 'current-user',
    'name': 'Jordan Smith',
    'email': 'student@university.edu',
    'avatar': 'https://api.dicebear.com/7.x/avataaars/svg?seed=Jordan',
    'bio':
        'Engineering Student | Tech enthusiast | Always hunting for the best campus deals 🎓',
  };

  @override
  void initState() {
    super.initState();
    final authUser = AuthService.getUser();
    _profileData = {
      ..._defaultProfile,
      if (authUser != null)
        ...authUser.map((key, value) => MapEntry(key, value?.toString() ?? '')),
    };

    if (authUser != null) {
      final Object? followersValue = authUser['followers'];
      if (followersValue is int) {
        _followersCount = followersValue;
      }
      final Object? followingValue = authUser['following'];
      if (followingValue is List) {
        _followingCount = followingValue.length;
      }
    }

    _itemStore = ItemStore.instance;
    _itemsNotifier = _itemStore.itemsNotifier;
    _syncItems(_itemsNotifier.value, shouldSetState: false);
    _itemsNotifier.addListener(_handleItemsChanged);
    _refreshUserData();
  }

  @override
  void dispose() {
    _itemsNotifier.removeListener(_handleItemsChanged);
    super.dispose();
  }

  void _handleItemsChanged() {
    _syncItems(_itemsNotifier.value);
  }

  void _syncItems(List<Item> items, {bool shouldSetState = true}) {
    final userId = _profileData['id'] ?? 'current-user';
    final userItems = items.where((item) => item.seller.id == userId).toList();

    // Build saved items list based on the current user's savedPosts array
    List<String> savedIds = [];
    final sessionUser = AuthService.getUser();
    if (sessionUser != null) {
      final Object? savedValue = sessionUser['savedPosts'];
      if (savedValue is List) {
        savedIds = savedValue.whereType<String>().toList();
      }
    }
    final savedItems = items
        .where((item) => savedIds.contains(item.id))
        .toList();
    void apply() {
      _userPosts = userItems;
      _savedPosts = savedItems;
    }

    if (shouldSetState && mounted) {
      setState(apply);
    } else {
      apply();
    }
  }

  Future<void> _refreshUserData() async {
    try {
      final firebaseUser = FirebaseAuthService.getCurrentUser();
      if (firebaseUser == null) return;

      final userData = await FirebaseAuthService.getUserData(firebaseUser.uid);
      if (userData == null) return;

      final Map<String, dynamic> userDataForApp = {
        ...userData,
        'id': firebaseUser.uid,
      };

      await AuthService.setSession(firebaseUser.uid, userDataForApp);

      if (!mounted) return;

      setState(() {
        _profileData = {
          ..._defaultProfile,
          ...userDataForApp.map(
            (key, value) =>
                MapEntry(key, value == null ? '' : value.toString()),
          ),
        };

        final Object? followersValue = userDataForApp['followers'];
        if (followersValue is int) {
          _followersCount = followersValue;
        } else {
          _followersCount = 0;
        }

        final Object? followingValue = userDataForApp['following'];
        if (followingValue is List) {
          _followingIds = followingValue.whereType<String>().toList();
          _followingCount = _followingIds.length;
        } else {
          _followingIds = [];
          _followingCount = 0;
        }
      });

      await _loadFollowPeople(firebaseUser.uid);
    } catch (_) {
      // If refresh fails, keep existing profile data
    }
  }

  Future<void> _loadFollowPeople(String userId) async {
    if (!mounted) return;

    setState(() {
      _isLoadingFollowers = true;
      _isLoadingFollowing = true;
    });

    try {
      final followers = await FirestoreService.getFollowersList(userId);
      final following = await FirestoreService.getFollowingList(userId);

      if (!mounted) return;

      setState(() {
        _followersPeople = followers;
        _followingPeople = following;
        _followersCount = followers.length;
        _followingCount = following.length;
        _isLoadingFollowers = false;
        _isLoadingFollowing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingFollowers = false;
        _isLoadingFollowing = false;
      });
    }
  }

  Future<void> _openEditProfile() async {
    final updatedData = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(profileData: _profileData),
      ),
    );

    if (updatedData != null && updatedData.isNotEmpty) {
      setState(() {
        _profileData = {..._profileData, ...updatedData};
      });
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileSettingsScreen(onSignOut: widget.onSignOut),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(theme, borderColor),
              const SizedBox(height: 12),
              _buildProfileActions(theme),
              const SizedBox(height: 16),
              _buildTabs(theme),
              const SizedBox(height: 16),
              _buildContent(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileActions(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openEditProfile,
        icon: const Icon(Icons.edit),
        label: const Text('Edit Profile'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Color borderColor) {
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? Colors.white70 : const Color(0xFF475569);
    final name = _profileData['name']!;
    final email = _profileData['email']!;
    final bio = _profileData['bio']!;
    final avatar = _profileData['avatar']!.isNotEmpty
        ? _profileData['avatar']!
        : _defaultProfile['avatar']!;
    final avatarImage = _avatarImageProvider(avatar);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0x11000000),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: avatarImage,
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
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _openSettings,
                icon: Icon(Icons.settings, color: theme.colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            bio,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat('Posts', _userPosts.length.toString(), theme),
              _stat('Followers', _followersCount.toString(), theme),
              _stat('Following', _followingCount.toString(), theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, ThemeData theme) {
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

  Widget _buildTabs(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: _ProfileTab.values.map((tab) {
          final isActive = tab == _activeTab;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeTab = tab;
                  if (tab == _ProfileTab.saved) {
                    _syncItems(_itemsNotifier.value, shouldSetState: false);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    tab.name[0].toUpperCase() + tab.name.substring(1),
                    style: TextStyle(
                      color: isActive
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    switch (_activeTab) {
      case _ProfileTab.posts:
        return _buildItemsGrid(_userPosts, theme);
      case _ProfileTab.saved:
        return _buildItemsGrid(_savedPosts, theme);
      case _ProfileTab.followers:
      case _ProfileTab.following:
        return _buildPeopleList(theme);
    }
  }

  Widget _buildItemsGrid(List<Item> items, ThemeData theme) {
    if (items.isEmpty) {
      return _buildEmptyState('Nothing here yet', theme);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(item.image, fit: BoxFit.cover),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${item.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFF5EEAD4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeopleList(ThemeData theme) {
    final isFollowersTab = _activeTab == _ProfileTab.followers;
    final people = isFollowersTab ? _followersPeople : _followingPeople;
    final isLoading = isFollowersTab
        ? _isLoadingFollowers
        : _isLoadingFollowing;
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (people.isEmpty) {
      final message = isFollowersTab
          ? 'No followers yet'
          : 'You are not following anyone yet';
      return _buildEmptyState(message, theme);
    }

    return Column(
      children: people.map((person) {
        final avatarImage = _avatarImageProvider(person['avatar'] ?? '');
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: avatarImage,
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
                    Text(
                      person['name']!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      person['username']!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(isFollowersTab ? 'Follow' : 'Following'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String message, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }
}
