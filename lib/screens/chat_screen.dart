import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> chats = [
      {
        'user': 'John Doe',
        'avatar': null,
        'lastMessage': 'See you in class!',
        'time': '09:30',
        'unread': 2,
      },
      {
        'user': 'Jane Smith',
        'avatar': null,
        'lastMessage': 'Thank you!',
        'time': '08:15',
        'unread': 0,
      },
      {
        'user': 'Emily Lee',
        'avatar': null,
        'lastMessage': 'Assignment submitted.',
        'time': 'Yesterday',
        'unread': 1,
      },
    ];
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueGrey,
        elevation: 0.5,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: chats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final chat = chats[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
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
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Text((chat['user'] as String)[0]),
              ),
              title: Text(
                chat['user'] as String,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                ),
              ),
              subtitle: Text(
                chat['lastMessage'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.blueGrey[500]),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    chat['time'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blueGrey[400],
                    ),
                  ),
                  if ((chat['unread'] as int) > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${chat['unread']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatDetailScreen(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
