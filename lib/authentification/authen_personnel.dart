import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          const SnackBar(
            content: Text('Connexion réussie !'),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 3),
          ),
        );
        print('connexion reussie');
      }
    } on AuthApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nom d\'utilisateur ou mot de passe incorrect !'),
            backgroundColor: Color(0xFFC62828),
            duration: Duration(seconds: 3),
          ),
        );
      }
      print('Erreur Supabase: ${e.message}');
    } catch (e) {
      // Gestion de l'erreur de connexion internet ou base de données inaccessible (ajouté)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Erreur de connexion : Veuillez vérifier votre connexion internet.',
            ),
            backgroundColor: Color(0xFFC62828),
            duration: Duration(seconds: 3),
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
                        const Text(
                          'Hopital de district de Manjo',
                          textAlign: TextAlign
                              .center, // S'assurer que le texte est centré
                          style: TextStyle(
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
                                const Text(
                                  "Connexion du Personnel",
                                  style: TextStyle(
                                    fontSize: 25,
                                    color: Color(0xFF1976D2),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 60),
                                TextFormField(
                                  controller: email,
                                  decoration: InputDecoration(
                                    labelText: "Nom d'utilisateur",
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
                                      return 'Veuillez entrer votre nom d\'utilisateur';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 30),
                                TextFormField(
                                  controller: password,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Mot de passe',
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
                                      return 'Veuillez entrer votre mot de passe';
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
                                        : const Text(
                                            'Se Connecter',
                                            style: TextStyle(
                                              fontSize: 17,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: () {
                                    context.go('/Authen_Patient');
                                  },
                                  child: const Text(
                                    'Connexion Patient',
                                    style: TextStyle(
                                      color: Color(0xFF5E35B1),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
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
}
