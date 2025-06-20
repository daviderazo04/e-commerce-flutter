import 'package:flutter/material.dart';

class UltimasComprasPage extends StatelessWidget {
  const UltimasComprasPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Aquí deberías hacer el fetch a tu API de compras y mostrar la lista
    // Puedes usar FutureBuilder y http.get para traer los datos reales
    return Scaffold(
      appBar: AppBar(title: const Text('Últimas compras')),
      body: const Center(
        child: Text('Aquí se mostrarán las últimas compras del usuario.'),
      ),
    );
  }
}
