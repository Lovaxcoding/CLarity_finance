// Dans lib/pages/objective_detail_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:myapp/model/objectives.dart';
import 'package:myapp/services/supabase_service.dart';

class ObjectiveDetailPage extends StatefulWidget {
  final Objective objective;

  const ObjectiveDetailPage({super.key, required this.objective});

  @override
  State<ObjectiveDetailPage> createState() => _ObjectiveDetailPageState();
}

class _ObjectiveDetailPageState extends State<ObjectiveDetailPage> {
  late Objective _currentObjective;
  bool _isSaving = false;
  bool _isLoadingProjections = true; // NOUVEAU
  double _monthlySavingsCapacity = 0.0; // NOUVEAU : Capacité calculée par l'IA

  final SupabaseService _supabaseService = SupabaseService();
  final Color _objectiveColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _currentObjective = widget.objective;
    _fetchSavingsProjections(); // NOUVEAU : Lance le calcul IA
  }

  // --- NOUVEAU : Récupère la capacité d'épargne du Coach IA ---
  Future<void> _fetchSavingsProjections() async {
    setState(() => _isLoadingProjections = true);

    // Si l'utilisateur n'a pas défini de date butoir, on calcule la capacité
    if (_currentObjective.targetDate == null) {
      final capacity = await _supabaseService.calculateMonthlySavingsCapacity();
      setState(() {
        _monthlySavingsCapacity = capacity;
      });
    } else {
      // Si la date butoir existe, nous pourrions calculer l'épargne nécessaire
      // Nous garderons _monthlySavingsCapacity à 0 pour l'instant si date butoir est présente
      // ou nous pourrions calculer le montant nécessaire par mois (Target / MoisRestants)
    }

    setState(() => _isLoadingProjections = false);
  }

  // Utilitaire pour formater la monnaie
  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'Ar',
      decimalDigits: 0,
    );
    return format.format(amount).replaceAll(' ', ' ');
  }

  // --- LOGIQUE D'AJOUT D'ÉPARGNE (inchangé) ---
  Future<void> _showAddSavingsModal() async {
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddSavingsModal(
        formatCurrency: _formatCurrency,
        objectiveTitle: _currentObjective.title,
      ),
    );

    if (result != null && result > 0) {
      await _addSavings(result);
      // Après l'ajout d'épargne, rafraîchir les projections si nécessaire
      _fetchSavingsProjections();
    }
  }

  Future<void> _addSavings(double amount) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await addSavingsToObjective(
        objectiveId: _currentObjective.id,
        amount: amount,
        note: 'Épargne manuelle',
      );
      setState(() {
        _currentObjective = _currentObjective.copyWith(
          savedAmount: _currentObjective.savedAmount + amount,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_formatCurrency(amount)} ajoutés à l\'objectif !'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec du dépôt : ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- WIDGET DE CALCUL DES PROJECTIONS ---
  Widget _buildSavingsProjections(ThemeData theme) {
    // Si la date butoir est fixée, on calcule le montant nécessaire
    if (_currentObjective.targetDate != null) {
      final now = DateTime.now();
      final difference = _currentObjective.targetDate!.difference(now);
      final daysRemaining = difference.inDays;
      final remainingAmount =
          _currentObjective.targetAmount - _currentObjective.savedAmount;

      if (daysRemaining <= 0 || remainingAmount <= 0) {
        return const SizedBox.shrink(); // Objectif atteint ou dépassé
      }

      final monthlyGoal =
          (remainingAmount / daysRemaining) *
          30.4375; // Moyenne de jours par mois
      final weeklyGoal = remainingAmount / (daysRemaining / 7);
      final dailyGoal = remainingAmount / daysRemaining;

      return _ProjectionsSummary(
        monthly: monthlyGoal,
        weekly: weeklyGoal,
        daily: dailyGoal,
        formatCurrency: _formatCurrency,
        title: 'Objectif Nécessaire',
        color: Colors.blue.shade600,
      );
    }
    // Si la date butoir n'est PAS fixée, on affiche la CAPACITÉ d'épargne IA
    else if (_monthlySavingsCapacity > 0) {
      // Les calculs sont basés sur la capacité mensuelle fournie par l'IA
      final monthly = _monthlySavingsCapacity;
      final weekly = monthly / 4.33;
      final daily = monthly / 30.4375;

      return _ProjectionsSummary(
        monthly: monthly,
        weekly: weekly,
        daily: daily,
        formatCurrency: _formatCurrency,
        title: 'Capacité d\'Épargne Estimée',
        color: Colors.purple.shade600,
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remainingAmount =
        _currentObjective.targetAmount - _currentObjective.savedAmount;

    final Widget objectiveIcon =
        _currentObjective.iconUrl != null &&
            _currentObjective.iconUrl!.isNotEmpty
        ? ClipOval(
            child: Image.network(
              _currentObjective.iconUrl!,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          )
        : Icon(Icons.savings_rounded, size: 40, color: _objectiveColor);

    final double percentage = _currentObjective.progressPercentage.clamp(
      0.0,
      1.0,
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(_currentObjective.title),
        titleTextStyle: theme.textTheme.headlineMedium!.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.background,
        foregroundColor: theme.colorScheme.onBackground,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ... (CERCLE DE PROGRESSION inchangé) ...
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: CircularProgressIndicator(
                      value: percentage,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _objectiveColor,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: _objectiveColor.withOpacity(0.1),
                        child: objectiveIcon,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${(percentage * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.headlineMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- SOMMAIRES DES MONTANTS (inchangé) ---
            _buildAmountSummary(theme, remainingAmount),
            const SizedBox(height: 30),

            // --- PROJECTIONS D'ÉPARGNE (NOUVEAU) ---
            _isLoadingProjections
                ? const Center(child: CircularProgressIndicator())
                : _buildSavingsProjections(theme),

            const SizedBox(height: 30),

            // --- DATE LIMITE ET NOTE (inchangé) ---
            _buildDetailsSection(theme),
          ],
        ),
      ),

      // --- BOUTONS D'ACTION (inchangé) ---
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Retirer'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _showAddSavingsModal,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Ajouter',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ... (Méthodes _buildAmountSummary, _summaryItem, _buildDetailsSection, _detailRow inchangées) ...

  Widget _buildAmountSummary(ThemeData theme, double remainingAmount) {
    // ... (corps de la fonction inchangé) ...
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _summaryItem(
              theme,
              title: 'Épargné',
              amount: _currentObjective.savedAmount,
              color: _objectiveColor,
            ),
            _summaryItem(
              theme,
              title: 'Restant',
              amount: remainingAmount,
              color: Colors.red,
            ),
            _summaryItem(
              theme,
              title: 'Total Objectif',
              amount: _currentObjective.targetAmount,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(
    ThemeData theme, {
    required String title,
    required double amount,
    required Color color,
  }) {
    // ... (corps de la fonction inchangé) ...
    return Column(
      children: [
        Text(
          _formatCurrency(amount),
          style: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: theme.textTheme.bodySmall!.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(ThemeData theme) {
    // ... (corps de la fonction inchangé) ...
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_currentObjective.targetDate != null)
          _detailRow(
            theme,
            icon: Icons.calendar_today_rounded,
            label: 'Date Limite',
            value: DateFormat.yMMMd(
              'fr_FR',
            ).format(_currentObjective.targetDate!),
          ),
        const SizedBox(height: 10),
        _detailRow(
          theme,
          icon: Icons.notes_rounded,
          label: 'Note',
          value:
              'Planifier un voyage de 10 jours en Asie du Sud-Est.', // Placeholder
        ),
      ],
    );
  }

  Widget _detailRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    // ... (corps de la fonction inchangé) ...
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: theme.textTheme.titleSmall),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET PROJECTIONS D'ÉPARGNE (NOUVEAU) ---
class _ProjectionsSummary extends StatelessWidget {
  final double daily;
  final double weekly;
  final double monthly;
  final Function(double) formatCurrency;
  final String title;
  final Color color;

  const _ProjectionsSummary({
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.formatCurrency,
    required this.title,
    required this.color,
  });

  Widget _projectionItem(ThemeData theme, String label, double amount) {
    return Column(
      children: [
        Text(
          formatCurrency(amount),
          style: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall!.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _projectionItem(theme, 'Quotidien', daily),
                _projectionItem(theme, 'Hebdomadaire', weekly),
                _projectionItem(theme, 'Mensuel', monthly),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- WIDGET MODAL D'AJOUT D'ÉPARGNE (inchangé) ---
class _AddSavingsModal extends StatefulWidget {
  final Function(double) formatCurrency;
  final String objectiveTitle;

  const _AddSavingsModal({
    required this.formatCurrency,
    required this.objectiveTitle,
  });

  @override
  State<_AddSavingsModal> createState() => _AddSavingsModalState();
}

class _AddSavingsModalState extends State<_AddSavingsModal> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ajouter',
            style: theme.textTheme.headlineSmall!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'pour l\'objectif : ${widget.objectiveTitle}',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),

          Text('Montant à ajouter (Ar)', style: theme.textTheme.titleSmall),
          TextFormField(
            controller: _amountController,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: theme.textTheme.headlineMedium,
            decoration: const InputDecoration(
              prefixText: 'Ar ',
              hintText: '0',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final amount = double.tryParse(value ?? '');
              if (amount == null || amount <= 0) {
                return 'Entrez un montant valide.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          _buildDateField(theme),
          const SizedBox(height: 20),

          _buildNoteField(theme),
          const SizedBox(height: 40),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(
                    _amountController.text.replaceAll(',', '.'),
                  );
                  if (amount != null && amount > 0) {
                    context.pop(amount);
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDateField(ThemeData theme) {
    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
        const SizedBox(width: 10),
        Text(
          'Aujourd\'hui, ${DateFormat.yMMMd('fr_FR').format(DateTime.now())}',
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildNoteField(ThemeData theme) {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Note (Optionnelle)',
        hintText: 'Ex: Vente d\'actions, économie du mois...',
      ),
    );
  }
}

// --- AJOUT UTILE AU MODÈLE Objective (inchangé) ---
extension ObjectiveExtension on Objective {
  Objective copyWith({
    String? id,
    String? userId,
    String? title,
    double? targetAmount,
    double? savedAmount,
    DateTime? targetDate,
    bool? isAchieved,
    DateTime? createdAt,
    String? iconUrl,
  }) {
    return Objective(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      targetDate: targetDate ?? this.targetDate,
      isAchieved: isAchieved ?? this.isAchieved,
      createdAt: createdAt ?? this.createdAt,
      iconUrl: iconUrl ?? this.iconUrl,
    );
  }
}
