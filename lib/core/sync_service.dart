// lib/core/sync_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models.dart';
import 'superbase_client.dart'; // <-- make sure your file is named exactly this

class SyncService {
  static final SupabaseClient _db = Supa.client;

  /// Upsert a planting into 'plantings' (idempotent by ID).
  static Future<void> upsertPlanting(Planting p) async {
    final row = {
      'id': p.id,                                      // text/uuid (matches DB)
      'device_id': p.deviceId,
      'planted_at': p.plantedAt.toUtc().toIso8601String(),
      'lat': p.lat,
      'lng': p.lng,
      'accuracy_m': p.accuracyM,
      'species_id': p.speciesId,
      'species_name': p.speciesName,
      'assoc_category': p.assocCategory,
      'assoc_name': p.assocName,
      'status': p.status,
      'phenology': p.phenology,
      'height_cm': p.heightCm,
      'note': p.note,
      'photo_url': p.photoUrl,                         // now exists in model
      // created_at is defaulted by DB
    };

    await _db.from('plantings').upsert(row);
  }

  /// Insert one status update row into 'planting_updates'.
  static Future<void> insertUpdate(StatusUpdate u) async {
    final row = {
      'id': u.id,                                      // text/uuid
      'planting_id': u.plantingId,                     // FK -> plantings.id
      'updated_at': u.updatedAt.toUtc().toIso8601String(),
      'status': u.status,
      'phenology': u.phenology,
      'height_cm': u.heightCm,
      'note': u.note,
      'photo_url': u.photoUrl,
    };

    await _db.from('planting_updates').insert(row);
  }

  /// (Optional) Convenience: push a Planting and its Updates together.
  static Future<void> syncPlantingWithUpdates(
    Planting p,
    List<StatusUpdate> updates,
  ) async {
    await upsertPlanting(p);
    if (updates.isNotEmpty) {
      final rows = updates.map((u) => {
            'id': u.id,
            'planting_id': u.plantingId,
            'updated_at': u.updatedAt.toUtc().toIso8601String(),
            'status': u.status,
            'phenology': u.phenology,
            'height_cm': u.heightCm,
            'note': u.note,
            'photo_url': u.photoUrl,
          });
      await _db.from('planting_updates').insert(rows.toList());
    }
  }
}
