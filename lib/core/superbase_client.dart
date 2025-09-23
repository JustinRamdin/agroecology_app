// lib/core/supabase_client.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class Supa {
  static SupabaseClient get client => Supabase.instance.client;
}

Future<void> initSupabase() async {
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dxsvnccatujgugappipo.supabase.co',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR4c3ZuY2NhdHVqZ3VnYXBwaXBvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwNTE5MTgsImV4cCI6MjA3MzYyNzkxOH0.Ai0iE_CixNk84CYs1sbNkzVjI01sAujAKnEra7KQhfA',
  );

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
}

