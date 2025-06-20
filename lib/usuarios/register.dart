import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String nombreUsuario = '';
  String correo = '';
  String password = '';
  String nombreCliente = '';
  String apellidoCliente = '';
  String cedulaRuc = '';
  String telefono = '';
  String direccion = '';
  DateTime? fechaNacimiento;
  bool isLoading = false;
  String? errorMsg;

  Future<void> registrar() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    final response = await http.post(
      Uri.parse(
          'https://backendpawstails.runasp.net/api/gestion/usuario/registrar-cliente'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "nombreUsuario": nombreUsuario,
        "correo": correo,
        "password": password,
        "nombreCliente": nombreCliente,
        "apellidoCliente": apellidoCliente,
        "cedulaRuc": cedulaRuc,
        "telefono": telefono,
        "fechaNacimiento": fechaNacimiento?.toIso8601String(),
        "direccion": direccion,
      }),
    );
    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200 && response.body == 'true') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Registro exitoso'),
          content: const Text('¡Usuario registrado correctamente!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        errorMsg = 'No se pudo registrar el usuario';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Nombre de usuario'),
                onChanged: (v) => nombreUsuario = v,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese un usuario' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Correo'),
                onChanged: (v) => correo = v,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese un correo' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                onChanged: (v) => password = v,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese una contraseña' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre'),
                onChanged: (v) => nombreCliente = v,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese su nombre' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Apellido'),
                onChanged: (v) => apellidoCliente = v,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese su apellido' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Cédula/RUC'),
                onChanged: (v) => cedulaRuc = v,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese su cédula o RUC' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Teléfono'),
                onChanged: (v) => telefono = v,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese su teléfono' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Dirección'),
                onChanged: (v) => direccion = v,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese su dirección' : null,
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(fechaNacimiento == null
                    ? 'Fecha de nacimiento'
                    : 'Fecha: ${fechaNacimiento!.toLocal()}'.split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      fechaNacimiento = picked;
                    });
                  }
                },
              ),
              if (errorMsg != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(errorMsg!,
                      style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 16),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate() &&
                            fechaNacimiento != null) {
                          registrar();
                        }
                      },
                      child: const Text('Registrarse'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
