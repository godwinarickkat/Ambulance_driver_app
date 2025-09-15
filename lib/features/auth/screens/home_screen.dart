import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

import 'welcome_screen.dart';
import 'profile_page.dart';
import 'on_trip_page.dart';
import 'ride_history_screen.dart';
import 'earnings_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> driverData;
  const HomeScreen({super.key, required this.driverData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final MapController _mapController = MapController();
  final Location _locationController = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  StreamSubscription<QuerySnapshot>? _rideRequestSubscription;
  LatLng? _currentPosition;
  final List<Marker> _markers = [];
  late bool _isOnline;

  // State variables for dashboard stats
  bool _isLoadingStats = true;
  int _totalRides = 0;
  double _totalKms = 0.0;
  double _totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _isOnline = widget.driverData['isOnline'] ?? false;
    _getInitialLocation();
    if (_isOnline) {
      _startListening();
    }
    _fetchDriverStats();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _rideRequestSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchDriverStats() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingStats = false);
      return;
    }

    final querySnapshot =
        await _firestore
            .collection('ride_requests')
            .where('driverId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'completed')
            .get();

    if (querySnapshot.docs.isEmpty) {
      if (mounted) setState(() => _isLoadingStats = false);
      return;
    }

    int rideCount = querySnapshot.docs.length;
    double kmsSum = 0.0;
    double earningsSum = 0.0;

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      kmsSum += (data['distance'] ?? 0).toDouble();
      earningsSum += (data['fare'] ?? 0).toDouble();
    }

    if (mounted) {
      setState(() {
        _totalRides = rideCount;
        _totalKms = kmsSum;
        _totalEarnings = earningsSum;
        _isLoadingStats = false;
      });
    }
  }

  Future<void> sendWhatsAppMessage({
    required String number,
    required String message,
  }) async {
    // This function remains the same
    const apiKey = "rQnSOZ9zXWz65BQQyUtoKEs0lmQoc3";
    const sender = "919531654045";
    final queryParameters = {
      'api_key': apiKey,
      'sender': sender,
      'number': number,
      'message': message,
      'footer': 'DEVSECIT Ambulance',
      'full': '1',
    };
    final url = Uri.https(
      'whatsapp.devsecit.com',
      '/send-message',
      queryParameters,
    );
    try {
      await http.get(url).timeout(const Duration(seconds: 15));
    } catch (e) {
      print("Error sending WhatsApp message: $e");
    }
  }

  Future<void> _updateOnlineStatus(bool status) async {
    setState(() => _isOnline = status);
    if (_isOnline) {
      _startListening();
    } else {
      _stopListening();
    }
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('drivers').doc(user.uid).update({
        'isOnline': status,
      });
    }
  }

  void _startListening() {
    _startListeningToLocation();
    _listenForRideRequests();
  }

  void _stopListening() {
    _stopListeningToLocation();
    _rideRequestSubscription?.cancel();
    _rideRequestSubscription = null;
  }

  void _listenForRideRequests() {
    final user = _auth.currentUser;
    if (user == null) return;
    _rideRequestSubscription?.cancel();
    final query = _firestore
        .collection('ride_requests')
        .where('driverId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending');
    _rideRequestSubscription = query.snapshots().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final rideDoc = snapshot.docs.first;
        if (ModalRoute.of(context)?.isCurrent == true) {
          _showRideRequestDialog(rideDoc);
        }
      }
    });
  }

  void _showRideRequestDialog(DocumentSnapshot rideDoc) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return RideRequestDialog(
          rideDoc: rideDoc,
          driverName: widget.driverData['name'] ?? 'Your Driver',
          homeScreenState: this,
        );
      },
    );
  }

  void _startListeningToLocation() {
    // This function remains the same
    _locationController.hasPermission().then((permission) {
      if (permission == PermissionStatus.granted) {
        _locationSubscription = _locationController.onLocationChanged.listen((
          locationData,
        ) {
          if (locationData.latitude != null && locationData.longitude != null) {
            final newPosition = LatLng(
              locationData.latitude!,
              locationData.longitude!,
            );
            if (mounted) {
              setState(() {
                _currentPosition = newPosition;
                _markers.clear();
                _markers.add(
                  Marker(
                    point: _currentPosition!,
                    child: Icon(
                      Icons.emergency,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              });
            }
            final user = _auth.currentUser;
            if (user != null && _isOnline) {
              _firestore.collection('drivers').doc(user.uid).update({
                'location': GeoPoint(
                  newPosition.latitude,
                  newPosition.longitude,
                ),
              });
            }
          }
        });
      }
    });
  }

  void _stopListeningToLocation() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  Future<void> _getInitialLocation() async {
    // This function remains the same
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) return;
    }
    permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }
    final locationData = await _locationController.getLocation();
    if (locationData.latitude != null && locationData.longitude != null) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(
            locationData.latitude!,
            locationData.longitude!,
          );
          _markers.clear();
          _markers.add(
            Marker(
              point: _currentPosition!,
              child: Icon(
                Icons.emergency,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        });
      }
      _goToCurrentPosition();
    }
  }

  void _goToCurrentPosition() {
    if (_currentPosition == null) return;
    _mapController.move(_currentPosition!, 15.0);
  }

  Future<void> _logout() async {
    // This function remains the same
    await _updateOnlineStatus(false);
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              // decoration: BoxDecoration(color: Colors.white),
              child: Text(
                'Welcome, ${widget.driverData['name'] ?? 'Driver'}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.black,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('My Profile & KYC'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ProfilePage(driverData: widget.driverData),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Ride History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RideHistoryScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('My Earnings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EarningsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition ?? const LatLng(10.5276, 76.2144),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.devsecit_ambulance_driver',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomSheet(theme),
          ),
          Positioned(
            // You can adjust these values to get the perfect position
            bottom: 180.0,
            right: 16.0,
            child: FloatingActionButton(
              foregroundColor: Colors.black,
              onPressed: _goToCurrentPosition,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   foregroundColor: Colors.black,
      //   backgroundColor: Colors.white,
      //   onPressed: _goToCurrentPosition,
      //   child: const Icon(Icons.my_location),
      // ),
    );
  }

  Widget _buildBottomSheet(ThemeData theme) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(12.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(
              color: Colors.grey[300],
              height: 1,
              thickness: 3,
              indent: 60,
              endIndent: 60,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.circle,
                color: _isOnline ? Colors.green : Colors.red,
                size: 16,
              ),
              title: Text(
                _isOnline ? 'You\'re online' : 'You\'re offline',
                // widget.driverData['name'] ?? 'Driver',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Switch(
                activeTrackColor: Colors.black,
                value: _isOnline,
                onChanged: _updateOnlineStatus,
                activeColor: Colors.white,
              ),
            ),
            // const Divider(height: 24),
            _isLoadingStats
                ? const CircularProgressIndicator()
                : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      "Total Rides",
                      _totalRides.toString(),
                      theme,
                    ),
                    _buildStatItem(
                      "Total KMs",
                      _totalKms.toStringAsFixed(1),
                      theme,
                    ),
                    _buildStatItem(
                      "Earnings",
                      "₹${_totalEarnings.toStringAsFixed(0)}",
                      theme,
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

// --- WIDGET FOR THE DIALOG ---
class RideRequestDialog extends StatefulWidget {
  final DocumentSnapshot rideDoc;
  final String driverName;
  final _HomeScreenState homeScreenState;

  const RideRequestDialog({
    super.key,
    required this.rideDoc,
    required this.driverName,
    required this.homeScreenState,
  });

  @override
  State<RideRequestDialog> createState() => _RideRequestDialogState();
}

class _RideRequestDialogState extends State<RideRequestDialog> {
  late Timer _timer;
  int _countdown = 30;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown == 0) {
        timer.cancel();
        _declineRide();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _declineRide() async {
    if (!mounted) return;
    await FirebaseFirestore.instance
        .collection('ride_requests')
        .doc(widget.rideDoc.id)
        .update({'status': 'declined'});
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _acceptRide() async {
    if (!mounted) return;
    _timer.cancel();

    await FirebaseFirestore.instance
        .collection('ride_requests')
        .doc(widget.rideDoc.id)
        .update({'status': 'accepted'});

    final rideData = widget.rideDoc.data() as Map<String, dynamic>;
    String? patientPhone = rideData['patientPhone']?.toString();

    if (patientPhone != null && patientPhone.startsWith('+')) {
      patientPhone = patientPhone.substring(1);
    }

    if (patientPhone != null) {
      final message =
          "Help is on the way! Your driver, ${widget.driverName}, has accepted the request and is en route.";
      await widget.homeScreenState.sendWhatsAppMessage(
        number: patientPhone,
        message: message,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OnTripPage(rideDoc: widget.rideDoc),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideData = widget.rideDoc.data() as Map<String, dynamic>;
    return AlertDialog(
      title: const Text("New Ride Request!"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Patient: ${rideData['patientName'] ?? 'N/A'}"),
          const SizedBox(height: 8),
          Text("From: ${rideData['pickupAddress'] ?? 'N/A'}"),
          const SizedBox(height: 8),
          Text("To: ${rideData['dropoffAddress'] ?? 'N/A'}"),
          const SizedBox(height: 16),
          Center(
            child: Text(
              "Time to accept: $_countdown",
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _declineRide, child: const Text("Decline")),
        ElevatedButton(onPressed: _acceptRide, child: const Text("Accept")),
      ],
    );
  }
}
