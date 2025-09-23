import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../core/hive_setup.dart';       // getDeviceId()
import '../../data/models.dart';          // Species, Planting

class PlantingForm extends StatefulWidget {
  const PlantingForm({required this.speciesCatalog, super.key});
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

  final _statusOptions =
      const ["thriving", "stable", "struggling", "dead", "harvested"];
  String? _status;

  final _phenologyOptions =
      const ["seedling", "vegetative", "flowering", "fruiting"];
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

  Future<void> _submit() async {
    if (_species == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a species')),
      );
      return;
    }
    if ((_assocCategory ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an association category')),
      );
      return;
    }

    // Height (optional)
    final height = int.tryParse(_heightCtrl.text.trim());

    // Get best-accuracy GPS right before saving
    Position pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get current location')),
      );
      return;
    }

    // Build the full Planting record here
    final p = Planting(
      id: const Uuid().v4(),
      deviceId: getDeviceId(),
      lat: pos.latitude,
      lng: pos.longitude,
      accuracyM: pos.accuracy, // meters
      speciesId: _species!.id,
      speciesName: _species!.commonName,
      assocCategory: _assocCategory!,
      assocName: _assocNameCtrl.text.trim(),
      status: _status,
      phenology: _phenology,
      heightCm: height,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      photoPath: _photoPath,
      plantedAt: DateTime.now(),
    );

    if (!mounted) return;
    Navigator.of(context).pop(p); // return Planting to caller
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
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),

                // Species
                DropdownButtonFormField<Species>(
                  decoration: const InputDecoration(
                    labelText: 'Species',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.speciesCatalog
                      .map((sp) =>
                          DropdownMenuItem(value: sp, child: Text(sp.commonName)))
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
