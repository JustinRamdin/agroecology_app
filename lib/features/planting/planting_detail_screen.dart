import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models.dart';

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
                if (p.status != null) Chip(label: Text('Status: ${p.status}')),
                if (p.phenology != null) Chip(label: Text('Phenology: ${p.phenology}')),
                if (p.heightCm != null) Chip(label: Text('Height: ${p.heightCm} cm')),
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
                  '${u.updatedAt.toLocal()}'.split('.').first.replaceAll('T', ' '),
                ),
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
                        child: Image.file(File(u.photoPath!), height: 140, fit: BoxFit.cover),
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

class UpdateForm extends StatefulWidget {
  @override
  State<UpdateForm> createState() => _UpdateFormState();
}

class _UpdateFormState extends State<UpdateForm> {
  final _statusOptions = const ["thriving","stable","struggling","dead","harvested"];
  String? _status;

  final _phenologyOptions = const ["seedling","vegetative","flowering","fruiting"];
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
