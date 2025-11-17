import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

void main() {
  runApp(const GPSApp());
}

class GPSApp extends StatelessWidget {
  const GPSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "GPS Tracker",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const GPSHome(),
    );
  }
}

class GPSHome extends StatefulWidget {
  const GPSHome({super.key});

  @override
  State<GPSHome> createState() => _GPSHomeState();
}

class _GPSHomeState extends State<GPSHome> {
  final MapController _mapController = MapController();

  Location location = Location();

  bool _isTracking = false;
  LatLng? _currentPosition;

  List<Marker> markers = [];

  List<LatLng> routePoints = [];
  late Stream<LocationData> _locationStream;

  @override
  void initState() {
    super.initState();
    initLocation();
  }

  Future<void> initLocation() async {
    bool enabled = await location.serviceEnabled();
    if (!enabled) {
      enabled = await location.requestService();
      if (!enabled) return;
    }

    PermissionStatus permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
      if (permission != PermissionStatus.granted) return;
    }
  }

  void _getCurrentLocation() async {
    final data = await location.getLocation();

    _currentPosition = LatLng(data.latitude!, data.longitude!);

    markers = [
      Marker(
        point: _currentPosition!,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ),
    ];

    _mapController.move(_currentPosition!, 16);

    setState(() {});
  }

  void _startTracking() {
    setState(() => _isTracking = true);

    _locationStream = location.onLocationChanged;
    _locationStream.listen((data) {
      final newPos = LatLng(data.latitude!, data.longitude!);

      // Update marker
      markers = [
        Marker(
          point: newPos,
          width: 40,
          height: 40,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
        ),
      ];

      // Add to route
      routePoints.add(newPos);

      // Move map
      _mapController.move(newPos, 17);

      setState(() {});
    });
  }

  void _stopTracking() {
    setState(() => _isTracking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GPS Tracker")),
      body: Column(
        children: [
          // Buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: _getCurrentLocation,
                  child: const Text("📍 Get Location"),
                ),
                ElevatedButton(
                  onPressed: _isTracking ? null : _startTracking,
                  child: const Text("▶️ Start"),
                ),
                ElevatedButton(
                  onPressed: !_isTracking ? null : _stopTracking,
                  child: const Text("⏹️ Stop"),
                ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(20.5937, 78.9629), // India default
                initialZoom: 4,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                ),

                // ⭐ Render path only when list is not empty
                if (routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        color: Colors.blue,
                        strokeWidth: 4,
                      ),
                    ],
                  ),

                MarkerLayer(markers: markers),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
