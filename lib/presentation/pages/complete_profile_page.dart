import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/core/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _primaryColor = Color.fromARGB(
  255,
  104,
  20,
  156,
); // Couleur principale

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  File? _avatarFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // --- UTILS ---

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: message.contains('Erreur')
              ? Colors.red.shade600
              : _primaryColor,
        ),
      );
    }
  }

  // --- LOGIQUE DE TÉLÉCHARGEMENT D'IMAGE ---

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _avatarFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadAvatar(String userId) async {
    if (_avatarFile == null) return null;

    try {
      final fileExt = _avatarFile!.path.split('.').last;
      // Nom du fichier : ID utilisateur/timestamp.extension
      final fileName =
          '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Téléchargement sécurisé vers le bucket 'avatars'
      final response = await supabase.storage
          .from('avatars')
          .upload(
            fileName,
            _avatarFile!,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Récupérer l'URL publique
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      _showSnackBar('Erreur lors du téléchargement de la photo de profil.');
      debugPrint('Erreur d\'upload d\'avatar: $e');
      return null;
    }
  }

  // --- LOGIQUE CLÉ : INSERTION DU PROFIL ---

  Future<void> _handleProfileCompletion() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      _showSnackBar('Erreur d\'authentification. Veuillez vous reconnecter.');
      context.go('/auth');
      return;
    }

    if (_firstNameCtrl.text.isEmpty || _lastNameCtrl.text.isEmpty) {
      _showSnackBar('Erreur: Les champs Nom et Prénom sont obligatoires.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Téléchargement de la photo (avant l'insertion dans la DB)
      final avatarUrl = await _uploadAvatar(user.id);

      // 2. Créer l'entrée dans la table 'profiles'
      // 2. Mettre à jour l'entrée existante dans la table 'profiles'
      await supabase
          .from('profiles')
          .update({
            'first_name': _firstNameCtrl.text.trim(),
            'last_name': _lastNameCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim().isEmpty
                ? null
                : _phoneCtrl.text.trim(),
            'avatar_url': avatarUrl,
          })
          .eq('id', user.id); // <-- CRITIQUE : AJOUTER LE FILTRE PAR ID

      // Succès: Le profil est créé. Rediriger vers l'accueil.
      _showSnackBar('Profil créé avec succès ! Bienvenue.');
      context.go('/');
    } catch (e) {
      // En cas d'échec (ex: problème de connexion, RLS inattendu)
      _showSnackBar(
        'Erreur: Échec de la création du profil. Déconnexion automatique.',
      );
      debugPrint('Erreur de création de profil: $e');

      // Déconnecter l'utilisateur pour éviter un compte "fantôme" à moitié créé
      await supabase.auth.signOut();
      context.go('/auth');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- MISE EN PAGE (BUILD) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compléter votre profil'),
        automaticallyImplyLeading: false, // Empêche de revenir en arrière
        backgroundColor: _primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Finalisez votre inscription pour accéder à toutes les fonctionnalités.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Sélecteur d'Avatar
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  backgroundImage: _avatarFile != null
                      ? FileImage(_avatarFile!)
                      : null,
                  child: _avatarFile == null
                      ? Icon(Icons.camera_alt, size: 40, color: _primaryColor)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Champ Prénom
            TextFormField(
              controller: _firstNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Prénom *',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            // Champ Nom
            TextFormField(
              controller: _lastNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom *',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Champ Téléphone
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone (Optionnel)',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 40),

            // Bouton de Complétion
            ElevatedButton(
              onPressed: _isLoading ? null : _handleProfileCompletion,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Terminer et accéder à l\'application',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
