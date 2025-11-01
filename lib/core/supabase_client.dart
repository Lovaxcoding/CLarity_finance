import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Définition de l'instance du client Supabase une seule fois
final supabase = Supabase.instance.client;

Future<bool> isProfileComplete() async {
  final user = supabase.auth.currentUser;
  if (user == null) return false;

  try {
    // Récupère la ligne de profil correspondant à l'utilisateur actuel
    final response = await supabase
        .from('profiles')
        .select('first_name, last_name') // Ne sélectionne que les champs importants
        .eq('id', user.id)
        .single();
        
    // Vérifie si les champs critiques sont non-nuls ou non-vides
    final firstName = response['first_name'];
    final lastName = response['last_name'];

    // Le profil est complet si les deux champs sont remplis
    return firstName != null && 
           firstName.toString().isNotEmpty && 
           lastName != null && 
           lastName.toString().isNotEmpty;

  } catch (e) {
    // En cas d'erreur de base de données (ex: table non trouvée), considérez le profil comme incomplet
    // pour forcer la redirection vers la page de complétion.
    debugPrint('Erreur lors de la vérification du profil: $e');
    return false; 
  }
}
