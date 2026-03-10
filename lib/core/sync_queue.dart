import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models.dart';
import 'sync_service.dart';
import 'storage_service.dart';

class SyncQueue {
  /// Process queued plantings (created when online sync failed).
  static Future<void> processPlantings() async {
    final box = Hive.box('outbox_plantings');
    final meta = Hive.box('meta');
    await meta.put('last_sync_attempt_at', DateTime.now().toIso8601String());

    final keys = box.keys.toList(); // stable snapshot
    int successCount = 0;
    for (final k in keys) {
      final raw = Map<String, dynamic>.from(box.get(k));
      final p = Planting.fromMap(raw);

      try {
        // If there is a pending local photo & no photoUrl yet, try upload first
        Planting toSend = p;
        if ((p.photoPath ?? '').isNotEmpty && (p.photoUrl ?? '').isEmpty) {
          final f = File(p.photoPath!);
          if (f.existsSync()) {
            final url = await StorageService.uploadPlantPhoto(
              plantingId: p.id,
              file: f,
            );
            if (url != null) {
              toSend = p.copyWith(photoUrl: url);
              // Also reflect the updated URL in local 'plantings' store
              final plantedBox = Hive.box('plantings');
              await plantedBox.put(toSend.id, toSend.toMap());
            }
          }
        }

        await SyncService.upsertPlanting(toSend);
        await box.delete(k); // success → remove from outbox
        successCount += 1;
      } catch (_) {
        // leave in queue; we'll retry later
      }
    }

    if (successCount > 0) {
      await meta.put('last_sync_success_at', DateTime.now().toIso8601String());
    }
    await meta.put('last_sync_plantings_success_count', successCount);
  }

  /// Process queued status updates.
  static Future<void> processUpdates() async {
    final box = Hive.box('outbox_updates');
    final meta = Hive.box('meta');
    await meta.put('last_sync_attempt_at', DateTime.now().toIso8601String());

    final keys = box.keys.toList();
    int successCount = 0;
    for (final k in keys) {
      final raw = Map<String, dynamic>.from(box.get(k));
      final u = StatusUpdate.fromMap(raw);

      try {
        // (Optional) if you support photo uploads for updates later
        // TODO: upload update photo and set u.photoUrl

        await SyncService.insertUpdate(u);
        await box.delete(k);
        successCount += 1;
      } catch (_) {
        // keep it; retry later
      }
    }

    if (successCount > 0) {
      await meta.put('last_sync_success_at', DateTime.now().toIso8601String());
    }
    await meta.put('last_sync_updates_success_count', successCount);
  }

  /// Convenience
  static Future<void> processAll() async {
    await processPlantings();
    await processUpdates();
  }
}
