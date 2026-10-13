import 'package:flutter/material.dart';
import 'dart:ui';
import 'screens/login_otp_screen.dart';

void main() {
  runApp(const MyApp());
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salma App',
      scrollBehavior: AppScrollBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF303489),
          secondary: const Color(0xFF8045DD),
        ),
        useMaterial3: true,
      ),
      home: const LoginOtpScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
