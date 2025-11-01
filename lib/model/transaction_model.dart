// transaction_model.dart (CORRIGÉ)

enum TransactionType { expense, income }

class Transaction {
  final double amount;
  final String
  title; // Ceci sera 'category' pour les dépenses et 'source' pour les revenus
  final DateTime date;
  final TransactionType type;

  Transaction({
    required this.amount,
    required this.title,
    required this.date,
    required this.type,
  });

  // Factory pour créer une transaction à partir d'une ligne de dépense
  // Utilise 'category' à la place de 'title'
  factory Transaction.fromExpenseJson(Map<String, dynamic> json) {
    return Transaction(
      amount: (json['amount'] as num).toDouble(),
      // UTILISATION DE 'category' ICI (qui doit être sélectionné dans la requête)
      title: json['category'] as String? ?? 'Dépense non catégorisée',
      date: DateTime.parse(json['created_at'] as String),
      type: TransactionType.expense,
    );
  }

  // Factory pour créer une transaction à partir d'une ligne de revenu
  // Utilise 'source' et le protège contre le null
  factory Transaction.fromIncomeJson(Map<String, dynamic> json) {
    return Transaction(
      amount: (json['amount'] as num).toDouble(),
      // UTILISATION DE 'source' ICI et protection contre le null
      title: json['source'] as String? ?? 'Revenu inconnu',
      date: DateTime.parse(json['created_at'] as String),
      type: TransactionType.income,
    );
  }
}
