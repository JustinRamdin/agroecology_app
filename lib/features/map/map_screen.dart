// lib/features/map/map_screen.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models.dart';
import '../../data/species_catalog.dart';
import '../planting/log_planting_sheet.dart';
import '../planting/planting_detail_screen.dart';

// Cloud sync + photo upload + outbox
import '../../core/storage_service.dart';
import '../../core/sync_service.dart';
import '../../core/sync_queue.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  static const LatLng _ttCenter = LatLng(10.5, -61.3);

  final Set<Marker> _markers = <Marker>{};
  final List<Planting> _plantings = [];
  List<Species> _speciesCatalog = [];

  // Grid controls/state
  bool _showKmGrid = true;               // toggle 1 km grid
  final Set<Polyline> _gridLines = {};   // current grid polylines
  int _gridRevision = 0;                 // helps give unique polyline ids

  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadSpecies();
    _loadSavedPlantings().then((_) => _drainOutboxSilently());
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _loadSpecies() {
    _speciesCatalog = kSpeciesData.map((e) => Species.fromJson(e)).toList();
    setState(() {});
  }

  Future<void> _loadSavedPlantings() async {
    final box = Hive.box('plantings');
    for (final raw in box.values) {
      final p = Planting.fromMap(Map<String, dynamic>.from(raw));
      _plantings.add(p);
      _markers.add(_markerFor(p));
    }
    if (!mounted) return;
    setState(() {});
    _fitToAllMarkers();
    await _updateKmGrid(); // build grid for initial camera
  }

  Marker _markerFor(Planting p) {
    final title = '${p.speciesName} • ${p.assocCategory}';
    final bits = <String>[];
    if (p.assocName.isNotEmpty) bits.add(p.assocName);
    if ((p.status ?? '').isNotEmpty) bits.add('Status: ${p.status}');
    if ((p.phenology ?? '').isNotEmpty) bits.add('Phenology: ${p.phenology}');
    if (p.heightCm != null) bits.add('Height: ${p.heightCm} cm');

    return Marker(
      markerId: MarkerId(p.id),
      position: LatLng(p.lat, p.lng),
      infoWindow: InfoWindow(
        title: title,
        snippet: bits.isEmpty ? (p.note ?? '') : bits.join(' · '),
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
    var perm = await Geolocator.checkPermission();
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

  void _fitToAllMarkers() {
    if (_markers.isEmpty || _mapController == null) return;

    if (_markers.length == 1) {
      final m = _markers.first;
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(m.position, 16));
      return;
    }

    double? minLat, maxLat, minLng, maxLng;
    for (final m in _markers) {
      final lat = m.position.latitude;
      final lng = m.position.longitude;
      minLat = (minLat == null) ? lat : math.min(minLat, lat);
      maxLat = (maxLat == null) ? lat : math.max(maxLat, lat);
      minLng = (minLng == null) ? lng : math.min(minLng, lng);
      maxLng = (maxLng == null) ? lng : math.max(maxLng, lng);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 60),
      );
    });
  }

  /// Recompute a ~1 km × 1 km grid over the visible region using polylines.
  Future<void> _updateKmGrid() async {
    if (!_showKmGrid || _mapController == null) {
      setState(() => _gridLines.clear());
      return;
    }

    final bounds = await _mapController!.getVisibleRegion();
    final minLat = math.min(bounds.southwest.latitude, bounds.northeast.latitude);
    final maxLat = math.max(bounds.southwest.latitude, bounds.northeast.latitude);
    final minLng = math.min(bounds.southwest.longitude, bounds.northeast.longitude);
    final maxLng = math.max(bounds.southwest.longitude, bounds.northeast.longitude);

    final centerLat = (minLat + maxLat) / 2.0;

    // 1 km in degrees
    const kmPerDegLat = 111.32; // ~km per degree latitude
    final dLat = 1.0 / kmPerDegLat; // ~0.008983°
    final kmPerDegLng = kmPerDegLat * math.cos(centerLat * math.pi / 180.0);
    final safeKmPerDegLng = kmPerDegLng.abs() < 1e-6 ? 1e-6 : kmPerDegLng;
    final dLng = 1.0 / safeKmPerDegLng;

    double snapDown(double value, double step) =>
        (step == 0) ? value : (value / step).floorToDouble() * step;

    final startLat = snapDown(minLat, dLat);
    final startLng = snapDown(minLng, dLng);

    const maxLines = 80; // cap for performance
    final newLines = <Polyline>{};
    int idSeq = _gridRevision + 1;

    // Vertical lines (constant longitude)
    for (double lon = startLng; lon <= maxLng + dLng; lon += dLng) {
      if (lon < -180 || lon > 180) continue;
      newLines.add(Polyline(
        polylineId: PolylineId('v_${idSeq++}'),
        points: [LatLng(minLat, lon), LatLng(maxLat, lon)],
        width: 1,
        color: Colors.black.withOpacity(0.15),
        geodesic: false,
      ));
      if (newLines.length >= maxLines) break;
    }

    // Horizontal lines (constant latitude)
    for (double lat = startLat; lat <= maxLat + dLat; lat += dLat) {
      if (lat < -85 || lat > 85) continue;
      newLines.add(Polyline(
        polylineId: PolylineId('h_${idSeq++}'),
        points: [LatLng(lat, minLng), LatLng(lat, maxLng)],
        width: 1,
        color: Colors.black.withOpacity(0.15),
        geodesic: false,
      ));
      if (newLines.length >= maxLines) break;
    }

    setState(() {
      _gridRevision = idSeq;
      _gridLines
        ..clear()
        ..addAll(newLines);
    });
  }

  /// SAVE -> (optional) UPLOAD PHOTO -> UPSERT TO SUPABASE
  /// Queue to outbox if any cloud step fails.
  Future<void> _logPlanting() async {
    final planting = await showModalBottomSheet<Planting>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: PlantingForm(speciesCatalog: _speciesCatalog),
      ),
    );
    if (planting == null) return;

    // 1) Save to local immediately (authoritative local copy)
    final plantingsBox = Hive.box('plantings');
    await plantingsBox.put(planting.id, planting.toMap());

    // 2) Try cloud photo + Supabase, else queue
    Planting finalPlanting = planting;

    try {
      // 2a) Upload photo if present
      if ((planting.photoPath ?? '').isNotEmpty) {
        final file = File(planting.photoPath!);
        if (file.existsSync()) {
          final url = await StorageService.uploadPlantPhoto(
            plantingId: planting.id,
            file: file,
          );
          if (url != null) {
            finalPlanting = planting.copyWith(photoUrl: url);
            // Update local record with cloud URL
            await plantingsBox.put(finalPlanting.id, finalPlanting.toMap());
          }
        }
      }

      // 2b) Push to Supabase
      await SyncService.upsertPlanting(finalPlanting);
    } catch (e) {
      // 3) Queue for retry
      final outbox = Hive.box('outbox_plantings');
      await outbox.put(finalPlanting.id, finalPlanting.toMap());
      _snack('Cloud sync failed — queued for retry.');
    }

    // 4) UI updates
    setState(() {
      _plantings.add(finalPlanting);
      _markers.add(_markerFor(finalPlanting));
    });

    _fitToAllMarkers();
    _snack('Planting logged: ${finalPlanting.speciesName}');
  }

  Future<void> _drainOutboxSilently() async {
    try {
      await SyncQueue.processAll();
    } catch (_) {
      // silent; user can tap Sync to retry
    }
  }

  Future<void> _syncNow() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      await SyncQueue.processAll();
      _snack('Sync complete');
    } catch (e) {
      _snack('Sync failed: $e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _openPlantingDetail(Planting p) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlantingDetailScreen(planting: p)),
    );
    setState(() {}); // refresh after possible updates
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agroecology Map'),
        actions: [
          IconButton(
            tooltip: _showKmGrid ? 'Hide 1 km grid' : 'Show 1 km grid',
            icon: const Icon(Icons.grid_on),
            onPressed: () async {
              setState(() => _showKmGrid = !_showKmGrid);
              await _updateKmGrid();
            },
          ),
          IconButton(
            tooltip: _syncing ? 'Syncing…' : 'Sync now',
            icon: _syncing
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator())
                : const Icon(Icons.sync),
            onPressed: _syncNow,
          ),
          IconButton(
            tooltip: 'Fit markers',
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _fitToAllMarkers,
          ),
          IconButton(
            tooltip: 'My Location',
            onPressed: _centerOnUser,
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(target: _ttCenter, zoom: 9),
        onMapCreated: (c) {
          _mapController = c;
          _updateKmGrid(); // build grid once map is ready
        },
        onCameraIdle: _updateKmGrid, // recompute grid after pan/zoom
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        markers: _markers,
        polylines: _showKmGrid ? _gridLines : <Polyline>{},
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
