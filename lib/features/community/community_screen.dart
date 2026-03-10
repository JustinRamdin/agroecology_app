import 'package:flutter/material.dart';
import 'package:hive/hive.dart' show Box;
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models.dart';
import '../contributions/my_contributions_screen.dart';
import '../map/map_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community Hub'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Activity', icon: Icon(Icons.campaign)),
              Tab(text: 'Leaderboard', icon: Icon(Icons.emoji_events)),
              Tab(text: 'Events', icon: Icon(Icons.event)),
            ],
          ),
        ),
        body: ValueListenableBuilder(
          valueListenable: Hive.box('plantings').listenable(),
          builder: (context, Box box, _) {
            final plantings = box.values
                .map((raw) => Planting.fromMap(Map<String, dynamic>.from(raw)))
                .toList()
              ..sort((a, b) => b.plantedAt.compareTo(a.plantedAt));

            final topSpecies = _topSpecies(plantings);

            return TabBarView(
              children: [
                _ActivityTab(plantings: plantings),
                _LeaderboardTab(
                  totalPlantings: plantings.length,
                  topSpecies: topSpecies,
                ),
                const _EventsTab(),
              ],
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MyContributionsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.inventory_2),
                  label: const Text('My Contributions'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MapScreen()),
                    );
                  },
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text('Log Planting'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static MapEntry<String, int>? _topSpecies(List<Planting> plantings) {
    if (plantings.isEmpty) return null;

    final counts = <String, int>{};
    for (final p in plantings) {
      counts.update(p.speciesName, (value) => value + 1, ifAbsent: () => 1);
    }

    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.plantings});

  final List<Planting> plantings;

  @override
  Widget build(BuildContext context) {
    final recent = plantings.take(5).toList();

    if (recent.isEmpty) {
      return const Center(
        child: Text('No community activity yet. Start by logging a planting 🌱'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recent.length,
      itemBuilder: (context, i) {
        final p = recent[i];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.eco)),
            title: Text('${p.assocName.isEmpty ? 'A member' : p.assocName} planted ${p.speciesName}'),
            subtitle: Text(
              '${p.assocCategory.isEmpty ? 'Community' : p.assocCategory} • ${_dateLabel(p.plantedAt)}',
            ),
          ),
        );
      },
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab({required this.totalPlantings, required this.topSpecies});

  final int totalPlantings;
  final MapEntry<String, int>? topSpecies;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.forest),
            title: const Text('Total plantings logged'),
            trailing: Text(
              '$totalPlantings',
              style: theme.textTheme.titleLarge,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.local_florist),
            title: const Text('Most planted species'),
            subtitle: Text(
              topSpecies == null
                  ? 'No species data yet'
                  : '${topSpecies!.key} • ${topSpecies!.value} plantings',
            ),
          ),
        ),
      ],
    );
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab();

  @override
  Widget build(BuildContext context) {
    final events = [
      ('Saturday Coastal Replant', 'Maraval Coast', 'Mar 23 • 7:00 AM'),
      ('School Food Forest Sprint', 'Arima East Secondary', 'Mar 29 • 8:30 AM'),
      ('Dry Season Watering Team', 'Caroni Plains', 'Apr 02 • 6:00 AM'),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final event = events[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.event_available),
            title: Text(event.$1),
            subtitle: Text('${event.$2} • ${event.$3}'),
            trailing: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Joined: ${event.$1}')),
                );
              },
              child: const Text('Join'),
            ),
          ),
        );
      },
    );
  }
}

String _dateLabel(DateTime dt) {
  final d = dt.toLocal();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
