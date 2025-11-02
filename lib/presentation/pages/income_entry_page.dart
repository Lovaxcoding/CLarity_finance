import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/core/supabase_client.dart';

class IncomeEntryPage extends StatefulWidget {
  const IncomeEntryPage({super.key});

  @override
  State<IncomeEntryPage> createState() => _IncomeEntryPageState();
}

class _IncomeEntryPageState extends State<IncomeEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  // ✅ CORRECTION : Variable pour suivre si le formulaire a été soumis au moins une fois
  bool _isFormSubmitted = false;
  String? _selectedSource;

  final Map<String, IconData> _incomeSourceMap = {
    'Salaire': Icons.work_outline_rounded,
    'Investissement': Icons.trending_up_rounded,
    'Cadeau': Icons.card_giftcard_rounded,
    'Vente': Icons.shopping_bag_outlined,
    'Autre': Icons.more_horiz_rounded,
  };

  late final List<String> _incomeSources = _incomeSourceMap.keys.toList();
  static const String _unusualSource = 'Autre';

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Fonction pour afficher l'alerte pour la source 'Autre'
  Future<void> _showSourceWarning(String source) async {
    if (source == _unusualSource) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue),
                SizedBox(width: 10),
                Text('Saisie Manuelle Recommandée'),
              ],
            ),
            content: const Text(
              'L\'utilisation de la source "Autre" rendra l\'analyse plus difficile. Veuillez ajouter une description claire !',
              style: TextStyle(fontSize: 16),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Compris'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _addIncome() async {
    // 1. Marquer le formulaire comme soumis pour afficher les erreurs
    if (!_isFormSubmitted) {
      setState(() {
        _isFormSubmitted = true;
      });
    }

    // Vérifier la validation du formulaire Flutter, y compris la validation manuelle
    if (!_formKey.currentState!.validate() || _selectedSource == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final double amount = double.parse(
        _amountController.text.replaceAll(',', '.'),
      );
      final String source = _selectedSource!; // Non-null car vérifié
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
          // Réinitialiser l'état de soumission
          _isFormSubmitted = false;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Ajouter un Revenu"),
        titleTextStyle: theme.textTheme.headlineSmall!.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
      ),
      backgroundColor: theme.colorScheme.background,

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 100.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- 1 & 2 : Montant ---
              Text(
                'Montant du revenu',
                style: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Center(
                child: IntrinsicWidth(
                  child: TextFormField(
                    controller: _amountController,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: theme.colorScheme.error),
                      ),
                      prefixText: 'MGA  ',
                      prefixStyle: theme.textTheme.displaySmall!.copyWith(
                        color: theme.colorScheme.primary.withOpacity(0.7),
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
                ),
              ),

              const SizedBox(height: 40),

              // --- 3. Sélection de la Source (Chips/Boutons Visuels) ---
              Text('Source de l\'argent', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),

              Column(
                children: _incomeSources.map((source) {
                  final isSelected = _selectedSource == source;

                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 10.0,
                    ), // Espace vertical entre les boutons
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSource = source;
                        });
                        _showSourceWarning(source);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 15,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withOpacity(
                                  0.15,
                                ) // Couleur de fond léger si sélectionné
                              : theme.colorScheme.surfaceVariant.withOpacity(
                                  0.3,
                                ), // Couleur de fond par défaut
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? theme
                                      .colorScheme
                                      .primary // Bordure primaire si sélectionné
                                : theme.colorScheme.outline.withOpacity(
                                    0.5,
                                  ), // Bordure légère par défaut
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Icône
                            Icon(
                              _incomeSourceMap[source],
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                              size: 28,
                            ),
                            const SizedBox(width: 15),
                            // Texte
                            Text(
                              source,
                              style: theme.textTheme.titleMedium!.copyWith(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              // --- Validation Manuelle (Correction appliquée ici) ---
              if (_selectedSource == null && _isFormSubmitted)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Veuillez sélectionner la source',
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 30),

              // --- 4. Champ Description ---
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
              const SizedBox(height: 20),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      // --- Bouton d'Action Fixe en Bas ---
      bottomNavigationBar: Padding(
        padding: MediaQuery.of(
          context,
        ).viewInsets.copyWith(left: 20, right: 20, bottom: 20),
        child: ElevatedButton.icon(
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
      ),
    );
  }
}
