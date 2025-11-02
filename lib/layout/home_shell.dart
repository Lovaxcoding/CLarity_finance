import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  // Définition des routes de la barre de navigation (MODIFIÉ : 'cards' remplacé par 'objectives')
  static const List<String> _routes = [
    '/dashboard',
    '/savings',
    '/expense_entry', // Item central 'Ajouter'
    '/objectives', // NOUVELLE ROUTE : Objectifs
    '/settings',
  ];

  // Définition des items de la barre de navigation (MODIFIÉ : 'Cards' remplacé par 'Objectifs')
  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Accueil'),
    BottomNavigationBarItem(
      icon: Icon(Icons.account_balance_wallet_rounded),
      label: 'Épargne',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.add_circle_rounded, size: 30),
      label: 'Ajouter',
    ), // Icône centrale plus grande
    BottomNavigationBarItem(
      icon: Icon(Icons.flag_rounded), // Icône suggérée pour les objectifs
      label: 'Objectifs',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Compte'),
  ];

  // Fonction pour déterminer l'index initial basé sur la route actuelle
  int _getCurrentIndex(String location) {
    // La méthode startsWith est robuste pour les routes avec sous-chemins (ex: /dashboard/details)
    final index = _routes.indexWhere((route) => location.startsWith(route));
    // Retourne l'index trouvé ou 0 (Accueil) par défaut
    return index >= 0 ? index : 0;
  }

  void _onItemTapped(int index) {
    final currentRoute = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.uri.toString();

    // Optimisation : Si la route correspondante est déjà active, on ne navigue pas.
    if (currentRoute.startsWith(_routes[index])) return;

    // Navigue vers la nouvelle route
    // On utilise `go` pour remplacer la vue actuelle et ne pas empiler l'historique de navigation.
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Lire la route actuelle pour déterminer l'index sélectionné
    final location = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.uri.toString();
    final selectedIndex = _getCurrentIndex(location);

    // Définition des couleurs
    final selectedColor = theme.colorScheme.primary; // Violet
    final unselectedColor = isDarkMode
        ? Colors.grey.shade400
        : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      // Le corps de l'application est le widget enfant (page) actuel de GoRouter
      body: SafeArea(child: widget.child),

      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: selectedIndex,
        onTap: _onItemTapped,

        // --- Amélioration de l'UX et du Style ---
        type:
            BottomNavigationBarType.fixed, // Empêche l'animation de glissement
        backgroundColor: theme.colorScheme.background,
        elevation: 10,

        // Couleurs
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,

        // Taille et style du texte
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 10),

        // Style spécial pour l'icône centrale 'Ajouter' (index 2)
        selectedIconTheme: IconThemeData(
          color: selectedColor,
          // L'icône 'Ajouter' (index 2) a une taille plus grande
          size: selectedIndex == 2 ? 30 : 24,
        ),
        unselectedIconTheme: IconThemeData(
          // L'icône 'Ajouter' est toujours colorée même si elle n'est pas sélectionnée
          color: selectedIndex == 2 ? selectedColor : unselectedColor,
          size: selectedIndex == 2 ? 30 : 24,
        ),
      ),
    );
  }
}
