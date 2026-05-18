import 'package:flutter/material.dart';
import 'validators.dart';

/// Exemple d'utilisation du système de validation dynamique
///
/// Ce fichier montre comment utiliser et étendre le système de validation
/// pour d'autres formulaires de l'application.

class ExempleUtilisationValidateurs extends StatefulWidget {
  const ExempleUtilisationValidateurs({super.key});

  @override
  State<ExempleUtilisationValidateurs> createState() =>
      _ExempleUtilisationValidateursState();
}

class _ExempleUtilisationValidateursState
    extends State<ExempleUtilisationValidateurs> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _codePostalController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _telephoneController.dispose();
    _ageController.dispose();
    _codePostalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exemples de Validateurs')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Exemple 1 : Validateur simple requis
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'exemple@email.com',
                ),
                validator: Validators.email(),
              ),
              const SizedBox(height: 16),

              // Exemple 2 : Validateur de téléphone avec longueur
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  hintText: '670619582',
                ),
                keyboardType: TextInputType.phone,
                validator: Validators.telephone(minLength: 9, maxLength: 9),
              ),
              const SizedBox(height: 16),

              // Exemple 3 : Validateur d'âge personnalisé
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Âge (Enfant)',
                  hintText: '0-18 ans',
                ),
                keyboardType: TextInputType.number,
                validator: Validators.age(min: 0, max: 18),
              ),
              const SizedBox(height: 16),

              // Exemple 4 : Validateur avec regex personnalisé
              TextFormField(
                controller: _codePostalController,
                decoration: const InputDecoration(
                  labelText: 'Code Postal',
                  hintText: '12345',
                ),
                keyboardType: TextInputType.number,
                validator: Validators.pattern(
                  pattern: r'^\d{5}$',
                  errorMessage: 'Code postal invalide (5 chiffres)',
                ),
              ),
              const SizedBox(height: 16),

              // Exemple 5 : Combinaison de validateurs
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  hintText: 'Au moins 3 caractères, max 50',
                ),
                validator: Validators.combine([
                  Validators.required(customMessage: 'Le nom est requis'),
                  Validators.minLength(3),
                  Validators.maxLength(50),
                ]),
              ),
              const SizedBox(height: 16),

              // Exemple 6 : Validateur de plage de nombres décimaux
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Taille (m)',
                  hintText: '1.50 - 2.50',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.doubleRange(
                  min: 1.0,
                  max: 2.5,
                  unit: 'm',
                ),
              ),
              const SizedBox(height: 16),

              // Exemple 7 : Validateur de plage de nombres entiers
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: '0 - 20',
                ),
                keyboardType: TextInputType.number,
                validator: Validators.intRange(
                  min: 0,
                  max: 20,
                  customMessage: 'Note entre 0 et 20',
                ),
              ),
              const SizedBox(height: 32),

              // Bouton de validation
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Formulaire valide !'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Valider'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Exemple de configuration personnalisée pour un autre formulaire
///
/// Vous pouvez créer des configurations similaires à PatientFormConfig
/// pour d'autres formulaires de votre application.
class PersonnelFormConfig {
  /// Validateur pour l'email professionnel
  static FieldValidator get emailProfessionnel => FieldValidator(
    fieldName: 'Email Professionnel',
    validator: Validators.combine([Validators.required(), Validators.email()]),
  );

  /// Validateur pour le matricule
  static FieldValidator get matricule => FieldValidator(
    fieldName: 'Matricule',
    validator: Validators.combine([
      Validators.required(),
      Validators.pattern(
        pattern: r'^[A-Z]{2}\d{6}$',
        errorMessage: 'Format: XX123456',
      ),
    ]),
  );

  /// Validateur pour le salaire
  static FieldValidator get salaire => FieldValidator(
    fieldName: 'Salaire',
    validator: Validators.doubleRange(
      min: 50000.0,
      max: 10000000.0,
      unit: ' FCFA',
    ),
  );

  /// Validateur pour l'ancienneté
  static FieldValidator get anciennete => FieldValidator(
    fieldName: 'Ancienneté',
    validator: Validators.intRange(
      min: 0,
      max: 50,
      customMessage: 'Ancienneté entre 0 et 50 ans',
    ),
  );
}

/// Exemple de validateurs personnalisés spécifiques à votre domaine
class ValidateursMetier {
  /// Validateur pour un numéro de téléphone camerounais
  static String? Function(String?) telephoneCamerounais() {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Requis';
      }

      // Format: 6XXXXXXXX (9 chiffres commençant par 6)
      if (!RegExp(r'^6[0-9]{8}$').hasMatch(value)) {
        return 'Format invalide (6XXXXXXXX)';
      }

      return null;
    };
  }

  /// Validateur pour un numéro de sécurité sociale
  static String? Function(String?) numeroSecuriteSociale() {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Requis';
      }

      // Format: 1 23 45 67 890 123 45
      if (!RegExp(r'^\d{15}$').hasMatch(value.replaceAll(' ', ''))) {
        return 'Numéro de sécurité sociale invalide';
      }

      return null;
    };
  }

  /// Validateur pour un code diagnostic médical (CIM-10)
  static String? Function(String?) codeCIM10() {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Requis';
      }

      // Format: A00.0 (lettre + 2 chiffres + point + chiffre)
      if (!RegExp(r'^[A-Z]\d{2}\.\d$').hasMatch(value)) {
        return 'Format invalide (ex: A00.0)';
      }

      return null;
    };
  }

  /// Validateur pour un numéro de dossier médical
  static String? Function(String?) numeroDossierMedical() {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Requis';
      }

      // Format: DM-2024-00001
      if (!RegExp(r'^DM-\d{4}-\d{5}$').hasMatch(value)) {
        return 'Format invalide (DM-YYYY-XXXXX)';
      }

      return null;
    };
  }

  /// Validateur pour une date de naissance (pas dans le futur)
  static String? Function(String?) dateNaissance() {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Requis';
      }

      try {
        final date = DateTime.parse(value);
        final now = DateTime.now();

        if (date.isAfter(now)) {
          return 'La date ne peut pas être dans le futur';
        }

        // Vérifier que la personne n'a pas plus de 150 ans
        final age = now.difference(date).inDays ~/ 365;
        if (age > 150) {
          return 'Date invalide';
        }

        return null;
      } catch (e) {
        return 'Format de date invalide';
      }
    };
  }

  /// Validateur pour un groupe sanguin
  static String? Function(String?) groupeSanguin() {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Requis';
      }

      final groupesValides = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

      if (!groupesValides.contains(value.toUpperCase())) {
        return 'Groupe sanguin invalide';
      }

      return null;
    };
  }
}
