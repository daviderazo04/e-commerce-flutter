import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paws_and_tails/usuarios/register.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      final userData = jsonDecode(body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userData', jsonEncode(userData));

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
    // Definimos un color principal para el tema
    final Color primaryColor = Colors.blue.shade700;

    return Scaffold(
      // Eliminamos el AppBar para un diseño más limpio y moderno
      // appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            // Centramos los elementos verticalmente
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Espacio superior para separación
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),

              // Agregamos el logo
              Image.asset(
                'assets/images/logoSinFondo.png',
                height: 150, // Ajusta el tamaño del logo
              ),
              const SizedBox(height: 16),

              // Mensaje de bienvenida
              Text(
                '¡Hola de nuevo!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Inicia sesión en tu cuenta',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Campo de Correo con diseño mejorado
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  labelStyle: TextStyle(color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide:
                        BorderSide(color: primaryColor.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: primaryColor, width: 2.0),
                  ),
                ),
                onChanged: (v) => correo =
                    v, // Recuerdo: Es mejor usar setState() o TextEditingController
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese su correo' : null,
              ),
              const SizedBox(height: 16),

              // Campo de Contraseña con diseño mejorado
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: TextStyle(color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide:
                        BorderSide(color: primaryColor.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: primaryColor, width: 2.0),
                  ),
                ),
                obscureText: true,
                onChanged: (v) => password =
                    v, // Recuerdo: Es mejor usar setState() o TextEditingController
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese su contraseña' : null,
              ),
              const SizedBox(height: 24),

              // Mensaje de error
              if (errorMsg != null)
                Text(
                  errorMsg!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              if (errorMsg != null) const SizedBox(height: 16),

              // Botón de Ingresar
              isLoading
                  ? CircularProgressIndicator(color: primaryColor)
                  : SizedBox(
                      width: double.infinity, // Ocupa todo el ancho
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            login();
                          }
                        },
                        child: const Text(
                          'Ingresar',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
              const SizedBox(height: 24),

              // Botón de registro
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
                child: Text(
                  '¿No tienes cuenta? Regístrate',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
