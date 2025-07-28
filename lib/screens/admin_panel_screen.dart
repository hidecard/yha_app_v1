import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _dateController = TextEditingController();
  final _feeController = TextEditingController();
  
  String? _selectedCategoryName;
  String? _selectedInstructorName;
  List<String> _selectedSubjects = [];
  File? _imageFile;
  Uint8List? _webImageBytes;
  String? _imageUrl;
  bool _loading = false;
  String? _error;

  bool get isAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email == 'admin@yha.com' || user?.email == 'admin@gmail.com';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _dateController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<String?> _uploadImage(File file) async {
    try {
      print('Starting image upload...');
      final fileName = 'course_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('course_images')
          .child(fileName);
      
      UploadTask uploadTask;
      if (kIsWeb && _webImageBytes != null) {
        uploadTask = ref.putData(
          _webImageBytes!,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploaded_by': FirebaseAuth.instance.currentUser?.email ?? 'unknown',
              'upload_time': DateTime.now().toIso8601String(),
            },
          ),
        );
      } else {
        uploadTask = ref.putFile(
          file,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploaded_by': FirebaseAuth.instance.currentUser?.email ?? 'unknown',
              'upload_time': DateTime.now().toIso8601String(),
            },
          ),
        );
      }
      
      // Show upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });
      
      final snapshot = await uploadTask;
      final downloadURL = await snapshot.ref.getDownloadURL();

      print('Image uploaded successfully: $downloadURL');

      // Add CORS headers and force refresh
      final corsUrl = downloadURL.contains('?') 
          ? '$downloadURL&t=${DateTime.now().millisecondsSinceEpoch}'
          : '$downloadURL?t=${DateTime.now().millisecondsSinceEpoch}';

      // Wait for Firebase to process and propagate
      await Future.delayed(const Duration(seconds: 3));

      return corsUrl;
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );
      
      if (pickedFile != null) {
        if (kIsWeb) {
          _webImageBytes = await pickedFile.readAsBytes();
          print('Web image bytes length: ${_webImageBytes?.length}');
        }
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        print('Image picked successfully: ${pickedFile.path}');
      }
    } catch (e) {
      print('Image picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _addCourse() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedSubjects.isEmpty) {
      setState(() => _error = 'Please select at least one subject');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      String? imageUrl;
      
      // Upload image if selected
      if (_imageFile != null) {
        print('Uploading image...');
        imageUrl = await _uploadImage(_imageFile!);
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
        print('Image URL: $imageUrl');
      }

      // Save course to database
      final courseData = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'date': _dateController.text.trim(),
        'fee': _feeController.text.trim(),
        'category': _selectedCategoryName,
        'subjects': _selectedSubjects,
        'instructor': _selectedInstructorName,
        'imageUrl': imageUrl,
        'createdAt': ServerValue.timestamp,
        'status': 'active',
      };

      print('Saving course data: $courseData');
      
      final courseRef = FirebaseDatabase.instance.ref().child('courses').push();
      await courseRef.set(courseData);
      
      print('Course saved successfully with ID: ${courseRef.key}');

      // Clear form
      _titleController.clear();
      _descController.clear();
      _dateController.clear();
      _feeController.clear();
      setState(() {
        _selectedCategoryName = null;
        _selectedSubjects.clear();
        _selectedInstructorName = null;
        _imageFile = null;
        _webImageBytes = null;
        _imageUrl = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course added successfully!')),
        );
      }
    } catch (e) {
      print('Error adding course: $e');
      setState(() => _error = 'Error adding course: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Course Image', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _imageFile != null
                ? kIsWeb && _webImageBytes != null
                    ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                    : Image.file(_imageFile!, fit: BoxFit.cover)
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                      Text('Tap to select image', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseForm() {
    return Column(
      children: [
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Course Title',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value?.isEmpty == true ? 'Please enter course title' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          validator: (value) => value?.isEmpty == true ? 'Please enter description' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _dateController,
          decoration: const InputDecoration(
            labelText: 'Course Date',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value?.isEmpty == true ? 'Please enter course date' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _feeController,
          decoration: const InputDecoration(
            labelText: 'Course Fee',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value?.isEmpty == true ? 'Please enter course fee' : null,
        ),
        const SizedBox(height: 12),
        // Category Dropdown
        StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance.ref().child('categories').onValue,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return const CircularProgressIndicator();
            }
            
            final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            final categories = data.entries.map((e) {
              final categoryData = e.value as Map<dynamic, dynamic>;
              return DropdownMenuItem<String>(
                value: categoryData['name'],
                child: Text(categoryData['name']),
              );
            }).toList();

            return DropdownButtonFormField<String>(
              value: _selectedCategoryName,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: categories,
              onChanged: (value) => setState(() => _selectedCategoryName = value),
              validator: (value) => value == null ? 'Please select a category' : null,
            );
          },
        ),
        const SizedBox(height: 12),
        // Subjects Multi-select
        StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance.ref().child('subjects').onValue,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return const CircularProgressIndicator();
            }
            
            final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            final subjects = data.entries.map((e) {
              final subjectData = e.value as Map<dynamic, dynamic>;
              return subjectData['name'] as String;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Subjects', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Wrap(
                  children: subjects.map((subject) {
                    return CheckboxListTile(
                      title: Text(subject),
                      value: _selectedSubjects.contains(subject),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedSubjects.add(subject);
                          } else {
                            _selectedSubjects.remove(subject);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        // Instructor Dropdown
        StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance.ref().child('instructors').onValue,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return const CircularProgressIndicator();
            }
            
            final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            final instructors = data.entries.map((e) {
              final instructorData = e.value as Map<dynamic, dynamic>;
              return DropdownMenuItem<String>(
                value: instructorData['name'],
                child: Text(instructorData['name']),
              );
            }).toList();

            return DropdownButtonFormField<String>(
              value: _selectedInstructorName,
              decoration: const InputDecoration(
                labelText: 'Instructor',
                border: OutlineInputBorder(),
              ),
              items: instructors,
              onChanged: (value) => setState(() => _selectedInstructorName = value),
              validator: (value) => value == null ? 'Please select an instructor' : null,
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Panel')),
        body: const Center(child: Text('Access denied. Admin only.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Add some test data first
          ElevatedButton(
            onPressed: _addTestData,
            child: const Text('Add Test Data'),
          ),
          const SizedBox(height: 24),
          // Course Form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add New Course', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildImagePicker(),
                    const SizedBox(height: 12),
                    _buildCourseForm(),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _addCourse,
                        child: _loading
                            ? const CircularProgressIndicator()
                            : const Text('Add Course'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addTestData() async {
    try {
      final db = FirebaseDatabase.instance.ref();
      
      // Add categories
      await db.child('categories').push().set({
        'name': 'Programming',
        'createdAt': ServerValue.timestamp,
      });
      
      await db.child('categories').push().set({
        'name': 'Design',
        'createdAt': ServerValue.timestamp,
      });
      
      // Add subjects
      await db.child('subjects').push().set({
        'name': 'Flutter',
        'createdAt': ServerValue.timestamp,
      });
      
 
     await db.child('subjects').push().set({
        'name': 'UI/UX',
        'createdAt': ServerValue.timestamp,
      });
      
      // Add instructors
      await db.child('instructors').push().set({
        'name': 'John Doe',
        'createdAt': ServerValue.timestamp,
      });
      
      await db.child('instructors').push().set({
        'name': 'Jane Smith',
        'createdAt': ServerValue.timestamp,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test data added successfully!')),
      );
    } catch (e) {
      print('Error adding test data: $e');
    }
  }
}







