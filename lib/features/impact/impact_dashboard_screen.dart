import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hive/hive.dart' show Box;
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models.dart';
import '../../data/species_catalog.dart';

class ImpactDashboardScreen extends StatelessWidget {
  const ImpactDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plantingsBox = Hive.box('plantings');
    final updatesBox = Hive.box('updates');

    return Scaffold(
      appBar: AppBar(title: const Text('Impact Dashboard')),
      body: ValueListenableBuilder(
        valueListenable: plantingsBox.listenable(),
        builder: (context, Box plantings, _) {
          return ValueListenableBuilder(
            valueListenable: updatesBox.listenable(),
            builder: (context, Box updates, __) {
              final metrics = _ImpactMetrics.fromBoxes(plantings, updates);
              if (metrics.totalPlantings == 0) {
                return const _EmptyImpactState();
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SummaryGrid(metrics: metrics),
                  const SizedBox(height: 16),
                  _Panel(
                    title: 'Status Snapshot',
                    child: Column(
                      children: metrics.statusBreakdown.entries
                          .map((e) => _StatusRow(
                                label: e.key,
                                count: e.value,
                                max: metrics.totalPlantings,
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Panel(
                    title: 'Plantings in the last 6 months',
                    child: Column(
                      children: metrics.monthlyCounts
                          .map(
                            (m) => _MonthBar(
                              monthLabel: m.label,
                              count: m.count,
                              maxCount: metrics.maxMonthlyCount,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Panel(
                    title: 'Top Species',
                    child: Column(
                      children: metrics.topSpecies
                          .map(
                            (s) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.spa),
                              title: Text(s.name),
                              trailing: Text(
                                '${s.count}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.metrics});
  final _ImpactMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _MetricTile(
          label: 'Total Plantings',
          value: '${metrics.totalPlantings}',
          icon: Icons.forest,
        ),
        _MetricTile(
          label: 'Unique Species',
          value: '${metrics.uniqueSpeciesCount}',
          icon: Icons.category,
        ),
        _MetricTile(
          label: 'Native Species',
          value: '${metrics.nativeSpeciesCount}',
          icon: Icons.public,
        ),
        _MetricTile(
          label: 'Survival Rate',
          value: '${metrics.survivalRate.round()}%',
          icon: Icons.favorite,
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.75),
        border: Border.all(color: const Color(0xFFB7E4C7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 26,
              color: Color(0xFF1B5E20),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2F5D3A),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.count,
    required this.max,
  });

  final String label;
  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    final ratio = max == 0 ? 0.0 : count / max;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 98,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: ratio, minHeight: 10),
            ),
          ),
          const SizedBox(width: 10),
          Text('$count'),
        ],
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.monthLabel,
    required this.count,
    required this.maxCount,
  });

  final String monthLabel;
  final int count;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final ratio = maxCount == 0 ? 0.0 : count / maxCount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 44, child: Text(monthLabel)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: ratio, minHeight: 12),
            ),
          ),
          const SizedBox(width: 10),
          Text('$count'),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB7E4C7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _EmptyImpactState extends StatelessWidget {
  const _EmptyImpactState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insights, size: 52),
            const SizedBox(height: 12),
            const Text(
              'No impact data yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Log your first planting to unlock the dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactMetrics {
  _ImpactMetrics({
    required this.totalPlantings,
    required this.uniqueSpeciesCount,
    required this.nativeSpeciesCount,
    required this.survivalRate,
    required this.statusBreakdown,
    required this.monthlyCounts,
    required this.maxMonthlyCount,
    required this.topSpecies,
  });

  final int totalPlantings;
  final int uniqueSpeciesCount;
  final int nativeSpeciesCount;
  final double survivalRate;
  final Map<String, int> statusBreakdown;
  final List<_MonthlyCount> monthlyCounts;
  final int maxMonthlyCount;
  final List<_SpeciesCount> topSpecies;

  static _ImpactMetrics fromBoxes(Box plantingsBox, Box updatesBox) {
    final plantings = plantingsBox.values
        .map((raw) => Planting.fromMap(Map<String, dynamic>.from(raw)))
        .toList();

    final updates = updatesBox.values
        .map((raw) => StatusUpdate.fromMap(Map<String, dynamic>.from(raw)))
        .toList();

    final speciesNativeLookup = <String, bool>{
      for (final s in kSpeciesData) s['id'] as String: s['native'] == true,
    };

    final statusByPlanting = <String, String?>{};
    for (final p in plantings) {
      statusByPlanting[p.id] = p.status?.toLowerCase();
    }
    updates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    for (final u in updates) {
      final existing = statusByPlanting[u.plantingId];
      if ((existing ?? '').isEmpty && (u.status ?? '').isNotEmpty) {
        statusByPlanting[u.plantingId] = u.status!.toLowerCase();
      }
    }

    final statusCounts = <String, int>{
      'Thriving': 0,
      'Stable': 0,
      'Struggling': 0,
      'Dead': 0,
      'Unknown': 0,
    };

    for (final status in statusByPlanting.values) {
      switch (status) {
        case 'thriving':
          statusCounts['Thriving'] = statusCounts['Thriving']! + 1;
          break;
        case 'stable':
          statusCounts['Stable'] = statusCounts['Stable']! + 1;
          break;
        case 'struggling':
          statusCounts['Struggling'] = statusCounts['Struggling']! + 1;
          break;
        case 'dead':
          statusCounts['Dead'] = statusCounts['Dead']! + 1;
          break;
        default:
          statusCounts['Unknown'] = statusCounts['Unknown']! + 1;
      }
    }

    final alive = statusCounts['Thriving']! + statusCounts['Stable']!;
    final considered = plantings.isEmpty ? 0 : plantings.length;
    final survivalRate = considered == 0 ? 0.0 : (alive / considered) * 100;

    final uniqueSpeciesIds = plantings.map((p) => p.speciesId).toSet();
    final nativeSpecies =
        uniqueSpeciesIds.where((id) => speciesNativeLookup[id] == true).length;

    final monthData = _buildMonthlyCounts(plantings);

    final speciesCounts = <String, int>{};
    for (final p in plantings) {
      speciesCounts[p.speciesName] = (speciesCounts[p.speciesName] ?? 0) + 1;
    }
    final topSpecies = speciesCounts.entries
        .map((e) => _SpeciesCount(name: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return _ImpactMetrics(
      totalPlantings: plantings.length,
      uniqueSpeciesCount: uniqueSpeciesIds.length,
      nativeSpeciesCount: nativeSpecies,
      survivalRate: survivalRate,
      statusBreakdown: statusCounts,
      monthlyCounts: monthData,
      maxMonthlyCount: monthData.fold(0, (m, e) => math.max(m, e.count)),
      topSpecies: topSpecies.take(5).toList(),
    );
  }

  static List<_MonthlyCount> _buildMonthlyCounts(List<Planting> plantings) {
    final now = DateTime.now();
    final months = <DateTime>[];

    for (int i = 5; i >= 0; i--) {
      months.add(DateTime(now.year, now.month - i));
    }

    final counts = <String, int>{
      for (final m in months) '${m.year}-${m.month}': 0,
    };

    for (final p in plantings) {
      final local = p.plantedAt.toLocal();
      final key = '${local.year}-${local.month}';
      if (counts.containsKey(key)) counts[key] = counts[key]! + 1;
    }

    return months
        .map(
          (m) => _MonthlyCount(
            label: _monthShort(m.month),
            count: counts['${m.year}-${m.month}']!,
          ),
        )
        .toList();
  }

  static String _monthShort(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return names[month - 1];
  }
}

class _MonthlyCount {
  _MonthlyCount({required this.label, required this.count});
  final String label;
  final int count;
}

class _SpeciesCount {
  _SpeciesCount({required this.name, required this.count});
  final String name;
  final int count;
}
