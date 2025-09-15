// lib/features/auth/screens/signup.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'otp_page.dart'; // Make sure you have this file from the previous guide

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // Use TextEditingControllers to get the input
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // In _SignupPageState, replace the old _sendOtp function

  void _sendOtp() async {
    if (_phoneController.text.length != 10 ||
        _nameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields correctly.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final phoneNumber = "+91${_phoneController.text.trim()}";

    // 1. Bundle all the registration data into a Map
    final driverData = {
      'name': _nameController.text.trim(),
      'phone': phoneNumber,
      'password': _passwordController.text.trim(),
    };

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        if (mounted)
          setState(() {
            _isLoading = false;
          });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification failed: ${e.message}")),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              // 2. Pass the bundled data to the new OtpPage
              builder:
                  (context) => OtpPage(
                    verificationId: verificationId,
                    isLogin: false, // This is a registration
                    registrationData: driverData,
                  ),
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          width: double.infinity,
          child: Column(
            children: <Widget>[
              const Text(
                "Sign up",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Create an account, it's free",
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
              ),
              const SizedBox(height: 30),

              // Use TextFormFields with controllers
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: "10-Digit Phone Number",
                  prefixText: "+91 ",
                  counterText: "", // Hides the character counter
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              const SizedBox(height: 40),
              MaterialButton(
                minWidth: double.infinity,
                height: 60,
                onPressed: _isLoading ? null : _sendOtp,
                color: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          "Get OTP",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
              ),
              const SizedBox(height: 20),
              // const Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: <Widget>[
              //     Text("Already have an account?"),
              //     Text(
              //       " Login",
              //       style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
