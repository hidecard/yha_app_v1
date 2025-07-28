import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  bool _loading = false;
  String? _error;
  File? _avatarFile;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _avatarUrl = user?.photoURL;
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _avatarFile = File(picked.path);
      });
    }
  }

  Future<String?> _uploadAvatar(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final ref = FirebaseStorage.instance.ref().child('avatars/${user.uid}.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      String? photoURL = _avatarUrl;
      if (_avatarFile != null) {
        photoURL = await _uploadAvatar(_avatarFile!);
      }
      if (user != null) {
        if (_nameController.text.trim() != user.displayName) {
          await user.updateDisplayName(_nameController.text.trim());
        }
        if (_emailController.text.trim() != user.email) {
          await user.updateEmail(_emailController.text.trim());
        }
        if (photoURL != null && photoURL != user.photoURL) {
          await user.updatePhotoURL(photoURL);
        }
        await user.reload();
      }
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarWidget = _avatarFile != null
        ? CircleAvatar(radius: 48, backgroundImage: FileImage(_avatarFile!))
        : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
        ? CircleAvatar(radius: 48, backgroundImage: NetworkImage(_avatarUrl!))
        : CircleAvatar(
            radius: 48,
            backgroundColor: Colors.blue[100],
            child: Text(
              _nameController.text.isNotEmpty ? _nameController.text[0] : '',
              style: const TextStyle(fontSize: 36),
            ),
          );
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueGrey,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Stack(
              children: [
                avatarWidget,
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter name' : null,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter email' : null,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _loading ? null : _save,
                        child: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(fontSize: 16),
                              ),
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
}
