import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'chat_detail_screen.dart';
import 'item_detail_screen.dart';
import 'user_profile_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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

  Color _badgeColor(String type) {
    switch (type) {
      case 'follow':
        return const Color(0xFF06B6D4);
      case 'comment':
        return const Color(0xFF8B5CF6);
      case 'message':
        return const Color(0xFF10B981);
      case 'like':
        return const Color(0xFFF43F5E);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'follow':
        return Icons.person_add_alt;
      case 'comment':
        return Icons.comment_outlined;
      case 'message':
        return Icons.message_outlined;
      case 'like':
        return Icons.favorite_border;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authUser = AuthService.getUser();
    final String? currentUserId = authUser != null
        ? authUser['id'] as String?
        : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(
              child: currentUserId == null
                  ? _buildEmptyState(theme)
                  : StreamBuilder<List<NotificationItem>>(
                      stream: FirestoreService.getUserNotificationsStream(
                        currentUserId,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final notifications = snapshot.data ?? [];

                        if (notifications.isEmpty) {
                          return _buildEmptyState(theme);
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            final badgeColor = _badgeColor(notification.type);
                            final avatarImage = _avatarImageProvider(
                              notification.userAvatar,
                            );

                            return InkWell(
                              onTap: () async {
                                // Mark as read (fire and forget)
                                FirestoreService.markNotificationRead(
                                  currentUserId,
                                  notification.id,
                                );

                                // Navigate based on notification type.
                                if ((notification.type == 'like' ||
                                        notification.type == 'comment') &&
                                    notification.itemId != null) {
                                  final itemId = notification.itemId!;
                                  final Item? item =
                                      await FirestoreService.getItemById(
                                        itemId,
                                      );
                                  if (item != null) {
                                    // ignore: use_build_context_synchronously
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ItemDetailScreen(item: item),
                                      ),
                                    );
                                  }
                                } else if (notification.type == 'follow' &&
                                    notification.fromUserId != null) {
                                  final fromUserId = notification.fromUserId!;
                                  final seller =
                                      await FirestoreService.getSellerById(
                                        fromUserId,
                                      );
                                  if (seller != null) {
                                    // ignore: use_build_context_synchronously
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            UserProfileScreen(seller: seller),
                                      ),
                                    );
                                  }
                                } else if (notification.type == 'message' &&
                                    notification.fromUserId != null) {
                                  final fromUserId = notification.fromUserId!;
                                  final seller =
                                      await FirestoreService.getSellerById(
                                        fromUserId,
                                      );
                                  if (seller != null) {
                                    // ignore: use_build_context_synchronously
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ChatDetailScreen(seller: seller),
                                      ),
                                    );
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: notification.read
                                        ? (isDark
                                              ? Colors.white10
                                              : const Color(0xFFE2E8F0))
                                        : badgeColor.withValues(alpha: 0.4),
                                    width: notification.read ? 1 : 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withValues(alpha: 0.35)
                                          : const Color(0x11000000),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
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
                                        Positioned(
                                          bottom: -2,
                                          right: -2,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: badgeColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: Icon(
                                              _iconForType(notification.type),
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          RichText(
                                            text: TextSpan(
                                              style: theme.textTheme.bodyMedium,
                                              children: [
                                                TextSpan(
                                                  text: notification.userName,
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: theme
                                                            .colorScheme
                                                            .onSurface,
                                                      ),
                                                ),
                                                TextSpan(
                                                  text: ' ${notification.text}',
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .outline,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            notification.timestamp,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      theme.colorScheme.outline,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!notification.read)
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: badgeColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
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
        'Notifications',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final muted = theme.brightness == Brightness.dark
        ? Colors.white60
        : const Color(0xFF475569);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 72,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
