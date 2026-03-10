import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/hive_setup.dart';
import 'core/superbase_client.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  await initSupabase(); // Supabase init
  runApp(const AgroApp());
}

class AgroApp extends StatelessWidget {
  const AgroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agroecology App',
      debugShowCheckedModeBanner: false,

      // 🌱 GLOBAL LIGHT-GREEN THEME
      theme: ThemeData(
        useMaterial3: true,

        // Seed color drives the whole palette
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF66BB6A), // fresh eco green
          brightness: Brightness.light,
        ),

        // Default app background
        scaffoldBackgroundColor: const Color(0xFFE9F7EF),

        // AppBars
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Color(0xFFE9F7EF),
          foregroundColor: Color(0xFF1B5E20),
          surfaceTintColor: Colors.transparent,
        ),

        // Cards / panels
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),

        // Inputs (forms)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFB7E4C7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF2E7D32),
              width: 2,
            ),
          ),
          labelStyle: const TextStyle(color: Color(0xFF1B5E20)),
        ),

        // Filled buttons (primary actions)
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        // Outlined buttons
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1B5E20),
            side: const BorderSide(color: Color(0xFF66BB6A)),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        // Floating Action Buttons
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),

        // Tabs (Trinidad / Tobago)
        tabBarTheme: const TabBarThemeData(
          labelColor: Color(0xFF1B5E20),
          unselectedLabelColor: Color(0xFF4E7C5B),
          indicatorColor: Color(0xFF2E7D32),
        ),

        // Typography defaults
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1B5E20),
          ),
          titleMedium: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B5E20),
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF1B5E20),
          ),
          bodySmall: TextStyle(
            color: Color(0xFF2F5D3A),
          ),
        ),
      ),

       home: AuthGate(repository: AuthRepository()),
    );
  }
}
