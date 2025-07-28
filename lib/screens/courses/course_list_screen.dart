import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'course_detail_screen.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  String? _selectedCategory;
  String? _selectedSubject;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueGrey,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filters
            Row(
              children: [
                Expanded(child: _buildCategoryFilter()),
                const SizedBox(width: 16),
                Expanded(child: _buildSubjectFilter()),
              ],
            ),
            const SizedBox(height: 16),
            // Courses list
            Expanded(child: _buildCoursesList()),
          ],
        ),
      ),
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
          return const Center(child: Text('No courses available'));
        }

        final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        var courses = data.entries.toList();

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
          return const Center(child: Text('No courses match your filters'));
        }

        return ListView.separated(
          itemCount: courses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final course = courses[index];
            final courseData = course.value as Map<dynamic, dynamic>;
            
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
                    // Course image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: _buildCourseImage(courseData['imageUrl']),
                    ),
                    // Course details
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            courseData['title'] ?? 'No Title',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            courseData['description'] ?? 'No Description',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.person, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                courseData['instructor'] ?? 'No Instructor',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const Spacer(),
                              Text(
                                courseData['fee'] ?? 'Free',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (courseData['subjects'] != null)
                            Wrap(
                              spacing: 4,
                              children: (courseData['subjects'] as List).take(3).map((subject) {
                                return Chip(
                                  label: Text(
                                    subject.toString(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                );
                              }).toList(),
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
          httpHeaders: const {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
          cacheManager: DefaultCacheManager(),
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
