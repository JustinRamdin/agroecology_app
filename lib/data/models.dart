// lib/data/models.dart
// Species, Planting, StatusUpdate models

class Species {
  final String id;
  final String commonName;
  final String scientificName;
  final bool native;
  Species({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.native,
  });

  factory Species.fromJson(Map<String, dynamic> j) => Species(
        id: j['id'],
        commonName: j['common_name'],
        scientificName: j['scientific_name'],
        native: j['native'] == true,
      );
}

class Planting {
  final String id;
  final double lat;
  final double lng;
  final String speciesId;
  final String speciesName;
  final String assocCategory;
  final String deviceId;
  final String assocName;
  final String? status;
  final double? accuracyM;
  final String? phenology;
  final int? heightCm;
  final String? note;

  /// Local path captured by ImagePicker (optional, device-only)
  final String? photoPath;

  /// Cloud URL after upload to Supabase Storage (optional)
  final String? photoUrl;

  final DateTime plantedAt;

  Planting({
    required this.id,
    required this.lat,
    required this.lng,
    required this.speciesId,
    required this.speciesName,
    required this.assocCategory,
    required this.deviceId,
    required this.assocName,
    this.status,
    this.accuracyM,
    this.phenology,
    this.heightCm,
    this.note,
    this.photoPath,
    this.photoUrl,
    required this.plantedAt,
  });

  /// For updating one or two fields (e.g., set photoUrl after upload)
  Planting copyWith({
    String? id,
    double? lat,
    double? lng,
    String? speciesId,
    String? speciesName,
    String? assocCategory,
    String? deviceId,
    String? assocName,
    String? status,
    double? accuracyM,
    String? phenology,
    int? heightCm,
    String? note,
    String? photoPath,
    String? photoUrl,
    DateTime? plantedAt,
  }) {
    return Planting(
      id: id ?? this.id,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      speciesId: speciesId ?? this.speciesId,
      speciesName: speciesName ?? this.speciesName,
      assocCategory: assocCategory ?? this.assocCategory,
      deviceId: deviceId ?? this.deviceId,
      assocName: assocName ?? this.assocName,
      status: status ?? this.status,
      accuracyM: accuracyM ?? this.accuracyM,
      phenology: phenology ?? this.phenology,
      heightCm: heightCm ?? this.heightCm,
      note: note ?? this.note,
      photoPath: photoPath ?? this.photoPath,
      photoUrl: photoUrl ?? this.photoUrl,
      plantedAt: plantedAt ?? this.plantedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'lat': lat,
        'lng': lng,
        'speciesId': speciesId,
        'speciesName': speciesName,
        'assocCategory': assocCategory,
        'deviceId': deviceId,
        'assocName': assocName,
        'status': status,
        'accuracyM': accuracyM,
        'phenology': phenology,
        'heightCm': heightCm,
        'note': note,
        'photoPath': photoPath,
        'photoUrl': photoUrl, // <-- NEW
        'plantedAt': plantedAt.toIso8601String(),
      };

  factory Planting.fromMap(Map map) => Planting(
        id: map['id'],
        deviceId: map['deviceId'] ?? '',
        lat: (map['lat'] as num).toDouble(),
        lng: (map['lng'] as num).toDouble(),
        accuracyM: map['accuracyM'] == null ? null : (map['accuracyM'] as num).toDouble(),
        speciesId: map['speciesId'],
        speciesName: map['speciesName'],
        assocCategory: map['assocCategory'],
        assocName: map['assocName'],
        status: map['status'],
        phenology: map['phenology'],
        heightCm: map['heightCm'],
        note: map['note'],
        photoPath: map['photoPath'],
        photoUrl: map['photoUrl'], // <-- NEW
        plantedAt: DateTime.parse(map['plantedAt']),
      );
}

class StatusUpdate {
  final String id;
  final String plantingId;
  final DateTime updatedAt;
  final String? status;
  final String? phenology;
  final int? heightCm;
  final String? note;

  /// Local path (optional)
  final String? photoPath;

  /// Cloud URL after upload (optional)
  final String? photoUrl;

  StatusUpdate({
    required this.id,
    required this.plantingId,
    required this.updatedAt,
    this.status,
    this.phenology,
    this.heightCm,
    this.note,
    this.photoPath,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'plantingId': plantingId,
        'updatedAt': updatedAt.toIso8601String(),
        'status': status,
        'phenology': phenology,
        'heightCm': heightCm,
        'note': note,
        'photoPath': photoPath,
        'photoUrl': photoUrl, // <-- NEW
      };

  factory StatusUpdate.fromMap(Map map) => StatusUpdate(
        id: map['id'],
        plantingId: map['plantingId'],
        updatedAt: DateTime.parse(map['updatedAt']),
        status: map['status'],
        phenology: map['phenology'],
        heightCm: map['heightCm'],
        note: map['note'],
        photoPath: map['photoPath'],
        photoUrl: map['photoUrl'], // <-- NEW
      );
}
