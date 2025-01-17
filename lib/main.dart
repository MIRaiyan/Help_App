import 'package:flutter/material.dart';
import 'package:help/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'map_page.dart'; // Import your MapPage here

final ThemeData appTheme = ThemeData(
  primarySwatch: Colors.blue,
  visualDensity: VisualDensity.adaptivePlatformDensity,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(
      url:
          'https://mltezrwluvgiurrkprha.supabase.co', // Replace with your Supabase URL
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1sdGV6cndsdXZnaXVycmtwcmhhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzY2NDQxMzMsImV4cCI6MjA1MjIyMDEzM30.UYM5q-21gSzWO3-sT_2TDneOeH9_nwgLp8DaQcBFW1s', // Replace with your Supabase Anon Key
    );
    print('Supabase initialized successfully');
  } catch (e) {
    print('Error initializing Supabase: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthGate(),
    );
  }
}
