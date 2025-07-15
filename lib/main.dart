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

      // Ya no es necesario 'theme', lo reemplazamos por el tema oscuro
      // theme: ThemeData(primarySwatch: Colors.teal),

      // Establece el modo de tema predeterminado a oscuro
      themeMode: ThemeMode.dark,

      // Define el tema oscuro con colores azules y un fondo oscuro
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue, // Colores azules para widgets como el botón
        scaffoldBackgroundColor: Colors.grey.shade900, // Un fondo oscuro
        // Personalización de la barra de navegación para que combine
        appBarTheme: const AppBarTheme(
          backgroundColor:
              Color.fromARGB(255, 14, 53, 91), // Un azul oscuro para la barra
        ),
      ),

      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
