import 'package:flutter/material.dart';
import 'package:paws_and_tails/dtos/producto_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Helper para obtener la cédula del usuario loggeado
Future<String> obtenerCedulaUsuario() async {
  final prefs = await SharedPreferences.getInstance();
  final userData = prefs.getString('userData');
  if (userData != null) {
    final userMap = json.decode(userData);
    return userMap['Cedula'] ?? '';
  }
  throw Exception('No hay usuario loggeado');
}

// Obtener cuentas del usuario
Future<List<Map<String, dynamic>>> fetchCuentasUsuario() async {
  final cedula = await obtenerCedulaUsuario();
  final url =
      'http://backendpawstails.runasp.net/api/gestion/usuario/cuentas-cliente/$cedula';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final cuentas = json.decode(response.body) as List;
    return cuentas.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Error al cargar cuentas');
  }
}

Future<int> obtenerIdUsuario() async {
  final prefs = await SharedPreferences.getInstance();
  final userData = prefs.getString('userData');
  if (userData != null) {
    final userMap = json.decode(userData);
    return userMap['IdUsuario'] ?? 0;
  }
  throw Exception('No hay usuario loggeado');
}

Future<void> realizarCompra({
  required Map<ProductDto, int> cart,
  required int cuentaId,
  required BuildContext context,
  required String direccion,
  required VoidCallback onCompraExitosa,
}) async {
  final idUsuario = await obtenerIdUsuario();

  final productos = cart.entries.map((entry) {
    return {
      "<idProducto>k__BackingField": entry.key.id,
      "<cantidad>k__BackingField": entry.value,
    };
  }).toList();

  final body = {
    "Carrito": {
      "<productos>k__BackingField": productos,
    },
    "Direccion": direccion,
    "MetodoPago": "Transferencia",
    "IdUsuario": idUsuario,
    "cuenta": cuentaId,
  };

  // Mostrar dialogo de cargando
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  final response = await http.post(
    Uri.parse('https://backendpawstails.runasp.net/api/gestion/compra'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );

  // Cerrar el dialogo de cargando
  Navigator.of(context, rootNavigator: true).pop();

  if (response.statusCode == 200) {
    final result = response.body.trim().toLowerCase();
    if (result == 'true') {
      onCompraExitosa();
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey.shade800,
          title: const Text('Error', style: TextStyle(color: Colors.white)),
          content: const Text('Algo falló al realizar la compra.',
              style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      );
    }
  } else {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade800,
        title: const Text('Error', style: TextStyle(color: Colors.white)),
        content: Text('No se pudo realizar la compra: ${response.body}',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}

class CartPage extends StatefulWidget {
  final Map<ProductDto, int> cart;

  const CartPage({Key? key, required this.cart}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  int? cuentaSeleccionada;
  double? saldoSeleccionado;
  final TextEditingController direccionController = TextEditingController();
  final Color primaryColor = Colors.blue.shade700;

  @override
  void dispose() {
    direccionController.dispose();
    super.dispose();
  }

  Future<void> saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartList = widget.cart.entries
        .map((e) => {
              'product': e.key.toJson(),
              'quantity': e.value,
            })
        .toList();
    await prefs.setString('cart', jsonEncode(cartList));
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = 0;
    widget.cart.forEach((product, quantity) {
      subtotal += product.precio * quantity;
    });
    double iva = subtotal * 0.15;
    double total = subtotal + iva;

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Carrito de compras',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: widget.cart.isEmpty
          ? const Center(
              child: Text(
                'El carrito está vacío',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: widget.cart.entries.map((entry) {
                      final product = entry.key;
                      final quantity = entry.value;
                      return Card(
                        color: Colors.grey.shade800,
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: product.imagenes.isNotEmpty
                                    ? Image.network(
                                        product.imagenes[0],
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.grey.shade700,
                                          child: Icon(Icons.pets,
                                              color: Colors.white
                                                  .withOpacity(0.7)),
                                        ),
                                      )
                                    : Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.grey.shade700,
                                        child: Icon(Icons.pets,
                                            color:
                                                Colors.white.withOpacity(0.7)),
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.nombre,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Cantidad: $quantity',
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.white70),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Precio: \$${(product.precio * quantity).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                tooltip: 'Quitar del carrito',
                                onPressed: () {
                                  setState(() {
                                    widget.cart.remove(product);
                                  });
                                  saveCart();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Contenedor principal de los elementos de pago y total
                Container(
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Dropdown de cuentas
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: fetchCuentasUsuario(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              child: Text(
                                  'Error al cargar cuentas: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.red)),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Text('No tienes cuentas registradas.',
                                  style: TextStyle(color: Colors.white70)),
                            );
                          }
                          final cuentas = snapshot.data!;
                          return DropdownButtonFormField<int>(
                            style: const TextStyle(color: Colors.white),
                            dropdownColor: Colors.grey.shade800,
                            decoration: InputDecoration(
                              labelText: 'Selecciona una cuenta',
                              labelStyle: TextStyle(color: primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide(
                                    color: primaryColor.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide:
                                    BorderSide(color: primaryColor, width: 2.0),
                              ),
                            ),
                            value: cuentaSeleccionada,
                            items: cuentas.map((cuenta) {
                              return DropdownMenuItem<int>(
                                value: cuenta['cuenta_id'],
                                child: Text(
                                  'Cuenta #${cuenta['cuenta_id']} - Saldo: \$${cuenta['saldo'].toStringAsFixed(2)}',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              final cuenta = cuentas
                                  .firstWhere((c) => c['cuenta_id'] == value);
                              setState(() {
                                cuentaSeleccionada = value;
                                saldoSeleccionado = cuenta['saldo']?.toDouble();
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Campo de dirección
                      TextField(
                        controller: direccionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Dirección de envío',
                          labelStyle: TextStyle(color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                                color: primaryColor.withOpacity(0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide:
                                BorderSide(color: primaryColor, width: 2.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Resumen de la compra
                      _buildSummaryRow(
                          'Subtotal:', '\$${subtotal.toStringAsFixed(2)}'),
                      _buildSummaryRow(
                          'IVA (15%):', '\$${iva.toStringAsFixed(2)}'),
                      const Divider(color: Colors.white12, height: 16),
                      _buildSummaryRow(
                        'Total:',
                        '\$${total.toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                      const SizedBox(height: 24),
                      // Botón de pagar
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: widget.cart.isEmpty ||
                                  cuentaSeleccionada == null ||
                                  direccionController.text.trim().isEmpty
                              ? null
                              : () async {
                                  await realizarCompra(
                                    cart: widget.cart,
                                    cuentaId: cuentaSeleccionada!,
                                    context: context,
                                    direccion: direccionController.text.trim(),
                                    onCompraExitosa: () async {
                                      // Vacia el carrito localmente y en el almacenamiento
                                      setState(() {
                                        widget.cart.clear();
                                        direccionController.clear();
                                        cuentaSeleccionada = null;
                                      });
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.remove('cart');
                                      // Muestra el dialogo de éxito
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: Colors.grey.shade800,
                                          title: const Text(
                                              '¡Gracias por tu compra!',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          content: const Text(
                                              'El pago se ha realizado con éxito.',
                                              style: TextStyle(
                                                  color: Colors.white70)),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(); // Cierra el AlertDialog
                                                Navigator.of(context).pop(
                                                    'compra_exitosa'); // Cierra la pantalla del carrito
                                              },
                                              child: const Text('OK',
                                                  style: TextStyle(
                                                      color: Colors.blue)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (widget.cart.isEmpty ||
                                    cuentaSeleccionada == null ||
                                    direccionController.text.trim().isEmpty)
                                ? Colors.grey.withOpacity(0.5)
                                : primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            widget.cart.isEmpty
                                ? 'Carrito vacío'
                                : (cuentaSeleccionada == null ||
                                        direccionController.text.trim().isEmpty)
                                    ? 'Completa los campos'
                                    : 'Pagar',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? primaryColor : Colors.white70,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? primaryColor : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
