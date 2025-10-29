import 'package:flutter/material.dart';

class ExpenseEntryPage extends StatelessWidget {
  const ExpenseEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Dépense ➕'),
        backgroundColor: Colors.indigo,
      ),
      body: const Center(
        child: Text(
          'Ceci est la page de Saisie de Dépenses. Le formulaire d\'entrée rapide sera ici.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}