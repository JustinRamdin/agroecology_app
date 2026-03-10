import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/models.dart';
import '../../data/species_catalog.dart';
import 'region_map_view.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Species> _speciesCatalog = [];

  @override
  void initState() {
    super.initState();
    _speciesCatalog = kSpeciesData.map((e) => Species.fromJson(e)).toList();
  }

  // Trinidad bounds
  static final LatLngBounds _trinidadBounds = LatLngBounds(
    southwest: const LatLng(10.00, -61.95),
    northeast: const LatLng(10.92, -60.50),
  );
  static const LatLng _trinidadCenter = LatLng(10.45, -61.35);

  // Tobago bounds
  static final LatLngBounds _tobagoBounds = LatLngBounds(
    southwest: const LatLng(10.98, -61.05),
    northeast: const LatLng(11.40, -60.35),
  );
  static const LatLng _tobagoCenter = LatLng(11.25, -60.70);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Agroecology Map'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(58),
            child: TabBar(
              // ✅ bigger tabs
              labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              labelPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              indicatorWeight: 4,
              tabs: const [
                Tab(text: 'Trinidad'),
                Tab(text: 'Tobago'),
              ],
            ),
          ),
        ),

        // ✅ Disable swipe between tabs (prevents conflict with map panning)
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            RegionMapView(
              title: 'Trinidad',
              center: _trinidadCenter,
              bounds: _trinidadBounds,
              speciesCatalog: _speciesCatalog,
              initialZoom: 10,
            ),
            RegionMapView(
              title: 'Tobago',
              center: _tobagoCenter,
              bounds: _tobagoBounds,
              speciesCatalog: _speciesCatalog,
              initialZoom: 12,
            ),
          ],
        ),
      ),
    );
  }
}
