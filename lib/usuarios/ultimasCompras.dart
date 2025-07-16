import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
    final Color primaryColor = Colors.blue.shade700;

    return Scaffold(
      backgroundColor: Colors.grey.shade900, // Fondo oscuro
      appBar: AppBar(
        backgroundColor: primaryColor, // Color de tema
        elevation: 0,
        title: const Text(
          'Últimas compras',
          style: TextStyle(color: Colors.white), // Texto blanco
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchCompras(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: primaryColor));
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No hay compras registradas.',
                    style: TextStyle(color: Colors.white70)));
          }
          final compras = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: compras.length,
            itemBuilder: (context, index) {
              final compra = compras[index];
              return Card(
                color: Colors.grey.shade800, // Color de tarjeta más claro
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Factura #${compra["ID_FACTURA"]}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  primaryColor, // Resalta el número de factura
                            ),
                          ),
                          Text(
                            '\$${compra["FAC_TOTAL"].toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Total en blanco
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fecha: ${compra["FAC_FECHAHORA"]}',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.white70),
                      ),
                      Text(
                        'Método de pago: ${compra["FAC_METODO_PAGO"]}',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.white70),
                      ),
                      Text(
                        'Estado: ${compra["FAC_ESTADO"]}',
                        style: TextStyle(
                          fontSize: 14,
                          color: compra["FAC_ESTADO"] == 'Completada'
                              ? Colors.greenAccent
                              : Colors.orangeAccent, // Colores para el estado
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Icon(Icons.receipt_long,
                            color: primaryColor, size: 30),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
