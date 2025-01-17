import 'package:flutter/material.dart';
import 'package:help/auth_service.dart';
import 'register.dart';
import 'map_page.dart';
import 'nid_info_upload.dart';  // Make sure you have the correct import

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Get Auth
  final authService = AuthService();

  // text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // login button pressed
  void login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password cannot be empty')),
      );
      return;
    }

    try {
      // Sign in the user
      await authService.signInWithEmailPassword(email, password);

      // Check the user profile after logging in
      final user = authService.getCurrentUser();
      if (user != null) {
        final profileData = await authService.getProfileData(user.email!);

        // If profile data is available and user_nid and images are not present, ask for profile setup
        if (profileData != null &&
            (profileData['user_nid'] == null || profileData['image_urls'] == null)) {
          // Redirect to profile setup page (NidInfoUploadPage)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const NidInfoUploadPage(),
            ),
          );
        } else {
          // Redirect to MapPage if profile is complete
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MapPage(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 50),
        children: [
          // email
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: "Email"),
          ),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: "Password"),
            obscureText: true,
          ),

          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: login,
            child: const Text('Login'),
          ),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RegisterPage(),
              ),
            ),
            child: const Center(
              child: Text("Don't have an account? Sign Up"),
            ),
          ),
        ],
      ),
    );
  }
}
