import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord 📊'),
        backgroundColor: Colors.blueGrey,
      ),
      body: const Center(
        child: Text(
          'Ceci est la page Tableau de bord. Graphiques et résumés iront ici.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}