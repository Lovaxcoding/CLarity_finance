import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/core/supabase_client.dart';

class IncomeEntryPage extends StatefulWidget {
  const IncomeEntryPage({super.key});

  @override
  State<IncomeEntryPage> createState() => _IncomeEntryPageState();
}

class _IncomeEntryPageState extends State<IncomeEntryPage> {
  // Clé pour valider le formulaire
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour les champs de texte
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Variable d'état pour le bouton
  bool _isLoading = false;

  // Liste des sources de revenu (simplifiée)
  String? _selectedSource;
  final List<String> _incomeSources = [
    'Salaire',
    'Investissement',
    'Cadeau',
    'Vente',
    'Autre',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- 2. Fonction d'Insertion Supabase ---
  Future<void> _addIncome() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final double amount = double.parse(
        _amountController.text.replaceAll(',', '.'),
      );
      final String source = _selectedSource ?? 'Autre';
      final String description = _descriptionController.text.trim();
      final User? user = supabase.auth.currentUser;

      if (user == null) {
        throw const FormatException("Utilisateur non authentifié.");
      }

      final incomeData = {
        'user_id': user.id,
        'amount': amount,
        'source': source,
        'description': description,
        // 'created_at' est géré par défaut dans Supabase
      };

      await supabase.from('incomes').insert(incomeData);

      // Succès ! Afficher un message et réinitialiser
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Revenu ajouté avec succès !')),
        );
        _amountController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedSource = null;
        });
      }
    } on FormatException catch (e) {
      _showErrorSnackBar('Erreur de format: ${e.message}');
    } on PostgrestException catch (e) {
      _showErrorSnackBar('Erreur BDD: ${e.message}');
    } catch (e) {
      _showErrorSnackBar('Erreur inattendue: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // --- 3. Construction de l'Interface Utilisateur (UI) ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter un Revenu"),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- Champ Montant (Clavier numérique) ---
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Montant du revenu (\$)',
                  prefixIcon: Icon(
                    Icons.attach_money_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // --- Sélection de la Source (Dropdown) ---
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Source de l\'argent',
                  prefixIcon: const Icon(Icons.category_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                value: _selectedSource,
                hint: const Text('Choisir la source (Salaire, Vente, etc.)'),
                items: _incomeSources.map((String source) {
                  return DropdownMenuItem<String>(
                    value: source,
                    child: Text(source),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSource = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner la source';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // --- Champ Description ---
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (facultatif)',
                  alignLabelWithHint: true,
                  hintText: 'Ex: Salaire de novembre',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60, left: 0),
                    child: Icon(Icons.notes_rounded),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // --- Bouton d'Ajout ---
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _addIncome,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.add_task_rounded),
                label: Text(
                  _isLoading ? 'Enregistrement...' : 'Enregistrer le Revenu',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
