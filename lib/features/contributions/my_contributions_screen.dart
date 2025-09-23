import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart' show Box;
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/repository.dart';
import '../../data/models.dart';
import '../planting/planting_detail_screen.dart';
import '../../core/export_csv.dart';

class MyContributionsScreen extends StatelessWidget {
  const MyContributionsScreen({super.key});

  Future<void> _export(BuildContext context) async {
    try {
      await CsvExporter.sharePlantingsCsv();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _confirmAndDelete(BuildContext context, Planting p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete planting?'),
        content: const Text(
          'This will remove the planting and its updates. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await Repo.deletePlantingById(p.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Planting deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantingsBox = Hive.box('plantings');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Contributions'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.download),
            onPressed: () => _export(context),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: plantingsBox.listenable(),
        builder: (context, Box box, _) {
          final items = box.values
              .map((raw) => Planting.fromMap(Map<String, dynamic>.from(raw)))
              .toList()
            ..sort((a, b) => b.plantedAt.compareTo(a.plantedAt));

          if (items.isEmpty) return const _EmptyState();

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = items[i];
              final dateStr = _formatDateTime(p.plantedAt);

              return Dismissible(
                key: ValueKey(p.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.red.withOpacity(0.85),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) => showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete planting?'),
                    content: const Text(
                      'This will remove the planting and its updates. This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                    ],
                  ),
                ),
                onDismissed: (_) async {
                  await Repo.deletePlantingById(p.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Planting deleted')),
                    );
                  }
                },
                child: Card(
                  child: ListTile(
                    leading: _Thumb(photoPath: p.photoPath),
                    title: Text(p.speciesName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateStr),
                        if (p.assocCategory.isNotEmpty || p.assocName.isNotEmpty)
                          Text([p.assocCategory, p.assocName].where((s) => s.isNotEmpty).join(' • ')),
                        if ((p.status ?? '').isNotEmpty) Text('Status: ${p.status}'),
                      ],
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmAndDelete(context, p),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PlantingDetailScreen(planting: p)),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photoPath});
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = (photoPath ?? '').isNotEmpty && File(photoPath!).existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: hasPhoto
            ? Image.file(File(photoPath!), fit: BoxFit.cover)
            : Container(
                color: Colors.green.withOpacity(0.1),
                child: const Icon(Icons.spa),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forest, size: 56),
            const SizedBox(height: 12),
            const Text('No plantings yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'Use “Log Planting” on the map to add your first tree.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ],
        ),
      ),
    );
  }
}

// — utils —
String _two(int n) => n.toString().padLeft(2, '0');
String _formatDateTime(DateTime dt) {
  final d = dt.toLocal();
  final y = d.year;
  final m = _two(d.month);
  final day = _two(d.day);
  final hh = _two(d.hour);
  final mm = _two(d.minute);
  return '$y-$m-$day  $hh:$mm';
}
