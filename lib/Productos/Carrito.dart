import 'package:flutter/material.dart';
import 'package:paws_and_tails/dtos/producto_dto.dart';

class CartPage extends StatelessWidget {
  final Map<ProductDto, int> cart;

  const CartPage({Key? key, required this.cart}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double subtotal = 0;
    cart.forEach((product, quantity) {
      subtotal += product.precio * quantity;
    });
    double iva = subtotal * 0.15;
    double total = subtotal + iva;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de compras'),
      ),
      body: cart.isEmpty
          ? const Center(child: Text('El carrito está vacío'))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    children: cart.entries.map((entry) {
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
                        trailing: Text(
                          'Subtotal: \$${(product.precio * quantity).toStringAsFixed(2)}',
                        ),
                        isThreeLine: true,
                      );
                    }).toList(),
                  ),
                ),
                const Divider(),
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
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('¡Gracias por tu compra!'),
                                content: const Text(
                                    'El pago se ha realizado con éxito.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
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
