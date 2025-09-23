// lib/core/hive_setup.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

Future<void> initHive() async {
  await Hive.initFlutter();

  // Meta & app-level boxes
  await Hive.openBox('meta');
  await Hive.openBox('app');             // holds app-level keys (deviceId, etc.)

  // Main data
  await Hive.openBox('plantings');       // map<id, map>
  await Hive.openBox('updates');         // map<id, map>

  // NEW: Outbox queues for offline-first sync
  await Hive.openBox('outbox_plantings'); // map<id, map>
  await Hive.openBox('outbox_updates');   // map<id, map>

  await _ensureDeviceId();
}

Future<void> _ensureDeviceId() async {
  final appBox = Hive.box('app');
  var id = appBox.get('deviceId') as String?;
  if (id == null || id.isEmpty) {
    id = _uuid.v4();                      // stable per-install UUID
    await appBox.put('deviceId', id);
  }
}

/// Convenient getter used across the app
String getDeviceId() => Hive.box('app').get('deviceId') as String;
