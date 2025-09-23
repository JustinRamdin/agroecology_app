import 'package:hive_flutter/hive_flutter.dart';

class Repo {
  /// Delete one planting and any updates that reference it.
  static Future<void> deletePlantingById(String plantingId) async {
    final plantings = Hive.box('plantings');
    final updates = Hive.box('updates');

    // Find the Hive key for this planting (we used put(id, map), so it’s the id)
    if (plantings.containsKey(plantingId)) {
      await plantings.delete(plantingId);
    } else {
      // Backward-compat: old items saved with numeric keys
      final dynamicKey = plantings.keys.firstWhere(
        (k) {
          final v = plantings.get(k);
          return v is Map && v['id'] == plantingId;
        },
        orElse: () => null,
      );
      if (dynamicKey != null) {
        await plantings.delete(dynamicKey);
      }
    }

    // Cascade delete updates for this planting
    final keysToDelete = <dynamic>[];
    for (final k in updates.keys) {
      final v = updates.get(k);
      if (v is Map && v['plantingId'] == plantingId) {
        keysToDelete.add(k);
      }
    }
    if (keysToDelete.isNotEmpty) {
      await updates.deleteAll(keysToDelete);
    }
  }
}
