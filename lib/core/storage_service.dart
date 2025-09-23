import 'dart:io';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'superbase_client.dart';

class StorageService {
  static const String bucket = 'plant-photos';

  /// Upload a local photo file to Supabase Storage.
  /// Returns a public URL (for a public bucket) or null on failure.
  static Future<String?> uploadPlantPhoto({
    required String plantingId,
    required File file,
  }) async {
    try {
      final ext = _extFromMime(file.path);
      final objectPath = 'plantings/$plantingId$ext';

      await Supa.client.storage.from(bucket).upload(
            objectPath,
            file,
            fileOptions: const FileOptions(
              upsert: true, // overwrite if the same id is re-uploaded
              cacheControl: '3600',
            ),
          );

      // Public bucket: use public URL
      final url = Supa.client.storage.from(bucket).getPublicUrl(objectPath);
      return url;
    } catch (e) {
      // You can log to Crashlytics/Sentry later
      return null;
    }
  }

  static String _extFromMime(String path) {
    final m = lookupMimeType(path) ?? 'image/jpeg';
    if (m.contains('png')) return '.png';
    if (m.contains('webp')) return '.webp';
    return '.jpg';
  }
}
