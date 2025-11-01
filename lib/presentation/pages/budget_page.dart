import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Nécessaire pour formater les dates et la monnaie
import 'package:myapp/core/supabase_client.dart';

// Constantes pour le style de l'application
const Color _primaryColor = Color.fromARGB(255, 119, 0, 238);
const Color _accentColor = Color(0xFFF0F0F0);

// Structure pour les données de la base de données
class ExpenseCategoryData {
  final String name;
  final double amount;
  final double percentage;
  final Color color;

  ExpenseCategoryData({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final List<String> _timeOptions = ['Weekly', 'Monthly', 'Yearly', 'All Time'];
  String _selectedTime = 'Weekly';

  // Future pour stocker la requête asynchrone
  late Future<List<ExpenseCategoryData>> _expensesFuture;

  // Mappage statique des couleurs pour la cohérence visuelle
  final Map<String, Color> _categoryColors = {
    'Bills & Utilities': Colors.red.shade600,
    'Entertainment': Colors.orange.shade600,
    'Business & Work': Colors.blue.shade600,
    'Food & Drinks': Colors.purple.shade600,
    'Education': Colors.green.shade600,
    'Gift & Charity': Colors.blueAccent.shade400,
    // Ajoutez d'autres catégories ici !
  };

  @override
  void initState() {
    super.initState();
    _expensesFuture = _fetchExpenses(); // Lancement de la première requête
  }

  // Méthode pour relancer la requête lors du changement de période
  void _onTimeSelected(String newTime) {
    if (newTime != _selectedTime) {
      setState(() {
        _selectedTime = newTime;
        _expensesFuture =
            _fetchExpenses(); // Relance la requête avec le nouveau filtre
      });
    }
  }

  // --- LOGIQUE DE RÉCUPÉRATION DES DONNÉES SUPABASE ---

  Future<List<ExpenseCategoryData>> _fetchExpenses() async {
    // 1. Déterminer les dates de début et de fin en fonction de _selectedTime
    final now = DateTime.now();
    DateTime startDate;

    if (_selectedTime == 'Weekly') {
      startDate = now.subtract(Duration(days: now.weekday - 1));
    } else if (_selectedTime == 'Monthly') {
      startDate = DateTime(now.year, now.month, 1);
    } else if (_selectedTime == 'Yearly') {
      startDate = DateTime(now.year, 1, 1);
    } else {
      // Pour 'All Time', on utilise une date très ancienne ou on ne filtre pas la date.
      startDate = DateTime(2000, 1, 1);
    }

    final endDate = now.add(
      const Duration(days: 1),
    ); // Pour inclure la journée en cours

    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    // 2. Requête Supabase : Filtrer, Regrouper et Calculer le total par catégorie
    // On utilise `rpc` pour une fonction agrégée si elle est définie, mais une
    // requête `select` basique avec agrégation suffit ici si PostgREST est bien configuré.
    // NOTE: Le groupement côté Dart est parfois plus simple que l'agrégation PostgREST
    // pour des cas simples, mais l'agrégation est plus efficace.

    // Pour cet exemple, nous allons simuler le regroupement côté Dart
    // et nous allons d'abord récupérer toutes les dépenses de la période.

    final userId = supabase.auth.currentUser!.id;

    final List<Map<String, dynamic>> rawExpenses = await supabase
        .from('expenses')
        .select('amount, category')
        .eq('user_id', userId)
        .gte('expense_date', startDateStr)
        .lte('expense_date', endDateStr);

    // 3. Regroupement et Calcul des Pourcentages (Logique côté Flutter)
    if (rawExpenses.isEmpty) {
      return [];
    }

    final Map<String, double> groupedExpenses = {};
    double grandTotal = 0;

    for (var expense in rawExpenses) {
      final category = expense['category'] as String;
      final amount = (expense['amount'] as num).toDouble();
      groupedExpenses[category] = (groupedExpenses[category] ?? 0) + amount;
      grandTotal += amount;
    }

    // Conversion finale en liste de DTOs (Data Transfer Objects)
    return groupedExpenses.entries.map((entry) {
        final percentage = entry.value / grandTotal;
        return ExpenseCategoryData(
          name: entry.key,
          amount: entry.value,
          percentage: percentage,
          color:
              _categoryColors[entry.key] ??
              Colors.grey.shade600, // Couleur par défaut
        );
      }).toList()
      // Tri par montant pour afficher les plus grosses dépenses en premier
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  // --- WIDGETS DE COMPOSITION ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Expense Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // 1. Boutons de Sélection de Période
          _buildTimeSelector(),

          // Utilisation de FutureBuilder pour gérer l'état de la requête Supabase
          Expanded(
            child: FutureBuilder<List<ExpenseCategoryData>>(
              future: _expensesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erreur de chargement: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final expenses = snapshot.data ?? [];

                if (expenses.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucune dépense trouvée pour cette période.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                // Calculer le total à partir des données réelles
                final grandTotal = expenses.fold(
                  0.0,
                  (sum, item) => sum + item.amount,
                );

                return Column(
                  children: [
                    // 2. Affichage de la Période et du Total (mis à jour)
                    _buildTotalExpenseHeader(
                      grandTotal,
                      'Dec 25 - Dec 31, 2024',
                    ), // Remplacer par la date dynamique si possible
                    // 3. Liste de Détails par Catégorie
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          return _buildCategoryTile(expenses[index]);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE COMPOSITION MIS À JOUR ---

  Widget _buildTimeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _timeOptions.map((time) {
            final isSelected = time == _selectedTime;
            return Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: ChoiceChip(
                label: Text(time),
                selected: isSelected,
                selectedColor: _primaryColor,
                backgroundColor: _accentColor,
                labelStyle: GoogleFonts.lato(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (bool selected) {
                  if (selected) {
                    _onTimeSelected(time);
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: isSelected
                      ? BorderSide.none
                      : const BorderSide(color: Colors.transparent),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTotalExpenseHeader(double total, String dateRange) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey),
                const SizedBox(width: 10),
                Text(
                  dateRange, // Date réelle ici
                  style: GoogleFonts.lato(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),

          Text(
            // Formatage de la monnaie
            NumberFormat.currency(locale: 'fr_FR', symbol: '\$').format(total),
            style: GoogleFonts.lato(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const Text(
            'Total des dépenses pour cette période',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(ExpenseCategoryData expense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: expense.percentage,
                strokeWidth: 4,
                color: expense.color,
                backgroundColor: expense.color.withOpacity(0.2),
              ),
              Text(
                '${(expense.percentage * 100).toInt()}%',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          expense.name,
          style: GoogleFonts.lato(fontWeight: FontWeight.w600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              NumberFormat.currency(
                locale: 'fr_FR',
                symbol: '\$',
              ).format(expense.amount),
              style: GoogleFonts.lato(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
        onTap: () {
          // TODO: Naviguer vers les détails de cette catégorie
        },
      ),
    );
  }
}
