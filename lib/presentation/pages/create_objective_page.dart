// lib/pages/create_objective_page.dart

import 'dart:io'; // Pour le type File
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart'; // NOUVEL IMPORT
import 'package:myapp/services/supabase_service.dart'; // REMPLACER PAR VOTRE VRAI CHEMIN

// Le service simulé est remplacé par l'import du service réel.
// class SupabaseService { ... } EST SUPPRIMÉ ICI

class CreateObjectivePage extends StatefulWidget {
  const CreateObjectivePage({super.key});

  @override
  State<CreateObjectivePage> createState() => _CreateObjectivePageState();
}

class _CreateObjectivePageState extends State<CreateObjectivePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: "Voyage en Asie");
  final _amountController = TextEditingController(text: "5000000");
  DateTime? _selectedTargetDate;
  File? _selectedImage; // NOUVEAU: Fichier image sélectionné
  bool _isLoading = false;
  double? _suggestedMonthlySaving;

  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _picker = ImagePicker(); // Outil de sélection d'image

  @override
  void initState() {
    super.initState();
    _fetchSavingsSuggestion();
  }

  // ... (Fonctions _fetchSavingsSuggestion et _selectDate inchangées)

  Future<void> _fetchSavingsSuggestion() async {
    try {
      final suggestion = await _supabaseService
          .calculateMonthlySavingsCapacity();
      setState(() {
        _suggestedMonthlySaving = suggestion;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Erreur de suggestion : $e");
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedTargetDate) {
      setState(() {
        _selectedTargetDate = picked;
      });
    }
  }

  // NOUVEAU : Fonction de sélection d'image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // MISE À JOUR : Appel à createObjective avec imageFile
  Future<void> _saveObjective() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _supabaseService.createObjective(
          title: _titleController.text.trim(),
          targetAmount: double.parse(
            _amountController.text.replaceAll(',', '.'),
          ),
          targetDate: _selectedTargetDate,
          imageFile: _selectedImage, // <-- L'IMAGE EST PASSÉE ICI !
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Objectif créé avec succès !')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Échec de la création : ${e.toString()}')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Créer un Nouvel Objectif'),
        centerTitle: true,
        titleTextStyle: theme.textTheme.bodyLarge!.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onBackground,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- 1. Icône/Couverture de l'Objectif (MISE À JOUR) ---
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primary.withOpacity(
                        0.1,
                      ),
                      // Affiche l'image sélectionnée ou l'icône par défaut
                      child: _selectedImage != null
                          ? ClipOval(
                              child: Image.file(
                                _selectedImage!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.beach_access,
                              size: 40,
                              color: Colors.orange,
                            ),
                    ),
                    TextButton(
                      onPressed:
                          _pickImage, // <-- Appel à la fonction de sélection
                      child: Text(
                        _selectedImage == null
                            ? 'Choisir une icône'
                            : 'Changer l\'icône',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ... (Reste des champs de formulaire inchangé)
              Text('Nom de l\'Objectif', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Ex: Achat Maison, Études, Vacances...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom pour l\'objectif';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Text(
                'Montant Total Visé (Ar)',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Ex: 5 000 000',
                  suffixText: 'Ar',
                ),
                validator: (value) {
                  if (value == null ||
                      double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Veuillez entrer un montant valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // --- 4. Suggestion d'Épargne de l'IA (le coach !) ---
              if (_suggestedMonthlySaving != null) _buildAISuggestion(theme),
              const SizedBox(height: 20),

              // --- 5. Date Limite (Optionnelle) ---
              Text(
                'Date Limite (Optionnelle)',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    hintText: 'Sélectionner une date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedTargetDate == null
                        ? 'Pas de date limite'
                        : '${_selectedTargetDate!.day.toString().padLeft(2, '0')}/${_selectedTargetDate!.month.toString().padLeft(2, '0')}/${_selectedTargetDate!.year}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // --- Bouton Enregistrer ---
              ElevatedButton(
                onPressed: _isLoading ? null : _saveObjective,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Enregistrer l\'Objectif',
                        style: theme.textTheme.titleMedium!.copyWith(
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 10),

              // Bouton Annuler (texte)
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  'Annuler',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ... (Méthode _buildAISuggestion inchangée)
  Widget _buildAISuggestion(ThemeData theme) {
    if (_suggestedMonthlySaving == null || _suggestedMonthlySaving! <= 0) {
      return const SizedBox.shrink();
    }

    // Calcul du nombre de mois requis
    final targetAmount = double.tryParse(
      _amountController.text.replaceAll(',', '.'),
    );
    final monthsNeeded = targetAmount != null && targetAmount > 0
        ? (targetAmount / _suggestedMonthlySaving!).ceil()
        : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Coach IA',
                style: theme.textTheme.titleMedium!.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: 'Selon votre historique, vous pourriez épargner ',
              children: [
                TextSpan(
                  text: '${_suggestedMonthlySaving!.toStringAsFixed(0)} Ar',
                  style: theme.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' par mois. \n'),
                if (monthsNeeded > 0)
                  TextSpan(
                    text:
                        'Objectif de ${_amountController.text} Ar atteint en ',
                    children: [
                      TextSpan(
                        text: '$monthsNeeded mois',
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
              ],
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
