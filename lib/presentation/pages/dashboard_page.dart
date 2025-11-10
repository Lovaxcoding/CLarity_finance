import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Pour formater le montant
import 'package:myapp/model/profile_model.dart';
import 'package:myapp/model/transaction_model.dart';

// Initialisation de Supabase Client
final supabase = Supabase.instance.client;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Variables d'état
  Profile? _profile;
  double _balance = 0.0;
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Format de la devise
  final _currencyFormat = NumberFormat.currency(
    locale: 'fr_MG',
    symbol: 'Ar',
    decimalDigits: 0,
  ); // L'Ariary n'utilise souvent pas de décimales

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // --- Fonction Principale de Récupération des Données ---
  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. Récupération du Profil (pour le nom)
      final profileResponse = await supabase
          .from('profiles')
          .select('first_name, avatar_url')
          .single();

      // 2. Récupération des Dépenses
      final expensesResponse = await supabase
          .from('expenses')
          .select('amount, category, created_at')
          .limit(10) // Limiter aux 10 dernières
          .order('created_at', ascending: false);

      // 3. Récupération des Revenus (ASSUME que la table 'incomes' est créée)
      final incomesResponse = await supabase
          .from('incomes')
          .select('amount, source, created_at')
          .limit(10) // Limiter aux 10 dernières
          .order('created_at', ascending: false);

      // --- Calcul du Solde ---
      final totalExpenses = (expensesResponse as List<dynamic>)
          .map((e) => (e['amount'] as num).toDouble())
          .fold<double>(0.0, (prev, curr) => prev + curr);

      final totalIncomes = (incomesResponse as List<dynamic>)
          .map((i) => (i['amount'] as num).toDouble())
          .fold<double>(0.0, (prev, curr) => prev + curr);

      final currentBalance = totalIncomes - totalExpenses;

      // --- Création de la Liste de Transactions ---
      final allExpenses = expensesResponse
          .map(Transaction.fromExpenseJson)
          .toList();
      final allIncomes = incomesResponse
          .map(Transaction.fromIncomeJson)
          .toList();

      // Combiner et trier les transactions par date
      final allTransactions = [...allExpenses, ...allIncomes];
      allTransactions.sort((a, b) => b.date.compareTo(a.date));

      // Mettre à jour l'état
      setState(() {
        _profile = Profile.fromJson(profileResponse);
        _balance = currentBalance;
        _transactions = allTransactions
            .take(5)
            .toList(); // Afficher les 5 plus récentes
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
      );
    }

    // Valeurs dynamiques
    final greetingName = _profile?.firstName ?? 'Utilisateur';

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Avatar Dynamique (peut-être NetworkImage pour l'avatar_url)
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: _profile?.avatarUrl != null
                        ? NetworkImage(_profile!.avatarUrl!)
                        : const AssetImage('images/profile.png')
                              as ImageProvider,
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Nom Dynamique
              Text(
                "Bonjour $greetingName",
                style: theme.textTheme.displayMedium,
              ),
              const SizedBox(height: 8),

              // --- Balance Card (Solde Dynamique) ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  // RETIRER la propriété 'color: theme.colorScheme.primary'
                  borderRadius: BorderRadius.circular(20),
                  // AJOUT DU DEGRADE (GRADIENT)
                  gradient: const LinearGradient(
                    // Un beau dégradé de bleu-violet à rose-violet
                    colors: [Color(0xFF6A0DAD), Color(0xFFC71585)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    // AJUSTEMENT de l'ombre pour correspondre au dégradé
                    BoxShadow(
                      color: const Color(0xFF6A0DAD).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currencyFormat.format(_balance), // Solde formaté
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Solde actuel",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    // ... (reste de la carte inchangé)
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Quick Action Buttons (inchangé) ---
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 3.2,
                ),
                children: [
                  _quickActionButton(
                    Icons.arrow_upward,
                    "Déposer",
                    () => context.go('/expense_entry'),
                  ),
                  _quickActionButton(
                    Icons.event_busy,
                    "Dépense",
                    () => context.go("/insights"),
                  ),
                  _quickActionButton(
                    Icons.request_page,
                    "Objectifs",
                    () => context.go("/objectives"),
                  ),
                  _quickActionButton(
                    Icons.account_balance_wallet,
                    "Poche",
                    () => context.go("/savings"),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Transaction History ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Historique des Transactions",
                    style: theme.textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      context.go('/insights');
                    },
                    child: const Text("Voir tout"),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Affichage des Transactions Dynamiques ---
              _transactions.isEmpty
                  ? Center(child: _noTransactionPlaceholder(theme))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];
                        return _buildTransactionTile(theme, transaction);
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget utilitaire pour les boutons d'action rapide
  Widget _quickActionButton(IconData icon, String label, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surface, // S'adapte mieux au mode sombre/clair
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour chaque ligne de transaction
  Widget _buildTransactionTile(ThemeData theme, Transaction transaction) {
    final isExpense = transaction.type == TransactionType.expense;
    final color = isExpense ? Colors.red : Colors.green;
    final sign = isExpense ? '-' : '+';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(
          isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          color: color,
        ),
      ),
      title: Text(transaction.title, style: theme.textTheme.titleSmall),
      subtitle: Text(
        DateFormat('dd MMM').format(transaction.date),
        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
      ),
      trailing: Text(
        '$sign ${_currencyFormat.format(transaction.amount)}',
        style: theme.textTheme.titleSmall!.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Widget utilitaire en cas d'absence de transaction
  Widget _noTransactionPlaceholder(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Text(
          "Aucune transaction pour le moment",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        const Text(
          "Dès que vous commencez à envoyer ou recevoir de l'argent, toute votre activité apparaîtra ici",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
