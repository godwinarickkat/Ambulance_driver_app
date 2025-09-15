// lib/features/auth/screens/on_trip_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OnTripPage extends StatefulWidget {
  final DocumentSnapshot rideDoc;
  const OnTripPage({super.key, required this.rideDoc});

  @override
  State<OnTripPage> createState() => _OnTripPageState();
}

class _OnTripPageState extends State<OnTripPage> {
  final MapController _mapController = MapController();
  final Location _locationController = Location();

  StreamSubscription<LocationData>? _locationSubscription;
  String _tripStatus = 'accepted';

  LatLng? _driverPosition;
  List<LatLng> _routePoints = [];
  double _estimatedDistance = 0.0; // The total route distance from API
  double _actualDistanceCovered = 0.0; // Live calculated distance
  LatLng? _lastLocation;

  @override
  void initState() {
    super.initState();
    // Initialize status based on the document, but default to 'accepted' if null
    // final rideData = widget.rideDoc.data() as Map<String, dynamic>;
    _tripStatus = 'accepted';

    // If the status is already past 'accepted', we fetch the appropriate route
    if (_tripStatus == 'on_trip') {
      _fetchDropoffRoute();
    } else {
      _fetchInitialLocationsAndRoute();
    }
    _startLiveLocationUpdates();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  // In _OnTripPageState

  void _startLiveLocationUpdates() {
    _locationSubscription = _locationController.onLocationChanged.listen((
      locationData,
    ) {
      if (locationData.latitude != null && locationData.longitude != null) {
        final newPosition = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );

        // --- THE LOGIC TO CALCULATE DISTANCE ---
        if (_lastLocation != null) {
          const Distance distance = Distance();
          final meters = distance.as(
            LengthUnit.Meter,
            _lastLocation!,
            newPosition,
          );
          _actualDistanceCovered += (meters / 1000.0);
        }
        // ------------------------------------

        if (mounted) {
          setState(() {
            _driverPosition = newPosition;
            // --- THE CRITICAL FIX ---
            // Update the last location to the current one for the next calculation
            _lastLocation = newPosition;
            // ------------------------
          });
        }

        FirebaseFirestore.instance
            .collection('drivers')
            .doc(widget.rideDoc['driverId'])
            .update({
              'location': GeoPoint(newPosition.latitude, newPosition.longitude),
            });
      }
    });
  }

  Future<void> _handleArrival() async {
    await FirebaseFirestore.instance
        .collection('ride_requests')
        .doc(widget.rideDoc.id)
        .update({'status': 'arrived'});
    if (mounted) {
      setState(() {
        _tripStatus = 'arrived';
      });
    }
  }

  Future<void> _startTrip() async {
    await FirebaseFirestore.instance
        .collection('ride_requests')
        .doc(widget.rideDoc.id)
        .update({'status': 'on_trip'});
    if (mounted) {
      setState(() {
        _tripStatus = 'on_trip';
      });
    }
    await _fetchDropoffRoute();
  }

  Future<void> _completeTrip() async {
    await FirebaseFirestore.instance
        .collection('ride_requests')
        .doc(widget.rideDoc.id)
        .update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          // --- NEW: Save the ACCURATE, live-tracked distance ---
          'distance': _actualDistanceCovered,
        });
    _locationSubscription?.cancel();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _fetchInitialLocationsAndRoute() async {
    final locationData = await _locationController.getLocation();
    if (locationData.latitude == null || locationData.longitude == null) return;
    final driverLocation = LatLng(
      locationData.latitude!,
      locationData.longitude!,
    );

    final rideData = widget.rideDoc.data() as Map<String, dynamic>;
    final pickupGeoPoint = rideData['pickupLocation'] as GeoPoint;
    final pickupLocation = LatLng(
      pickupGeoPoint.latitude,
      pickupGeoPoint.longitude,
    );

    if (mounted) {
      setState(() {
        _driverPosition = driverLocation;
      });
    }
    await _fetchRoute(start: driverLocation, end: pickupLocation);
  }

  Future<void> _fetchDropoffRoute() async {
    final rideData = widget.rideDoc.data() as Map<String, dynamic>;
    final pickupGeoPoint = rideData['pickupLocation'] as GeoPoint;
    final dropoffGeoPoint = rideData['dropoffLocation'] as GeoPoint;

    await _fetchRoute(
      start: LatLng(pickupGeoPoint.latitude, pickupGeoPoint.longitude),
      end: LatLng(dropoffGeoPoint.latitude, dropoffGeoPoint.longitude),
    );
  }

  Future<void> _fetchRoute({required LatLng start, required LatLng end}) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=polyline';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geometry = data['routes'][0]['geometry'];
        final distanceInMeters = data['routes'][0]['distance'];
        final distanceInKm = distanceInMeters / 1000.0;
        final decodedPoints = decodePolyline(geometry);

        if (decodedPoints.isNotEmpty && mounted) {
          setState(() {
            _routePoints = decodedPoints;
            // --- NEW: Store the estimated distance for display purposes ---
            _estimatedDistance = distanceInKm;
          });
          _mapController.fitCamera(
            CameraFit.coordinates(
              coordinates: [start, end],
              padding: const EdgeInsets.all(50),
            ),
          );
        }
      }
    } catch (e) {
      // print("Error fetching route from OSRM: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideData = widget.rideDoc.data() as Map<String, dynamic>;

    String appBarTitle = "Navigating to Pickup";
    LatLng? destinationMarkerPosition;

    if (_tripStatus == 'arrived') {
      appBarTitle = "Waiting for Patient";
      final pickupGeoPoint = rideData['pickupLocation'] as GeoPoint;
      destinationMarkerPosition = LatLng(
        pickupGeoPoint.latitude,
        pickupGeoPoint.longitude,
      );
    } else if (_tripStatus == 'on_trip') {
      appBarTitle = "Navigating to Destination";
      final dropoffGeoPoint = rideData['dropoffLocation'] as GeoPoint;
      destinationMarkerPosition = LatLng(
        dropoffGeoPoint.latitude,
        dropoffGeoPoint.longitude,
      );
    } else {
      // 'accepted' status
      final pickupGeoPoint = rideData['pickupLocation'] as GeoPoint;
      destinationMarkerPosition = LatLng(
        pickupGeoPoint.latitude,
        pickupGeoPoint.longitude,
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          appBarTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.amber),
        automaticallyImplyLeading: false,
      ),
      body:
          _driverPosition == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _driverPosition!,
                        initialZoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.example.devsecit_ambulance_driver',
                        ),
                        if (_routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                strokeWidth: 5.0,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            if (_driverPosition != null)
                              Marker(
                                point: _driverPosition!,
                                width: 80,
                                height: 80,
                                child: const Icon(
                                  Icons.emergency,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            Marker(
                              point: destinationMarkerPosition,
                              width: 80,
                              height: 80,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.green,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Pickup: ${rideData['pickupAddress'] ?? 'N/A'}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Dropoff: ${rideData['dropoffAddress'] ?? 'N/A'}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          if (_tripStatus == 'accepted')
                            ElevatedButton(
                              onPressed: _handleArrival,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                              ),
                              child: const Text(
                                "Arrived at Pickup",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          if (_tripStatus == 'arrived')
                            ElevatedButton(
                              onPressed: _startTrip,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                              ),
                              child: const Text(
                                "Start Trip (Patient Onboard)",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          if (_tripStatus == 'on_trip')
                            ElevatedButton(
                              onPressed: _completeTrip,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text("Complete Trip"),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}

// Helper function to decode polylines
List<LatLng> decodePolyline(String encoded) {
  List<LatLng> points = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;
  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;
    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;
    points.add(LatLng(lat / 1E5, lng / 1E5));
  }
  return points;
}
