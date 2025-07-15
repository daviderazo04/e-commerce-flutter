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
  final TextEditingController _nombreUsuarioController =
      TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nombreClienteController =
      TextEditingController();
  final TextEditingController _apellidoClienteController =
      TextEditingController();
  final TextEditingController _cedulaRucController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();

  DateTime? fechaNacimiento;
  bool isLoading = false;
  String? errorMsg;

  @override
  void dispose() {
    _nombreUsuarioController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _nombreClienteController.dispose();
    _apellidoClienteController.dispose();
    _cedulaRucController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> registrar() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });

    final payload = {
      "nombreUsuario": _nombreUsuarioController.text.trim(),
      "correo": _correoController.text.trim(),
      "password": _passwordController.text,
      "nombreCliente": _nombreClienteController.text.trim(),
      "apellidoCliente": _apellidoClienteController.text.trim(),
      "cedulaRuc": _cedulaRucController.text.trim(),
      "telefono": _telefonoController.text.trim(),
      "fechaNacimiento": fechaNacimiento?.toIso8601String(),
      "direccion": _direccionController.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse(
            'https://backendpawstails.runasp.net/api/gestion/usuario/registrar-cliente'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 && response.body.trim() == 'true') {
        _showSuccessDialog();
      } else {
        setState(() {
          errorMsg = 'No se pudo registrar el usuario. Inténtelo de nuevo.';
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = 'Ocurrió un error al conectar con el servidor.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
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
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.blue.shade700;

    return Scaffold(
      body: SafeArea(
        // <--- Se añade SafeArea para evitar el notch
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila para alinear el logo y el texto
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Crea tu cuenta',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Llena los datos para continuar',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Image.asset(
                      'assets/images/logoPata.png',
                      height: 60,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Campos de texto
                _buildTextFormField(
                  controller: _nombreUsuarioController,
                  labelText: 'Nombre de usuario',
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: _correoController,
                  labelText: 'Correo electrónico',
                  primaryColor: primaryColor,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: _passwordController,
                  labelText: 'Contraseña',
                  primaryColor: primaryColor,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: _nombreClienteController,
                  labelText: 'Nombre',
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: _apellidoClienteController,
                  labelText: 'Apellido',
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: _cedulaRucController,
                  labelText: 'Cédula/RUC',
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: _telefonoController,
                  labelText: 'Teléfono',
                  primaryColor: primaryColor,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: _direccionController,
                  labelText: 'Dirección',
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 16),

                // Selector de fecha
                _buildDateSelector(primaryColor),
                const SizedBox(height: 16),

                // Mensaje de error
                if (errorMsg != null)
                  Text(
                    errorMsg!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                if (errorMsg != null) const SizedBox(height: 16),

                // Botón de registro
                _buildRegisterButton(primaryColor),
                const SizedBox(height: 24),

                // Botón para volver al login
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: Text(
                      '¿Ya tienes cuenta? Inicia sesión',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Método para construir un campo de texto con el estilo del login
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required Color primaryColor,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: primaryColor, width: 2.0),
        ),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: (v) =>
          v == null || v.isEmpty ? 'Este campo es obligatorio' : null,
    );
  }

  // Método para construir el selector de fecha con el estilo deseado
  Widget _buildDateSelector(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: primaryColor.withOpacity(0.5),
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        title: Text(
          fechaNacimiento == null
              ? 'Fecha de nacimiento'
              : 'Fecha: ${fechaNacimiento!.toLocal().toString().split(' ')[0]}',
          style: TextStyle(color: primaryColor),
        ),
        trailing: Icon(Icons.calendar_today, color: primaryColor),
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
    );
  }

  // Método para construir el botón de registro
  Widget _buildRegisterButton(Color primaryColor) {
    return isLoading
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : SizedBox(
            width: double.infinity,
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
                if (_formKey.currentState!.validate() &&
                    fechaNacimiento != null) {
                  registrar();
                } else if (fechaNacimiento == null) {
                  setState(() {
                    errorMsg = 'Por favor, seleccione su fecha de nacimiento.';
                  });
                }
              },
              child: const Text(
                'Registrarse',
                style: TextStyle(fontSize: 18),
              ),
            ),
          );
  }
}
