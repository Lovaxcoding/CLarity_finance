import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'package:myapp/core/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Utilisation d'une route temporaire pour simuler la redirection après l'enregistrement
// NOTE: Changez '/home' par la route réelle de votre tableau de bord.
const String _completionRoute = '/';

class ExpenseEntryPage extends StatefulWidget {
  const ExpenseEntryPage({super.key});

  @override
  State<ExpenseEntryPage> createState() => _ExpenseEntryPageState();
}

class _ExpenseEntryPageState extends State<ExpenseEntryPage> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentStep = 0;
  bool _confirmedReview = false; // Remplace _acceptedTerms
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false; //

  // Controllers pour les champs de saisie des dépenses
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  String _selectedCategory = 'Nourriture';
  final List<String> _categories = [
    'Nourriture',
    'Transport',
    'Logement',
    'Divertissement',
    'Autre',
  ];

  final int _totalSteps = 3; // Définition du nombre total d'étapes

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      // Logique pour passer à la page suivante
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
      );
    } else {
      // Étape finale : Enregistrer la dépense et rediriger
      if (!_confirmedReview) {
        _showSnackBar('Veuillez confirmer les détails de la dépense.');
        return;
      }
      _insertExpense();

      // Simuler l'enregistrement (vous ajouterez votre logique de base de données ici)
      if (kDebugMode) {
        print('Enregistrement de la dépense:');
      }
      if (kDebugMode) {
        print('Montant: ${_amountCtrl.text} MGA');
      }
      if (kDebugMode) {
        print('Catégorie: $_selectedCategory');
      }
      if (kDebugMode) {
        print('Notes: ${_notesCtrl.text}');
      }

      // Redirection
      context.go(_completionRoute);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ), // Permet 1 an dans le futur
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF10B981), // Utiliser votre primaryColor
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _insertExpense() async {
    if (supabase.auth.currentUser == null) {
      _showSnackBar(
        'Erreur: Vous devez être connecté pour enregistrer une dépense.',
        isError: true,
      );
      context.go('/auth'); // Rediriger l'utilisateur vers la connexion
      return;
    }

    final amountText = _amountCtrl.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      _showSnackBar(
        'Veuillez entrer un montant valide et positif.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final expenseData = {
        'user_id': supabase.auth.currentUser!.id,
        'amount': amount,
        'description': _notesCtrl.text.trim(),
        'category': _selectedCategory,
        'expense_date': _selectedDate.toIso8601String().substring(
          0,
          10,
        ), // Format YYYY-MM-DD
      };

      await supabase.from('expenses').insert(expenseData);

      _showSnackBar('Dépense de $amountText MGA enregistrée avec succès !');

      // Redirection après succès
      context.go(_completionRoute);
    } on PostgrestException catch (e) {
      _showSnackBar('Erreur de base de données : ${e.message}', isError: true);
      if (kDebugMode) print(e);
    } catch (e) {
      _showSnackBar('Une erreur inattendue est survenue.', isError: true);
      if (kDebugMode) print(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Fonction utilitaire pour les messages
  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Colors.red.shade600
              : const Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Définir la couleur du fond en fonction du mode (clair ou sombre)
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final primaryColor = const Color(
      0xFF10B981,
    ); // Couleur principale verte pour les boutons

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. Barre de navigation et indicateur d'étape ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      onPressed: _previousStep,
                    ),
                  const Spacer(),
                  // Indicateur de progression (points animés)
                  AnimatedProgressDots(
                    currentIndex: _currentStep,
                    count: _totalSteps,
                    primaryColor: primaryColor,
                  ),
                  const Spacer(),
                  // Espace réservé si le bouton retour n'est pas là pour maintenir l'alignement
                  if (_currentStep == 0) const SizedBox(width: 48),
                ],
              ),
            ),

            // --- 2. Contenu des pages avec transition 3D ---
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Empêche le défilement manuel
                itemCount: _totalSteps,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      // Logique pour l'effet de transition 3D (rotation et échelle)
                      double pageValue =
                          _pageController.hasClients &&
                              _pageController.page != null
                          ? _pageController.page!
                          : _currentStep.toDouble();

                      final double diff = pageValue - index;
                      final double absDiff = diff.abs();

                      final double scale = (1 - (absDiff * 0.2)).clamp(
                        0.9,
                        1.0,
                      );
                      final double angle =
                          diff * (math.pi / 12); // Rotation moins prononcée

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0015) // Perspective
                          ..rotateY(angle)
                          ..scale(scale),
                        child: Opacity(
                          opacity: (1 - absDiff).clamp(0.0, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: _buildStep(index, theme, primaryColor),
                  );
                },
              ),
            ),

            // --- 3. Bouton Continuer/Enregistrer ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed:
                    (_currentStep == _totalSteps - 1 && !_confirmedReview) ||
                        _isLoading
                    ? null // Désactiver le bouton si la révision n'est pas confirmée (facultatif)
                    : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size(
                    double.infinity,
                    56,
                  ), // Bouton plus grand
                  disabledBackgroundColor: primaryColor.withOpacity(0.5),
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
                        _currentStep < _totalSteps - 1
                            ? 'CONTINUER'
                            : 'ENREGISTRER LA DÉPENSE',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets pour chaque étape du formulaire ---
  Widget _buildStep(int index, ThemeData theme, Color primaryColor) {
    switch (index) {
      case 0:
        return _buildAmountStep(theme, primaryColor);
      case 1:
        return _buildCategoryStep(theme, primaryColor);
      default:
        return _buildReviewStep(theme, primaryColor);
    }
  }

  // --- ÉTAPE 1 : Saisie du Montant ---
  Widget _buildAmountStep(ThemeData theme, Color primaryColor) {
    return _ExpenseStepContainer(
      title: "1. Quel est le montant de la dépense ?",
      description: "Entrez le montant exact en Ariary Malgache (MGA).",
      child: Column(
        children: [
          // Champ de saisie stylisé pour le montant
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w300,
                color: primaryColor.withOpacity(0.4),
              ),
              prefixText: 'MGA ',
              prefixStyle: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w400,
                color: primaryColor.withOpacity(0.7),
              ),
              border: InputBorder.none, // Supprimer la bordure
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const Divider(thickness: 2),
          const SizedBox(height: 16),
          // Champ pour les notes
          TextField(
            controller: _notesCtrl,
            decoration: InputDecoration(
              labelText: 'Notes (Ex: Achat au supermarché)',
              prefixIcon: const Icon(Icons.edit_note),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // SÉLECTION DE DATE
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.dividerColor),
            ),
            leading: const Icon(Icons.calendar_today),
            title: Text(
              'Date de la dépense',
              style: theme.textTheme.titleMedium,
            ),
            trailing: Text(
              // Afficher la date sélectionnée (format court)
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            onTap: () => _selectDate(context),
          ),
        ],
      ),
    );
  }

  // --- ÉTAPE 2 : Choix de la Catégorie ---
  Widget _buildCategoryStep(ThemeData theme, Color primaryColor) {
    return _ExpenseStepContainer(
      title: "2. Choisissez la catégorie de dépense",
      description: "Cela aidera à analyser votre budget.",
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Card(
              color: isSelected
                  ? primaryColor.withOpacity(0.1)
                  : (theme.brightness == Brightness.dark
                        ? Colors.grey[900]
                        : Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? primaryColor
                      : (theme.brightness == Brightness.dark
                            ? Colors.grey[800]!
                            : Colors.grey[300]!),
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  _getCategoryIcon(category),
                  color: isSelected ? primaryColor : theme.iconTheme.color,
                ),
                title: Text(
                  category,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: primaryColor)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Nourriture':
        return Icons.fastfood;
      case 'Transport':
        return Icons.directions_bus;
      case 'Logement':
        return Icons.home;
      case 'Divertissement':
        return Icons.movie;
      default:
        return Icons.category;
    }
  }

  // --- ÉTAPE 3 : Révision et Confirmation ---
  Widget _buildReviewStep(ThemeData theme, Color primaryColor) {
    final isDark = theme.brightness == Brightness.dark;

    return _ExpenseStepContainer(
      title: "3. Confirmez la dépense",
      description: "Vérifiez les détails avant d'enregistrer.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Récapitulatif stylisé
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewItem(
                  "Montant total",
                  "${_amountCtrl.text} MGA",
                  primaryColor,
                  isBold: true,
                ),
                const Divider(),
                _buildReviewItem("Catégorie", _selectedCategory, primaryColor),
                _buildReviewItem(
                  "Notes",
                  _notesCtrl.text.isEmpty ? "Aucune note" : _notesCtrl.text,
                  primaryColor,
                ),
                _buildReviewItem(
                  "Date",
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', // Utiliser la date sélectionnée
                  primaryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Checkbox de confirmation
          Row(
            children: [
              Checkbox(
                value: _confirmedReview,
                onChanged: (val) =>
                    setState(() => _confirmedReview = val ?? false),
                activeColor: primaryColor,
              ),
              const Flexible(
                child: Text("J'ai vérifié et je confirme les détails."),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- CLASSE UTILITAIRE : Conteneur de Page pour l'Animation ---
class _ExpenseStepContainer extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _ExpenseStepContainer({
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre principal de l'étape
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 40),
          // Contenu du formulaire (montant, catégorie, etc.)
          child,
        ],
      ),
    );
  }
}

// --- CLASSE UTILITAIRE : Item de Révision ---
Widget _buildReviewItem(
  String label,
  String value,
  Color color, {
  bool isBold = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isBold ? color : null,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

/// --- CLASSE UTILITAIRE : Indicateur moderne de progression des étapes ---
class AnimatedProgressDots extends StatelessWidget {
  final int currentIndex;
  final int count;
  final Color primaryColor;

  const AnimatedProgressDots({
    super.key,
    required this.currentIndex,
    required this.count,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          // La largeur s'étend pour l'étape active
          width: isActive ? 24 : 8,
          decoration: BoxDecoration(
            color: isActive ? primaryColor : primaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}
