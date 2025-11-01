import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math; // Nécessaire pour les utilitaires de page !

// Renommer l'ancien AuthFlow en WelcomePage pour la clarté
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentStep = 0;
  bool _acceptedTerms = false;
  // PAS de _isLoading ici, car nous faisons seulement des transitions de page

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 1) { // On va seulement de 0 à 1 (Welcome -> Terms)
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
      );
    } else {
      // Étape finale : Rediriger vers la page de Connexion
      if (mounted) context.go('/auth'); // Rediriger vers la nouvelle LoginPage
    }
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
            // Indicateur de progression (sur 2 étapes maintenant)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: AnimatedProgressDots(currentIndex: _currentStep, count: 2),
            ),
            
            // Les étapes (Welcome et Terms)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 2, // Seulement 2 étapes maintenant
                itemBuilder: (context, index) {
                  // ... (Logique d'animation Transform 3D - Gardée pour l'effet) ...
                  double pageValue = 0.0;
                  if (_pageController.hasClients &&
                      _pageController.position.haveDimensions &&
                      _pageController.page != null) {
                    pageValue = _pageController.page!;
                  } else {
                    pageValue = _currentStep.toDouble();
                  }
                  final double diff = pageValue - index;
                  final double absDiff = diff.abs();
                  final double scale = (1 - (absDiff * 0.3)).clamp(0.8, 1.0);
                  final double angle = diff * (math.pi / 8);

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateY(angle)
                      ..scale(scale),
                    child: Opacity(
                      opacity: (1 - absDiff).clamp(0.0, 1.0),
                      child: index == 0 
                          ? _buildWelcomeStep(theme) 
                          : _buildTermsStep(theme),
                    ),
                  );
                },
              ),
            ),
            
            // Bouton Continuer
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                // Désactivé si on est sur la page des Termes sans avoir accepté
                onPressed: (_currentStep == 1 && !_acceptedTerms) 
                    ? null 
                    : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: Text(
                  _currentStep < 1 ? 'Démarrer' : 'Me connecter',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fonctions _buildWelcomeStep et _buildTermsStep de l'ancien AuthFlow (à déplacer ici)
  Widget _buildWelcomeStep(ThemeData theme) {
    // ... (Contenu de l'étape 0) ...
    return _AnimatedParallax(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wallet_rounded,
              size: 100,
              color: const Color(0xFF8B5CF6),
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
              "Gérez vos dépenses et vos budgets intelligemment. Une nouvelle expérience de contrôle financier moderne.",
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

  Widget _buildTermsStep(ThemeData theme) {
    // ... (Contenu de l'étape 1) ...
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
                  "En utilisant SmartExpense, vous acceptez nos conditions générales et notre politique de confidentialité. Nous nous engageons à protéger vos données et à améliorer continuellement votre expérience.",
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
}

// NOTE : Les classes utilitaires _AnimatedParallax et AnimatedProgressDots
// doivent être définies soit dans ce fichier, soit dans un fichier utilitaire séparé
// pour que WelcomePage puisse les utiliser.
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