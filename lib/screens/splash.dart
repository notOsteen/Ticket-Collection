import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ticket_collection/gen/assets.gen.dart';
import 'package:ticket_collection/screens/homepage.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.sizeOf(context);
    var padding = MediaQuery.paddingOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(Assets.splash.provider(), context);

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
      body: Stack(
        children: [
          SizedBox.expand(
            child: Assets.splash.image(fit: BoxFit.cover),
          ),
          Positioned(
            top: padding.top,
            left: 0,
            right: 0,
            child: Assets.logo.image(
              fit: BoxFit.contain,
              height: size.width * 0.32,
              width: size.width * 0.32,
            ),
          ),
          Positioned(
            top: padding.top + size.width * 0.32,
            left: 0,
            right: 0,
            child: const Text(
              'FFJ',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Positioned(
            bottom: padding.bottom + size.width * 0.1,
            left: 0,
            right: 0,
            child: const Text(
              'TICKET CALCULATOR',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
