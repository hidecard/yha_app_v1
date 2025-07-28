import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'create_post_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String? _selectedTag;
  final List<String> _popularTags = [
    'All', 'education', 'programming', 'flutter', 'design', 'announcement'
  ];

  Future<void> _likePost(String postId, int currentLikes) async {
    try {
      await FirebaseDatabase.instance
          .ref()
          .child('posts')
          .child(postId)
          .child('likes')
          .set(currentLikes + 1);
    } catch (e) {
      print('Error liking post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Create post button
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreatePostScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue[100],
                      child: Icon(Icons.person, color: Colors.blue[600]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "What's on your mind?",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Icon(Icons.photo_library, color: Colors.green[600]),
                  ],
                ),
              ),
            ),
          ),
          
          // Tag filter
          Container(
            height: 50,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _popularTags.length,
              itemBuilder: (context, index) {
                final tag = _popularTags[index];
                final isSelected = _selectedTag == tag || (tag == 'All' && _selectedTag == null);
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tag == 'All' ? 'All' : '#$tag'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTag = tag == 'All' ? null : tag;
                      });
                    },
                    selectedColor: Colors.blue[100],
                    checkmarkColor: Colors.blue[600],
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 8),
          // Posts feed
          Expanded(child: _buildPostsFeed()),
        ],
      ),
    );
  }

  Widget _buildPostsFeed() {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance
          .ref()
          .child('posts')
          .orderByChild('timestamp')
          .onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.feed, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No posts yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                SizedBox(height: 8),
                Text('Be the first to share something!', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        var posts = data.entries.toList()
          ..sort((a, b) {
            final aTime = (a.value as Map)['timestamp'] ?? 0;
            final bTime = (b.value as Map)['timestamp'] ?? 0;
            return bTime.compareTo(aTime);
          });

        // Filter by selected tag
        if (_selectedTag != null) {
          posts = posts.where((post) {
            final postData = post.value as Map<dynamic, dynamic>;
            final tags = postData['tags'] as List<dynamic>?;
            return tags?.contains(_selectedTag) ?? false;
          }).toList();
        }

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_list, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No posts found for #$_selectedTag',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final postData = post.value as Map<dynamic, dynamic>;
            final tags = (postData['tags'] as List<dynamic>?)?.cast<String>() ?? [];
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            (postData['authorName'] ?? 'A')[0].toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                postData['authorName'] ?? 'Anonymous',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _formatTimestamp(postData['timestamp']),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_horiz),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Post content
                    if (postData['content'] != null && postData['content'].toString().isNotEmpty)
                      Text(
                        postData['content'],
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    
                    // Post tags
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: tags.map((tag) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTag = tag;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    
                    // Post image
                    if (postData['imageUrl'] != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: postData['imageUrl'],
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                SizedBox(height: 4),
                                Text('Image unavailable', 
                                  style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    // Post actions
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _likePost(
                            post.key,
                            postData['likes'] ?? 0,
                          ),
                          icon: Icon(
                            Icons.favorite_border,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          label: Text(
                            '${postData['likes'] ?? 0}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          icon: Icon(
                            Icons.comment_outlined,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          label: Text(
                            '${postData['comments'] ?? 0}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          icon: Icon(
                            Icons.share_outlined,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          label: Text(
                            'Share',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    
    final now = DateTime.now();
    final postTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(postTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
