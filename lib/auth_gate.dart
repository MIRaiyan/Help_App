import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'map_page.dart';
import 'login.dart';
import 'nid_info_upload.dart';
import 'auth_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Show loading indicator while waiting for authentication state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Get the current session
        final session = snapshot.hasData ? snapshot.data!.session : null;

        // Check if a user session exists
        if (session != null) {
          // Fetch and verify user profile asynchronously
          return FutureBuilder<bool>(
            future: _isProfileComplete(),
            builder: (context, profileSnapshot) {
              // Show loading indicator while profile is being verified
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Handle profile verification result
              if (profileSnapshot.hasData && profileSnapshot.data == true) {
                // Profile is complete, navigate to the map page
                return const MapPage();
              } else {
                // Profile is incomplete, navigate to NID info upload page
                return const NidInfoUploadPage();
              }
            },
          );
        } else {
          // If no session, navigate to the login page
          return const LoginPage();
        }
      },
    );
  }

  /// Checks if the user profile is complete
  Future<bool> _isProfileComplete() async {
    try {
      // Fetch the current user's email
      final email = _authService.getCurrentUserEmail();

      if (email == null) {
        // No email found, profile is incomplete
        return false;
      }

      // Fetch the user profile from the database
      final profile = await _authService.getProfileData(email);

      // Check if required profile fields are complete
      if (profile != null &&
          profile['user_nid'] != null &&
          profile['image_urls'] != null &&
          profile['image_urls']['face'] != null &&
          profile['image_urls']['nid_front'] != null &&
          profile['image_urls']['nid_back'] != null) {
        return true; // Profile is complete
      } else {
        return false; // Profile is incomplete
      }
    } catch (e) {
      // Handle any errors during profile verification
      debugPrint('Error verifying profile: $e');
      return false;
    }
  }
}
