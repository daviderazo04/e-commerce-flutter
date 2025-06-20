import 'package:flutter/material.dart';
import 'package:paws_and_tails/usuarios/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paws & Tails',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
