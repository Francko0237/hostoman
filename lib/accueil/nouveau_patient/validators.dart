/// Classe de configuration pour les validateurs de champs
class FieldValidator {
  final String? Function(String?) validator;
  final String fieldName;

  const FieldValidator({required this.validator, required this.fieldName});
}

/// Classe utilitaire contenant tous les validateurs réutilisables
class Validators {
  /// Validateur pour les champs requis simples
  static String? Function(String?) required({String? customMessage}) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return customMessage ?? 'Requis';
      }
      return null;
    };
  }

  /// Validateur pour le nom complet
  static String? Function(String?) nomComplet({int minLength = 3}) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Veuillez entrer le nom complet.';
      }
      if (value.trim().length < minLength) {
        return 'Le nom doit faire au moins $minLength caractères.';
      }
      return null;
    };
  }

  /// Validateur pour l'âge
  static String? Function(String?) age({int min = 1, int max = 120}) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Requis';
      }
      final n = int.tryParse(value);
      if (n == null) {
        return 'Invalide';
      }
      if (n < min || n > max) {
        return '$min-$max ans';
      }
      return null;
    };
  }

  /// Validateur pour la température
  static String? Function(String?) temperature({
    double min = 32.0,
    double max = 43.0,
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Requis';
      }
      final cleanValue = value.trim().replaceAll(RegExp(r'[^\d.,]'), '');
      if (cleanValue.isEmpty) {
        return 'Chiffres uniquement';
      }
      final temp = double.tryParse(cleanValue.replaceAll(',', '.'));
      if (temp == null) {
        return 'Invalide';
      }
      if (temp < min || temp > max) {
        return '$min-$max°C';
      }
      return null;
    };
  }

  /// Validateur pour le poids
  static String? Function(String?) poids({
    double min = 1.0,
    double max = 350.0,
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Requis';
      }
      final poidsVal = double.tryParse(value.replaceAll(',', '.'));
      if (poidsVal == null) {
        return 'Invalide';
      }
      if (poidsVal < min || poidsVal > max) {
        return '$min-${max}kg';
      }
      return null;
    };
  }

  /// Validateur pour la tension artérielle (systolique)
  static String? Function(String?) tensionSystolique({
    int min = 50,
    int max = 300,
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Requis';
      }
      final val = int.tryParse(value);
      if (val == null) {
        return 'Nombre';
      }
      if (val < min || val > max) {
        return '$min-$max';
      }
      return null;
    };
  }

  /// Validateur pour la tension artérielle (diastolique)
  static String? Function(String?) tensionDiastolique({
    int min = 30,
    int max = 200,
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Requis';
      }
      final val = int.tryParse(value);
      if (val == null) {
        return 'Nombre';
      }
      if (val < min || val > max) {
        return '$min-$max';
      }
      return null;
    };
  }

  /// Validateur pour les nombres entiers avec plage
  static String? Function(String?) intRange({
    required int min,
    required int max,
    String? customMessage,
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Requis';
      }
      final val = int.tryParse(value);
      if (val == null) {
        return 'Nombre invalide';
      }
      if (val < min || val > max) {
        return customMessage ?? '$min-$max';
      }
      return null;
    };
  }

  /// Validateur pour les nombres décimaux avec plage
  static String? Function(String?) doubleRange({
    required double min,
    required double max,
    String? customMessage,
    String? unit,
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Requis';
      }
      final val = double.tryParse(value.replaceAll(',', '.'));
      if (val == null) {
        return 'Nombre invalide';
      }
      if (val < min || val > max) {
        return customMessage ?? '$min-$max${unit ?? ''}';
      }
      return null;
    };
  }

  /// Validateur pour le téléphone
  static String? Function(String?) telephone({
    int? minLength,
    int? maxLength,
    String? pattern,
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Requis';
      }

      if (minLength != null && value.length < minLength) {
        return 'Minimum $minLength caractères';
      }

      if (maxLength != null && value.length > maxLength) {
        return 'Maximum $maxLength caractères';
      }

      if (pattern != null && !RegExp(pattern).hasMatch(value)) {
        return 'Format invalide';
      }

      return null;
    };
  }

  /// Validateur pour l'email
  static String? Function(String?) email() {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Requis';
      }

      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );

      if (!emailRegex.hasMatch(value)) {
        return 'Email invalide';
      }

      return null;
    };
  }

  /// Validateur combiné (permet de combiner plusieurs validateurs)
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) {
          return result;
        }
      }
      return null;
    };
  }

  /// Validateur conditionnel
  static String? Function(String?) conditional({
    required bool Function() condition,
    required String? Function(String?) validator,
  }) {
    return (String? value) {
      if (condition()) {
        return validator(value);
      }
      return null;
    };
  }

  /// Validateur pour la longueur minimale
  static String? Function(String?) minLength(int length) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Requis';
      }
      if (value.trim().length < length) {
        return 'Minimum $length caractères';
      }
      return null;
    };
  }

  /// Validateur pour la longueur maximale
  static String? Function(String?) maxLength(int length) {
    return (String? value) {
      if (value != null && value.length > length) {
        return 'Maximum $length caractères';
      }
      return null;
    };
  }

  /// Validateur pour les regex personnalisés
  static String? Function(String?) pattern({
    required String pattern,
    required String errorMessage,
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Requis';
      }
      if (!RegExp(pattern).hasMatch(value)) {
        return errorMessage;
      }
      return null;
    };
  }
}

/// Configuration des champs du formulaire patient
class PatientFormConfig {
  /// Configuration pour le nom complet
  static FieldValidator get nomComplet => FieldValidator(
    fieldName: 'Nom Complet',
    validator: Validators.nomComplet(minLength: 3),
  );

  /// Configuration pour l'âge
  static FieldValidator get age => FieldValidator(
    fieldName: 'Âge',
    validator: Validators.age(min: 1, max: 120),
  );

  /// Configuration pour le téléphone
  static FieldValidator get telephone =>
      FieldValidator(fieldName: 'Téléphone', validator: Validators.required());

  /// Configuration pour l'adresse
  static FieldValidator get adresse =>
      FieldValidator(fieldName: 'Adresse', validator: Validators.required());

  /// Configuration pour la profession
  static FieldValidator get profession =>
      FieldValidator(fieldName: 'Profession', validator: Validators.required());

  /// Configuration pour la température
  static FieldValidator get temperature => FieldValidator(
    fieldName: 'Température',
    validator: Validators.temperature(min: 32.0, max: 43.0),
  );

  /// Configuration pour le poids
  static FieldValidator get poids => FieldValidator(
    fieldName: 'Poids',
    validator: Validators.poids(min: 1.0, max: 350.0),
  );

  /// Configuration pour la tension systolique
  static FieldValidator get tensionSystolique => FieldValidator(
    fieldName: 'Tension Systolique',
    validator: Validators.tensionSystolique(min: 50, max: 300),
  );

  /// Configuration pour la tension diastolique
  static FieldValidator get tensionDiastolique => FieldValidator(
    fieldName: 'Tension Diastolique',
    validator: Validators.tensionDiastolique(min: 30, max: 200),
  );

  /// Configuration pour le test VIH
  static FieldValidator get testVIH =>
      FieldValidator(fieldName: 'Test VIH', validator: Validators.required());

  /// Configuration pour la vaccination
  static FieldValidator get vaccination => FieldValidator(
    fieldName: 'Vaccination',
    validator: Validators.required(),
  );

  /// Configuration pour le motif de consultation
  static FieldValidator get motifConsultation => FieldValidator(
    fieldName: 'Motif de Consultation',
    validator: Validators.required(),
  );
}
