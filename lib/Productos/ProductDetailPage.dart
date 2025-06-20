import 'package:flutter/material.dart';
import 'package:paws_and_tails/dtos/producto_dto.dart';

class ProductDetailPage extends StatefulWidget {
  final ProductDto product;
  final Function(int) onAddToCart;

  const ProductDetailPage({
    Key? key,
    required this.product,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int cantidad = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      appBar: AppBar(
        title: Text(product.nombre),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.imagenes.isNotEmpty)
              SizedBox(
                height: 250,
                width: double.infinity,
                child: PageView(
                  children: product.imagenes
                      .map((img) => Image.network(
                            img,
                            fit: BoxFit.cover,
                          ))
                      .toList(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nombre,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.descripcion,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Categoría: ${product.categoria}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Proveedor: ${product.proveedor}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stock: ${product.stock}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '\$${product.precio.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  const SizedBox(height: 24),
                  // Selector de cantidad
                  Row(
                    children: [
                      const Text('Cantidad:'),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: cantidad > 1
                            ? () => setState(() => cantidad--)
                            : null,
                      ),
                      Text('$cantidad'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: cantidad < product.stock
                            ? () => setState(() => cantidad++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onAddToCart(cantidad);
                        Navigator.pop(context, true);
                      },
                      child: const Text('Añadir al carrito'),
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
