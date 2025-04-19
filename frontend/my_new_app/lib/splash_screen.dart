import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:my_new_app/sections/main_page.dart';

class AnimatedSplashScreenWidget extends StatelessWidget {
  const AnimatedSplashScreenWidget ({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Center(
                child: Lottie.asset('assets/animations/splashScreenAnimation.json'),
              ),
 
      nextScreen: MainPage(), 
      splashIconSize: 200,
      backgroundColor: const Color.fromARGB(255, 38, 38, 38),
      duration: 3000,
    );
  }
}