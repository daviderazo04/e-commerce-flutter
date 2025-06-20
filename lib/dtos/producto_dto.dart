class ProductDto {
  final int id;
  final String categoria;
  final String nombre;
  final String descripcion;
  final double precio;
  final int stock;
  final String proveedor;
  final List<String> imagenes;

  ProductDto({
    required this.id,
    required this.categoria,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.stock,
    required this.proveedor,
    required this.imagenes,
  });

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    return ProductDto(
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
