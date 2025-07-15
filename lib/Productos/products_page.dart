import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paws_and_tails/Productos/Carrito.dart';
import 'package:paws_and_tails/Productos/ProductDetailPage.dart';
import 'package:paws_and_tails/dtos/producto_dto.dart';
import 'package:paws_and_tails/usuarios/perfil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  int cartCount = 0;
  List<ProductDto> allProducts = [];
  List<ProductDto> filteredProducts = [];
  List<String> categories = [];
  String searchQuery = '';
  String selectedCategory = 'Todas';
  double minPrice = 0;
  double maxPrice = 1000;
  RangeValues selectedPriceRange = const RangeValues(0, 1000);
  bool isLoading = true;

  // Aquí defines el carrito:
  final Map<ProductDto, int> cart = {};

  @override
  void initState() {
    super.initState();
    fetchProducts();
    loadCart();
  }

  Future<void> fetchProducts() async {
    final response = await http.get(
        Uri.parse('http://backendpawstails.runasp.net/api/gestion/productos'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      allProducts = data.map((json) => ProductDto.fromJson(json)).toList();

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

  void _incrementCart(ProductDto product, int cantidad) {
    setState(() {
      cart[product] = (cart[product] ?? 0) + cantidad;
      cartCount = cart.values.fold(0, (a, b) => a + b);
    });
    saveCart();
  }

  Future<void> saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartList = cart.entries
        .map((e) => {
              'product': e.key.toJson(),
              'quantity': e.value,
            })
        .toList();
    await prefs.setString('cart', jsonEncode(cartList));
  }

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString('cart');
    cart.clear();
    if (cartString != null && cartString.isNotEmpty) {
      final List<dynamic> cartList = jsonDecode(cartString);
      for (var item in cartList) {
        final product = ProductDto.fromJson(item['product']);
        final quantity = item['quantity'] as int;
        cart[product] = quantity;
      }
    }
    cartCount = cart.values.fold(0, (a, b) => a + b);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Productos'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartPage(cart: cart),
                    ),
                  );
                  if (result == 'compra_exitosa') {
                    await loadCart();
                    setState(() {});
                    // Se elimina el showDialog de compra exitosa
                  } else {
                    // Solo actualiza el contador si no hubo compra
                    setState(() {
                      cartCount = cart.values.fold(0, (a, b) => a + b);
                    });
                  }
                },
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$cartCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () async {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PerfilPage()),
              );
            },
          ),
        ],
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
                                onTap: () async {
                                  final dynamic cantidadSeleccionada =
                                      await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailPage(
                                        product: product,
                                      ),
                                    ),
                                  );
                                  if (cantidadSeleccionada != null &&
                                      cantidadSeleccionada > 0) {
                                    setState(() {
                                      cart[product] = (cart[product] ?? 0) +
                                          (cantidadSeleccionada as int);
                                      cartCount =
                                          cart.values.fold(0, (a, b) => a + b);
                                    });
                                  }
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
