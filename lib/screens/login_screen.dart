import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/login/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xff009fd6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Add the image at the top
            Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: Image.asset(
                'assets/logo.png',
                height: 100, // Adjust height as needed
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20), // Spacing between image and form
            SizedBox(
              height: 471, // Set the desired height for the form container
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(5.0),
                  color: Colors.white.withOpacity(0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaY: 5, sigmaX: 5),
                    child: const Padding(
                      padding: EdgeInsets.all(25),
                      child: LoginForm(), // Use the LoginForm widget
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}