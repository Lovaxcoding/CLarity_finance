import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:myapp/model/objectives.dart';
import 'package:myapp/services/supabase_service.dart'; // Assurez-vous que le chemin est correct

class ObjectivesPage extends StatefulWidget {
  const ObjectivesPage({super.key});

  @override
  State<ObjectivesPage> createState() => _ObjectivesPageState();
}

class _ObjectivesPageState extends State<ObjectivesPage> {
  List<Objective> _objectives = [];
  bool _isLoading = true;
  // Utilisation du VRAI service Supabase
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _fetchObjectives();
  }

  Future<void> _fetchObjectives() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Appel à la fonction RÉELLE du service
      final data = await _supabaseService.fetchObjectives();
      setState(() {
        _objectives = data;
      });
    } catch (e) {
      // NOTE: En cas d'erreur de Supabase (ex: utilisateur déconnecté)
      // une notification est recommandée ici.
      print("Erreur de récupération des objectifs : $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Utilitaire pour formater les montants en Ariary (inchangé)
  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'Ar',
      decimalDigits: 0,
    );
    return format.format(amount).replaceAll(' ', ' ');
  }

  // Gère la navigation vers la page de création d'objectif (inchangé)
  void _goToCreateObjective() async {
    // Naviguer et attendre le retour (pour rafraîchir la liste)
    await context.push('/objectives/create');

    // Après être revenu de la page de création, rafraîchir la liste
    _fetchObjectives();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Mes Objectifs'),
        titleTextStyle: theme.textTheme.headlineMedium!.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onBackground,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.background,
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _objectives.isEmpty
          ? Center(
              child: Text(
                'Aucun objectif pour l\'instant. Commencez-en un !',
                style: theme.textTheme.titleMedium,

                textAlign: TextAlign.center,
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchObjectives,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _objectives.length,
                itemBuilder: (context, index) {
                  final objective = _objectives[index];
                  // Nous devons passer une couleur par défaut si l'URL est vide
                  final Color cardColor = _getObjectiveColor(index);

                  return _ObjectiveCard(
                    objective: objective,
                    formatCurrency: _formatCurrency,
                    cardColor: cardColor, // Passe la couleur au widget enfant
                  );
                },
              ),
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: _goToCreateObjective,
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Fonction utilitaire pour attribuer une couleur à un objectif
  Color _getObjectiveColor(int index) {
    const colors = [
      Colors.orange,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.purple,
    ];
    // Cycle à travers les couleurs basées sur l'index
    return colors[index % colors.length];
  }
}

// --- Widget de Carte d'Objectif (Similaire au design fourni) ---
// Mise à jour pour accepter une couleur pour l'icône/progression
class _ObjectiveCard extends StatelessWidget {
  final Objective objective;
  final Function(double) formatCurrency;
  final Color cardColor; // NOUVEAU

  const _ObjectiveCard({
    required this.objective,
    required this.formatCurrency,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remainingAmount = objective.targetAmount - objective.savedAmount;

    // Détermine l'icône à afficher (inchangé)
    final Widget objectiveIcon =
        // ... (Logique de l'icône inchangée) ...
        objective.iconUrl != null && objective.iconUrl!.isNotEmpty
        ? ClipOval(
            child: Image.network(
              objective.iconUrl!,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.savings_rounded, size: 18, color: cardColor),
            ),
          )
        : Icon(Icons.savings_rounded, size: 18, color: cardColor);

    return InkWell(
      // 1. Rendre la carte cliquable avec InkWell pour l'effet d'ondulation
      onTap: () {
        // 2. Appeler la navigation GoRouter
        context.push(
          // Utiliser l'ID pour l'URL si besoin, mais surtout passer l'objet complet
          '/objectives/${objective.id}',
          extra:
              objective, // 3. Passer l'objet 'Objective' complet en tant qu'extra
        );
      },
      borderRadius: BorderRadius.circular(15),
      child: Card(
        // Retirer le margin si vous voulez que l'InkWell couvre toute la zone
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // ... (Contenu de la carte inchangé) ...
            children: [
              // L'InkWell va ajouter l'effet de clic
              // tout le reste du contenu de la carte
              // ...
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: cardColor.withOpacity(0.1),
                        child: objectiveIcon,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        objective.title,
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    formatCurrency(objective.targetAmount),
                    style: theme.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: objective.progressPercentage,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatCurrency(objective.savedAmount),
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Épargné',
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCurrency(
                          remainingAmount < 0 ? 0 : remainingAmount,
                        ),
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Restant',
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
