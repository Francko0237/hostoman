import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hostoman/model_unifier.dart';
import 'service.dart';
import 'validators.dart';
import 'dart:ui';
import '../champs_config/accueil_champs_config_service.dart';
import '../../medecin/Consultation/champs_config/champ_config_model.dart';

// Map: valeur stockée en DB (en français) -> clé de traduction
// On garde la valeur en FR pour ne pas casser les données Supabase
const Map<String, String> _kMaritalLabels = {
  'Marié Monogame': 'np_marital_married_mono',
  'Concubinage': 'np_marital_concubinage',
  'Veuve': 'np_marital_widow',
  'Marié Polygame': 'np_marital_married_poly',
  'Célibataire': 'np_marital_single',
  'Divorcé': 'np_marital_divorced',
};
const Map<String, String> _kServiceLabels = {
  'Consultation': 'np_service_consultation',
  'Consultation prénatale CPN1': 'np_service_cpn1',
  'Rendez-vous': 'np_service_appointment',
};

/// ---------------------------
/// Variables globales (remises)
/// ---------------------------
final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

// Controllers globaux
final TextEditingController nom_completController = TextEditingController();
final TextEditingController age = TextEditingController();
final TextEditingController telephone = TextEditingController();
final TextEditingController adresse = TextEditingController();
final TextEditingController profession = TextEditingController();
final TextEditingController temperature = TextEditingController();
final TextEditingController poid = TextEditingController();
final TextEditingController test_VIH = TextEditingController();
final TextEditingController vaccination = TextEditingController();
final TextEditingController motif_consultation = TextEditingController();
final TextEditingController systolique = TextEditingController();
final TextEditingController diastolique = TextEditingController();

// Champs globaux simples
String? sexeTexte;
String? StatutMatrimonial = '';
String? sexe = '';
String? type_service = '';
String? _idMedecinSelectionne;

// Listes globales (valeurs stockées en DB en FR)
final List<String> _services = _kServiceLabels.keys.toList();
String? _typeServiceSelectionne;
List<Medecin> _medecins = [];

String? _value = '';
String? _statutMatrimonialSelectionne;
final List<String> _statutsMatrimoniaux = _kMaritalLabels.keys.toList();

// Couleurs
const Color npPrimaryColor = Color(0xFF1565C0);
const Color npAccentColor = Color(0xFF2196F3);
const Color npSuccessColor = Color(0xFF4CAF50);
const Color npErrorColor = Color(0xFFD32F2F);
const Color npPageBackgroundStart = Color(0xFF0D47A1);
const Color npPageBackgroundEnd = Color(0xFF1976D2);

/// ---------------------------
/// Widget Nouveau_Patient
/// ---------------------------
class Nouveau_Patient extends StatefulWidget {
  const Nouveau_Patient({super.key});

  @override
  State<Nouveau_Patient> createState() => _Nouveau_PatientState();
}

class _Nouveau_PatientState extends State<Nouveau_Patient> {
  final PatientService patientService = PatientService(
    Supabase.instance.client,
  );

  late final AccueilChampsConfigService _champsService;
  List<ChampConfig> _configs = [];
  bool _configsLoading = true;
  final Map<String, TextEditingController> _dynamicControllers = {};
  final Map<String, FocusNode> _dynamicFocusNodes = {};

  // FocusNodes pour le focus et défilement automatique lors de la validation
  final FocusNode _nomCompletFocusNode = FocusNode();
  final FocusNode _sexeFocusNode = FocusNode();
  final FocusNode _ageFocusNode = FocusNode();
  final FocusNode _telephoneFocusNode = FocusNode();
  final FocusNode _adresseFocusNode = FocusNode();
  final FocusNode _professionFocusNode = FocusNode();
  final FocusNode _statutMatrimonialFocusNode = FocusNode();
  final FocusNode _temperatureFocusNode = FocusNode();
  final FocusNode _poidsFocusNode = FocusNode();
  final FocusNode _systoliqueFocusNode = FocusNode();
  final FocusNode _diastoliqueFocusNode = FocusNode();
  final FocusNode _testHivFocusNode = FocusNode();
  final FocusNode _vaccinationFocusNode = FocusNode();
  final FocusNode _motifFocusNode = FocusNode();
  final FocusNode _serviceFocusNode = FocusNode();
  final FocusNode _medecinFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _champsService = AccueilChampsConfigService(Supabase.instance.client);
    _loadChampsConfig();
  }

  Future<void> _loadChampsConfig() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final data = await _champsService.getChampsConfig(uid);
      if (mounted) {
        setState(() {
          _configs = data;
          _configsLoading = false;
        });
        _initDynamicFields();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _configsLoading = false);
      }
    }
  }

  void _initDynamicFields() {
    for (final config in _configs) {
      if (!config.isDefault) {
        _dynamicControllers.putIfAbsent(config.cle, () => TextEditingController());
        _dynamicFocusNodes.putIfAbsent(config.cle, () => FocusNode());
      }
    }
  }

  void _focusAndScrollTo(FocusNode node) {
    node.requestFocus();
    if (node.context != null) {
      Scrollable.ensureVisible(
        node.context!,
        duration: const Duration(milliseconds: 300),
        alignment: 0.5,
      );
    }
  }

  void _focusOnFirstInvalidField() {
    for (final config in _configs) {
      String? Function(String?)? validator;
      TextEditingController? controller;
      FocusNode? focusNode;

      if (config.isDefault) {
        if (config.cle == 'nom_complet') {
          validator = PatientFormConfig.nomComplet.validator;
          controller = nom_completController;
          focusNode = _nomCompletFocusNode;
        } else if (config.cle == 'age') {
          validator = PatientFormConfig.age.validator;
          controller = age;
          focusNode = _ageFocusNode;
        } else if (config.cle == 'telephone') {
          validator = PatientFormConfig.telephone.validator;
          controller = telephone;
          focusNode = _telephoneFocusNode;
        } else if (config.cle == 'adresse') {
          validator = PatientFormConfig.adresse.validator;
          controller = adresse;
          focusNode = _adresseFocusNode;
        } else if (config.cle == 'profession') {
          validator = PatientFormConfig.profession.validator;
          controller = profession;
          focusNode = _professionFocusNode;
        } else if (config.cle == 'temperature') {
          validator = PatientFormConfig.temperature.validator;
          controller = temperature;
          focusNode = _temperatureFocusNode;
        } else if (config.cle == 'poids') {
          validator = PatientFormConfig.poids.validator;
          controller = poid;
          focusNode = _poidsFocusNode;
        } else if (config.cle == 'tension_systolique') {
          validator = PatientFormConfig.tensionSystolique.validator;
          controller = systolique;
          focusNode = _systoliqueFocusNode;
        } else if (config.cle == 'tension_diastolique') {
          validator = PatientFormConfig.tensionDiastolique.validator;
          controller = diastolique;
          focusNode = _diastoliqueFocusNode;
        } else if (config.cle == 'test_vih') {
          validator = PatientFormConfig.testVIH.validator;
          controller = test_VIH;
          focusNode = _testHivFocusNode;
        } else if (config.cle == 'vaccination') {
          validator = PatientFormConfig.vaccination.validator;
          controller = vaccination;
          focusNode = _vaccinationFocusNode;
        } else if (config.cle == 'motif_consultation') {
          validator = PatientFormConfig.motifConsultation.validator;
          controller = motif_consultation;
          focusNode = _motifFocusNode;
        }
      } else {
        controller = _dynamicControllers[config.cle];
        focusNode = _dynamicFocusNodes[config.cle];
        validator = (val) {
          if (config.obligatoire && (val == null || val.trim().isEmpty)) {
            return 'fiche_field_required'.tr();
          }
          if (config.type == 'numerique' && val != null && val.trim().isNotEmpty) {
            if (double.tryParse(val.trim()) == null) {
              return 'Veuillez saisir un nombre valide';
            }
          }
          return null;
        };
      }

      if (controller != null && validator != null && focusNode != null) {
        if (validator(controller.text) != null) {
          _focusAndScrollTo(focusNode);
          return;
        }
      }
    }

    if (_value == null || _value!.isEmpty) {
      _focusAndScrollTo(_sexeFocusNode);
      return;
    }
    if (_statutMatrimonialSelectionne == null) {
      _focusAndScrollTo(_statutMatrimonialFocusNode);
      return;
    }
    if (_typeServiceSelectionne == null) {
      _focusAndScrollTo(_serviceFocusNode);
      return;
    }
    if ((_typeServiceSelectionne == 'Consultation' ||
            _typeServiceSelectionne == 'Rendez-vous') &&
        _idMedecinSelectionne == null) {
      _focusAndScrollTo(_medecinFocusNode);
      return;
    }
  }

  @override
  void dispose() {
    _nomCompletFocusNode.dispose();
    _sexeFocusNode.dispose();
    _ageFocusNode.dispose();
    _telephoneFocusNode.dispose();
    _adresseFocusNode.dispose();
    _professionFocusNode.dispose();
    _statutMatrimonialFocusNode.dispose();
    _temperatureFocusNode.dispose();
    _poidsFocusNode.dispose();
    _systoliqueFocusNode.dispose();
    _diastoliqueFocusNode.dispose();
    _testHivFocusNode.dispose();
    _vaccinationFocusNode.dispose();
    _motifFocusNode.dispose();
    _serviceFocusNode.dispose();
    _medecinFocusNode.dispose();

    _dynamicControllers.forEach((_, c) => c.dispose());
    _dynamicFocusNodes.forEach((_, f) => f.dispose());

    super.dispose();
  }

  Future<void> _chargerMedecins() async {
    try {
      final response = await Supabase.instance.client
          .from('Personnel_hopital')
          .select('id_personnel, Nom, Prenom, Specialite')
          .eq('Specialite', 'Médecin Généraliste');

      setState(() {
        _medecins = (response as List).map((e) {
          final map = e as Map<String, dynamic>;
          return Medecin.fromMap({
            'id_personnel': map['id_personnel'],
            'Nom': map['Nom'],
            'Prenom': map['Prenom'],
            'Specialite': map['Specialite'],
          });
        }).toList();
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des médecins : $e');
      setState(() {
        _medecins = [];
      });
    }
  }

  void _showMessage(String message, {Color background = Colors.green}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              background == Colors.green ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: background,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildMedecinTile(Medecin med) {
    final isSelected = _idMedecinSelectionne == med.id_personnel;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? npAccentColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? npAccentColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        title: Text(
          '${med.nom} ${med.prenom}',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? npPrimaryColor : Colors.black87,
          ),
        ),
        subtitle: Text(
          med.specialite ?? 'np_doctor_specialty_unknown'.tr(),
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? npAccentColor : Colors.grey[600],
          ),
        ),
        value: med.id_personnel,
        groupValue: _idMedecinSelectionne,
        onChanged: (val) => setState(() => _idMedecinSelectionne = val),
        activeColor: npAccentColor,
      ),
    );
  }

  String _getEffectiveCategory(ChampConfig config) {
    if (config.categorie != null && config.categorie!.isNotEmpty) {
      return config.categorie!;
    }
    // Rétrocompatibilité intelligente : on classifie selon la clé
    final medicalKeys = {
      'temperature',
      'poids',
      'tension_systolique',
      'tension_diastolique',
      'test_vih',
      'vaccination',
      'motif_consultation'
    };
    if (medicalKeys.contains(config.cle)) {
      return 'medical';
    }
    return 'personnel';
  }

  Widget? _buildSingleConfiguredField(ChampConfig config) {
    if (config.cle == 'nom_complet') {
      return _buildTextFormField(
        controller: nom_completController,
        label: config.label,
        hint: 'np_full_name_hint'.tr(),
        icon: Icons.person,
        validator: PatientFormConfig.nomComplet.validator,
        focusNode: _nomCompletFocusNode,
      );
    } else if (config.cle == 'age') {
      return _buildTextFormField(
        controller: age,
        label: config.label,
        hint: 'np_age_hint'.tr(),
        icon: Icons.cake,
        keyboardType: TextInputType.number,
        validator: PatientFormConfig.age.validator,
        focusNode: _ageFocusNode,
      );
    } else if (config.cle == 'telephone') {
      return _buildTextFormField(
        controller: telephone,
        label: config.label,
        hint: 'np_phone_hint'.tr(),
        icon: Icons.phone,
        keyboardType: TextInputType.phone,
        prefixText: '+237 ',
        maxLength: 9,
        validator: PatientFormConfig.telephone.validator,
        focusNode: _telephoneFocusNode,
      );
    } else if (config.cle == 'adresse') {
      return _buildTextFormField(
        controller: adresse,
        label: config.label,
        hint: 'np_address_hint'.tr(),
        icon: Icons.house,
        validator: config.obligatoire 
            ? (val) => val == null || val.trim().isEmpty ? 'fiche_field_required'.tr() : null
            : PatientFormConfig.adresse.validator,
        focusNode: _adresseFocusNode,
      );
    } else if (config.cle == 'profession') {
      return _buildTextFormField(
        controller: profession,
        label: config.label,
        hint: 'np_profession_hint'.tr(),
        icon: Icons.work,
        validator: config.obligatoire 
            ? (val) => val == null || val.trim().isEmpty ? 'fiche_field_required'.tr() : null
            : PatientFormConfig.profession.validator,
        focusNode: _professionFocusNode,
      );
    } else if (config.cle == 'temperature') {
      return _buildTextFormField(
        controller: temperature,
        label: config.label,
        hint: '37.2',
        icon: Icons.thermostat,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: config.obligatoire 
            ? (val) {
                if (val == null || val.trim().isEmpty) return 'fiche_field_required'.tr();
                return PatientFormConfig.temperature.validator(val);
              }
            : PatientFormConfig.temperature.validator,
        focusNode: _temperatureFocusNode,
      );
    } else if (config.cle == 'poids') {
      return _buildTextFormField(
        controller: poid,
        label: config.label,
        hint: '70.5',
        icon: Icons.scale,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: config.obligatoire 
            ? (val) {
                if (val == null || val.trim().isEmpty) return 'fiche_field_required'.tr();
                return PatientFormConfig.poids.validator(val);
              }
            : PatientFormConfig.poids.validator,
        focusNode: _poidsFocusNode,
      );
    } else if (config.cle == 'tension_systolique') {
      return _buildTextFormField(
        controller: systolique,
        label: config.label,
        hint: '120',
        icon: Icons.monitor_heart_outlined,
        keyboardType: TextInputType.number,
        validator: config.obligatoire 
            ? (val) {
                if (val == null || val.trim().isEmpty) return 'fiche_field_required'.tr();
                return PatientFormConfig.tensionSystolique.validator(val);
              }
            : PatientFormConfig.tensionSystolique.validator,
        focusNode: _systoliqueFocusNode,
      );
    } else if (config.cle == 'tension_diastolique') {
      return _buildTextFormField(
        controller: diastolique,
        label: config.label,
        hint: '80',
        icon: Icons.monitor_heart_outlined,
        keyboardType: TextInputType.number,
        validator: config.obligatoire 
            ? (val) {
                if (val == null || val.trim().isEmpty) return 'fiche_field_required'.tr();
                return PatientFormConfig.tensionDiastolique.validator(val);
              }
            : PatientFormConfig.tensionDiastolique.validator,
        focusNode: _diastoliqueFocusNode,
      );
    } else if (config.cle == 'test_vih') {
      return _buildTextFormField(
        controller: test_VIH,
        label: config.label,
        icon: Icons.bloodtype,
        validator: config.obligatoire 
            ? (val) => val == null || val.trim().isEmpty ? 'fiche_field_required'.tr() : null
            : PatientFormConfig.testVIH.validator,
        focusNode: _testHivFocusNode,
      );
    } else if (config.cle == 'vaccination') {
      return _buildTextFormField(
        controller: vaccination,
        label: config.label,
        icon: Icons.vaccines,
        validator: config.obligatoire 
            ? (val) => val == null || val.trim().isEmpty ? 'fiche_field_required'.tr() : null
            : PatientFormConfig.vaccination.validator,
        focusNode: _vaccinationFocusNode,
      );
    } else if (config.cle == 'motif_consultation') {
      return _buildTextFormField(
        controller: motif_consultation,
        label: config.label,
        icon: Icons.medical_information,
        keyboardType: TextInputType.multiline,
        maxLines: config.hauteurLignes,
        validator: PatientFormConfig.motifConsultation.validator,
        focusNode: _motifFocusNode,
      );
    } else {
      // Champ custom
      final ctrl = _dynamicControllers[config.cle];
      final fn = _dynamicFocusNodes[config.cle];
      if (ctrl != null && fn != null) {
        return _buildTextFormField(
          controller: ctrl,
          label: config.label + (config.obligatoire ? ' *' : ''),
          icon: config.type == 'numerique' ? Icons.numbers : Icons.text_fields,
          keyboardType: config.type == 'numerique' ? TextInputType.number : TextInputType.text,
          maxLines: config.hauteurLignes,
          validator: (value) {
            if (config.obligatoire && (value == null || value.trim().isEmpty)) {
              return 'fiche_field_required'.tr();
            }
            if (config.type == 'numerique' && value != null && value.trim().isNotEmpty) {
              if (double.tryParse(value.trim()) == null) {
                return 'Veuillez saisir un nombre valide';
              }
            }
            return null;
          },
          focusNode: fn,
        );
      }
    }
    return null;
  }

  List<Widget> _buildDynamicPatientFields(String category) {
    if (_configsLoading) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator(color: npAccentColor)),
        )
      ];
    }

    final List<Widget> fields = [];
    final categoryConfigs = _configs.where((c) => _getEffectiveCategory(c) == category).toList();

    for (final config in categoryConfigs) {
      // Le Nom Complet est géré séparément tout en haut de la fiche
      if (config.cle == 'nom_complet') continue;

      final widget = _buildSingleConfiguredField(config);
      if (widget != null) {
        fields.add(widget);
        fields.add(const SizedBox(height: 16));
      }
    }
    
    if (fields.isNotEmpty) {
      fields.removeLast();
    }
    return fields;
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      _focusOnFirstInvalidField();
      return;
    }

    String? errorMessage;
    FocusNode? errorFocusNode;
    if (_value == null || _value!.isEmpty) {
      errorMessage = 'np_select_sex'.tr();
      errorFocusNode = _sexeFocusNode;
    } else if (_statutMatrimonialSelectionne == null) {
      errorMessage = 'np_select_marital'.tr();
      errorFocusNode = _statutMatrimonialFocusNode;
    } else if (_typeServiceSelectionne == null) {
      errorMessage = 'np_select_service'.tr();
      errorFocusNode = _serviceFocusNode;
    } else if ((_typeServiceSelectionne == 'Consultation' ||
            _typeServiceSelectionne == 'Rendez-vous') &&
        _idMedecinSelectionne == null) {
      errorMessage = 'np_select_doctor'.tr();
      errorFocusNode = _medecinFocusNode;
    }

    if (errorMessage != null) {
      _showMessage(errorMessage, background: npErrorColor);
      if (errorFocusNode != null) {
        _focusAndScrollTo(errorFocusNode);
      }
      return;
    }

    sexe = _value;
    StatutMatrimonial = _statutMatrimonialSelectionne;
    type_service = _typeServiceSelectionne;

    showDialog(
      context: context,
      barrierDismissible: false,
      // On réduit l'opacité de la barrière pour plus de douceur
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (_) => BackdropFilter(
        // Le flou rend l'apparition moins "violente" pour les yeux
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Center(
          child: Container(
            width: 180, // Largeur fixe pour un look plus compact
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9), // Légère transparence
              borderRadius: BorderRadius.circular(28), // Bords très arrondis
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Un loader plus fin et plus moderne
                SizedBox(
                  height: 45,
                  width: 45,
                  child: CircularProgressIndicator(
                    color: npPrimaryColor,
                    strokeWidth: 3, // Plus fin = plus élégant
                    strokeCap: StrokeCap.round, // Bords arrondis sur le trait
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'np_loading'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: npPrimaryColor.withOpacity(0.8),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    decoration:
                        TextDecoration.none, // Pour éviter les traits jaunes
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final Map<String, dynamic> champsSupplementaires = {};
    for (final config in _configs) {
      if (!config.isDefault) {
        champsSupplementaires[config.cle] = {
          'label': config.label,
          'valeur': _dynamicControllers[config.cle]?.text ?? '',
          'type': config.type,
        };
      }
    }

    try {
      final success = await patientService.patientSave(
        context: context,
        idMedecin: _idMedecinSelectionne,
        champsSupplementaires: champsSupplementaires,
      );

      Navigator.pop(context);

      if (!success) return;

      _showMessage('np_saved_success'.tr(), background: npSuccessColor);

      setState(() {
        _value = '';
        _statutMatrimonialSelectionne = null;
        _typeServiceSelectionne = null;
        _idMedecinSelectionne = null;
        _medecins = [];
      });

      nom_completController.clear();
      age.clear();
      telephone.clear();
      adresse.clear();
      profession.clear();
      temperature.clear();
      poid.clear();
      test_VIH.clear();
      vaccination.clear();
      motif_consultation.clear();
      systolique.clear();
      diastolique.clear();
      sexe = '';
      StatutMatrimonial = null;
      type_service = null;
      _dynamicControllers.forEach((_, c) => c.clear());
    } catch (e) {
      Navigator.pop(context);
      _showMessage(
        'np_error_generic'.tr(namedArgs: {'msg': e.toString()}),
        background: npErrorColor,
      );
    }
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    String? prefixText,
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        counterText: '',
        prefixStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: icon != null ? Icon(icon, color: npPrimaryColor) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: npAccentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: npErrorColor),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: npAccentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: npPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: npPageBackgroundStart,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: npPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.person_add, color: npPrimaryColor, size: 24),
            const SizedBox(width: 12),
            Text(
              '  ${'np_title'.tr()}',
              style: const TextStyle(
                color: npPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: !isDesktop,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [npPageBackgroundStart, npPageBackgroundEnd],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 900 : double.infinity,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 40 : (isTablet ? 24 : 16),
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 100,
                                height: 100,
                                color: npPrimaryColor.withOpacity(0.1),
                                child: Icon(
                                  Icons.local_hospital,
                                  size: 50,
                                  color: npPrimaryColor,
                                ),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: npAccentColor.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: npErrorColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'np_info_message'.tr(),
                              style: const TextStyle(
                                fontSize: 15,
                                color: npErrorColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
        Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Section Informations personnelles (Nom complet + Sexe + Champs personnels + Statut matrimonial)
                          _buildSectionCard(
                            title: 'np_section_personal'.tr(),
                            children: [
                              // 1. Nom complet en premier si configuré
                              ...() {
                                final nomConfig = _configs.where((c) => c.cle == 'nom_complet' && c.visible).toList();
                                if (nomConfig.isNotEmpty) {
                                  final w = _buildSingleConfiguredField(nomConfig.first);
                                  if (w != null) {
                                    return [w, const SizedBox(height: 16)];
                                  }
                                }
                                return <Widget>[];
                              }(),

                              // 2. Sexe
                              Text(
                                'np_sex'.tr(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Focus(
                                focusNode: _sexeFocusNode,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _value == 'Homme'
                                              ? npAccentColor.withOpacity(0.1)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _value == 'Homme'
                                                ? npAccentColor
                                                : Colors.grey.shade300,
                                            width: _value == 'Homme' ? 2 : 1,
                                          ),
                                        ),
                                        child: RadioListTile<String>(
                                          value: 'Homme',
                                          title: Text(
                                            'np_sex_male'.tr(),
                                            style: const TextStyle(fontSize: 15),
                                          ),
                                          groupValue: _value,
                                          onChanged: (v) =>
                                              setState(() => _value = v),
                                          activeColor: npAccentColor,
                                          dense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _value == 'Femme'
                                              ? npAccentColor.withOpacity(0.1)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _value == 'Femme'
                                                ? npAccentColor
                                                : Colors.grey.shade300,
                                            width: _value == 'Femme' ? 2 : 1,
                                          ),
                                        ),
                                        child: RadioListTile<String>(
                                          value: 'Femme',
                                          title: Text(
                                            'np_sex_female'.tr(),
                                            style: const TextStyle(fontSize: 15),
                                          ),
                                          groupValue: _value,
                                          onChanged: (v) =>
                                              setState(() => _value = v),
                                          activeColor: npAccentColor,
                                          dense: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 3. Autres champs personnels dynamiques
                              ..._buildDynamicPatientFields('personnel'),
                              
                              if (_configs.where((c) => _getEffectiveCategory(c) == 'personnel' && c.cle != 'nom_complet' && c.visible).isNotEmpty)
                                const SizedBox(height: 16),

                              Text(
                                'np_marital'.tr(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Focus(
                                focusNode: _statutMatrimonialFocusNode,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      dropdownColor: Colors.white,
                                      value: _statutMatrimonialSelectionne,
                                      isExpanded: true,
                                      hint: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text('np_marital_select'.tr()),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      items: _statutsMatrimoniaux
                                          .map(
                                            (s) => DropdownMenuItem(
                                              value: s,
                                              child: Text((_kMaritalLabels[s] ?? s).tr()),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) => setState(
                                        () => _statutMatrimonialSelectionne = v,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Section Données médicales (Champs médicaux dynamiques)
                          _buildSectionCard(
                            title: 'np_section_medical'.tr(),
                            children: _buildDynamicPatientFields('medical'),
                          ),

                          // Section Service
                          _buildSectionCard(
                            title: 'np_section_service'.tr(),
                            children: [
                              Text(
                                'np_service_type'.tr(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Focus(
                                focusNode: _serviceFocusNode,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      dropdownColor: Colors.white,
                                      value: _typeServiceSelectionne,
                                      isExpanded: true,
                                      hint: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Text('np_service_select'.tr()),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      items: _services
                                          .map(
                                            (s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(
                                                (_kServiceLabels[s] ?? s).tr(),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (service) async {
                                        setState(() {
                                          _typeServiceSelectionne = service;
                                          _idMedecinSelectionne = null;
                                          _medecins = [];
                                        });
                                        if (service == 'Consultation' ||
                                            service == 'Rendez-vous') {
                                          await _chargerMedecins();
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              if (_typeServiceSelectionne == 'Consultation' ||
                                  _typeServiceSelectionne == 'Rendez-vous') ...[
                                Focus(
                                  focusNode: _medecinFocusNode,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'np_doctor_responsible'.tr(),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      if (_medecins.isEmpty)
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.orange.shade200,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.warning_amber,
                                                color: Colors.orange.shade700,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'np_doctor_none'.tr(),
                                                  style: TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                    color:
                                                        Colors.orange.shade700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        ..._medecins.map(_buildMedecinTile),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Bouton Enregistrer
                          ElevatedButton(
                            onPressed: _onSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: npSuccessColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: npSuccessColor.withOpacity(0.4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save, size: 22),
                                const SizedBox(width: 12),
                                Text(
                                  'np_save_button'.tr(),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                          Center(
                            child: Text(
                              'acc_footer_copyright'.tr(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
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
    );
  }
}
