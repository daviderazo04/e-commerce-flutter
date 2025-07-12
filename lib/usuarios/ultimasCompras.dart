import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> obtenerCedulaUsuario() async {
  final prefs = await SharedPreferences.getInstance();
  final userData = prefs.getString('userData');
  if (userData != null) {
    final userMap = json.decode(userData);
    return userMap['Cedula'] ?? '';
  }
  throw Exception('No hay usuario loggeado');
}

Future<List<dynamic>> fetchCompras() async {
  final cedula = await obtenerCedulaUsuario();
  final url =
      'http://backendpawstails.runasp.net/api/gestion/factura/cedula/$cedula';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Error al cargar compras');
  }
}

class UltimasComprasPage extends StatelessWidget {
  const UltimasComprasPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Últimas compras')),
      body: FutureBuilder<List<dynamic>>(
        future: fetchCompras(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay compras registradas.'));
          }
          final compras = snapshot.data!;
          return ListView.builder(
            itemCount: compras.length,
            itemBuilder: (context, index) {
              final compra = compras[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(
                      'Factura #${compra["ID_FACTURA"]} - \$${compra["FAC_TOTAL"]}'),
                  subtitle: Text(
                    'Fecha: ${compra["FAC_FECHAHORA"]}\n'
                    'Método de pago: ${compra["FAC_METODO_PAGO"]}\n'
                    'Estado: ${compra["FAC_ESTADO"]}',
                  ),
                  isThreeLine: true,
                  trailing: Icon(Icons.receipt_long),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
