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

  Future<void> _deletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseDatabase.instance
            .ref()
            .child('posts')
            .child(postId)
            .remove();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting post: $e')),
          );
        }
      }
    }
  }

  Future<void> _editPost(String postId, String currentContent) async {
    final controller = TextEditingController(text: currentContent);
    
    final newContent = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Post'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'What\'s on your mind?',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          minLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (newContent != null && newContent.isNotEmpty && newContent != currentContent) {
      try {
        await FirebaseDatabase.instance
            .ref()
            .child('posts')
            .child(postId)
            .child('content')
            .set(newContent);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating post: $e')),
          );
        }
      }
    }
  }

  Future<void> _addComment(String postId, int currentComments) async {
    final controller = TextEditingController();
    
    final comment = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Write a comment...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          minLines: 1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Comment'),
          ),
        ],
      ),
    );

    if (comment != null && comment.isNotEmpty) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        
        // Add comment to comments collection
        await FirebaseDatabase.instance
            .ref()
            .child('comments')
            .child(postId)
            .push()
            .set({
          'content': comment,
          'authorId': user?.uid,
          'authorName': user?.displayName ?? user?.email?.split('@')[0] ?? 'Anonymous',
          'timestamp': ServerValue.timestamp,
        });

        // Update comment count
        await FirebaseDatabase.instance
            .ref()
            .child('posts')
            .child(postId)
            .child('comments')
            .set(currentComments + 1);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comment added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding comment: $e')),
          );
        }
      }
    }
  }

  void _showPostOptions(String postId, String authorId, String content) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == authorId;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Post'),
                onTap: () {
                  Navigator.pop(context);
                  _editPost(postId, content);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost(postId);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report Post'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post reported')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showComments(String postId) {
    final commentController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance
                      .ref()
                      .child('comments')
                      .child(postId)
                      .orderByChild('timestamp')
                      .onValue,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                      return const Center(
                        child: Text('No comments yet', style: TextStyle(color: Colors.grey)),
                      );
                    }

                    final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    final comments = data.entries.toList()
                      ..sort((a, b) {
                        final aTime = (a.value as Map)['timestamp'] ?? 0;
                        final bTime = (b.value as Map)['timestamp'] ?? 0;
                        return aTime.compareTo(bTime);
                      });

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final commentData = comment.value as Map<dynamic, dynamic>;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.blue[100],
                                child: Text(
                                  (commentData['authorName'] ?? 'A')[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[600],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        commentData['authorName'] ?? 'Anonymous',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        commentData['content'] ?? '',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTimestamp(commentData['timestamp']),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Comment input section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                padding: const EdgeInsets.all(16),
                child: SafeArea(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blue[100],
                        child: Icon(Icons.person, color: Colors.blue[600], size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextField(
                            controller: commentController,
                            decoration: const InputDecoration(
                              hintText: 'Write a comment...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (value) async {
                              if (value.trim().isNotEmpty) {
                                await _addCommentDirect(postId, value.trim());
                                commentController.clear();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () async {
                          if (commentController.text.trim().isNotEmpty) {
                            await _addCommentDirect(postId, commentController.text.trim());
                            commentController.clear();
                          }
                        },
                        icon: Icon(Icons.send, color: Colors.blue[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addCommentDirect(String postId, String comment) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // Add comment to comments collection
      await FirebaseDatabase.instance
          .ref()
          .child('comments')
          .child(postId)
          .push()
          .set({
        'content': comment,
        'authorId': user?.uid,
        'authorName': user?.displayName ?? user?.email?.split('@')[0] ?? 'Anonymous',
        'timestamp': ServerValue.timestamp,
      });

      // Update comment count
      final postSnapshot = await FirebaseDatabase.instance
          .ref()
          .child('posts')
          .child(postId)
          .get();
      
      if (postSnapshot.exists) {
        final postData = postSnapshot.value as Map<dynamic, dynamic>;
        final currentComments = postData['comments'] ?? 0;
        
        await FirebaseDatabase.instance
            .ref()
            .child('posts')
            .child(postId)
            .child('comments')
            .set(currentComments + 1);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: $e')),
        );
      }
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
                          onPressed: () => _showPostOptions(
                            post.key,
                            postData['authorId'] ?? '',
                            postData['content'] ?? '',
                          ),
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
                          onPressed: () => _showComments(post.key),
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
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Share functionality coming soon!')),
                            );
                          },
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
