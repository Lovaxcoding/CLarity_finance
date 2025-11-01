import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/core/supabase_client.dart';
import 'package:myapp/core/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';


// Assurez-vous que ThemeProvider est bien importé de 'package:myapp/core/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Utilisation d'un thème plus doux pour le fond
    final backgroundColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[900]
        : Colors.grey[50];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Paramètres',
          style: GoogleFonts.lato(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Aligner le titre à gauche pour un style moderne
        centerTitle: false,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          // Section Thème (Personnalisation)
          _buildSectionHeader(context, 'Personnalisation'),
          _buildThemeSection(context),
          const SizedBox(height: 20),

          // Section Compte
          _buildSectionHeader(context, 'Compte et Sécurité'),
          _buildAccountSection(context),
          // Option déconnexion
          _buildLogoutButton(context),
          const SizedBox(height: 20),

          // Section Informations
          _buildSectionHeader(context, 'Informations'),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  // Widget utilitaire pour les titres de section
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
          color: Theme.of(context).colorScheme.secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Utilitaire pour un style de carte unifié
  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return Card(
      elevation: 1, // Ombre légère pour le style moderne
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? Theme.of(context).colorScheme.primary,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing:
            trailing ??
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      ),
    );
  }

  // --- 1. Personnalisation ---
  Widget _buildThemeSection(BuildContext context) {
    return _buildSettingTile(
      context: context,
      icon: Icons.brightness_6,
      title: 'Mode Thème',
      trailing: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return DropdownButton<ThemeMode>(
            value: themeProvider.themeMode,
            underline: Container(),
            onChanged: (ThemeMode? newMode) {
              if (newMode != null) {
                themeProvider.setThemeMode(newMode);
              }
            },
            items: const [
              DropdownMenuItem(child: Text('Clair'), value: ThemeMode.light),
              DropdownMenuItem(child: Text('Sombre'), value: ThemeMode.dark),
              DropdownMenuItem(child: Text('Système'), value: ThemeMode.system),
            ],
          );
        },
      ),
    );
  }

  // --- 2. Compte ---
  Widget _buildAccountSection(BuildContext context) {
    return _buildSettingTile(
      context: context,
      icon: Icons.account_circle,
      title: 'Gérer mon Compte',
      subtitle:
          'Modifier les informations de profil, l\'e-mail et le mot de passe',
      onTap: () {
        // TODO: Mettez ici votre route GoRouter pour la gestion de profil
        context.push('/profile-management');
      },
    );
  }

  // --- 🎯 Déconnexion (Fonctionnalité implémentée) ---
  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: _buildSettingTile(
        context: context,
        icon: Icons.logout,
        title: 'Se Déconnecter',
        iconColor: Colors.red,
        // Trailing vide pour ne pas avoir de flèche
        trailing: const SizedBox.shrink(),
        onTap: () async {
          // Affiche une boîte de dialogue de confirmation (Bonne pratique)
          final shouldLogout =
              await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content: const Text(
                    'Êtes-vous sûr de vouloir vous déconnecter ?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Oui, se déconnecter'),
                    ),
                  ],
                ),
              ) ??
              false;

          if (shouldLogout) {
            try {
              // 1. Appel de la déconnexion Supabase
              await supabase.auth.signOut();

              // 2. Redirection vers l'écran d'authentification
              // Utiliser go pour nettoyer la pile de navigation
              context.go('/auth');

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vous êtes déconnecté.')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur lors de la déconnexion : $e')),
              );
            }
          }
        },
      ),
    );
  }

  // --- 3. À Propos ---
  Widget _buildAboutSection(BuildContext context) {
    return _buildSettingTile(
      context: context,
      icon: Icons.info_outline,
      title: 'À Propos de l\'application',
      subtitle: 'Version, licences, et informations légales',
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
              child: Text(
                'Développé avec Flutter et Supabase.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        );
      },
    );
  }
}
