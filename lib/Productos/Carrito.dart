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
  // Usar el contexto que nos dio showDialog
  Navigator.of(context, rootNavigator: true).pop();

  if (response.statusCode == 200) {
    final result = response.body.trim().toLowerCase();
    if (result == 'true') {
      onCompraExitosa();
      // ¡IMPORTANTE! Se movió la lógica del AlertDialog a la función de callback.
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Algo falló al realizar la compra.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  } else {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text('No se pudo realizar la compra: ${response.body}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
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
      appBar: AppBar(
        title: const Text('Carrito de compras'),
      ),
      body: widget.cart.isEmpty
          ? const Center(child: Text('El carrito está vacío'))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    children: widget.cart.entries.map((entry) {
                      final product = entry.key;
                      final quantity = entry.value;
                      return ListTile(
                        leading: product.imagenes.isNotEmpty
                            ? Image.network(product.imagenes[0],
                                width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.pets),
                        title: Text(product.nombre),
                        subtitle: Text(
                          'Cantidad: $quantity\nPrecio: \$${product.precio.toStringAsFixed(2)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Subtotal: \$${(product.precio * quantity).toStringAsFixed(2)}',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
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
                        isThreeLine: true,
                      );
                    }).toList(),
                  ),
                ),
                const Divider(),
                // ComboBox de cuentas
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchCuentasUsuario(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child:
                            Text('Error al cargar cuentas: ${snapshot.error}'),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No tienes cuentas registradas.'),
                      );
                    }
                    final cuentas = snapshot.data!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Selecciona una cuenta para pagar',
                          border: OutlineInputBorder(),
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
                      ),
                    );
                  },
                ),
                // Campo para dirección de envío
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: direccionController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección de envío',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:'),
                          Text('\$${subtotal.toStringAsFixed(2)}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('IVA (15%):'),
                          Text('\$${iva.toStringAsFixed(2)}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: cuentaSeleccionada == null ||
                                  direccionController.text.trim().isEmpty
                              ? null
                              : () async {
                                  await realizarCompra(
                                    cart: widget.cart,
                                    cuentaId: cuentaSeleccionada!,
                                    context: context,
                                    direccion: direccionController.text.trim(),
                                    onCompraExitosa: () async {
                                      setState(() {
                                        widget.cart.clear();
                                        direccionController.clear();
                                      });
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.remove('cart');
                                      // Después de esto, se muestra el dialogo y luego se navega
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                              '¡Gracias por tu compra!'),
                                          content: const Text(
                                              'El pago se ha realizado con éxito.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(); // Cierra el AlertDialog
                                                Navigator.of(context).pop(
                                                    'compra_exitosa'); // Cierra la pantalla del carrito
                                              },
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                          child: const Text('Pagar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
