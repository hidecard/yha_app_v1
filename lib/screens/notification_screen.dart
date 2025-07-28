import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'New Course Available',
        'message': 'Flutter for Beginners is now open for enrollment.',
        'time': '2h ago',
        'unread': true,
      },
      {
        'title': 'Assignment Reminder',
        'message': 'Don’t forget to submit your assignment by Friday.',
        'time': '5h ago',
        'unread': false,
      },
      {
        'title': 'Class Schedule Updated',
        'message': 'UI/UX Design Basics class moved to Aug 15.',
        'time': '1d ago',
        'unread': true,
      },
    ];
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueGrey,
        elevation: 0.5,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final n = notifications[index];
          return Container(
            decoration: BoxDecoration(
              color: n['unread'] as bool ? Colors.blue[50] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              leading: Icon(
                n['unread'] as bool
                    ? Icons.notifications_active
                    : Icons.notifications_none,
                color: n['unread'] as bool
                    ? Colors.blueAccent
                    : Colors.blueGrey,
                size: 32,
              ),
              title: Text(
                n['title'] as String,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                ),
              ),
              subtitle: Text(
                n['message'] as String,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.blueGrey[500]),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    n['time'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blueGrey[400],
                    ),
                  ),
                  if (n['unread'] as bool)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              onTap: () {
                // TODO: Mark as read or show detail
              },
            ),
          );
        },
      ),
    );
  }
}
