import 'dart:async';
import 'package:babyshophub/User/welcome_screen.dart';
import 'package:flutter/material.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  bool _isAnimated = false;

  @override
  void initState() {
    super.initState();

    // start animation immediately
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isAnimated = true;
        });
      }
    });

    // navigate after animation completes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 1000),
          opacity: _isAnimated ? 1 : 0,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 1000),
            scale: _isAnimated ? 1 : 0.5,
            curve: Curves.easeOutBack,
            child: Image.asset("images/logonew.png", width: 200),
          ),
        ),
      ),
    );
  }
}
