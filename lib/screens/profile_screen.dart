import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'No Name';
    final email = user?.email ?? 'No Email';
    final photoURL = user?.photoURL;
    final avatarWidget = (photoURL != null && photoURL.isNotEmpty)
        ? CircleAvatar(radius: 48, backgroundImage: NetworkImage(photoURL))
        : CircleAvatar(
            radius: 48,
            backgroundColor: Colors.blue[100],
            child: Text(displayName[0], style: const TextStyle(fontSize: 36)),
          );
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueGrey,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                avatarWidget,
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey[400]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text(
                        'Course History',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Remove or comment out all (user['courses'] as List) and (user['certificates'] as List) usages, so only Firebase Auth info is shown for now.
                  // ...List.generate(
                  //   (user['courses'] as List).length,
                  //   (i) => Padding(
                  //     padding: const EdgeInsets.symmetric(vertical: 4),
                  //     child: Row(
                  //       children: [
                  //         const Icon(
                  //           Icons.check_circle,
                  //           color: Colors.green,
                  //           size: 18,
                  //         ),
                  //         const SizedBox(width: 8),
                  //         Text(
                  //           (user['courses'] as List)[i],
                  //           style: Theme.of(context).textTheme.bodyMedium,
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text(
                        'Certificates',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ...List.generate(
                  //   (user['certificates'] as List).length,
                  //   (i) => Padding(
                  //     padding: const EdgeInsets.symmetric(vertical: 4),
                  //     child: Row(
                  //       children: [
                  //         const Icon(
                  //           Icons.picture_as_pdf,
                  //           color: Colors.orange,
                  //           size: 18,
                  //         ),
                  //         const SizedBox(width: 8),
                  //         Text(
                  //           (user['certificates'] as List)[i],
                  //           style: Theme.of(context).textTheme.bodyMedium,
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
            icon: const Icon(Icons.lock_reset),
            label: const Text('Change Password'),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
