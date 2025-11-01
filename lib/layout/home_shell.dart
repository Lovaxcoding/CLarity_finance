import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  // Définition des routes de la barre de navigation
  static const List<String> _routes = [
    '/dashboard',
    '/savings',
    '/expense_entry', // Item central 'Add'
    '/cards',
    '/settings',
  ];

  // Définition des items de la barre de navigation (simplifiée)
  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
    BottomNavigationBarItem(
      icon: Icon(Icons.account_balance_wallet_rounded),
      label: 'Savings',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.add_circle_rounded, size: 30),
      label: 'Add',
    ), // Icône centrale plus grande
    BottomNavigationBarItem(
      icon: Icon(Icons.credit_card_rounded),
      label: 'Cards',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Account'),
  ];

  // Fonction pour déterminer l'index initial basé sur la route actuelle
  int _getCurrentIndex(String location) {
    final index = _routes.indexWhere((route) => location.startsWith(route));
    return index >= 0 ? index : 0;
  }

  void _onItemTapped(int index) {
    final currentRoute = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.uri.toString();

    // Si la route est déjà active, ne rien faire
    if (currentRoute.startsWith(_routes[index])) return;

    // Navigue vers la nouvelle route
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

    // Ajustement des couleurs pour le mode sombre/clair et l'esthétique violette
    final selectedColor = theme.colorScheme.primary; // Violet
    final unselectedColor = isDarkMode
        ? Colors.grey.shade400
        : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(child: widget.child),

      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: selectedIndex,
        onTap: _onItemTapped,

        // --- Amélioration de l'UX et du Style ---
        type: BottomNavigationBarType
            .fixed, // Empêche le décalage lors de la sélection
        backgroundColor:
            theme.colorScheme.surface, // S'adapte au mode sombre/clair
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

        // Style spécial pour l'icône centrale 'Add' (index 2)
        selectedIconTheme: IconThemeData(
          color: selectedColor,
          size: selectedIndex == 2
              ? 30
              : 24, // Taille spéciale pour l'item 'Add'
        ),
        unselectedIconTheme: IconThemeData(
          color: selectedIndex == 2
              ? selectedColor
              : unselectedColor, // L'icône 'Add' est toujours en couleur primaire
          size: selectedIndex == 2 ? 30 : 24,
        ),
      ),
    );
  }
}
