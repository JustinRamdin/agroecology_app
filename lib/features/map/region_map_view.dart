import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models.dart';
import '../planting/log_planting_sheet.dart';
import '../planting/planting_detail_screen.dart';

// Cloud sync + photo upload + outbox
import '../../core/storage_service.dart';
import '../../core/sync_service.dart';
import '../../core/sync_queue.dart';
import '../../core/superbase_client.dart'; // Supa.client

class RegionMapView extends StatefulWidget {
  const RegionMapView({
    required this.title,
    required this.center,
    required this.bounds,
    required this.speciesCatalog,
    this.initialZoom = 9,
    super.key,
  });

  final String title;
  final LatLng center;

  /// Hard bounds (used for snap-back / filtering plantings)
  final LatLngBounds bounds;

  final List<Species> speciesCatalog;

  /// Per-tab zoom
  final double initialZoom;

  @override
  State<RegionMapView> createState() => _RegionMapViewState();
}

class _RegionMapViewState extends State<RegionMapView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  GoogleMapController? _mapController;

  final Set<Marker> _markers = <Marker>{};
  final List<Planting> _plantings = [];

  // Draft marker (from long-press or "add here")
  static const String _draftMarkerId = '__draft_marker__';

  // 1 km² server grid
  bool _showKmGrid = true;
  final Set<Polygon> _gridPolys = <Polygon>{};
  int _polyRev = 0;
  bool _gridLoading = false;

  bool _syncing = false;

    ({String emoji, double hue}) _emojiStyleForPlanting(Planting p) {
    final name = p.speciesName.toLowerCase();

    if (name.contains('mango')) {
      return (emoji: '🥭', hue: BitmapDescriptor.hueOrange);
    }
    if (name.contains('coconut')) {
      return (emoji: '🥥', hue: BitmapDescriptor.hueGreen);
    }
    if (name.contains('citrus') ||
        name.contains('orange') ||
        name.contains('lime')) {
      return (emoji: '🍊', hue: BitmapDescriptor.hueYellow);
    }
    if (name.contains('banana')) {
      return (emoji: '🍌', hue: BitmapDescriptor.hueYellow);
    }
    if (name.contains('avocado')) {
      return (emoji: '🥑', hue: BitmapDescriptor.hueGreen);
    }

    // fallback
    return (emoji: '🌱', hue: BitmapDescriptor.hueAzure);
  }

  // Soft-bounds snapback
  bool _snappingBack = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPlantings().then((_) => _drainOutboxSilently());
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ---------- Bounds helpers ----------
  LatLngBounds _expandBounds(LatLngBounds b,
      {double latPad = 0.18, double lngPad = 0.18}) {
    final south = math.min(b.southwest.latitude, b.northeast.latitude) - latPad;
    final north = math.max(b.southwest.latitude, b.northeast.latitude) + latPad;
    final west =
        math.min(b.southwest.longitude, b.northeast.longitude) - lngPad;
    final east =
        math.max(b.southwest.longitude, b.northeast.longitude) + lngPad;

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  bool _isInsideBounds(LatLng p, LatLngBounds b) {
    final south = math.min(b.southwest.latitude, b.northeast.latitude);
    final north = math.max(b.southwest.latitude, b.northeast.latitude);
    final west = math.min(b.southwest.longitude, b.northeast.longitude);
    final east = math.max(b.southwest.longitude, b.northeast.longitude);

    return p.latitude >= south &&
        p.latitude <= north &&
        p.longitude >= west &&
        p.longitude <= east;
  }

  LatLng _clampLatLngToBounds(LatLng p, LatLngBounds b) {
    final south = math.min(b.southwest.latitude, b.northeast.latitude);
    final north = math.max(b.southwest.latitude, b.northeast.latitude);
    final west = math.min(b.southwest.longitude, b.northeast.longitude);
    final east = math.max(b.southwest.longitude, b.northeast.longitude);

    final lat = p.latitude.clamp(south, north);
    final lng = p.longitude.clamp(west, east);
    return LatLng(lat, lng);
  }

  Future<void> _enforceHardBounds() async {
    if (_mapController == null || _snappingBack) return;

    // Approx camera target = center of visible region
    final vr = await _mapController!.getVisibleRegion();
    final center = LatLng(
      (vr.southwest.latitude + vr.northeast.latitude) / 2,
      (vr.southwest.longitude + vr.northeast.longitude) / 2,
    );

    if (_isInsideBounds(center, widget.bounds)) return;

    final clamped = _clampLatLngToBounds(center, widget.bounds);

    _snappingBack = true;
    try {
      await _mapController!.animateCamera(CameraUpdate.newLatLng(clamped));
    } finally {
      _snappingBack = false;
    }
  }

  // ---------- Data loading ----------
  Future<void> _loadSavedPlantings() async {
    final box = Hive.box('plantings');
    _markers.clear();
    _plantings.clear();

    for (final raw in box.values) {
      final p = Planting.fromMap(Map<String, dynamic>.from(raw));
      final pos = LatLng(p.lat, p.lng);

      // Only show plantings inside this region
      if (!_isInsideBounds(pos, widget.bounds)) continue;

      _plantings.add(p);
      _markers.add(_markerFor(p));
    }

    if (!mounted) return;
    setState(() {});
    _fitToAllMarkers();
  }

    Marker _markerFor(Planting p) {
    final style = _emojiStyleForPlanting(p);

    final title = '${style.emoji} ${p.speciesName} • ${p.assocCategory}';

    final bits = <String>[];
    if (p.assocName.isNotEmpty) bits.add(p.assocName);
    if ((p.status ?? '').isNotEmpty) bits.add('Status: ${p.status}');
    if ((p.phenology ?? '').isNotEmpty) bits.add('Phenology: ${p.phenology}');
    if (p.heightCm != null) bits.add('Height: ${p.heightCm} cm');

    return Marker(
      markerId: MarkerId(p.id),
      position: LatLng(p.lat, p.lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(style.hue),
      infoWindow: InfoWindow(
        title: title,
        snippet: bits.isEmpty ? (p.note ?? '') : bits.join(' · '),
        onTap: () => _openPlantingDetail(p),
      ),
    );
  }


  Marker _draftMarker(LatLng latLng) {
    return Marker(
      markerId: const MarkerId(_draftMarkerId),
      position: latLng,
      draggable: false,
      infoWindow: const InfoWindow(
        title: 'New planting',
        snippet: 'Fill out the details below',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );
  }

  // ---------- UI actions ----------
  Future<void> _openPlantingDetail(Planting p) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlantingDetailScreen(planting: p)),
    );
    setState(() {});
  }

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
      final here = LatLng(pos.latitude, pos.longitude);

      if (!_isInsideBounds(here, widget.bounds)) {
        _snack('You are outside ${widget.title} bounds.');
        return;
      }

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(here, 16));
    } catch (_) {
      _snack('Could not get current location.');
    }
  }

  void _fitToAllMarkers() {
    if (_markers.isEmpty || _mapController == null) return;

    final realMarkers =
        _markers.where((m) => m.markerId.value != _draftMarkerId).toList();
    if (realMarkers.isEmpty) return;

    if (realMarkers.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(realMarkers.first.position, 16),
      );
      return;
    }

    double? minLat, maxLat, minLng, maxLng;
    for (final m in realMarkers) {
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
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    });
  }

  Future<void> _drainOutboxSilently() async {
    try {
      await SyncQueue.processAll();
    } catch (_) {}
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

  // ---------- Grid ----------
  Future<void> _updateServerGrid() async {
    if (!_showKmGrid || _mapController == null) {
      if (mounted) setState(() => _gridPolys.clear());
      return;
    }
    if (_gridLoading) return;
    _gridLoading = true;

    try {
      final bounds = await _mapController!.getVisibleRegion();
      final minLat =
          math.min(bounds.southwest.latitude, bounds.northeast.latitude);
      final maxLat =
          math.max(bounds.southwest.latitude, bounds.northeast.latitude);
      final minLng =
          math.min(bounds.southwest.longitude, bounds.northeast.longitude);
      final maxLng =
          math.max(bounds.southwest.longitude, bounds.northeast.longitude);

      final db = Supa.client;

      final dynamic res = await db.rpc('cells_in_bbox', params: {
        'south': minLat,
        'west': minLng,
        'north': maxLat,
        'east': maxLng,
      });

      final rows = (res is List) ? res : <dynamic>[];
      final newPolys = <Polygon>{};
      final localRev = _polyRev + 1;

      for (final row in rows) {
        if (row is! Map) continue;
        final id = row['id'];
        final gj = row['geojson'];
        if (gj is! Map) continue;

        if (gj['type'] != 'Polygon') continue;
        final outer = (gj['coordinates'] as List).first as List;
        final pts = <LatLng>[];
        for (final c in outer) {
          if (c is List && c.length >= 2) {
            pts.add(LatLng(
              (c[1] as num).toDouble(),
              (c[0] as num).toDouble(),
            ));
          }
        }
        if (pts.length < 3) continue;

        newPolys.add(
          Polygon(
            polygonId: PolygonId('cell_${id}_$localRev'),
            points: pts,
            strokeWidth: 1,
            strokeColor: Colors.black.withOpacity(0.20),
            fillColor: Colors.greenAccent.withOpacity(0.06),
            consumeTapEvents: false,
          ),
        );

        if (newPolys.length >= 800) break;
      }

      if (!mounted) return;
      setState(() {
        _polyRev = localRev;
        _gridPolys
          ..clear()
          ..addAll(newPolys);
      });
    } catch (_) {
      // keep last grid
    } finally {
      _gridLoading = false;
    }
  }

  // ---------- Create planting from a point ----------
  Future<void> _startPlantingAt(LatLng latLng) async {
    if (!_isInsideBounds(latLng, widget.bounds)) {
      _snack('Outside ${widget.title} bounds.');
      return;
    }

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == _draftMarkerId);
      _markers.add(_draftMarker(latLng));
    });

    _mapController?.showMarkerInfoWindow(const MarkerId(_draftMarkerId));

    final planting = await showModalBottomSheet<Planting>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: PlantingForm(
          speciesCatalog: widget.speciesCatalog,
          fixedLocation: latLng,
          fixedAccuracyM: null,
        ),
      ),
    );

    // Cancel -> remove draft marker
    if (planting == null) {
      if (!mounted) return;
      setState(() {
        _markers.removeWhere((m) => m.markerId.value == _draftMarkerId);
      });
      return;
    }

    await _savePlantingLocalAndCloud(planting);

    if (!mounted) return;
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == _draftMarkerId);
      _plantings.add(planting);
      _markers.add(_markerFor(planting));
    });

    _snack('Planting logged: ${planting.speciesName}');
  }

  Future<void> _savePlantingLocalAndCloud(Planting planting) async {
    // 1) Save local
    final plantingsBox = Hive.box('plantings');
    await plantingsBox.put(planting.id, planting.toMap());

    Planting finalPlanting = planting;

    // 2) Try cloud photo + Supabase, else queue
    try {
      if ((planting.photoPath ?? '').isNotEmpty) {
        final file = File(planting.photoPath!);
        if (file.existsSync()) {
          final url = await StorageService.uploadPlantPhoto(
            plantingId: planting.id,
            file: file,
          );
          if (url != null) {
            finalPlanting = planting.copyWith(photoUrl: url);
            await plantingsBox.put(finalPlanting.id, finalPlanting.toMap());
          }
        }
      }

      await SyncService.upsertPlanting(finalPlanting);
    } catch (_) {
      final outbox = Hive.box('outbox_plantings');
      await outbox.put(finalPlanting.id, finalPlanting.toMap());
      _snack('Cloud sync failed — queued for retry.');
    }
  }

  // ---------- New button: Add marker at my current location ----------
  Future<void> _addMarkerAtMyLocation() async {
    await _ensureLocationPermission();
    try {
      final pos = await Geolocator.getCurrentPosition();
      final here = LatLng(pos.latitude, pos.longitude);

      if (!_isInsideBounds(here, widget.bounds)) {
        _snack('You are outside ${widget.title} bounds.');
        return;
      }

      // Center slightly, then open form
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(here, 16));
      await _startPlantingAt(here);
    } catch (_) {
      _snack('Could not get current location.');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final softBounds =
        CameraTargetBounds(_expandBounds(widget.bounds, latPad: 0.18, lngPad: 0.18));

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.center,
              zoom: widget.initialZoom,
            ),

            // Soft bounds for smoother zoom/pan
            cameraTargetBounds: softBounds,

            onMapCreated: (c) {
              _mapController = c;
              _updateServerGrid();
            },

            onCameraIdle: () async {
              await _enforceHardBounds();
              await _updateServerGrid();
            },

            onLongPress: _startPlantingAt,

            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
            polygons: _showKmGrid ? _gridPolys : <Polygon>{},
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),

          // Top-right overlay buttons (replaces inner AppBar actions)
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RoundIconBtn(
                      tooltip: _showKmGrid ? 'Hide 1 km grid' : 'Show 1 km grid',
                      icon: Icons.grid_on,
                      onTap: () async {
                        setState(() => _showKmGrid = !_showKmGrid);
                        await _updateServerGrid();
                      },
                    ),
                    const SizedBox(height: 10),
                    _RoundIconBtn(
                      tooltip: _syncing ? 'Syncing…' : 'Sync now',
                      icon: Icons.sync,
                      spinning: _syncing,
                      onTap: _syncNow,
                    ),
                    const SizedBox(height: 10),
                    _RoundIconBtn(
                      tooltip: 'Fit markers',
                      icon: Icons.center_focus_strong,
                      onTap: _fitToAllMarkers,
                    ),
                    const SizedBox(height: 10),
                    _RoundIconBtn(
                      tooltip: 'My Location (center)',
                      icon: Icons.my_location,
                      onTap: _centerOnUser,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ✅ Bottom-left: Add marker at my current location (and open form)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FloatingActionButton.extended(
                  heroTag: '${widget.title}_add_here',
                  onPressed: _addMarkerAtMyLocation,
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text('Add Here'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  const _RoundIconBtn({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.spinning = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: spinning ? null : onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Center(
            child: spinning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}
