import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'course_edit_screen.dart';

class CourseDetailScreen extends StatelessWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  bool get isAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email == 'admin@yha.com' || user?.email == 'admin@gmail.com';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueGrey,
        elevation: 0.5,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseEditScreen(courseId: courseId),
                  ),
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref().child('courses').child(courseId).onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('Course not found'));
          }

          final courseData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course image
                if (courseData['imageUrl'] != null && courseData['imageUrl'].toString().isNotEmpty)
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                    ),
                    child: CachedNetworkImage(
                      imageUrl: courseData['imageUrl'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        print('Image load error for ${courseData['title']}: $error');
                        return Container(
                          color: Colors.grey[200],
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Image not available', 
                                style: TextStyle(color: Colors.grey, fontSize: 14)),
                            ],
                          ),
                        );
                      },
                      httpHeaders: const {
                        'Cache-Control': 'no-cache',
                        'Accept': 'image/*',
                      },
                      fadeInDuration: const Duration(milliseconds: 300),
                      memCacheWidth: 800,
                      memCacheHeight: 600,
                    ),
                  )
                else
                  Container(
                    height: 250,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 50, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No image', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseData['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        courseData['description'] ?? 'No Description',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Instructor', courseData['instructor']),
                      _buildInfoRow('Category', courseData['category']),
                      _buildInfoRow('Date', courseData['date']),
                      _buildInfoRow('Fee', courseData['fee']),
                      
                      if (courseData['subjects'] != null) ...[
                        const SizedBox(height: 16),
                        const Text('Subjects:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: (courseData['subjects'] as List).map((subject) {
                            return Chip(label: Text(subject.toString()));
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value?.toString() ?? 'Not specified'),
          ),
        ],
      ),
    );
  }
}
