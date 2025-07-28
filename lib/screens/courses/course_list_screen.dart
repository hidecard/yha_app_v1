import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'course_detail_screen.dart';
import 'course_edit_screen.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  String? _selectedCategory;
  String? _selectedSubject;

  bool get isAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email == 'admin@yha.com' || user?.email == 'admin@gmail.com';
  }

  Future<void> _deleteCourse(String courseId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Are you sure you want to delete "$title"?'),
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
            .child('courses')
            .child(courseId)
            .remove();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting course: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Courses', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Add search functionality later
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header section with filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Find the perfect course for you',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                // Filters
                Row(
                  children: [
                    Expanded(child: _buildCategoryFilter()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSubjectFilter()),
                  ],
                ),
              ],
            ),
          ),
          // Courses list
          Expanded(child: _buildCoursesList()),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/admin');
              },
              backgroundColor: Colors.blue[600],
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildCategoryFilter() {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref().child('categories').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Text('No categories');
        }
        
        final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        final categories = <String>['All'];
        
        for (var entry in data.entries) {
          final categoryData = entry.value as Map<dynamic, dynamic>;
          if (categoryData['name'] != null) {
            categories.add(categoryData['name']);
          }
        }

        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
          value: _selectedCategory,
          items: categories.map((category) {
            return DropdownMenuItem(
              value: category == 'All' ? null : category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
        );
      },
    );
  }

  Widget _buildSubjectFilter() {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref().child('subjects').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Text('No subjects');
        }
        
        final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        final subjects = <String>['All'];
        
        for (var entry in data.entries) {
          final subjectData = entry.value as Map<dynamic, dynamic>;
          if (subjectData['name'] != null) {
            subjects.add(subjectData['name']);
          }
        }

        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Subject',
            border: OutlineInputBorder(),
          ),
          value: _selectedSubject,
          items: subjects.map((subject) {
            return DropdownMenuItem(
              value: subject == 'All' ? null : subject,
              child: Text(subject),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSubject = value;
            });
          },
        );
      },
    );
  }

  Widget _buildCoursesList() {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref().child('courses').onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No courses available', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        var courses = data.entries.where((entry) {
          final courseData = entry.value as Map<dynamic, dynamic>;
          return courseData['status'] != 'deleted';
        }).toList();

        // Apply filters
        if (_selectedCategory != null) {
          courses = courses.where((course) {
            final courseData = course.value as Map<dynamic, dynamic>;
            return courseData['category'] == _selectedCategory;
          }).toList();
        }

        if (_selectedSubject != null) {
          courses = courses.where((course) {
            final courseData = course.value as Map<dynamic, dynamic>;
            if (courseData['subjects'] != null) {
              final subjects = List<String>.from(courseData['subjects']);
              return subjects.contains(_selectedSubject);
            }
            return false;
          }).toList();
        }

        if (courses.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_list_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No courses match your filters', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            final courseData = course.value as Map<dynamic, dynamic>;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CourseDetailScreen(courseId: course.key),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course image with overlay
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: _buildCourseImage(courseData['imageUrl']),
                        ),
                        // Category badge
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              courseData['category'] ?? 'General',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        // Admin controls
                        if (isAdmin)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CourseEditScreen(courseId: course.key),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                    onPressed: () => _deleteCourse(
                                      course.key,
                                      courseData['title'] ?? 'Unknown Course',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Course details
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and rating
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  courseData['title'] ?? 'No Title',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, size: 14, color: Colors.amber[700]),
                                    const SizedBox(width: 2),
                                    Text(
                                      '4.5',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.amber[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Description
                          Text(
                            courseData['description'] ?? 'No Description',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          // Instructor and students
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.blue[100],
                                child: Icon(Icons.person, size: 14, color: Colors.blue[600]),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  courseData['instructor'] ?? 'No Instructor',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '1.2k students',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Subjects and price
                          Row(
                            children: [
                              Expanded(
                                child: courseData['subjects'] != null
                                    ? Wrap(
                                        spacing: 4,
                                        children: (courseData['subjects'] as List).take(2).map((subject) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              subject.toString(),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      )
                                    : const SizedBox(),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  courseData['fee'] ?? 'Free',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildCourseImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey[200],
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) {
            print('Course image load error: $error');
            return Container(
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
            );
          },
          fadeInDuration: const Duration(milliseconds: 200),
        ),
      );
    }
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 40, color: Colors.grey),
          SizedBox(height: 4),
          Text('No image', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
