// lib/features/auth/screens/login_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devsecit_ambulance_driver/features/auth/screens/otp_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  Future<void> _sendOtp() async {
    final phoneNumber = "+91${_phoneController.text.trim()}";
    if (phoneNumber.length != 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid 10-digit phone number."),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Check if a driver with this phone number exists before sending OTP
    final driverQuery =
        await _firestore
            .collection('drivers')
            .where('phone', isEqualTo: phoneNumber)
            .limit(1)
            .get();

    if (driverQuery.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No account found with this phone number."),
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification Failed: ${e.message}")),
        );
        if (mounted)
          setState(() {
            _isLoading = false;
          });
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => OtpPage(
                    verificationId: verificationId,
                    isLogin: true, // Tell OtpPage this is a login
                    phoneNumber: phoneNumber,
                  ),
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    // Your existing UI can be adapted, but here is a simple version
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Driver Login",
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
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  prefixText: "+91 ",
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _sendOtp,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(250, 60),
                      backgroundColor: Colors.black,
                    ),
                    child: const Text(
                      "Send OTP",
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
