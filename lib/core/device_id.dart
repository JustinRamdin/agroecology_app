import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';

const _metaBoxName = 'meta';
const _deviceIdKey = 'device_id';

String getDeviceId() {
  final box = Hive.box(_metaBoxName);
  var id = box.get(_deviceIdKey) as String?;
  if (id != null && id.isNotEmpty) return id;

  // Make a random 32-char hex string (stable after first run)
  final rand = Random.secure();
  final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
  id = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  box.put(_deviceIdKey, id);
  return id;
}