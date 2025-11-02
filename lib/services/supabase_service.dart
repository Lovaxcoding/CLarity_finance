import 'dart:io'; // Nécessaire pour le type File
import 'package:myapp/core/supabase_client.dart';
import 'package:myapp/model/objectives.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // Pour kDebugMode

class SupabaseService {
  // Nom du bucket où seront stockées les icônes des objectifs
  static const String _objectiveIconsBucket = 'objective_icons';

  // --- Fonction 1 : Créer un Objectif (avec gestion d'upload d'icône) ---
  Future<void> createObjective({
    required String title,
    required double targetAmount,
    DateTime? targetDate,
    File? imageFile, // Le fichier d'image local à uploader
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException(
        'Utilisateur non connecté. Redirection nécessaire.',
      );
    }
    final userId = user.id;
    String? finalIconUrl;

    // Étape 1 : UPLOAD DE L'IMAGE (si fournie)
    if (imageFile != null) {
      try {
        final fileExtension = imageFile.path.split('.').last;
        final fileName =
            '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

        // Upload du fichier
        await supabase.storage
            .from(_objectiveIconsBucket)
            .upload(fileName, imageFile);

        // Récupérer l'URL publique
        finalIconUrl = supabase.storage
            .from(_objectiveIconsBucket)
            .getPublicUrl(fileName);
      } on StorageException catch (e) {
        if (kDebugMode) {
          print("Erreur d'upload Supabase: ${e.message}");
        }
        // Nous choisissons ici de lancer une erreur pour que l'utilisateur sache que l'icône n'a pas été enregistrée.
        throw Exception("Échec de l'upload de l'icône: ${e.message}");
      }
    }

    // Étape 2 : Préparer les données pour l'insertion
    // Créez une instance temporaire du modèle pour utiliser toJson()
    final newObjective = Objective(
      id: '', // Temporaire, l'ID sera généré par Supabase
      userId: userId,
      title: title,
      targetAmount: targetAmount,
      savedAmount: 0.0,
      targetDate: targetDate,
      isAchieved: false,
      createdAt: DateTime.now(), // Temporaire
      iconUrl: finalIconUrl,
    );

    // Étape 3 : Insérer l'Objectif dans la table 'objectives'
    try {
      await supabase.from('objectives').insert(newObjective.toJson());
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print(
          "Erreur PostgREST lors de la création de l'objectif: ${e.message}",
        );
      }
      throw Exception(
        "Erreur de base de données lors de l'enregistrement de l'objectif.",
      );
    }
  }

  // --- Fonction 2 : Logique d'IA (Calcul de la capacité d'épargne) ---
  // Nous allons implémenter ceci à l'étape suivante !
  Future<double> calculateMonthlySavingsCapacity() async {
    // Actuellement une valeur simulée
    await Future.delayed(const Duration(milliseconds: 500));
    return 850000.0;
  }

  // --- Fonction 3 : Récupérer les Objectifs (pour ObjectivesPage) ---
  Future<List<Objective>> fetchObjectives() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Utilisateur non connecté.');
    }

    try {
      final response = await supabase
          .from('objectives')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      // Mappage des résultats JSON vers la liste d'Objective
      final List<Objective> objectives = (response as List)
          .map((json) => Objective.fromJson(json))
          .toList();
      return objectives;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print("Erreur de récupération des objectifs: ${e.message}");
      }
      throw Exception(
        "Erreur de base de données lors de la récupération des objectifs.",
      );
    }
  }
}

Future<List<Objective>> fetchObjectives() async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw const AuthException('Utilisateur non connecté.');
  }

  try {
    final response = await supabase
        .from('objectives')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    // La ligne qui cause l'erreur (maintenant corrigée par l'importation)
    final List<Objective> objectives = (response as List)
        .map(
          (json) => Objective.fromJson(json as Map<String, dynamic>),
        ) // Assurez le cast en Map
        .toList();

    return objectives;
  } on PostgrestException catch (e) {
    // ... (gestion des erreurs)
    throw Exception(
      "Erreur de base de données lors de la récupération des objectifs.",
    );
  }
}

Future<void> addSavingsToObjective({
  required String objectiveId,
  required double amount,
  String? note,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw const AuthException('Utilisateur non connecté.');
  }

  // Étape 1 : Enregistrer l'épargne comme une DÉPENSE (dans la table 'expenses')
  try {
    // ⚠️ ATTENTION : Utilisation de la table 'expenses' et de la colonne 'expense_date'
    await supabase.from('expenses').insert({
      'user_id': user.id,
      'amount': amount,
      // L'épargne est considérée comme une dépense pour le solde
      'category': 'Épargne', // Utilisation de 'Épargne' comme catégorie
      'expense_date': DateTime.now()
          .toIso8601String(), // Utilisation de expense_date
      'description': note ?? 'Dépôt d\'épargne pour objectif',
      // Votre table expenses doit avoir une colonne 'objective_id' si vous voulez
      // lier l'expense à l'objectif. Je pars du principe qu'elle existe.
    });
  } on PostgrestException catch (e) {
    if (kDebugMode) {
      print(
        "Erreur PostgREST lors de l'enregistrement de l'expense : ${e.message}",
      );
    }
    throw Exception("Échec de l'enregistrement de la dépense d'épargne.");
  }

  // Étape 2 : Mettre à jour le montant épargné (saved_amount) dans l'objectif
  // Cette partie n'a pas changé (elle utilise la fonction PostgreSQL que vous devez créer)
  try {
    await supabase.rpc(
      'increment_objective_savings',
      params: {'p_objective_id': objectiveId, 'p_amount': amount},
    );
  } on PostgrestException catch (e) {
    if (kDebugMode) {
      print(
        "Erreur PostgREST lors de la mise à jour de l'objectif : ${e.message}",
      );
    }
    throw Exception(
      "Échec de la mise à jour du montant épargné de l'objectif.",
    );
  }
}
