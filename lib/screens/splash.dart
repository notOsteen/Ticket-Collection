import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ticket_collection/gen/assets.gen.dart';
import 'package:ticket_collection/screens/homepage.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(Assets.splashPng.provider(), context);

      Future.delayed(const Duration(seconds: 3), () {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(builder: (context) => const MyHomePage()),
          );
        }
      });
    });

    return Scaffold(
      body: SizedBox.expand(
        child: Assets.splashPng.image(fit: BoxFit.cover),
      ),
    );
  }
}
