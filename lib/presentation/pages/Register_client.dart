import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// --- INITIALISATION SUPABASE GLOBALE ---
// Assurez-vous que cette ligne est correcte et pointe vers votre client initialisé.
// Si 'supabase' est un getter ou une variable globale définie dans 'core/supabase_client.dart',
// le code actuel fonctionnera. Sinon, utilisez 'Supabase.instance.client'.

// ----------------------------------------

const int _totalSteps = 3;
const Color _primaryColor = Color(
  0xFF8B5CF6,
); // Couleur principale pour la cohérence

class RegisterClientPage extends StatefulWidget {
  const RegisterClientPage({super.key});

  @override
  State<RegisterClientPage> createState() => _RegisterClientPageState();
}

class _RegisterClientPageState extends State<RegisterClientPage> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentStep = 0;

  // Contrôleurs pour les champs
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  File? _avatarFile; // Pour stocker le fichier image sélectionné
  bool _isLoading = false;

  // ... (LOGIQUE DE NAVIGATION & SUPABASE inchangée - elle est correcte !) ...
  // (Inclus dans le code ci-dessous pour la complétude)

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Si on est à l'étape 0, on peut quitter le formulaire
      context.pop();
    }
  }

  void _nextStep() async {
    // Validation simple avant de passer à l'étape suivante
    if (_currentStep == 0 &&
        (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty)) {
      _showSnackBar('Veuillez entrer un email et un mot de passe.');
      return;
    }
    if (_currentStep == 1 &&
        (_firstNameCtrl.text.isEmpty || _lastNameCtrl.text.isEmpty)) {
      _showSnackBar('Veuillez entrer votre nom et prénom.');
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      // Transition vers l'étape suivante
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
      );
    } else {
      // Étape finale : Enregistrement de l'utilisateur
      await _handleRegistration();
    }
  }

  Future<void> _handleRegistration() async {
  setState(() => _isLoading = true);

  try {
    // 1. Inscription de l'utilisateur (Crée l'entrée dans auth.users et ENVOIE l'email de confirmation)
    final AuthResponse response = await supabase.auth.signUp(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );

    // *******************************************************************
    // L'inscription a toujours lieu, mais la session est souvent null
    // si la vérification d'email est requise. On s'arrête là !
    // *******************************************************************

    // 2. Tenter de télécharger l'avatar et mettre à jour le profil
    // ATTENTION : Si la confirmation est requise, l'utilisateur n'est pas encore authentifié, 
    // et donc les politiques RLS empêcheront l'UPLOAD de l'avatar et l'UPDATE du profil.
    // Pour l'instant, nous déplaçons cette logique dans un autre écran APRÈS la connexion.

    // 3. Succès : Informer l'utilisateur et rediriger
    _showSnackBar(
      'Inscription réussie ! Veuillez vérifier votre email pour activer votre compte. Vous serez redirigé vers la page de connexion.',
    );
    // On redirige toujours vers l'écran d'authentification après le sign-up avec confirmation
    if (mounted) context.go('/auth');
    
  } on AuthException catch (e) {
    _showSnackBar('Erreur d\'authentification : ${e.message}');
  } catch (e) {
    _showSnackBar(
      'Une erreur inattendue est survenue lors de l\'enregistrement.',
    );
    debugPrint('Erreur d\'inscription: $e');
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Utiliser la source `ImageSource.gallery` pour les plateformes mobiles/web
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        // Utilisation de la classe File pour pouvoir l'uploader
        _avatarFile = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
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
            // --- Indicateur d'étape (Ajout) ---
            Padding(
              padding: const EdgeInsets.only(
                top: 20.0,
                bottom: 20.0,
                left: 10,
                right: 10,
              ),
              child: Row(
                children: [
                  // Bouton de retour (seulement si possible de revenir en arrière)
                  if (_currentStep > 0)
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      onPressed: _previousStep,
                    )
                  else // Bouton pour quitter si on est à la première étape
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      onPressed: () => context.pop(),
                    ),

                  const Spacer(),
                  // Indicateur de progression centré
                  AnimatedProgressDots(
                    currentIndex: _currentStep,
                    count: _totalSteps,
                    primaryColor: _primaryColor,
                  ),
                  const Spacer(),
                  // Espace pour l'alignement (si pas de bouton de retour)
                  if (_currentStep <= 0)
                    const SizedBox(
                      width: 48,
                    ), // Taille du bouton pour centrer les points
                ],
              ),
            ),
            // ------------------------------------

            // Pages avec transition 3D
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _totalSteps,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double pageValue =
                          _pageController.hasClients &&
                              _pageController.page != null
                          ? _pageController.page!
                          : _currentStep.toDouble();
                      final double diff = pageValue - index;
                      final double absDiff = diff.abs();
                      final double scale = (1 - (absDiff * 0.3)).clamp(
                        0.8,
                        1.0,
                      );
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
                    child: _buildStep(index, theme, _primaryColor),
                  );
                },
              ),
            ),

            // Bouton Continuer/S'inscrire
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size(double.infinity, 52),
                  disabledBackgroundColor: _primaryColor.withOpacity(0.5),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        _currentStep < _totalSteps - 1
                            ? 'CONTINUER'
                            : 'S\'INSCRIRE',
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

  Widget _buildStep(int index, ThemeData theme, Color primaryColor) {
    switch (index) {
      case 0:
        return _buildCredentialsStep(theme);
      case 1:
        return _buildProfileStep(theme);
      default:
        return _buildAvatarStep(theme, primaryColor);
    }
  }

  // ÉTAPE 1 : Email et Mot de passe
  Widget _buildCredentialsStep(ThemeData theme) {
    return _RegistrationStepContainer(
      title: "1. Créez votre compte",
      description: "Utilisez votre adresse email pour l'authentification.",
      child: Column(
        children: [
          _AnimatedParallax(
            child: Icon(
              Icons.verified_user_rounded,
              size: 80,
              color: _primaryColor, // Couleur primaire
            ),
          ),
          const SizedBox(height: 32),
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
        ],
      ),
    );
  }

  // ... (buildProfileStep & buildAvatarStep restent inchangés) ...
  Widget _buildProfileStep(ThemeData theme) {
    return _RegistrationStepContainer(
      title: "2. Vos informations personnelles",
      description: "Ces informations aident au suivi de vos dépenses.",
      child: Column(
        children: [
          _AnimatedParallax(
            child: Icon(Icons.person_outline, size: 80, color: _primaryColor),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _firstNameCtrl,
                  decoration: InputDecoration(
                    hintText: "Prénom",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _lastNameCtrl,
                  decoration: InputDecoration(
                    hintText: "Nom",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: "Téléphone (Optionnel)",
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStep(ThemeData theme, Color primaryColor) {
    return _RegistrationStepContainer(
      title: "3. Photo de profil",
      description:
          "Ajoutez une photo pour personnaliser votre compte (Optionnel).",
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: primaryColor.withOpacity(0.1),
              backgroundImage: _avatarFile != null
                  ? FileImage(_avatarFile!)
                  : null,
              child: _avatarFile == null
                  ? Icon(Icons.camera_alt, size: 40, color: primaryColor)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.upload_file),
            label: Text(
              _avatarFile == null
                  ? "Sélectionner une image"
                  : "Changer l'image",
            ),
            style: TextButton.styleFrom(foregroundColor: primaryColor),
          ),
        ],
      ),
    );
  }
}

// --- CLASSE UTILITAIRE : Conteneur de Page ---
// NOTE : Le bouton de retour a été retiré ici car il est géré dans le build de RegisterClientPage
class _RegistrationStepContainer extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _RegistrationStepContainer({
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 28.0, right: 28.0, bottom: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 40),
          child,
        ],
      ),
    );
  }
}

// --- Les classes utilitaires _AnimatedParallax et AnimatedProgressDots sont correctes et restent inchangées ---

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

/// --- Indicateur moderne de progression des étapes (Corrigé) ---
class AnimatedProgressDots extends StatelessWidget {
  final int currentIndex;
  final int count;
  final Color primaryColor;

  const AnimatedProgressDots({
    super.key,
    required this.currentIndex,
    required this.count,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
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
            color: isActive ? primaryColor : primaryColor.withOpacity(0.25),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}
