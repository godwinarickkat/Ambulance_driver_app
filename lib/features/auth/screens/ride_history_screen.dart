import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  Future<List<DocumentSnapshot>> _fetchCompletedRides() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return []; // Return empty list if user is not logged in
    }

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('ride_requests')
            .where('driverId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'completed')
            .orderBy('completedAt', descending: true)
            .get();

    return querySnapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Ride History",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.amber),
      ),

      // In ride_history_screen.dart, replace the existing Scaffold body
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _fetchCompletedRides(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("An error occurred."));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No completed rides found."));
          }

          final rides = snapshot.data!;
          // --- CHANGE 1: Get the total count from the length of the list ---
          final rideCount = rides.length;

          // --- CHANGE 2: Use a Column to stack the count above the list ---
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CHANGE 3: Display the count in a Text widget ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    "Total Completed Rides: $rideCount",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      backgroundColor: Colors.amber,
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  'History Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              // --- CHANGE 4: IMPORTANT: Wrap the ListView in an Expanded widget ---
              Expanded(
                child: ListView.builder(
                  itemCount: rides.length,
                  itemBuilder: (context, index) {
                    final rideDoc = rides[index];
                    final rideData = rideDoc.data() as Map<String, dynamic>;

                    final timestamp = rideData['completedAt'] as Timestamp?;
                    final date =
                        timestamp != null
                            ? DateFormat(
                              'dd MMM yyyy, hh:mm a',
                            ).format(timestamp.toDate())
                            : 'N/A';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Patient: ${rideData['patientName'] ?? 'N/A'}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text("Date: $date"),
                            // const Divider(height: 20),
                            Text("From: ${rideData['pickupAddress'] ?? 'N/A'}"),
                            const SizedBox(height: 4),
                            Text("To: ${rideData['dropoffAddress'] ?? 'N/A'}"),
                            const Divider(height: 20),
                            const SizedBox(height: 8),
                            Text(
                              "Distance: ${rideData['distance']?.toStringAsFixed(2) ?? 'N/A'} km",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              "Fare: ₹${rideData['fare'] ?? '0.00'}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
