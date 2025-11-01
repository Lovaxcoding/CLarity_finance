import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/presentation/pages/Welcome_Page.dart';
import 'package:myapp/presentation/pages/complete_profile_page.dart';
import 'package:myapp/presentation/pages/dashboard_page.dart';
import 'package:myapp/presentation/pages/expense_entry_page.dart';
import 'package:myapp/presentation/pages/budget_page.dart';
import 'package:myapp/presentation/pages/filter_page.dart';
import 'package:myapp/presentation/pages/income_entry_page.dart';
import 'package:myapp/presentation/pages/login_page.dart';
import 'package:myapp/presentation/pages/settings_page.dart';
import 'package:myapp/layout/home_shell.dart';
import 'package:myapp/presentation/pages/home_page.dart';
import 'package:myapp/presentation/pages/auth_flow.dart';
import 'package:myapp/presentation/pages/Register_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<bool> isProfileComplete() async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) {
    return true; // Si non connecté, l'utilisateur n'a pas à "compléter" (il sera redirigé vers /auth)
  }

  try {
    // Requête pour vérifier si le prénom est renseigné
    final response = await supabase
        .from('profiles')
        .select(
          'first_name',
        ) // Vérifiez une donnée essentielle, par exemple 'first_name'
        .eq('id', userId)
        .single();

    // Le profil est complet si 'first_name' existe et n'est pas NULL ou vide
    final firstName = response['first_name'];
    return firstName != null && (firstName as String).isNotEmpty;
  } on PostgrestException catch (e) {
    // PGRST116 (No rows found) signifie que le Trigger a peut-être échoué ou n'a pas été exécuté.
    // L'utilisateur doit absolument compléter le profil.
    if (e.code == 'PGRST116') {
      debugPrint(
        'Erreur PGRST116: Profil non trouvé. Redirection vers complétion.',
      );
      return false;
    }
    debugPrint('Erreur de vérification de complétion de profil: ${e.message}');
    return false;
  } catch (e) {
    debugPrint('Erreur inattendue lors de la vérification: $e');
    return false;
  }
}

Future<bool> hasProfile() async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) {
    return false; // Non connecté
  }

  try {
    // Tenter de lire l'enregistrement du profil
    final response = await supabase
        .from('profiles')
        .select('id') // On sélectionne juste l'ID, c'est plus rapide
        .eq('id', userId)
        .single()
        .limit(1);

    // Si la réponse contient une donnée, le profil existe
    return response.isNotEmpty;
  } on PostgrestException catch (e) {
    // Si aucune ligne n'est trouvée, Postgrest lève une erreur,
    // que nous considérons ici comme l'absence de profil.
    // D'autres erreurs devraient être loggées.
    if (e.code == 'PGRST116') {
      // Code d'erreur pour 'No rows found'
      return false;
    }
    // Gérer d'autres erreurs de base de données
    debugPrint('Erreur de vérification de profil: ${e.message}');
    return false;
  } catch (e) {
    debugPrint('Erreur inattendue lors de la vérification de profil: $e');
    return false;
  }
}

final router = GoRouter(
  initialLocation: '/welcome',
  routes: [
    // 1. Route d'Authentification (sans Shell)
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomePage()),
    GoRoute(path: '/auth', builder: (context, state) => const LoginPage()),

    // 2. Route d'Inscription (sans Shell - NON PROTÉGÉE)
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterClientPage(),
    ),
    GoRoute(
      path: '/complete-profile',
      builder: (context, state) =>
          const CompleteProfilePage(), // CRÉER CETTE PAGE
    ),
    // 3. ShellRoute pour l'Application principale (PROTÉGÉE)
    ShellRoute(
      builder: (context, state, child) => HomeShell(child: child),
      routes: [
        // La page d'accueil de l'application
        GoRoute(path: '/', builder: (context, state) => const HomePage()),

        // Routes internes qui utilisent le HomeShell (Dashboards, etc.)
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/savings',
          builder: (context, state) => const IncomeEntryPage(),
        ),
        GoRoute(
          path: '/expense_entry',
          builder: (context, state) => const ExpenseEntryPage(),
        ),
        GoRoute(
          path: '/budget',
          builder: (context, state) => const BudgetPage(),
        ),
        GoRoute(
          path: '/filter',
          builder: (context, state) => const FilterPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
  ],
  redirect: (context, state) async {
    final user = supabase.auth.currentUser;
    final isAuthenticated = user != null;

    final isWelcomeRoute = state.matchedLocation == '/welcome'; // NOUVEAU
    final isAuthRoute = state.matchedLocation == '/auth';
    final isRegisterRoute = state.matchedLocation == '/register';
    final isCompleteProfileRoute = state.matchedLocation == '/complete-profile';

    // --- NON CONNECTÉ ---
    if (!isAuthenticated) {
      // Autoriser l'accès aux pages d'intro, auth, register, ou gestion de lien (access_token)
      if (isWelcomeRoute ||
          isAuthRoute ||
          isRegisterRoute ||
          state.uri.queryParameters.containsKey('access_token')) {
        return null;
      }
      // Sinon, on renvoie à la page de bienvenue pour commencer le flux.
      return '/welcome';
    }

    // --- CONNECTÉ ---

    // 1. Si connecté, on n'a rien à faire sur /welcome, /auth ou /register
    if (isWelcomeRoute || isAuthRoute || isRegisterRoute) {
      return '/'; // Rediriger vers le début de l'app
    }

    // 2. Vérification de la complétion du profil (comme avant)
    final profileComplete = await isProfileComplete();

    if (!profileComplete) {
      // Si incomplet, on force la complétion (sauf si on y est déjà)
      if (!isCompleteProfileRoute) {
        return '/complete-profile';
      }
    } else {
      // Si complet, on ne peut plus rester sur la page de complétion
      if (isCompleteProfileRoute) {
        return '/';
      }
    }

    // Aucune redirection requise
    return null;
  },
  // Optionnel: Ajouter une gestion des erreurs 404
  errorBuilder: (context, state) => const Text('Page non trouvée'),
);
