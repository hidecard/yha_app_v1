import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/courses/course_list_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/admin_panel_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FlutterLogo(size: 80),
            const SizedBox(height: 24),
            Text(
              'YHA App',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasData) {
          return const MainShell();
        }
        return const LoginScreen();
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  static final List<Widget> _screens = <Widget>[
    CourseListScreen(),
    FeedScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = FirebaseAuth.instance.currentUser?.email == 'admin@yha.com';
    return Scaffold(
      appBar: AppBar(
        title: const Text('YHA App'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueGrey,
        elevation: 0.5,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.blueGrey[300],
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.feed), label: 'Feed'),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YHA App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/otp_verification': (context) => const OTPVerificationScreen(),
        '/courses': (context) => const CourseListScreen(),
        '/main': (context) => const MainShell(),
        '/admin': (context) => const AdminPanelScreen(),
      },
    );
  }
}
