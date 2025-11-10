import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/core/supabase_client.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  // --- Constante de couleur pour la simplicité du thème ---
  static const Color _primaryColor = Color(0xFF8B5CF6);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Veuillez saisir votre e-mail et votre mot de passe.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null && mounted) {
        _showSnackBar('Connexion réussie ! Redirection...');
        // Redirection vers '/', le GoRouter s'occupera de la vérification de profil
        context.go('/');
      }
    } on AuthException catch (e) {
      // Message d'erreur plus convivial en français
      String errorMessage = 'Erreur de connexion. Vérifiez vos identifiants.';
      if (e.message.contains('Invalid login credentials')) {
        errorMessage = 'E-mail ou mot de passe incorrect.';
      }
      _showSnackBar(' ${errorMessage}', isError: true);
    } catch (_) {
      _showSnackBar(' Une erreur inattendue est survenue.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade600 : _primaryColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Couleurs ajustées pour le thème
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final inputFillColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;

    return Scaffold(
      // Arrière-plan s'adapte au thème
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 80, 28, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Titres humanisés et thémés ---
              Text(
                "Bienvenue de retour ",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900, // Typographie plus forte
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Connectez-vous pour reprendre le contrôle de vos finances.",
                style: theme.textTheme.bodyLarge?.copyWith(color: hintColor),
              ),
              const SizedBox(height: 40),

              // --- Champ email ---
              _buildTextField(
                controller: _emailCtrl,
                hint: "Adresse e-mail",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                isDark: isDark,
                fillColor: inputFillColor,
              ),
              const SizedBox(height: 16),

              // --- Champ mot de passe ---
              _buildTextField(
                controller: _passCtrl,
                hint: "Mot de passe",
                icon: Icons.lock_outline,
                obscure: _obscure,
                isDark: isDark,
                fillColor: inputFillColor,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: hintColor,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),

              const SizedBox(height: 20),

              // --- Conditions d'utilisation (Francisé) ---
              Row(
                children: [
                  Checkbox(
                    value: true,
                    onChanged: null,
                    activeColor: _primaryColor,
                    checkColor: Colors.white,
                  ),
                  Flexible(
                    child: GestureDetector(
                      onTap: () {
                        /* Redirection vers les conditions */
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "J'accepte les ",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor.withOpacity(0.8),
                          ),
                          children: [
                            TextSpan(
                              text: "Conditions d'utilisation",
                              style: TextStyle(
                                color: _primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // --- Bouton de Connexion (Sign in) ---
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          "Se connecter",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 22),

              // --- Lien vers inscription (Francisé) ---
              Center(
                child: TextButton(
                  onPressed: () => context.go('/register'),
                  child: RichText(
                    text: TextSpan(
                      text: "Pas encore de compte ? ",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor.withOpacity(0.8),
                      ),
                      children: [
                        TextSpan(
                          text: "S'inscrire",
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- Séparateur et boutons sociaux ---
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget de champ de texte Thémé ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color fillColor,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    final hintColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final iconColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;

    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(icon, color: iconColor),
        suffixIcon: suffix,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryColor, width: 1.8),
        ),
      ),
    );
  }

  // --- Widget de bouton social Thémé ---
  Widget _socialButton(String assetPath, bool isDark) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Center(
        child: Image.asset(
          assetPath,
          width: 26,
          height: 26,
          // Appliquer un filtre d'inversion pour les icônes si en mode sombre (si les assets ne sont pas optimisés pour le mode sombre)
          color:
              isDark &&
                  (assetPath == 'assets/x.png' ||
                      assetPath == 'assets/apple.png')
              ? Colors.white
              : null,
          colorBlendMode:
              isDark &&
                  (assetPath == 'assets/x.png' ||
                      assetPath == 'assets/apple.png')
              ? BlendMode.srcIn
              : null,
        ),
      ),
    );
  }
}
