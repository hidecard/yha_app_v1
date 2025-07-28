import 'package:flutter/material.dart';
import 'feed_detail_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> posts = [
      {
        'user': 'John Doe',
        'avatar': null,
        'time': '2h ago',
        'content': 'Welcome to the new course! 🎉',
        'image': null,
        'likes': 12,
        'comments': 3,
      },
      {
        'user': 'Jane Smith',
        'avatar': null,
        'time': '5h ago',
        'content': 'Don’t forget to submit your assignment by Friday.',
        'image': null,
        'likes': 8,
        'comments': 1,
      },
      {
        'user': 'Emily Lee',
        'avatar': null,
        'time': '1d ago',
        'content': 'Check out the new UI/UX Design Basics class!',
        'image': null,
        'likes': 20,
        'comments': 5,
      },
    ];
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Feed'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueGrey,
        elevation: 0.5,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final post = posts[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FeedDetailScreen(),
                ),
              );
            },
            child: Container(
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text((post['user'] as String)[0]),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post['user'] as String,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey[900],
                                ),
                          ),
                          Text(
                            post['time'] as String,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.blueGrey[400]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post['content'] as String,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.blueGrey[900],
                    ),
                  ),
                  if (post['image'] != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(post['image'] as String),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.thumb_up_alt_outlined,
                        size: 20,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 4),
                      Text('${post['likes']}'),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.comment_outlined,
                        size: 20,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 4),
                      Text('${post['comments']}'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
