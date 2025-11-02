import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase

// Constantes pour les couleurs spécifiques
const Color expenseColor = Color(
  0xFF10B981,
); // Couleur forte pour Dépense (Vert)
const Color incomeColor = Color(
  0xFF8B5CF6,
); // Couleur forte pour Revenu (Violet)

// --- Modèles de Données Utilisés ---

class CategoryInsight {
  final String title;
  final double amount;
  final double percentage;
  final Color color;

  CategoryInsight({
    required this.title,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

enum TransactionType { expense, income }

class Transaction {
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String category;

  Transaction({
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
  });

  // Mapper une ligne de 'expenses' de Supabase en Transaction
  static Transaction fromExpenseJson(Map<String, dynamic> json) {
    final transactionTitle = json['category'] as String? ?? 'Dépense';
    return Transaction(
      title: transactionTitle,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['created_at'] as String),
      type: TransactionType.expense,
      category: json['category'] as String? ?? 'Inconnu',
    );
  }

  // Mapper une ligne de 'incomes' de Supabase en Transaction
  static Transaction fromIncomeJson(Map<String, dynamic> json) {
    return Transaction(
      title:
          json['source'] as String? ?? 'Revenu', // Utiliser 'source' ou 'title'
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['created_at'] as String),
      type: TransactionType.income,
      category:
          json['source'] as String? ??
          'Inconnu', // Utiliser 'source' ou 'category'
    );
  }
}

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _errorMessage = '';

  // --- Données Dynaliques ---
  double _totalExpense = 0.0;
  double _totalIncome = 0.0;

  List<CategoryInsight> _expenseInsights = [];
  List<CategoryInsight> _incomeInsights = [];
  List<Transaction> _allTransactions = [];

  // Format de la devise
  final _currencyFormat = NumberFormat.currency(
    locale: 'fr_MG',
    symbol: 'Ar',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchInsightsData(); // Appel de la fonction dynamisée
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- NOUVELLE Fonction de Récupération des Données de la DB ---
  Future<void> _fetchInsightsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. Récupération des Dépenses et Revenus
      // Note: Pour une période donnée (ex: le mois en cours), il faudrait ajouter un filtre.
      final expensesResponse = await supabase
          .from('expenses')
          .select(' amount, category, created_at');
      final incomesResponse = await supabase
          .from('incomes')
          .select('source, amount, created_at');

      final allExpenses = (expensesResponse as List<dynamic>)
          .cast<
            Map<String, dynamic>
          >() // On s'assure que chaque élément est une Map<String, dynamic>
          .map(Transaction.fromExpenseJson)
          .toList();

      final allIncomes = (incomesResponse as List<dynamic>)
          .cast<
            Map<String, dynamic>
          >() // On s'assure que chaque élément est une Map<String, dynamic>
          .map(Transaction.fromIncomeJson)
          .toList();
      // 2. Calcul des Totaux
      final totalExpenses = allExpenses.fold<double>(
        0.0,
        (prev, curr) => prev + curr.amount,
      );
      final totalIncomes = allIncomes.fold<double>(
        0.0,
        (prev, curr) => prev + curr.amount,
      );

      // 3. Calcul de la Répartition par Catégorie (Insights)
      final expenseCategoryMap = <String, double>{};
      for (var exp in allExpenses) {
        expenseCategoryMap[exp.category] =
            (expenseCategoryMap[exp.category] ?? 0) + exp.amount;
      }

      final incomeCategoryMap = <String, double>{};
      for (var inc in allIncomes) {
        incomeCategoryMap[inc.category] =
            (incomeCategoryMap[inc.category] ?? 0) + inc.amount;
      }

      // Convertir en liste d'Insights Dépenses
      final expenseInsightsList = expenseCategoryMap.entries.map((entry) {
        final percentage = totalExpenses > 0
            ? entry.value / totalExpenses
            : 0.0;
        return CategoryInsight(
          title: entry.key,
          amount: entry.value,
          percentage: percentage,
          color: HSLColor.fromAHSL(
            1.0,
            (entry.key.hashCode % 360).toDouble(),
            0.8,
            0.4,
          ).toColor(), // Couleur dynamique
        );
      }).toList();

      // Convertir en liste d'Insights Revenus
      final incomeInsightsList = incomeCategoryMap.entries.map((entry) {
        final percentage = totalIncomes > 0 ? entry.value / totalIncomes : 0.0;
        return CategoryInsight(
          title: entry.key,
          amount: entry.value,
          percentage: percentage,
          color: HSLColor.fromAHSL(
            1.0,
            (entry.key.hashCode % 360).toDouble(),
            0.8,
            0.4,
          ).toColor(), // Couleur dynamique
        );
      }).toList();

      // Combiner et trier toutes les transactions pour l'historique
      final allTransactionsSorted = [...allExpenses, ...allIncomes];
      allTransactionsSorted.sort((a, b) => b.date.compareTo(a.date));

      // 4. Mise à jour de l'état
      setState(() {
        _totalExpense = totalExpenses;
        _totalIncome = totalIncomes;
        _expenseInsights = expenseInsightsList;
        _incomeInsights = incomeInsightsList;
        _allTransactions = allTransactionsSorted;
        _isLoading = false;
      });
    } on PostgrestException catch (e) {
      setState(() {
        _errorMessage = "Erreur Supabase: ${e.message}";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur inattendue: ${e.toString()}";
        _isLoading = false;
      });
      print("Erreur: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              _errorMessage,
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Le reste du code build() reste inchangé, utilisant les variables d'état mises à jour.

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        title: Text(
          "Aperçu des Finances",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onBackground,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // --- 1. Onglets (Income / Expense) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _tabController.index == 0 ? incomeColor : expenseColor,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: theme.colorScheme.onSurface,
                tabs: const [
                  Tab(text: 'Revenus'),
                  Tab(text: 'Dépenses'),
                ],
                onTap: (index) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- 2. Contenu des Onglets (Graphiques et Listes) ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Contenu pour l'onglet Revenus (Income)
                _buildInsightContent(theme, false),
                // Contenu pour l'onglet Dépenses (Expense)
                _buildInsightContent(theme, true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget de Contenu des Insights (Graphique + Détails + Liste Complète) ---
  Widget _buildInsightContent(ThemeData theme, bool isExpense) {
    // Les données sont maintenant des variables d'état mises à jour par _fetchInsightsData
    final List<CategoryInsight> data = isExpense
        ? _expenseInsights
        : _incomeInsights;
    final Color mainColor = isExpense ? expenseColor : incomeColor;
    final String mainTitle = isExpense ? "Dépense Totale" : "Revenu Total";
    final double totalAmount = isExpense ? _totalExpense : _totalIncome;

    // Filtrer les transactions en fonction de l'onglet
    final List<Transaction> filteredTransactions = _allTransactions
        .where(
          (t) => isExpense
              ? t.type == TransactionType.expense
              : t.type == TransactionType.income,
        )
        .toList();

    // Si le total est zéro, on affiche un message dans le graphique.
    if (totalAmount == 0.0) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              "Aucune donnée pour les ${isExpense ? 'dépenses' : 'revenus'} ce mois-ci.",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Carte du Total et Graphique Circulaire ---
          Card(
            color: theme.colorScheme.surface,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mainTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Graphique Circulaire (Pie Chart)
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: _buildPieChart(data),
                      ),
                      const SizedBox(width: 20),
                      // Détails du Total
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currencyFormat.format(totalAmount),
                              style: theme.textTheme.headlineLarge?.copyWith(
                                color: mainColor,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Légende des Catégories
                            ...data.map(
                              (insight) => _buildIndicator(
                                insight.color,
                                '${insight.title} (${(insight.percentage * 100).toStringAsFixed(0)}%)',
                                theme,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- Graphique en Barre de Tendance (Données toujours simulées) ---
          Text(
            isExpense
                ? "Tendance des Dépenses (simulée)"
                : "Tendance des Revenus (simulée)",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.surface,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SizedBox(
                height: 180,
                child: _buildBarChart(mainColor, isExpense),
              ), // On passe isExpense
            ),
          ),
          const SizedBox(height: 30),

          // --- Historique Complet des Transactions (Dynamique) ---
          Text(
            isExpense
                ? "Historique complet des Dépenses"
                : "Historique complet des Revenus",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          _buildTransactionList(theme, filteredTransactions, isExpense),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // --- NOUVEAU WIDGET : Liste des Transactions (inchangé, utilisant les données _allTransactions) ---
  Widget _buildTransactionList(
    ThemeData theme,
    List<Transaction> transactions,
    bool isExpense,
  ) {
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            "Aucune transaction trouvée pour cette période.",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      children: transactions.map((t) {
        final amountText = _currencyFormat.format(t.amount);
        final color = isExpense ? expenseColor : incomeColor;
        final icon = isExpense
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            title: Text(t.title, style: theme.textTheme.titleMedium),
            subtitle: Text(
              '${t.category} - ${DateFormat('dd MMM').format(t.date)}',
              style: theme.textTheme.bodySmall,
            ),
            trailing: Text(
              amountText,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- Widgets Utilitaires ---

  // Pie Chart (utilise les données dynamiques 'data')
  Widget _buildPieChart(List<CategoryInsight> data) {
    if (data.isEmpty) {
      return const Center(child: Text("Pas de données"));
    }
    // Filtrer les insights avec un montant > 0 pour éviter des tranches invisibles
    final validData = data.where((i) => i.amount > 0).toList();
    if (validData.isEmpty) {
      return const Center(child: Text("Pas de données"));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: validData.asMap().entries.map((entry) {
          final insight = entry.value;
          return PieChartSectionData(
            color: insight.color,
            value: insight.amount,
            title: '',
            radius: 20,
          );
        }).toList(),
      ),
    );
  }

  // Indicateur de légende (inchangé)
  Widget _buildIndicator(Color color, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bar Chart (TOUJOURS SIMULÉ pour l'exemple)
  Widget _buildBarChart(Color color, bool isExpense) {
    final List<double> chartData;

    // Utilisation de données simulées pour le graphique en barres
    if (isExpense) {
      chartData = [800, 750, 600, 850, 700, 780, 650]; // Dépenses simulées
    } else {
      chartData = [1000, 500, 0, 1500, 0, 0, 2000]; // Revenus simulés
    }

    final maxY =
        chartData.reduce((a, b) => a > b ? a : b) * 1.2; // 20% au-dessus du max

    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                _currencyFormat.format(rod.toY),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(
                ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'][value
                    .toInt()],
                style: const TextStyle(fontSize: 10),
              ),
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: maxY > 0 ? maxY / 4 : 200, // Intervalle dynamique
              getTitlesWidget: (value, meta) => Text(
                _currencyFormat.format(value).replaceAll('Ar', '').trim(),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
        ),
        barGroups: List.generate(7, (i) {
          double y = chartData[i];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: y,
                color: color.withOpacity(0.6),
                width: 15,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                ),
              ),
            ],
          );
        }),
        groupsSpace: 10,
        maxY: maxY == 0 ? 100 : maxY,
      ),
    );
  }
}
