import 'package:flutter/material.dart';

class ProfileSettingsScreen extends StatelessWidget {
  final VoidCallback? onSignOut;

  const ProfileSettingsScreen({super.key, this.onSignOut});

  void _handleSignOut(BuildContext context) {
    Navigator.of(context).pop();
    onSignOut?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Privacy'),
                  subtitle: const Text('Manage visibility and account security'),
                  onTap: () {},
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  subtitle: const Text('Choose what alerts you receive'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: theme.colorScheme.errorContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: theme.colorScheme.onErrorContainer,
              ),
              title: Text(
                'Log out',
                style: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _handleSignOut(context),
            ),
          ),
        ],
      ),
    );
  }
}


