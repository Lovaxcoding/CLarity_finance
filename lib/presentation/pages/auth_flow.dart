import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/supabase_client.dart';
import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentStep = 0;
  bool _acceptedTerms = false;
  bool _isLoading = false;

  // controllers moved to fields so they are not recreated each build
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
      );
    } else {
      // Ancien code: context.go('/');
      // NOUVEAU : Appeler la fonction de connexion Supabase
      _signIn();
    }
  }

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Veuillez remplir l\'e-mail et le mot de passe.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔑 Appel à l'API de connexion Supabase
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Si la réponse contient une session valide
      if (response.session != null) {
        _showSnackBar('Connexion réussie ! Redirection...');
        // Supabase gère le stockage local sécurisé de la session automatiquement !
        // Redirection vers la page d'accueil (la route '/' dans votre cas)
        if (mounted) context.go('/');
      } else {
        // Cela ne devrait normalement pas arriver avec signInWithPassword,
        // car les erreurs sont généralement lancées comme des exceptions.
        _showSnackBar(
          'Erreur de connexion : Aucune session retournée.',
          isError: true,
        );
      }
    } on AuthException catch (e) {
      // 🛑 Gestion des erreurs spécifiques à l'authentification (e.g. mauvais mot de passe)
      _showSnackBar('Erreur : ${e.message}', isError: true);
    } catch (e) {
      // ⚠️ Gestion des autres erreurs (e.g. problème réseau)
      _showSnackBar('Une erreur inattendue est survenue.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Fonction utilitaire pour les messages ---
  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Colors.red.shade600
              : const Color(0xFF8B5CF6), // Couleur principale
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator (modernized)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: AnimatedProgressDots(currentIndex: _currentStep, count: 3),
            ),

            // 3D Page transitions
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      // Safely read page value with fallbacks
                      double pageValue = 0.0;
                      if (_pageController.hasClients &&
                          _pageController.position.haveDimensions &&
                          _pageController.page != null) {
                        pageValue = _pageController.page!;
                      } else {
                        // no dimensions yet -> use currentStep as fallback
                        pageValue = _currentStep.toDouble();
                      }

                      final double diff = pageValue - index;
                      final double absDiff = diff.abs();

                      // scale effect clamped
                      final double scale = (1 - (absDiff * 0.3)).clamp(
                        0.8,
                        1.0,
                      );
                      // rotation angle based on difference
                      final double angle = diff * (math.pi / 8);

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0015)
                          ..rotateY(angle)
                          ..scale(scale),
                        child: Opacity(
                          opacity: (1 - absDiff).clamp(0.0, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: _buildStep(index, theme),
                  );
                },
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: (_currentStep == 1 && !_acceptedTerms) || _isLoading
                    ? null
                    : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        _currentStep < 2 ? 'Continuer' : 'Se connecter',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int index, ThemeData theme) {
    switch (index) {
      case 0:
        return _buildWelcomeStep(theme);
      case 1:
        return _buildTermsStep(theme);
      default:
        return _buildLoginStep(theme);
    }
  }

  // --- STEP 1 : Bienvenue ---
  Widget _buildWelcomeStep(ThemeData theme) {
    return _AnimatedParallax(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wallet_rounded,
              size: 100,
              color: '#8B5CF6'.toLowerCase() == '#8b5cf6'
                  ? const Color(0xFF8B5CF6)
                  : theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              "Bienvenue dans Clarity Finance",
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Gérez vos dépenses et vos budgets intelligemment. "
              "Une nouvelle expérience de contrôle financier moderne.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- STEP 2 : Conditions ---
  Widget _buildTermsStep(ThemeData theme) {
    return _AnimatedParallax(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              "Conditions d’utilisation",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  "En utilisant SmartExpense, vous acceptez nos conditions générales "
                  "et notre politique de confidentialité. Nous nous engageons à protéger vos données "
                  "et à améliorer continuellement votre expérience.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: _acceptedTerms,
                  onChanged: (val) =>
                      setState(() => _acceptedTerms = val ?? false),
                ),
                const Flexible(
                  child: Text("J’accepte les conditions d’utilisation"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- STEP 3 : Connexion ---
  // --- STEP 3 : Connexion (MODIFIÉE) ---
  Widget _buildLoginStep(ThemeData theme) {
    return _AnimatedParallax(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Connexion",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // ... (Champs Email et Mot de passe) ...
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "Adresse e-mail",
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Mot de passe",
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Bouton "Mot de passe oublié ?"
            TextButton(
              onPressed: () {},
              child: const Text("Mot de passe oublié ?"),
            ),

            // NOUVEAU : Bouton pour l'inscription
            const SizedBox(height: 10),
            TextButton(
              // --- C'EST LA REDIRECTION VERS /REGISTER ---
              onPressed: () => context.go('/register'),
              // ------------------------------------------
              child: Text(
                "Pas de compte ? S'inscrire ici",
                style: TextStyle(
                  color: theme
                      .colorScheme
                      .primary, // Utiliser la couleur principale
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// --- Classe utilitaire pour l'effet de parallaxe douce ---
class _AnimatedParallax extends StatefulWidget {
  final Widget child;
  const _AnimatedParallax({required this.child});

  @override
  State<_AnimatedParallax> createState() => _AnimatedParallaxState();
}

class _AnimatedParallaxState extends State<_AnimatedParallax>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _offset = Tween<double>(
      begin: -4,
      end: 4,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _offset.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// --- Indicateur moderne de progression des étapes ---
class AnimatedProgressDots extends StatelessWidget {
  final int currentIndex;
  final int count;

  const AnimatedProgressDots({
    super.key,
    required this.currentIndex,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          height: 8,
          width: isActive ? 26 : 10,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withOpacity(0.25),
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
        );
      }),
    );
  }
}
