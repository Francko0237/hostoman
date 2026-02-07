import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Authen_Patient extends StatefulWidget {
  const Authen_Patient({super.key});

  @override
  State<Authen_Patient> createState() => _Authen_PatientState();
}

class _Authen_PatientState extends State<Authen_Patient> {
  final _formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  String nom_utilisateur = '';

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> Authen() async {
    // Valider le formulaire avant de continuer
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String nomUtilisateur = "${email.text}@gmail.com";
    String motDePasse = password.text;

    try {
      final Reponse = await Supabase.instance.client.auth.signInWithPassword(
        email: nomUtilisateur,
        password: motDePasse,
      );
      if (Reponse.user != null) {
        print('connexion reussie');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connexion réussie !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // Ajouter ici la navigation pour les patients si nécessaire
        }
      }
    } on AuthApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nom Complet ou numero de telephone incorrect !'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      print('Erreur Supabase: ${e.message}');
    } catch (e) {
      print(nomUtilisateur);
      print(motDePasse);
      print('$e ');
    }
        }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFB8F1F1),
        // --- DÉBUT DES MODIFICATIONS RESPONSIVE ---
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Définir la largeur maximale pour le contenu du formulaire
            const double maxWidth = 450;

            // Déterminer la largeur à utiliser (limite ou largeur de l'écran)
            final double contentWidth = constraints.maxWidth > maxWidth ? maxWidth : constraints.maxWidth;

            return Center(
                child: SizedBox(
                  width: contentWidth, // Applique la largeur maximale
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
                                colors: [
                                  Color(0xFF6200EA), // Violet
                                  Color(0xFF00BCD4), // Cyan
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.26), // Meilleure pratique
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
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
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 45),
                          Form(
                            key: _formKey,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              // Utilisation de EdgeInsets.symmetric pour la marge latérale
                              margin: const EdgeInsets.symmetric(horizontal: 20),
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
                                    "Connexion des Patients",
                                    style: TextStyle(
                                      fontSize: 25,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 60),
                                  TextFormField(
                                    controller: email,
                                    decoration: InputDecoration(
                                      labelText: "Nom Complet",
                                      labelStyle: const TextStyle(color: Color(0xFF757575)),
                                      prefixIcon: const Icon(Icons.person, color: Color(0xFF00BCD4)),
                                      filled: true,
                                      fillColor: const Color(0xFFF5F5F5),
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
                                        borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 2),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.red, width: 2),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer votre nom Complet';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 30),
                                  TextFormField(
                                    controller: password,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: 'Numero de Téléphone',
                                      labelStyle: const TextStyle(color: Color(0xFF757575)),
                                      prefixIcon: const Icon(Icons.phone, color: Color(0xFF00BCD4)),
                                      filled: true,
                                      fillColor: const Color(0xFFF5F5F5),
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
                                        borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 2),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.red, width: 2),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer votre Numero de téléphone';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 30),
                                  SizedBox(
                                    width: double.infinity, // Force le bouton à prendre toute la largeur du formulaire
                                    child: ElevatedButton(
                                      onPressed: Authen,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF32B9D1),
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        elevation: 3,
                                      ),
                                      child: const Text(
                                        'Se Connecter',
                                        style: TextStyle(fontSize: 17, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton(
                                    onPressed: () {
                                      context.go('/Authen_Personnel');
                                    },
                                    child: const Text(
                                      'Connexion Personnel',
                                      style: TextStyle(
                                        color: Colors.deepPurple,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ),
                );
            },
        ),
        // --- FIN DES MODIFICATIONS RESPONSIVE ---
      ),
    );
  }
}
