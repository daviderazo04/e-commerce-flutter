import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:paws_and_tails/usuarios/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ultimasCompras.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({Key? key}) : super(key: key);

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('userData');
    if (data != null) {
      setState(() {
        userData = jsonDecode(data);
      });
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    await prefs.remove('cart');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Icon(Icons.account_circle, size: 100, color: Colors.teal),
            const SizedBox(height: 16),
            Text('Nombre: ${userData!['UsuarioNombre'] ?? ''}',
                style: const TextStyle(fontSize: 18)),
            Text('Correo: ${userData!['UsuarioCorreo'] ?? ''}',
                style: const TextStyle(fontSize: 18)),
            Text('Cédula: ${userData!['Cedula'] ?? ''}',
                style: const TextStyle(fontSize: 18)),
            Text('Rol: ${userData!['Rol'] ?? ''}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Ver últimas compras'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UltimasComprasPage()),
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: logout,
            ),
          ],
        ),
      ),
    );
  }
}
