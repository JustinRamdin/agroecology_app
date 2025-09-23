import 'dart:io';
import 'package:csv/csv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models.dart'; // Your Planting/StatusUpdate model types

class CsvExporter {
  /// Builds a CSV from all plantings currently in Hive and returns the file path.
  static Future<String> createPlantingsCsvFile() async {
    final box = Hive.box('plantings');

    // Header
    final rows = <List<dynamic>>[
      [
        'id',
        'deviceId',
        'lat',
        'lng',
        'accuracyM',
        'speciesId',
        'speciesName',
        'assocCategory',
        'assocName',
        'status',
        'phenology',
        'heightCm',
        'note',
        'photoPath',
        'plantedAt',
      ],
    ];

    for (final raw in box.values) {
      final p = Planting.fromMap(Map<String, dynamic>.from(raw));
      rows.add([
        p.id,
        p.deviceId,
        p.lat,
        p.lng,
        p.accuracyM ?? '',
        p.speciesId,
        p.speciesName,
        p.assocCategory,
        p.assocName,
        p.status ?? '',
        p.phenology ?? '',
        p.heightCm ?? '',
        (p.note ?? '').replaceAll('\n', ' '),
        p.photoPath ?? '',
        p.plantedAt.toUtc().toIso8601String(),
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);

    // Put file in a shareable temp dir (no storage permission needed)
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/agro_plantings.csv');
    await file.writeAsString(csv);
    return file.path;
  }

  /// Creates and opens the platform share sheet for the CSV file.
  static Future<void> sharePlantingsCsv() async {
    final path = await createPlantingsCsvFile();
    await Share.shareXFiles([XFile(path)], text: 'Agroecology plantings CSV');
  }
}
