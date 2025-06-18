import 'package:flutter/material.dart';
import 'products_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final VoidCallback onAddToCart;

  const ProductDetailPage({
    Key? key,
    required this.product,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      appBar: AppBar(title: Text(product.nombre)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 450,
              child: PageView(
                children: product.imagenes
                    .map((img) => Image.network(img, fit: BoxFit.cover))
                    .toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.nombre,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Categoría: ${product.categoria}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(product.descripcion,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Stock: ${product.stock}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Precio: \$${product.precio.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20, color: Colors.teal)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Cantidad:', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: quantity > 1
                            ? () => setState(() => quantity--)
                            : null,
                      ),
                      Text('$quantity', style: const TextStyle(fontSize: 18)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: quantity < product.stock
                            ? () => setState(() => quantity++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Agregar al carrito'),
                      onPressed: product.stock > 0
                          ? () {
                              // Aquí puedes pasar la cantidad seleccionada
                              widget.onAddToCart();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Agregado $quantity al carrito')),
                              );
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
