import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  // Initialisation à ThemeMode.system (par défaut)
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  // Méthode corrigée pour définir explicitement le mode de thème
  // C'est celle qui est appelée par le DropdownButton de la SettingsPage.
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      // Notifie tous les widgets (comme le MaterialApp) que l'état a changé.
      notifyListeners();
    }
  }

  // NOTE : La méthode 'toggleTheme' n'est plus nécessaire si vous utilisez 'setThemeMode'.
  // Si vous vouliez une méthode pour basculer rapidement, elle pourrait ressembler à ceci :
  // void toggleLightDark() {
  //   _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  //   notifyListeners();
  // }
}
