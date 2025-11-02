class Objective {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final DateTime? targetDate;
  final bool isAchieved;
  final DateTime createdAt;
  final String? iconUrl;

  Objective({
    required this.id,
    required this.iconUrl,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    this.targetDate,
    required this.isAchieved,
    required this.createdAt,
  });

  // Factory pour créer un Objective à partir des données de Supabase (JSON)
  factory Objective.fromJson(Map<String, dynamic> json) {
    return Objective(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      iconUrl: json['icon_url'] as String?,
      // Conversion des types numériques
      targetAmount: (json['target_amount'] as num).toDouble(),
      savedAmount: (json['saved_amount'] as num).toDouble(),
      // Gestion de la date cible optionnelle
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
      isAchieved: json['is_achieved'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Méthode pour préparer les données pour l'insertion dans Supabase
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'target_amount': targetAmount,
      'saved_amount': savedAmount,
      // Formatage de la date pour Supabase
      'target_date': targetDate?.toIso8601String().split('T').first,
      'is_achieved': isAchieved,
      // 'created_at' n'est pas nécessaire car il est géré par défaut dans Supabase
      'icon_url': iconUrl,
    };
  }

  // Propriété calculée pour le pourcentage d'avancement
  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return savedAmount / targetAmount;
  }
}
