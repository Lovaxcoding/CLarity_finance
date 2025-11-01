// Dans un fichier utilitaire, par exemple 'profile_checker.dart'

import 'package:myapp/core/supabase_client.dart';

/// Vérifie si le profil de l'utilisateur actuellement connecté est complet.
/// Retourne `true` si les données obligatoires (ex: first_name) sont présentes.
Future<bool> isProfileComplete() async {
  final user = supabase.auth.currentUser;
  
  if (user == null) {
    // Si l'utilisateur n'est pas connecté, le profil ne peut pas être "complet"
    return false;
  }

  try {
    // Requête pour récupérer le profil de l'utilisateur connecté.
    // On sélectionne uniquement la colonne "first_name" pour être rapide.
    final data = await supabase
        .from('profiles')
        .select('first_name')
        .eq('id', user.id)
        .single();
    
    // Le profil est complet si le 'first_name' n'est PAS null ou vide.
    final firstName = data['first_name'];
    return firstName != null && (firstName as String).isNotEmpty;

  } catch (e) {
    // En cas d'erreur (ex: le profil n'a pas été créé par le trigger), on considère qu'il est incomplet.
    return false;
  }
}