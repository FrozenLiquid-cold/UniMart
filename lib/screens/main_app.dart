import 'package:flutter/material.dart';
import '../data/item_store.dart';
import 'marketplace_feed.dart';
import 'search_screen.dart';
import 'create_post_screen.dart';
import 'chats_screen.dart';
import 'profile_screen.dart';

class MainApp extends StatefulWidget {
  final VoidCallback onSignOut;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const MainApp({
    super.key,
    required this.onSignOut,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize ItemStore to start listening to Firestore
    ItemStore.instance.initialize();
  }

  final _navItems = const [
    _NavItem(icon: Icons.home, label: 'Home'),
    _NavItem(icon: Icons.search, label: 'Search'),
    _NavItem(icon: Icons.add_circle_outline, label: 'Post'),
    _NavItem(icon: Icons.message_outlined, label: 'Messages'),
    _NavItem(icon: Icons.person_outline, label: 'Profile'),
  ];

  List<Widget> get _screens => [
    MarketplaceFeed(
      isDarkMode: widget.isDarkMode,
      onThemeChanged: widget.onThemeChanged,
    ),
    const SearchScreen(),
    const CreateListingScreen(),
    const ChatsScreen(),
    ProfileScreen(onSignOut: widget.onSignOut),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gradientStart = isDark
        ? const Color(0xFF050C1A)
        : const Color(0xFFFFFFFF);
    final gradientEnd = isDark
        ? const Color(0xFF0B1528)
        : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStart, gradientEnd],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    Expanded(
                      child: IndexedStack(
                        index: _currentIndex,
                        children: _screens,
                      ),
                    ),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildBottomNav(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor.withValues(alpha: isDark ? 0.95 : 0.98);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.45)
                  : const Color(0x14000000),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final isActive = index == _currentIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _currentIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
