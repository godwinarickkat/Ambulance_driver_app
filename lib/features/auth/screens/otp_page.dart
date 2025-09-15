// lib/features/auth/screens/otp_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devsecit_ambulance_driver/features/auth/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class OtpPage extends StatefulWidget {
  final String verificationId;
  final bool isLogin;
  final String? phoneNumber;
  final Map<String, dynamic>? registrationData;

  const OtpPage({
    super.key,
    required this.verificationId,
    this.isLogin = false,
    this.phoneNumber,
    this.registrationData,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otpController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpController.text.trim(),
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        Map<String, dynamic>? driverData;

        if (widget.isLogin) {
          // LOGIN: Fetch the existing driver data from Firestore
          final doc =
              await _firestore.collection('drivers').doc(user.uid).get();
          driverData = doc.data();
        } else {
          // REGISTRATION: Create a new driver document in Firestore
          driverData = widget.registrationData;
          if (driverData != null) {
            driverData['uid'] = user.uid;
            driverData['isOnline'] = false;
            driverData['createdAt'] = FieldValue.serverTimestamp();
            await _firestore
                .collection('drivers')
                .doc(user.uid)
                .set(driverData);
          }
        }

        if (driverData != null && mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => HomeScreen(driverData: driverData!),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OTP Verification Failed: ${e.toString()}")),
      );
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Your existing UI will work here
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Verify OTP",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Enter the OTP sent to your phone"),
              const SizedBox(height: 20),
              Pinput(controller: _otpController, length: 6, autofocus: true),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(250, 60),
                      backgroundColor: Colors.black,
                    ),
                    child: const Text(
                      "Verify & Proceed",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
