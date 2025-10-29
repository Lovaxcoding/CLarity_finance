import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/core/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Utilisation de GoogleFonts comme demandé
        title: Text('Paramètres', style: GoogleFonts.lato(
          // Assure un bon contraste en mode sombre/clair
          color: Theme.of(context).colorScheme.onSurface, 
        )),
        backgroundColor: Colors.transparent, // Pour un look moderne
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          // Section Thème (avec Dropdown pour le choix)
          _buildSectionHeader(context, 'Personnalisation'),
          _buildThemeSection(context),
          const Divider(height: 30),

          // Section Compte (avec Supabase Auth ici plus tard)
          _buildSectionHeader(context, 'Compte'),
          _buildAccountSection(context),
          // Option déconnexion
          _buildLogoutButton(context),
          const Divider(height: 30),

          // Section À Propos
          _buildSectionHeader(context, 'À Propos'),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  // Widget utilitaire pour les titres de section
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  Widget _buildThemeSection(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.palette),
        title: const Text('Mode Thème'),
        trailing: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return DropdownButton<ThemeMode>(
              value: themeProvider.themeMode,
              // Cache l'indicateur par défaut pour un look plus propre
              underline: Container(), 
              items: const [
                DropdownMenuItem(child: Text('Clair'), value: ThemeMode.light),
                DropdownMenuItem(child: Text('Sombre'), value: ThemeMode.dark),
                DropdownMenuItem(child: Text('Système'), value: ThemeMode.system),
              ],
              onChanged: (ThemeMode? newMode) {
                if (newMode != null) {
                  themeProvider.setThemeMode(newMode);
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person),
        title: const Text('Gérer mon Compte'),
        subtitle: const Text('Modifier le profil, l\'e-mail et le mot de passe'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // TODO: Naviguer vers une page de gestion de compte (GoRouter)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Navigation vers la gestion de compte...'))
          );
        },
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextButton.icon(
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text(
          'Se Déconnecter',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          // TODO: Implémenter la déconnexion Supabase
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Déconnexion en cours...'))
          );
        },
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('À Propos de l\'application'),
        subtitle: const Text('Version, licences, et informations légales'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Affiche la boîte de dialogue d'information standard de Flutter
          showAboutDialog(
            context: context,
            applicationName: 'Smart Expense Tracker',
            applicationVersion: '1.0.0 (Beta)',
            applicationLegalese: '© 2025 Smart Expense Tracker',
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Text('Développé avec Flutter et Supabase.', 
                  style: Theme.of(context).textTheme.bodySmall
                ),
              ),
            ]
          );
        },
      ),
    );
  }
}