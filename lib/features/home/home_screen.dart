// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import '../map/map_screen.dart';
import '../contributions/my_contributions_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _goToMap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MapScreen()),
    );
  }

  void _goToContributions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyContributionsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Agroecology'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // App intro / hero
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.park_rounded, size: 96, color: cs.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Grow the Map',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Log plantings, share updates, and explore contributions around you.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              // Primary action
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _goToMap(context),
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('Open Map'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Secondary actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Placeholder for a future Species screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Species catalog coming soon')),
                        );
                      },
                      icon: const Icon(Icons.local_florist_outlined),
                      label: const Text('Species'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _goToContributions(context),
                      icon: const Icon(Icons.volunteer_activism_outlined),
                      label: const Text('My Plantings'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
