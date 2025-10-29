import 'package:flutter/material.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets '),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          'Ceci est la page de Budget. Définition et suivi des limites ici.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
