import 'package:flutter/material.dart';
import 'package:hive/hive.dart' show Box;
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models.dart';
import '../map/map_screen.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  static const int _monthlyGoal = 25;
  static const int _nativeGoal = 12;
  static const int _newAreasGoal = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions'),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('plantings').listenable(),
        builder: (context, Box box, _) {
          final plantings = box.values
              .map((raw) => Planting.fromMap(Map<String, dynamic>.from(raw)))
              .toList();

          final monthPlantings = _currentMonthPlantings(plantings);
          final nativeCount = monthPlantings.where((p) => _isNativeLikely(p.speciesName)).length;
          final exploredAreas = monthPlantings
              .map((p) => '${p.lat.toStringAsFixed(2)},${p.lng.toStringAsFixed(2)}')
              .toSet()
              .length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _MissionProgressCard(
                title: 'Monthly planting target',
                subtitle: 'Log at least $_monthlyGoal plantings this month.',
                progress: monthPlantings.length / _monthlyGoal,
                current: monthPlantings.length,
                goal: _monthlyGoal,
                icon: Icons.forest,
              ),
              const SizedBox(height: 12),
              _MissionProgressCard(
                title: 'Native species push',
                subtitle: 'Record at least $_nativeGoal native-friendly species entries.',
                progress: nativeCount / _nativeGoal,
                current: nativeCount,
                goal: _nativeGoal,
                icon: Icons.spa,
              ),
              const SizedBox(height: 12),
              _MissionProgressCard(
                title: 'Explore new areas',
                subtitle: 'Plant in at least $_newAreasGoal different grid areas.',
                progress: exploredAreas / _newAreasGoal,
                current: exploredAreas,
                goal: _newAreasGoal,
                icon: Icons.explore,
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mission tips',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text('• Pair fruit trees with pollinator-friendly species.'),
                      const Text('• Revisit previous plantings and add status updates.'),
                      const Text('• Coordinate weekend planting with community groups.'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MapScreen()),
            );
          },
          icon: const Icon(Icons.add_location_alt),
          label: const Text('Log a planting for mission progress'),
        ),
      ),
    );
  }

  static List<Planting> _currentMonthPlantings(List<Planting> plantings) {
    final now = DateTime.now();
    return plantings.where((p) {
      final date = p.plantedAt.toLocal();
      return date.year == now.year && date.month == now.month;
    }).toList();
  }

  static bool _isNativeLikely(String speciesName) {
    final s = speciesName.toLowerCase();
    return s.contains('native') || s.contains('mango') || s.contains('cedar') || s.contains('balata');
  }
}

class _MissionProgressCard extends StatelessWidget {
  const _MissionProgressCard({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.current,
    required this.goal,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final double progress;
  final int current;
  final int goal;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final normalized = progress.clamp(0, 1).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('$current/$goal'),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: normalized),
          ],
        ),
      ),
    );
  }
}
