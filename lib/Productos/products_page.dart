import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paws_and_tails/Productos/ProductDetailPage.dart';

class Product {
  final int id;
  final String categoria;
  final String nombre;
  final String descripcion;
  final double precio;
  final int stock;
  final String proveedor;
  final List<String> imagenes;

  Product({
    required this.id,
    required this.categoria,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.stock,
    required this.proveedor,
    required this.imagenes,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['idProducto'],
      categoria: json['prodCategoria'],
      nombre: json['prodNombre'],
      descripcion: json['prodDescripcion'],
      precio: (json['prodPrecio'] as num).toDouble(),
      stock: json['prodStock'],
      proveedor: json['prodProveedor'],
      imagenes: List<String>.from(json['prodImg']),
    );
  }
}

class ProductsPage extends StatefulWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<Product> allProducts = [];
  List<Product> filteredProducts = [];
  List<String> categories = [];
  String searchQuery = '';
  String selectedCategory = 'Todas';
  double minPrice = 0;
  double maxPrice = 1000;
  RangeValues selectedPriceRange = const RangeValues(0, 1000);
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final response = await http.get(
        Uri.parse('http://backendpawstails.runasp.net/api/gestion/productos'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      allProducts = data.map((json) => Product.fromJson(json)).toList();

      // Obtener categorías únicas
      final uniqueCategories =
          allProducts.map((p) => p.categoria).toSet().toList();
      categories = ['Todas', ...uniqueCategories];

      // Obtener precios min y max
      if (allProducts.isNotEmpty) {
        minPrice =
            allProducts.map((p) => p.precio).reduce((a, b) => a < b ? a : b);
        maxPrice =
            allProducts.map((p) => p.precio).reduce((a, b) => a > b ? a : b);
        selectedPriceRange = RangeValues(minPrice, maxPrice);
      }

      isLoading = false;
      applyFilters();
    } else {
      throw Exception('Error al cargar productos');
    }
  }

  void applyFilters() {
    setState(() {
      filteredProducts = allProducts.where((product) {
        final matchesSearch =
            product.nombre.toLowerCase().contains(searchQuery.toLowerCase());
        final matchesCategory = selectedCategory == 'Todas' ||
            product.categoria == selectedCategory;
        final matchesPrice = product.precio >= selectedPriceRange.start &&
            product.precio <= selectedPriceRange.end;
        return matchesSearch && matchesCategory && matchesPrice;
      }).toList();
    });
  }

  void onSearchChanged(String value) {
    searchQuery = value;
    applyFilters();
  }

  void onCategoryChanged(String? value) {
    if (value != null) {
      selectedCategory = value;
      applyFilters();
    }
  }

  void onPriceRangeChanged(RangeValues values) {
    selectedPriceRange = values;
    applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Buscador
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Buscar producto',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
                // Filtro por categoría
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedCategory,
                    items: categories
                        .map((cat) =>
                            DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: onCategoryChanged,
                    isExpanded: true,
                  ),
                ),
                // Filtro por precio
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const Text('Filtrar por precio'),
                      RangeSlider(
                        values: selectedPriceRange,
                        min: minPrice,
                        max: maxPrice,
                        divisions: 20,
                        labels: RangeLabels(
                          '\$${selectedPriceRange.start.toStringAsFixed(2)}',
                          '\$${selectedPriceRange.end.toStringAsFixed(2)}',
                        ),
                        onChanged: (values) =>
                            setState(() => onPriceRangeChanged(values)),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Lista de productos
                Expanded(
                  child: filteredProducts.isEmpty
                      ? const Center(
                          child: Text('No hay productos que coincidan'))
                      : ListView.builder(
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return Card(
                              margin: const EdgeInsets.all(8),
                              child: ListTile(
                                leading: product.imagenes.isNotEmpty
                                    ? Image.network(product.imagenes[0],
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover)
                                    : const Icon(Icons.pets),
                                title: Text(product.nombre),
                                subtitle: Text(
                                    '${product.descripcion}\n\$${product.precio.toStringAsFixed(2)}'),
                                isThreeLine: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailPage(
                                        product: product,
                                        onAddToCart: () {},
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
