import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

class Authen_Personnel extends StatefulWidget {
  const Authen_Personnel({super.key}); // Ajout de la clé (bonne pratique)

  @override
  State<Authen_Personnel> createState() => _Authen_PersonnelState();
}

class _Authen_PersonnelState extends State<Authen_Personnel> {
  final _formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  String nom_utilisateur = '';
  bool _obscurePassword = true;

  // Variable pour gérer l'état du bouton (ajoutée)
  bool _isLoading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  // Fonction d'authentification
  Future<void> Authen() async {
    // Valider le formulaire avant de continuer
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Désactiver le bouton (ajouté)
    setState(() {
      _isLoading = true;
    });

    String nomUtilisateur = "${email.text.trim()}@gmail.com";
    String motDePasse = password.text.trim();
    print("debut de l'athentification");
    try {
      final Reponse = await Supabase.instance.client.auth.signInWithPassword(
        email: nomUtilisateur,
        password: motDePasse,
      );
      print("fin de l'authentification");
      if (Reponse.user != null) {
        final userId = Reponse.user!.id;
        print(userId);
        final userData = await Supabase.instance.client
            .from('Personnel_hopital')
            .select('Specialite')
            .eq('id_personnel', userId)
            .single();
        final role = userData['Specialite'];

        //Redirection vers les pages correspondante
        if (role == 'Major Accueil') {
          context.go('/Dashboard_Accueil');
        } else if (role == 'Directeur') {
          context.go('/Dashboard_Directeur');
        } else if (role == 'Caissier') {
          context.go('/Dashboard_Caisse');
        } else if (role == 'Médecin Généraliste') {
          context.go('/Dashboard_Medecin');
        } else if (role == 'Laborantin') {
          context.go('/Dashboard_Laboratoire');
        } else {
          print('erreur de role');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth_login_success'.tr()),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 3),
          ),
        );
        print('connexion reussie');
      }
    } on AuthApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth_personnel_invalid'.tr()),
            backgroundColor: const Color(0xFFC62828),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print('Erreur Supabase: ${e.message}');
    } catch (e) {
      // Gestion de l'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'auth_error_generic'.tr(namedArgs: {'msg': e.toString()}),
            ),
            backgroundColor: const Color(0xFFC62828),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print(nomUtilisateur);
      print(motDePasse);
      print('$e ');
    } finally {
      // Réactivation du bouton après la tentative, que ce soit un succès ou un échec (ajouté)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    // Sur PC (>= 700px) : layout 2 colonnes premium
    if (w >= 700) return _buildPcLoginLayout();

    // Mobile : layout centré existant
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          ),
        ),

        // **DÉBUT DE L'AJUSTEMENT RESPONSIVE**
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Définir la largeur maximale pour le contenu du formulaire
            const double maxWidth = 450;

            // Déterminer la largeur à utiliser (limite ou largeur de l'écran)
            final double contentWidth = constraints.maxWidth > maxWidth
                ? maxWidth
                : constraints.maxWidth;

            return Center(
              child: SizedBox(
                width: contentWidth, // Applique la largeur maximale
                // Le reste du contenu est centré à l'intérieur de ce Container
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  0.12,
                                ), // Utilisation de Colors.black.withOpacity()
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'auth_hospital_name'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            color: Color(0xFF0D47A1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 45),
                        Form(
                          key: _formKey,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ), // Utiliser horizontal pour garder la marge latérale
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'auth_personnel_title'.tr(),
                                  style: const TextStyle(
                                    fontSize: 25,
                                    color: Color(0xFF1976D2),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 60),
                                TextFormField(
                                  controller: email,
                                  decoration: InputDecoration(
                                    labelText: 'auth_username'.tr(),
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF757575),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.person,
                                      color: Color(0xFF1976D2),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF5F5F5),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF1976D2),
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFC62828),
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFC62828),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'auth_username_required'.tr();
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 30),
                                TextFormField(
                                  controller: password,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'auth_password'.tr(),
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF757575),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock,
                                      color: Color(0xFF1976D2),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: const Color(0xFF757575),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF5F5F5),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF1976D2),
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFC62828),
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFC62828),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'auth_password_required'.tr();
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 30),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    // Désactivation du bouton si _isLoading est vrai
                                    onPressed: _isLoading ? null : Authen,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1976D2),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 3,
                                    ),
                                    // Affichage d'un indicateur de chargement si nécessaire
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            'auth_login_button'.tr(),
                                            style: const TextStyle(
                                              fontSize: 17,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        // **FIN DE L'AJUSTEMENT RESPONSIVE**
      ),
    );
  }

  // ===== VERSION PC LAYOUT 2-COLONNES =====
  Widget _buildPcLoginLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Panneau gauche — Branding hôpital
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0D47A1),
                    Color(0xFF1565C0),
                    Color(0xFF1976D2),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.local_hospital,
                                size: 64,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'auth_hospital_name_pc'.tr(),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 48,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const SizedBox(height: 48),
                      _infoBadge(Icons.security, 'auth_confidentiality'.tr()),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Panneau droit — Formulaire
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFFF8FAFF),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 40,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'auth_personnel_title_short'.tr(),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'auth_personnel_subtitle'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 36),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _pcField(
                                controller: email,
                                label: 'auth_username'.tr(),
                                icon: Icons.person_outline,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'auth_field_required'.tr()
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              _pcField(
                                controller: password,
                                label: 'auth_password'.tr(),
                                icon: Icons.lock_outline,
                                obscure: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: const Color(0xFF9E9E9E),
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'auth_field_required'.tr()
                                    : null,
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : Authen,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1565C0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    shadowColor: const Color(
                                      0xFF1565C0,
                                    ).withOpacity(0.4),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          'auth_login_button'.tr(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _pcField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1565C0), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }
}
