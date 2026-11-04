import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mytel Login App',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
