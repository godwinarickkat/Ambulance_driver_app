import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  Future<List<DocumentSnapshot>> _fetchCompletedRides() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('ride_requests')
            .where('driverId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'completed')
            .orderBy('completedAt', descending: true)
            .get();
    return querySnapshot.docs;
  }

  // Helper to check if a timestamp is from today
  bool _isToday(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "My Earnings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.amber),
      ),
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
            return const Center(child: Text("No earnings records found."));
          }

          final rides = snapshot.data!;
          double totalEarnings = 0;
          double todayEarnings = 0;

          // Calculate earnings
          for (var doc in rides) {
            final data = doc.data() as Map<String, dynamic>;
            final fare = (data['fare'] ?? 0).toDouble();
            totalEarnings += fare;

            final timestamp = data['completedAt'] as Timestamp?;
            if (timestamp != null && _isToday(timestamp)) {
              todayEarnings += fare;
            }
          }

          return Column(
            children: [
              // Summary Cards
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        "Today's Earnings",
                        "₹${todayEarnings.toStringAsFixed(2)}",
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        "Total Earnings",
                        "₹${totalEarnings.toStringAsFixed(2)}",
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(),
              ),
              // List of trips
              Expanded(
                child: ListView.builder(
                  itemCount: rides.length,
                  itemBuilder: (context, index) {
                    final rideData =
                        rides[index].data() as Map<String, dynamic>;
                    final timestamp = rideData['completedAt'] as Timestamp?;
                    final date =
                        timestamp != null
                            ? DateFormat(
                              'dd MMM yyyy',
                            ).format(timestamp.toDate())
                            : 'N/A';

                    return ListTile(
                      title: Text(
                        "Patient: ${rideData['patientName'] ?? 'N/A'}",
                      ),
                      subtitle: Text(date),
                      trailing: Text(
                        "₹${(rideData['fare'] ?? 0).toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
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

  Widget _buildSummaryCard(String title, String amount, Color color) {
    return Card(
      elevation: 4,
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
