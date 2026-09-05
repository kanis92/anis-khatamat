import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../l10n/gen_l10n/app_localizations.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Demo notifications - localized for consistency
          _NotificationCard(
            title: l10n.notificationsDemoReadingTime,
            subtitle: l10n.notificationsDemoReadingTimeBody,
            time: l10n.notificationsTimeHoursAgo(2),
            isRead: false,
            icon: Icons.menu_book,
          ),
          _NotificationCard(
            title: l10n.notificationsDemoKhatmaReminder,
            subtitle: l10n.notificationsDemoKhatmaBody,
            time: l10n.notificationsTimeYesterday,
            isRead: true,
            icon: Icons.groups,
          ),
          _NotificationCard(
            title: l10n.notificationsDemoWorkshop,
            subtitle: l10n.notificationsDemoWorkshopBody,
            time: l10n.notificationsTimeDaysAgo(3),
            isRead: true,
            icon: Icons.school,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.notificationsSettingsTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text(l10n.notificationsEnableReadingReminders),
                    subtitle: Text(l10n.notificationsReceiveHizbReminders),
                    value: true,
                    onChanged: (v) {},
                  ),
                  SwitchListTile(
                    title: Text(l10n.notificationsGroupNotifications),
                    value: true,
                    onChanged: (v) {},
                  ),
                  SwitchListTile(
                    title: Text(l10n.notificationsWorkshopReminders),
                    value: true,
                    onChanged: (v) {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final bool isRead;
  final IconData icon;

  const _NotificationCard({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isRead,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isRead ? null : AppTheme.primaryGreen.withValues(alpha: 0.05),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
          child: Icon(icon, color: AppTheme.primaryGreen),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(subtitle),
            const SizedBox(height: 4),
            Text(
              time,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton(
          itemBuilder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return [
              PopupMenuItem(value: 'read', child: Text(l10n.notificationsMarkAsRead)),
              PopupMenuItem(value: 'delete', child: Text(l10n.notificationsDelete)),
            ];
          },
        ),
      ),
    );
  }
}
