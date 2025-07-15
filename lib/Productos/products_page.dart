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

      final uniqueCategories =
          allProducts.map((p) => p.categoria).toSet().toList();
      categories = ['Todas', ...uniqueCategories];

      if (allProducts.isNotEmpty) {
        minPrice =
            allProducts.map((p) => p.precio).reduce((a, b) => a < b ? a : b);
        maxPrice =
            allProducts.map((p) => p.precio).reduce((a, b) => a > b ? a : b);
        selectedPriceRange = RangeValues(minPrice, maxPrice);
      }

      setState(() {
        isLoading = false;
      });
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
    setState(() {
      selectedPriceRange = values;
    });
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
    final Color primaryColor = Colors.blue.shade700;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Image.asset(
            'assets/images/logoPataBlanco.png',
            height: 30,
          ),
        ),
        title: const Text(
          'Productos',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartPage(cart: cart),
                    ),
                  );
                  if (result == 'compra_exitosa') {
                    await loadCart();
                  } else {
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
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(
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
            icon: const Icon(Icons.account_circle, color: Colors.white),
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Buscar producto',
                      labelStyle: TextStyle(color: primaryColor),
                      prefixIcon: Icon(Icons.search, color: primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide:
                            BorderSide(color: primaryColor.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: primaryColor, width: 2.0),
                      ),
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _buildFilterChip(
                            label: 'Categoría',
                            onTap: () =>
                                _showCategoryFilter(context, primaryColor),
                            icon: Icons.category,
                            primaryColor: primaryColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: _buildFilterChip(
                            label: 'Precio',
                            onTap: () =>
                                _showPriceFilter(context, primaryColor),
                            icon: Icons.attach_money,
                            primaryColor: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, indent: 16, endIndent: 16),
                const SizedBox(height: 8),
                Expanded(
                  child: filteredProducts.isEmpty
                      ? const Center(
                          child: Text('No hay productos que coincidan',
                              style: TextStyle(fontSize: 16)))
                      : ListView.builder(
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return _buildProductCard(product, primaryColor);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onTap,
    required IconData icon,
    required Color primaryColor,
  }) {
    return ActionChip(
      avatar: Icon(icon, color: primaryColor),
      label: Text(
        label,
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: onTap,
      backgroundColor: primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: primaryColor.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  void _showCategoryFilter(BuildContext context, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecciona una categoría',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return RadioListTile<String>(
                      title: Text(cat),
                      value: cat,
                      groupValue: selectedCategory,
                      onChanged: (value) {
                        onCategoryChanged(value);
                        Navigator.pop(context);
                      },
                      activeColor: primaryColor,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPriceFilter(BuildContext context, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Filtrar por precio',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '\$${selectedPriceRange.start.toStringAsFixed(0)} - \$${selectedPriceRange.end.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  RangeSlider(
                    values: selectedPriceRange,
                    min: minPrice,
                    max: maxPrice,
                    divisions: (maxPrice - minPrice).round(),
                    activeColor: primaryColor,
                    inactiveColor: primaryColor.withOpacity(0.3),
                    onChanged: (values) {
                      modalSetState(() {
                        selectedPriceRange = values;
                      });
                      onPriceRangeChanged(values);
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Aplicar',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductCard(ProductDto product, Color primaryColor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          final dynamic cantidadSeleccionada = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(
                product: product,
              ),
            ),
          );
          if (cantidadSeleccionada != null && cantidadSeleccionada > 0) {
            _incrementCart(product, cantidadSeleccionada as int);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: product.imagenes.isNotEmpty
                    ? Image.network(
                        product.imagenes[0],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: Icon(Icons.pets,
                            color: primaryColor.withOpacity(0.7)),
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
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${product.precio.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
