import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign In
  Future<AuthResponse> signInWithEmailPassword(
      String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Error signing in: $e');
    }
  }

  // Sign Up
  Future<AuthResponse> signUpWithEmailPassword(
      String email, String password) async {
    try {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Error signing up: $e');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Error signing out: $e');
    }
  }

  // Get Current User Email
  String? getCurrentUserEmail() {
    try {
      final session = _supabase.auth.currentSession;
      final user = session?.user;
      return user?.email;
    } catch (e) {
      throw Exception('Error fetching current user email: $e');
    }
  }

  // Upload Image to Supabase Storage and Return the Public URL
  Future<String> uploadUserImage(File imageFile, String email, String imageType) async {
    try {
      final fileName = '$email-$imageType.jpg';
      await _supabase.storage.from('user_images').upload(fileName, imageFile);
      final publicUrl = _supabase.storage.from('user_images').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  // Insert or Update User Profile Data
  Future<void> upsertProfileData(Map<String, dynamic> profileData) async {
    try {
      final response = await _supabase.from('profiles').upsert(profileData);

      if (response.error != null) {
        throw Exception('Error upserting profile data: ${response.error.message}');
      }
    } catch (e) {
      throw Exception('Error upserting profile data: $e');
    }
  }


  // Get Current User (from session)
  User? getCurrentUser() {
    try {
      final session = _supabase.auth.currentSession;
      return session?.user;
    } catch (e) {
      throw Exception('Error fetching current user: $e');
    }
  }

// Fetch User Profile Data by Email
  Future<Map<String, dynamic>?> getProfileData(String email) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*') // Use '*' to fetch all columns or specify columns like 'user_nid, image_urls'
          .eq('email', email)
          .maybeSingle(); // Ensures it fetches a single row or null if no match

      return response; // No type casting needed
    } catch (e) {
      throw Exception('Error fetching profile data: $e');
    }
  }

// Fetch User NID by Current User's Email
  Future<String?> getUserNid() async {
    try {
      final email = getCurrentUserEmail();
      if (email == null) {
        throw Exception('No user email found in session.');
      }

      final response = await _supabase
          .from('profiles')
          .select('user_nid') // Specify the column you want to fetch
          .eq('email', email)
          .maybeSingle(); // Ensures it fetches a single row or null if no match

      return response?['user_nid'] as String?; // Safely access user_nid if response is not null
    } catch (e) {
      throw Exception('Error fetching user NID: $e');
    }
  }

}
