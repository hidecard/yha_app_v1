import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await cred.user?.updateDisplayName(_nameController.text.trim());
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OTPVerificationScreen()),
        );
      }
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  const FlutterLogo(size: 72),
                  const SizedBox(height: 16),
                  Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.blueGrey[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign up to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blueGrey[500],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Enter name' : null,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Enter email' : null,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Enter password' : null,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmController,
                          obscureText: true,
                          validator: (v) => v != _passwordController.text
                              ? 'Passwords do not match'
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
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
                            onPressed: _loading ? null : _register,
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
                                    'Register',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('or continue with'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.g_mobiledata,
                          size: 32,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {},
                        tooltip: 'Register with Google',
                      ),
                      // Add more social register buttons if needed
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
