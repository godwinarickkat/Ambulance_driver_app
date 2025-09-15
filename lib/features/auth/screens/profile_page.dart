// lib/features/auth/screens/profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  // Receives the driver data
  final Map<String, dynamic> driverData;

  const ProfilePage({super.key, required this.driverData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;
  final _imagePicker = ImagePicker();

  late Map<String, dynamic> _driverData;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Initialize the state with the widget's data
    _driverData = widget.driverData;
  }

  Future<void> _pickAndUploadImage(String docType) async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (image == null) return; // User cancelled the picker

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final file = File(image.path);
      final ref = _storage.ref('kyc_documents/${user.uid}/$docType.jpg');
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      final updatedData = {'${docType}Url': imageUrl, 'kycStatus': 'submitted'};

      await _firestore.collection('drivers').doc(user.uid).update(updatedData);

      // Refresh the local data to show the new status and image
      setState(() {
        _driverData.addAll(updatedData);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$docType uploaded successfully!")),
      );
    } catch (e) {
      print("Failed to upload image: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to upload image: $e")));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Profile & KYC",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.amber),
      ),
      body:
          _isUploading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 20),
                  _buildKycSection(),
                ],
              ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: const Icon(Icons.person_pin_circle, size: 40),
        title: Text(
          _driverData['name'] ?? 'Driver Name',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_driverData['phone'] ?? 'Phone Number'),
      ),
    );
  }

  Widget _buildKycSection() {
    final kycStatus = _driverData['kycStatus'] ?? 'pending';
    final licenseUrl = _driverData['licenseUrl'];
    final rcUrl = _driverData['rcUrl'];

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Document Verification (KYC)",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Chip(
              label: Text(
                kycStatus.toUpperCase(),
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor:
                  kycStatus == 'approved' ? Colors.green[500] : Colors.red[500],
            ),
            const Divider(height: 20),
            _buildDocUploadTile(
              title: "Driver's License",
              docType: "license",
              imageUrl: licenseUrl,
            ),
            _buildDocUploadTile(
              title: "Vehicle RC",
              docType: "rc",
              imageUrl: rcUrl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocUploadTile({
    required String title,
    required String docType,
    String? imageUrl,
  }) {
    return ListTile(
      leading:
          imageUrl != null
              ? Image.network(
                imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
              : const Icon(Icons.image_not_supported, size: 40),
      title: Text(title),
      trailing: ElevatedButton(
        onPressed: () => _pickAndUploadImage(docType),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black, // <-- The button's background color
          foregroundColor: Colors.white, // <-- The button's text color
          // side: const BorderSide(
          //   color: Colors.white24,
          // ), // Optional: adds a subtle border
        ),
        child: Text(imageUrl != null ? "Re-upload" : "Upload"),
      ),
    );
  }
}
