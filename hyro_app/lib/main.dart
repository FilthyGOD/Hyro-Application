import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://biuytttsqlevvrtbywxt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJpdXl0dHRzcWxldnZydGJ5d3h0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI3MzUxODYsImV4cCI6MjA4ODMxMTE4Nn0.HT523GGYw1vUR5Ip0LMcKslNFxQK3nVBoHW8WcOmPw8',
  );

  runApp(const HyroApp());
}
