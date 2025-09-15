// lib/features/auth/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'login.dart';
import 'signup.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(color: Colors.white),
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          // padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Opacity(
                    opacity: 0.9,
                    child: Image.asset('assets/images/pulse.png', width: 160),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      'Pulse',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 50,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 20, right: 20),
                    child: Text(
                      'Log in to begin your shift. Real-time alerts and optimized routes are just a tap away.',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  ),
                  // Opacity(
                  //   opacity: 0.9,
                  //   child: Image.asset('assets/images/welcome_screen.png'),
                  // ),
                ],
              ),

              Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                      color: Colors.white,
                      shape: BoxShape.rectangle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // Opacity(
                        //   opacity: 0.9,
                        //   child: Image.asset(
                        //     'assets/images/welcome_screen.png',
                        //   ),
                        // ),
                        Text(
                          'Let\'s get started',
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 10),
                        MaterialButton(
                          minWidth: 250,
                          height: 60,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Colors.black),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20), // Added for spacing
                        MaterialButton(
                          minWidth: 250,
                          height: 60,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupPage(),
                              ),
                            );
                          },
                          color: Colors.black,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Text(
                            'SIGNUP',
                            style: TextStyle(
                              color: Colors.white, // Text color for dark button
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
