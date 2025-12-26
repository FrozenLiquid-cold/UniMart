import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class NotificationsButton extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onTap;

  const NotificationsButton({required this.isDarkMode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final authUser = AuthService.getUser();
    final String? currentUserId = authUser != null
        ? authUser['id'] as String?
        : null;

    if (currentUserId == null) {
      return _buildButton(context, 0);
    }

    return StreamBuilder<List<NotificationItem>>(
      stream: FirestoreService.getUserNotificationsStream(currentUserId),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? const <NotificationItem>[];
        final int unreadCount = notifications
            .where((notification) => notification.read == false)
            .length;
        return _buildButton(context, unreadCount);
      },
    );
  }

  Widget _buildButton(BuildContext context, int unreadCount) {
    final borderColor = isDarkMode
        ? const Color(0xFF334155)
        : Colors.grey.shade200;
    final backgroundColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final iconColor = isDarkMode ? Colors.white : const Color(0xFF2563EB);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
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
              child: Icon(Icons.notifications_outlined, color: iconColor),
            ),
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                unreadCount > 9 ? '9+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
