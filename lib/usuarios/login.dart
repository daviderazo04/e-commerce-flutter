import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paws_and_tails/usuarios/register.dart';
import '../Productos/products_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String correo = '';
  String password = '';
  bool isLoading = false;
  String? errorMsg;

  Future<void> login() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });

    final payload = {
      'correo': correo,
      'password': password,
    };

    print('Enviando a login: $payload');

    final response = await http.post(
      Uri.parse(
          'https://backendpawstails.runasp.net/api/gestion/usuario/autenticar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    print('Status code: ${response.statusCode}');
    print('Respuesta body: ${response.body}');

    setState(() {
      isLoading = false;
    });

    final body = response.body.trim();
    if (response.statusCode == 200 && body != 'null' && body.isNotEmpty) {
      // Login exitoso
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProductsPage()),
      );
    } else {
      setState(() {
        errorMsg = 'Correo o contraseña incorrectos';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Correo'),
                onChanged: (v) => correo = v,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese su correo' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                onChanged: (v) => password = v,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese su contraseña' : null,
              ),
              const SizedBox(height: 16),
              if (errorMsg != null)
                Text(errorMsg!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          login();
                        }
                      },
                      child: const Text('Ingresar'),
                    ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
                child: const Text('¿No tienes cuenta? Regístrate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
