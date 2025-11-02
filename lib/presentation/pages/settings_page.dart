import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Note: Assurez-vous que 'supabase_client.dart' contient 'final supabase = Supabase.instance.client;'
import 'package:myapp/core/supabase_client.dart';
import 'package:myapp/core/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1. Standardisation du fond
    // Utilisation de theme.colorScheme.background comme demandé

    // --- Suppression de la navigation en bas ---
    // (Cette page est un simple Scaffold, elle n'inclut pas de BottomNavigationBar,
    // donc cette partie est déjà respectée.)
    // ------------------------------------------

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Paramètres',
          // Utilisation du style du thème pour une meilleure cohérence
          style: theme.textTheme.headlineLarge!.copyWith(
            fontWeight: FontWeight.w800, // Rendre le titre plus impactant
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(
          color: theme
              .colorScheme
              .onBackground, // Icônes claires ou sombres selon le thème
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          // Section Thème (Personnalisation)
          _buildSectionHeader(context, 'Personnalisation'),
          _buildThemeSection(context),

          // Séparateur léger pour une lecture aérée
          const SizedBox(height: 25),

          // Section Compte
          _buildSectionHeader(context, 'Compte et Sécurité'),
          _buildAccountSection(context),

          // Option déconnexion (avec un peu plus d'espace)
          const SizedBox(height: 10),
          _buildLogoutButton(context),

          const SizedBox(height: 25),

          // Section Informations
          _buildSectionHeader(context, 'Informations'),
          _buildAboutSection(context),
          const SizedBox(height: 40), // Espace en bas de la liste
        ],
      ),
    );
  }

  // Widget utilitaire pour les titres de section (Aéré et accentué)
  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 8.0),
      child: Text(
        title.toUpperCase(), // TITRES EN MAJUSCULES pour le look minimaliste
        style: theme.textTheme.labelLarge!.copyWith(
          // Utiliser la couleur d'accentuation ou une couleur moins dominante (Tertiary)
          color: theme.colorScheme.tertiary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Utilitaire pour un style de carte unifié (Plus plat et accentué)
  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);

    return Card(
      // 💡 Design minimaliste : Éléver seulement très légèrement
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Ajouter une légère bordure pour le style "carte" en mode sombre
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          // Utiliser iconColor si spécifié, sinon la couleur primaire/accentuée du thème
          color: iconColor ?? theme.colorScheme.primary,
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w600, // Texte plus gras pour l'emphase
          ),
        ),
        subtitle: subtitle != null
            ? Text(subtitle, style: theme.textTheme.bodySmall)
            : null,
        trailing:
            trailing ??
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
    );
  }

  // --- 1. Personnalisation ---
  Widget _buildThemeSection(BuildContext context) {
    // Rendre cette section plus "bouton" en utilisant le onTap
    return _buildSettingTile(
      context: context,
      icon: Icons.brightness_6,
      title: 'Mode Thème',
      // On retire l'action onTap sur la tuile principale car le Dropdown la gère déjà
      onTap: null,
      trailing: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return DropdownButton<ThemeMode>(
            value: themeProvider.themeMode,
            // Rendre le Dropdown invisible pour le look minimaliste
            underline: Container(),
            onChanged: (ThemeMode? newMode) {
              if (newMode != null) {
                themeProvider.setThemeMode(newMode);
              }
            },
            // Utiliser le même style de police que le reste de l'app
            style: Theme.of(context).textTheme.titleMedium,
            items: [
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
    return Column(
      children: [
        _buildSettingTile(
          context: context,
          icon: Icons.account_circle,
          title: 'Gérer mon Compte',
          subtitle:
              'Modifier les informations de profil, l\'e-mail et le mot de passe',
          onTap: () {
            context.push('/profile-management');
          },
        ),
        _buildSettingTile(
          context: context,
          icon: Icons.verified_user_outlined,
          title: 'Sécurité et Confidentialité',
          subtitle: 'Gérer les sessions actives et les autorisations',
          onTap: () {
            // TODO: Route pour la sécurité
            // context.push('/security');
          },
        ),
      ],
    );
  }

  // --- 🎯 Déconnexion (Bouton plus visible) ---
  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      // Plus de padding vertical pour séparer clairement l'action
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 4.0),
      child: SizedBox(
        height: 50,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.logout, color: Colors.red),
          label: Text(
            'Se Déconnecter',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            // Bordure rouge pour l'alerte
            side: const BorderSide(color: Colors.red, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () async {
            // Logic de déconnexion (inchangée, elle est déjà bien faite)
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
                        child: Text(
                          'Oui, se déconnecter',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
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
