import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UsuarioSesion {
  final int idUsuario;
  final String usuarioNombre;
  final String usuarioCorreo;
  final String cedula;
  final String rol;

  UsuarioSesion({
    required this.idUsuario,
    required this.usuarioNombre,
    required this.usuarioCorreo,
    required this.cedula,
    required this.rol,
  });

  factory UsuarioSesion.fromJson(Map<String, dynamic> json) {
    return UsuarioSesion(
      idUsuario: json['IdUsuario'],
      usuarioNombre: json['UsuarioNombre'],
      usuarioCorreo: json['UsuarioCorreo'],
      cedula: json['Cedula'],
      rol: json['Rol'],
    );
  }

  static Future<UsuarioSesion?> cargarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('userData');
    if (userData == null) return null;
    return UsuarioSesion.fromJson(jsonDecode(userData));
  }
}
