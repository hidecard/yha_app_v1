import 'package:flutter/material.dart';

class ChatDetailScreen extends StatelessWidget {
  const ChatDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy chat messages
    final List<Map<String, dynamic>> messages = [
      {
        'fromMe': false,
        'user': 'John Doe',
        'avatar': null,
        'time': '09:30',
        'content': 'Hi! Are you joining the class today?',
      },
      {
        'fromMe': true,
        'user': 'Me',
        'avatar': null,
        'time': '09:31',
        'content': 'Yes, I will be there!',
      },
      {
        'fromMe': false,
        'user': 'John Doe',
        'avatar': null,
        'time': '09:32',
        'content': 'Great! See you soon.',
      },
    ];
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: const Text('J'),
            ),
            const SizedBox(width: 12),
            const Text('John Doe'),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueGrey,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['fromMe'] as bool;
                return Row(
                  mainAxisAlignment: isMe
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isMe)
                      CircleAvatar(
                        backgroundColor: Colors.blue[50],
                        radius: 16,
                        child: Text((msg['user'] as String)[0]),
                      ),
                    if (!isMe) const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blueAccent : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg['content'] as String,
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white
                                    : Colors.blueGrey[900],
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg['time'] as String,
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white70
                                    : Colors.blueGrey[400],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isMe) const SizedBox(width: 8),
                    if (isMe)
                      const CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        radius: 16,
                        child: Text('M', style: TextStyle(color: Colors.white)),
                      ),
                  ],
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
