import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/species_catalog.dart';

class SpeciesLibraryScreen extends StatefulWidget {
  const SpeciesLibraryScreen({super.key});

  @override
  State<SpeciesLibraryScreen> createState() => _SpeciesLibraryScreenState();
}

class _SpeciesLibraryScreenState extends State<SpeciesLibraryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _nativeOnly = false;

  late final List<Species> _allSpecies;

  @override
  void initState() {
    super.initState();
    _allSpecies = kSpeciesData.map(Species.fromJson).toList()
      ..sort((a, b) => a.commonName.compareTo(b.commonName));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Species> get _filteredSpecies {
    final query = _searchCtrl.text.trim().toLowerCase();

    return _allSpecies.where((species) {
      if (_nativeOnly && !species.native) return false;
      if (query.isEmpty) return true;

      return species.commonName.toLowerCase().contains(query) ||
          species.scientificName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredSpecies;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Species Library'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search by common or scientific name',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CheckboxListTile(
              value: _nativeOnly,
              onChanged: (v) => setState(() => _nativeOnly = v ?? false),
              title: const Text('Show native species only'),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${filtered.length} species',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No species match your filters yet.'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final species = filtered[index];

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: species.native
                                ? Colors.green.withOpacity(0.18)
                                : Colors.orange.withOpacity(0.18),
                            child: Icon(
                              species.native ? Icons.forest : Icons.public,
                              color: species.native
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800,
                            ),
                          ),
                          title: Text(species.commonName),
                          subtitle: Text(species.scientificName),
                          trailing: Chip(
                            label: Text(species.native ? 'Native' : 'Introduced'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
