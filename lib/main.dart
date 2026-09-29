import 'package:flutter/material.dart';
import 'screens/login_otp_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatBot',
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
