import 'package:flutter/material.dart';

class FilterPage extends StatelessWidget {
  const FilterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtres et Rapports 🔍'),
        backgroundColor: Colors.orange,
      ),
      body: const Center(
        child: Text(
          'Ceci est la page de Filtrage. Options pour rechercher et exporter les dépenses ici.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}