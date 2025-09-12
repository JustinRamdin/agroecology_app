// lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';

// Inlined species catalog (editable)
const List<Map<String, dynamic>> kSpeciesData = [
  { "id": "chataigne", "common_name": "Chataigne (Breadnut)", "scientific_name": "Artocarpus camansi", "native": false },
  { "id": "breadfruit", "common_name": "Breadfruit", "scientific_name": "Artocarpus altilis", "native": false },
  { "id": "coconut", "common_name": "Coconut", "scientific_name": "Cocos nucifera", "native": false },
  { "id": "pomarac", "common_name": "Pomarac", "scientific_name": "Syzygium malaccense", "native": false },
  { "id": "cocorite", "common_name": "Cocorite", "scientific_name": "Attalea maripa", "native": true },
  { "id": "peewah", "common_name": "Peewah", "scientific_name": "Bactris gasipaes", "native": false },
  { "id": "mango", "common_name": "Mango", "scientific_name": "Mangifera indica", "native": false },
  { "id": "avocado", "common_name": "Avocado", "scientific_name": "Persea americana", "native": false },
  { "id": "soursop", "common_name": "Soursop", "scientific_name": "Annona muricata", "native": false },
  { "id": "guava", "common_name": "Guava", "scientific_name": "Psidium guajava", "native": false }
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('plantings');
  await Hive.openBox('updates');
  runApp(const AgroApp());
}

/// Root of the app
class AgroApp extends StatelessWidget {
  const AgroApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agroecology App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}

/// Species model (built from inline list)
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

/// Planting record
class Planting {
  final String id;
  final double lat;
  final double lng;
  final String speciesId;
  final String speciesName;     // denormalized for display
  final String assocCategory;   // e.g. Hunters Association
  final String assocName;       // specific group name
  final String? status;         // thriving|stable|struggling|dead|harvested
  final String? phenology;      // flowering|fruiting|vegetative|seedling
  final int? heightCm;
  final String? note;
  final String? photoPath;      // local path (ImagePicker), can be uploaded later
  final DateTime plantedAt;

  Planting({
    required this.id,
    required this.lat,
    required this.lng,
    required this.speciesId,
    required this.speciesName,
    required this.assocCategory,
    required this.assocName,
    this.status,
    this.phenology,
    this.heightCm,
    this.note,
    this.photoPath,
    required this.plantedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'lat': lat,
        'lng': lng,
        'speciesId': speciesId,
        'speciesName': speciesName,
        'assocCategory': assocCategory,
        'assocName': assocName,
        'status': status,
        'phenology': phenology,
        'heightCm': heightCm,
        'note': note,
        'photoPath': photoPath,
        'plantedAt': plantedAt.toIso8601String(),
      };

  factory Planting.fromMap(Map map) => Planting(
        id: map['id'],
        lat: (map['lat'] as num).toDouble(),
        lng: (map['lng'] as num).toDouble(),
        speciesId: map['speciesId'],
        speciesName: map['speciesName'],
        assocCategory: map['assocCategory'],
        assocName: map['assocName'],
        status: map['status'],
        phenology: map['phenology'],
        heightCm: map['heightCm'],
        note: map['note'],
        photoPath: map['photoPath'],
        plantedAt: DateTime.parse(map['plantedAt']),
      );
}

/// Per-planting status update record (timeline)
class StatusUpdate {
  final String id;
  final String plantingId;
  final DateTime updatedAt;
  final String? status;
  final String? phenology;
  final int? heightCm;
  final String? note;
  final String? photoPath;

  StatusUpdate({
    required this.id,
    required this.plantingId,
    required this.updatedAt,
    this.status,
    this.phenology,
    this.heightCm,
    this.note,
    this.photoPath,
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
      );
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  static const LatLng _ttCenter = LatLng(10.5, -61.3);

  final Set<Marker> _markers = {};
  final List<Planting> _plantings = [];
  List<Species> _speciesCatalog = [];

  // Custom marker icon (loaded once)
  BitmapDescriptor? _iconDefault;

  @override
  void initState() {
    super.initState();
    _loadSpecies();
    _loadMarkerIcon();
    _loadSavedPlantings();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // Use the inlined list instead of loading from assets
  void _loadSpecies() {
    setState(() {
      _speciesCatalog = kSpeciesData.map((e) => Species.fromJson(e)).toList();
    });
  }

  Future<void> _loadMarkerIcon() async {
    final icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/icons/marker_default.png',
    );
    if (mounted) setState(() => _iconDefault = icon);
  }

  Future<void> _loadSavedPlantings() async {
    final box = Hive.box('plantings');
    for (final raw in box.values) {
      final p = Planting.fromMap(Map<String, dynamic>.from(raw));
      _plantings.add(p);
      _markers.add(_markerFor(p));
    }
    if (mounted) setState(() {});
  }

  Marker _markerFor(Planting p) {
    final title = '${p.speciesName} • ${p.assocCategory}';
    final snippetParts = <String>[];
    if ((p.assocName).isNotEmpty) snippetParts.add(p.assocName);
    if ((p.status ?? '').isNotEmpty) snippetParts.add('Status: ${p.status}');
    if ((p.phenology ?? '').isNotEmpty) snippetParts.add('Phenology: ${p.phenology}');
    if (p.heightCm != null) snippetParts.add('Height: ${p.heightCm} cm');
    final snippet = snippetParts.isEmpty ? (p.note ?? '') : snippetParts.join(' · ');

    return Marker(
      markerId: MarkerId(p.id),
      position: LatLng(p.lat, p.lng),
      icon: _iconDefault ?? BitmapDescriptor.defaultMarker, // use custom icon
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
        onTap: () => _openPlantingDetail(p),
      ),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _snack('Please enable Location Services.');
      return;
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      _snack('Location permission denied. Enable it in Settings.');
    }
  }

  Future<void> _centerOnUser() async {
    await _ensureLocationPermission();
    try {
      final pos = await Geolocator.getCurrentPosition();
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 16),
      );
    } catch (_) {
      _snack('Could not get current location.');
    }
  }

  Future<void> _logPlanting() async {
    await _ensureLocationPermission();
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition();
    } catch (_) {
      _snack('Could not get current location.');
      return;
    }
    if (pos == null) return;

    final result = await showModalBottomSheet<_PlantingFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: PlantingForm(speciesCatalog: _speciesCatalog),
      ),
    );
    if (result == null) return;

    final p = Planting(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      lat: pos.latitude,
      lng: pos.longitude,
      speciesId: result.species.id,
      speciesName: result.species.commonName,
      assocCategory: result.assocCategory,
      assocName: result.assocName,
      status: result.status,
      phenology: result.phenology,
      heightCm: result.heightCm,
      note: result.note,
      photoPath: result.photoPath,
      plantedAt: DateTime.now(),
    );

    final box = Hive.box('plantings');
    await box.add(p.toMap());

    setState(() {
      _plantings.add(p);
      _markers.add(_markerFor(p));
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(p.lat, p.lng), 17),
    );
    _snack('Planting logged: ${p.speciesName}');
  }

  void _openPlantingDetail(Planting p) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlantingDetailScreen(planting: p)),
    );
    setState(() {}); // simple refresh for demo
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agroecology Map'),
        actions: [
          IconButton(
            tooltip: 'My Location',
            onPressed: _centerOnUser,
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition:
            const CameraPosition(target: _ttCenter, zoom: 9),
        onMapCreated: (c) => _mapController = c,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        markers: _markers,
        mapToolbarEnabled: false,
        compassEnabled: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Log Planting'),
        onPressed: _logPlanting,
      ),
    );
  }
}

/// ===== Planting Form (create) =====
class PlantingForm extends StatefulWidget {
  const PlantingForm({required this.speciesCatalog});
  final List<Species> speciesCatalog;

  @override
  State<PlantingForm> createState() => _PlantingFormState();
}

class _PlantingFormState extends State<PlantingForm> {
  final _formKey = GlobalKey<FormState>();
  Species? _species;
  final TextEditingController _assocNameCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final _assocCategories = const [
    "Hunters Association",
    "Scouting Group",
    "Hiking Group",
    "NGO",
    "Religious Group",
    "Sporting Club",
    "Community Development Group",
    "Other",
  ];
  String? _assocCategory;

  final _statusOptions = const [
    "thriving",
    "stable",
    "struggling",
    "dead",
    "harvested"
  ];
  String? _status;

  final _phenologyOptions = const [
    "seedling",
    "vegetative",
    "flowering",
    "fruiting"
  ];
  String? _phenology;

  String? _photoPath;

  @override
  void dispose() {
    _assocNameCtrl.dispose();
    _noteCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final xfile = await _picker.pickImage(source: ImageSource.camera);
    if (xfile != null) setState(() => _photoPath = xfile.path);
  }

  void _submit() {
    if (_species == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a species')));
      return;
    }
    if ((_assocCategory ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an association category')));
      return;
    }
    final height = int.tryParse(_heightCtrl.text.trim());
    Navigator.of(context).pop(_PlantingFormResult(
      species: _species!,
      assocCategory: _assocCategory!,
      assocName: _assocNameCtrl.text.trim(),
      status: _status,
      phenology: _phenology,
      heightCm: height,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      photoPath: _photoPath,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Log Planting',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),

                // Species
                DropdownButtonFormField<Species>(
                  decoration: const InputDecoration(
                    labelText: 'Species',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.speciesCatalog
                      .map((sp) => DropdownMenuItem(
                            value: sp,
                            child: Text(sp.commonName),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _species = val),
                ),
                const SizedBox(height: 12),

                // Association category
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Association (category)',
                    border: OutlineInputBorder(),
                  ),
                  items: _assocCategories
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setState(() => _assocCategory = val),
                ),
                const SizedBox(height: 12),

                // Association name
                TextFormField(
                  controller: _assocNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Association Name (specific troop/club or Other)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Status
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Status (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: _statusOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setState(() => _status = val),
                ),
                const SizedBox(height: 12),

                // Phenology
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Phenology (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: _phenologyOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setState(() => _phenology = val),
                ),
                const SizedBox(height: 12),

                // Height
                TextFormField(
                  controller: _heightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm, optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Note
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'e.g., partial shade, near stream, good soil',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Photo
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickPhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Add Photo (optional)'),
                      ),
                    ),
                  ],
                ),
                if (_photoPath != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Photo added: ${_photoPath!.split(Platform.pathSeparator).last}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.check),
                        label: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlantingFormResult {
  final Species species;
  final String assocCategory;
  final String assocName;
  final String? status;
  final String? phenology;
  final int? heightCm;
  final String? note;
  final String? photoPath;
  _PlantingFormResult({
    required this.species,
    required this.assocCategory,
    required this.assocName,
    this.status,
    this.phenology,
    this.heightCm,
    this.note,
    this.photoPath,
  });
}

/// ===== Planting Detail + Add Update =====
class PlantingDetailScreen extends StatefulWidget {
  const PlantingDetailScreen({super.key, required this.planting});
  final Planting planting;

  @override
  State<PlantingDetailScreen> createState() => _PlantingDetailScreenState();
}

class _PlantingDetailScreenState extends State<PlantingDetailScreen> {
  List<StatusUpdate> _updates = [];

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  Future<void> _loadUpdates() async {
    final box = Hive.box('updates');
    final list = <StatusUpdate>[];
    for (final raw in box.values) {
      final su = StatusUpdate.fromMap(Map<String, dynamic>.from(raw));
      if (su.plantingId == widget.planting.id) list.add(su);
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    setState(() => _updates = list);
  }

  Future<void> _addUpdate() async {
    final res = await showModalBottomSheet<_UpdateFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: UpdateForm(),
      ),
    );
    if (res == null) return;
    final su = StatusUpdate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      plantingId: widget.planting.id,
      updatedAt: DateTime.now(),
      status: res.status,
      phenology: res.phenology,
      heightCm: res.heightCm,
      note: res.note,
      photoPath: res.photoPath,
    );
    await Hive.box('updates').add(su.toMap());
    await _loadUpdates();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.planting;
    return Scaffold(
      appBar: AppBar(title: Text(p.speciesName)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addUpdate,
        icon: const Icon(Icons.add),
        label: const Text('Add Update'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${p.speciesName} • ${p.assocCategory}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (p.assocName.isNotEmpty) Text(p.assocName),
          const SizedBox(height: 8),
          if (p.photoPath != null && p.photoPath!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(p.photoPath!), height: 180, fit: BoxFit.cover),
            ),
          const SizedBox(height: 12),
          if (p.status != null || p.phenology != null || p.heightCm != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (p.status != null)
                  Chip(label: Text('Status: ${p.status}')),
                if (p.phenology != null)
                  Chip(label: Text('Phenology: ${p.phenology}')),
                if (p.heightCm != null)
                  Chip(label: Text('Height: ${p.heightCm} cm')),
              ],
            ),
          if ((p.note ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(p.note!),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Updates', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_updates.isEmpty)
            const Text('No updates yet. Tap "Add Update" to contribute.'),
          for (final u in _updates)
            Card(
              child: ListTile(
                title: Text(
                    '${u.updatedAt.toLocal()}'.split('.').first.replaceAll('T', ' ')),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (u.status != null) Text('Status: ${u.status}'),
                    if (u.phenology != null) Text('Phenology: ${u.phenology}'),
                    if (u.heightCm != null) Text('Height: ${u.heightCm} cm'),
                    if ((u.note ?? '').isNotEmpty) Text(u.note!),
                    if ((u.photoPath ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(File(u.photoPath!),
                            height: 140, fit: BoxFit.cover),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Update form (status/phenology/height/note/photo)
class UpdateForm extends StatefulWidget {
  @override
  State<UpdateForm> createState() => _UpdateFormState();
}

class _UpdateFormState extends State<UpdateForm> {
  final _statusOptions = const [
    "thriving",
    "stable",
    "struggling",
    "dead",
    "harvested"
  ];
  String? _status;

  final _phenologyOptions = const [
    "seedling",
    "vegetative",
    "flowering",
    "fruiting"
  ];
  String? _phenology;

  final TextEditingController _heightCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _photoPath;

  @override
  void dispose() {
    _heightCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final xfile = await _picker.pickImage(source: ImageSource.camera);
    if (xfile != null) setState(() => _photoPath = xfile.path);
  }

  void _submit() {
    final height = int.tryParse(_heightCtrl.text.trim());
    Navigator.of(context).pop(_UpdateFormResult(
      status: _status,
      phenology: _phenology,
      heightCm: height,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      photoPath: _photoPath,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Add Update',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Status (optional)',
                  border: OutlineInputBorder(),
                ),
                items: _statusOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Phenology (optional)',
                  border: OutlineInputBorder(),
                ),
                items: _phenologyOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _phenology = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _heightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Height (cm, optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Add Photo (optional)'),
                    ),
                  ),
                ],
              ),
              if ((_photoPath ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Photo added: ${_photoPath!.split(Platform.pathSeparator).last}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpdateFormResult {
  final String? status;
  final String? phenology;
  final int? heightCm;
  final String? note;
  final String? photoPath;
  _UpdateFormResult({
    this.status,
    this.phenology,
    this.heightCm,
    this.note,
    this.photoPath,
  });
}
