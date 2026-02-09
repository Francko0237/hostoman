# Système de Validation Dynamique

Ce document explique comment utiliser le système de validation dynamique pour les formulaires de l'application Hostoman.

## 📋 Vue d'ensemble

Le système de validation a été conçu pour être **réutilisable**, **configurable** et **maintenable**. Au lieu de coder en dur les validateurs dans chaque champ, nous utilisons maintenant une approche centralisée.

## 🏗️ Architecture

### 1. **Classe `Validators`**
Contient tous les validateurs réutilisables de base :

```dart
// Validateur simple requis
Validators.required()

// Validateur d'âge avec plage personnalisable
Validators.age(min: 1, max: 120)

// Validateur de température
Validators.temperature(min: 32.0, max: 43.0)

// Validateur de poids
Validators.poids(min: 1.0, max: 350.0)

// Et bien d'autres...
```

### 2. **Classe `PatientFormConfig`**
Configuration centralisée pour tous les champs du formulaire patient :

```dart
// Au lieu de :
validator: (v) {
  if (v == null || v.trim().isEmpty) return 'Veuillez entrer le nom complet.';
  if (v.trim().length < 3) return 'Le nom doit faire au moins 3 caractères.';
  return null;
}

// Utilisez :
validator: PatientFormConfig.nomComplet.validator
```

## 🚀 Utilisation

### Exemple 1 : Champ simple
```dart
_buildTextFormField(
  controller: nom_completController,
  label: 'Nom Complet *',
  hint: 'Ex: Yamga Mokube Francko Daniel',
  icon: Icons.person,
  validator: PatientFormConfig.nomComplet.validator,
)
```

### Exemple 2 : Validateur personnalisé
```dart
// Créer un nouveau validateur dans PatientFormConfig
static FieldValidator get email => FieldValidator(
  fieldName: 'Email',
  validator: Validators.email(),
);

// Utiliser dans le formulaire
_buildTextFormField(
  controller: emailController,
  label: 'Email *',
  validator: PatientFormConfig.email.validator,
)
```

### Exemple 3 : Validateur avec paramètres personnalisés
```dart
// Dans PatientFormConfig
static FieldValidator get ageEnfant => FieldValidator(
  fieldName: 'Âge Enfant',
  validator: Validators.age(min: 0, max: 18),
);
```

### Exemple 4 : Combinaison de validateurs
```dart
// Valider plusieurs conditions
validator: Validators.combine([
  Validators.required(),
  Validators.minLength(5),
  Validators.pattern(
    pattern: r'^[a-zA-Z\s]+$',
    errorMessage: 'Lettres uniquement',
  ),
])
```

### Exemple 5 : Validateur conditionnel
```dart
validator: Validators.conditional(
  condition: () => _typeServiceSelectionne == 'Consultation',
  validator: Validators.required(),
)
```

## 📚 Validateurs disponibles

| Validateur | Description | Exemple |
|------------|-------------|---------|
| `required()` | Champ obligatoire | `Validators.required()` |
| `nomComplet()` | Nom avec longueur min | `Validators.nomComplet(minLength: 3)` |
| `age()` | Âge avec plage | `Validators.age(min: 1, max: 120)` |
| `temperature()` | Température avec plage | `Validators.temperature(min: 32.0, max: 43.0)` |
| `poids()` | Poids avec plage | `Validators.poids(min: 1.0, max: 350.0)` |
| `tensionSystolique()` | Tension systolique | `Validators.tensionSystolique(min: 50, max: 300)` |
| `tensionDiastolique()` | Tension diastolique | `Validators.tensionDiastolique(min: 30, max: 200)` |
| `telephone()` | Téléphone avec options | `Validators.telephone(minLength: 9)` |
| `email()` | Email valide | `Validators.email()` |
| `intRange()` | Nombre entier avec plage | `Validators.intRange(min: 0, max: 100)` |
| `doubleRange()` | Nombre décimal avec plage | `Validators.doubleRange(min: 0.0, max: 100.0)` |
| `minLength()` | Longueur minimale | `Validators.minLength(5)` |
| `maxLength()` | Longueur maximale | `Validators.maxLength(50)` |
| `pattern()` | Regex personnalisé | `Validators.pattern(pattern: r'^\d+$', errorMessage: 'Chiffres uniquement')` |
| `combine()` | Combiner plusieurs validateurs | `Validators.combine([...])` |
| `conditional()` | Validation conditionnelle | `Validators.conditional(condition: () => true, validator: ...)` |

## ✨ Avantages

### 1. **Réutilisabilité**
- Un validateur écrit une fois, utilisé partout
- Pas de duplication de code

### 2. **Maintenabilité**
- Modification centralisée
- Changez une fois, effet partout

### 3. **Lisibilité**
```dart
// Avant (difficile à lire)
validator: (v) {
  if (v == null || v.trim().isEmpty) return 'Requis';
  final cleanValue = v.trim().replaceAll(RegExp(r'[^\d.,]'), '');
  if (cleanValue.isEmpty) return 'Chiffres uniquement';
  final temp = double.tryParse(cleanValue.replaceAll(',', '.'));
  if (temp == null) return 'Invalide';
  if (temp < 32 || temp > 43) return '32-43°C';
  return null;
}

// Après (clair et concis)
validator: PatientFormConfig.temperature.validator
```

### 4. **Flexibilité**
- Paramètres configurables
- Validateurs combinables
- Validations conditionnelles

### 5. **Testabilité**
- Facile à tester unitairement
- Validateurs isolés

## 🔧 Personnalisation

### Ajouter un nouveau validateur global

1. Ajoutez la méthode dans la classe `Validators` :
```dart
static String? Function(String?) codePostal() {
  return (String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Requis';
    }
    if (!RegExp(r'^\d{5}$').hasMatch(value)) {
      return 'Code postal invalide (5 chiffres)';
    }
    return null;
  };
}
```

2. Ajoutez la configuration dans `PatientFormConfig` :
```dart
static FieldValidator get codePostal => FieldValidator(
  fieldName: 'Code Postal',
  validator: Validators.codePostal(),
);
```

3. Utilisez-le dans votre formulaire :
```dart
validator: PatientFormConfig.codePostal.validator
```

## 🎯 Bonnes pratiques

1. **Toujours utiliser `PatientFormConfig`** pour les champs du formulaire patient
2. **Créer des validateurs réutilisables** dans la classe `Validators`
3. **Paramétrer les validateurs** plutôt que de les dupliquer
4. **Combiner les validateurs** pour des validations complexes
5. **Documenter les validateurs personnalisés**

## 📝 Exemples d'utilisation avancée

### Validation d'un numéro de téléphone camerounais
```dart
static FieldValidator get telephoneCameroun => FieldValidator(
  fieldName: 'Téléphone',
  validator: Validators.combine([
    Validators.required(),
    Validators.pattern(
      pattern: r'^6[0-9]{8}$',
      errorMessage: 'Format: 6XXXXXXXX',
    ),
  ]),
);
```

### Validation d'un email professionnel
```dart
static FieldValidator get emailProfessionnel => FieldValidator(
  fieldName: 'Email Professionnel',
  validator: Validators.combine([
    Validators.required(),
    Validators.email(),
    Validators.pattern(
      pattern: r'^[a-zA-Z0-9._%+-]+@(company\.com|enterprise\.org)$',
      errorMessage: 'Email professionnel uniquement',
    ),
  ]),
);
```

### Validation conditionnelle basée sur un autre champ
```dart
validator: Validators.conditional(
  condition: () => _typePatient == 'Enfant',
  validator: Validators.age(min: 0, max: 18),
)
```

## 🔍 Débogage

Si un validateur ne fonctionne pas comme prévu :

1. Vérifiez que le validateur est bien importé
2. Vérifiez les paramètres passés au validateur
3. Testez le validateur isolément
4. Vérifiez les messages d'erreur retournés

## 📦 Structure des fichiers

```
lib/accueil/nouveau_patient/
├── nouveau_patient.dart      # Formulaire principal
├── validators.dart           # Système de validation
├── service.dart             # Services métier
└── README_VALIDATORS.md     # Cette documentation
```

## 🚀 Migration

Pour migrer un ancien formulaire vers ce système :

1. Importez `validators.dart`
2. Remplacez les validateurs inline par `PatientFormConfig.xxx.validator`
3. Si un validateur n'existe pas, créez-le dans `Validators`
4. Testez le formulaire

---

**Auteur:** Yamgai Mokube Franck Daniel  
**Date:** 2026-02-09  
**Version:** 1.0.0
