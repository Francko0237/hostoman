import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'fiche_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

// --- Page de Consultation (StatefulWidget) ---
class ConsultationPage extends StatefulWidget {
  final int idConsultation;
  const ConsultationPage({super.key, required this.idConsultation});

  @override
  State<ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage> {
  // 🔑 Clé globale pour gérer l'état et la validation du formulaire
  final _formKey = GlobalKey<FormState>();

  late final MedecinServices medecinService;
  String _patientName = '';
  bool _patientNameLoaded = false;

  // --- Contrôleurs ---
  final TextEditingController _antecedentsController = TextEditingController();
  final TextEditingController _signesSymptomesController =
      TextEditingController();
  final TextEditingController _diagnosticInitialController =
      TextEditingController();
  final TextEditingController _diagnosticFinalController =
      TextEditingController();
  final TextEditingController _traitementPrescritController =
      TextEditingController();
  final TextEditingController _rdvDateController = TextEditingController();
  final TextEditingController _rdvHeureController = TextEditingController();

  // --- Variables d'État du Formulaire ---
  String? _statutConsultation;
  String? _programmationRdv;
  DateTime? _selectedRdvDate;
  TimeOfDay? _selectedRdvTime;
  bool _showExamens = false;
  bool _showRdvDateTime = false;

  // État des examens (Chargés depuis la base de données)
  List<Map<String, dynamic>> _examens = [];
  bool _examensLoading = true;

  // --- Couleurs et Styles (Consolidés) ---
  final Color fieldBackgroundColor = const Color(0xFFF8F9FA);
  final Color fieldBorderColor = const Color(0xFFE0E0E0);
  final Color primaryPurple = const Color(0xFF6A5ACD);
  final Color primaryBlue = const Color(0xFF007BFF);
  final Color lightPurple = const Color(0xFF8A7DF0);

  @override
  void initState() {
    super.initState();
    medecinService = MedecinServices(Supabase.instance.client);
    _loadPatientName();
    _loadExamens();
  }

  @override
  void dispose() {
    _antecedentsController.dispose();
    _signesSymptomesController.dispose();
    _diagnosticInitialController.dispose();
    _diagnosticFinalController.dispose();
    _traitementPrescritController.dispose();
    _rdvDateController.dispose();
    _rdvHeureController.dispose();
    super.dispose();
  }

  // --- LOGIQUE DE CHARGEMENT ET D'AFFICHAGE ---

  Future<void> _loadPatientName() async {
    try {
      final data = await medecinService.infosPatient(widget.idConsultation);
      if (data.isNotEmpty) {
        final patient = data[0]['Patient'] as Map<String, dynamic>;
        final String nomComplet = (patient['nom_complet']?.toString() ?? '');
        if (mounted) {
          setState(() {
            _patientName = nomComplet;
            _patientNameLoaded = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _patientName = 'fiche_loading_error'.tr();
          _patientNameLoaded = true;
        });
      }
      print('Erreur de chargement du nom: $e');
    }
  }

  Future<void> _loadExamens() async {
    try {
      final examensData = await medecinService.getListeExamens();
      if (mounted) {
        setState(() {
          _examens = examensData.map((examen) {
            return {
              'id_examlist': examen['id_examlist'],
              'nom_examen': examen['nom_examen'],
              'prix_examen': examen['prix_examen'],
              'selected': false,
            };
          }).toList();
          _examensLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _examensLoading = false;
        });
      }
      print('Erreur de chargement des examens: $e');
    }
  }

  void _showPatientInfoModal(BuildContext context) {
    // ... (Logique inchangée pour le modal d'information patient)
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text('fiche_modal_title'.tr()),
          content: SingleChildScrollView(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: medecinService.infosPatient(widget.idConsultation),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'fiche_modal_load_error'.tr(
                        namedArgs: {'msg': '${snapshot.error}'},
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('fiche_modal_no_info'.tr()));
                }

                final consultationData = snapshot.data![0];
                final patient =
                    consultationData['Patient'] as Map<String, dynamic>;
                final parametresVitaux =
                    consultationData['Parametres_vitaux']
                        as Map<String, dynamic>? ??
                    {};

                final String nomComplet =
                    (patient['nom_complet']?.toString() ??
                    'fiche_value_na'.tr());
                final String sexe =
                    (patient['sexe']?.toString() ?? 'fiche_value_unknown'.tr());
                final String telephone =
                    (patient['telephone']?.toString() ??
                    'fiche_value_unknown'.tr());
                final String adresse =
                    (patient['adresse']?.toString() ??
                    'fiche_value_unknown'.tr());
                final int? age = patient['age'] as int?;
                final profesion =
                    patient['profession'] ?? 'fiche_value_unknown'.tr();
                final StatutMatrimonial = patient['statut_matrimonial'];
                final temperature = parametresVitaux['temperature'] ?? 0;
                final poid = parametresVitaux['poid'] ?? 0;
                final systolique = parametresVitaux['systolique'];
                final diastolique = parametresVitaux['diastolique'];
                final statutVih = parametresVitaux['statut_VIH'];
                final vaccination = parametresVitaux['vaccination'];
                final motif = parametresVitaux['motif_de_consultation'];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'fiche_modal_admin_section'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    Text(
                      'fiche_modal_full_name'.tr(
                        namedArgs: {'value': nomComplet},
                      ),
                    ),
                    Text('fiche_modal_sex'.tr(namedArgs: {'value': sexe})),
                    Text(
                      'fiche_modal_age'.tr(
                        namedArgs: {
                          'value':
                              age?.toString() ?? 'fiche_value_unknown'.tr(),
                        },
                      ),
                    ),
                    Text(
                      'fiche_modal_phone'.tr(namedArgs: {'value': telephone}),
                    ),
                    Text(
                      'fiche_modal_profession'.tr(
                        namedArgs: {'value': '$profesion'},
                      ),
                    ),
                    Text(
                      'fiche_modal_marital'.tr(
                        namedArgs: {'value': '$StatutMatrimonial'},
                      ),
                    ),
                    Text(
                      'fiche_modal_address'.tr(namedArgs: {'value': adresse}),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'fiche_modal_vitals_section'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    Text(
                      'fiche_modal_temperature'.tr(
                        namedArgs: {'value': '$temperature'},
                      ),
                    ),
                    Text(
                      'fiche_modal_tension'.tr(
                        namedArgs: {'value': '$systolique/$diastolique'},
                      ),
                    ),
                    Text(
                      'fiche_modal_weight'.tr(namedArgs: {'value': '$poid'}),
                    ),
                    Text(
                      'fiche_modal_hiv'.tr(namedArgs: {'value': '$statutVih'}),
                    ),
                    Text(
                      'fiche_modal_vaccination'.tr(
                        namedArgs: {'value': '$vaccination'},
                      ),
                    ),
                    Text(
                      'fiche_modal_motif'.tr(namedArgs: {'value': '$motif'}),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('fiche_modal_close'.tr()),
            ),
          ],
        );
      },
    );
  }

  // --- WIDGETS DE FORMULAIRE RÉUTILISABLES ---

  /// Construit un champ de texte stylisé avec validation (Utilise TextFormField)
  Widget _buildFormField({
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        // 🛑 Utilisation de TextFormField pour la validation
        controller: controller,
        minLines: 3,
        maxLines: 5,
        validator: validator, // 🛑 Ajout du validateur
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          errorStyle: const TextStyle(
            height: 0.5,
          ), // Réduit l'espace des messages d'erreur
          filled: true,
          fillColor: fieldBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: fieldBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primaryBlue.withOpacity(0.5)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Colors.red,
            ), // Mettre en évidence les erreurs
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
  }

  /// Construit une case à cocher pour un examen
  Widget _buildExamCheckbox({
    required Map<String, dynamic> examen,
    required int index,
  }) {
    return CheckboxListTile(
      title: Text(
        'fiche_exam_label'.tr(
          namedArgs: {
            'name': '${examen['nom_examen']}',
            'price': '${examen['prix_examen']}',
          },
        ),
        style: const TextStyle(fontSize: 14),
      ),
      value: examen['selected'] as bool,
      onChanged: (bool? newValue) {
        setState(() {
          _examens[index]['selected'] = newValue!;
        });
      },
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: primaryPurple,
    );
  }

  // --- FONCTION DE SOUMISSION AVEC VALIDATION ---

  Future<void> _finalizeConsultation() async {
    // 🛑 VALIDATION: Tente de valider tous les champs du formulaire
    if (!_formKey.currentState!.validate()) {
      // Si la validation échoue (champs obligatoires vides), arrêter l'exécution
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('fiche_form_validation_error'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 1. Collecte des examens prescrits
    final List<Map<String, dynamic>> examensPrescrits = _examens
        .where((examen) => examen['selected'] == true)
        .map(
          (examen) => {
            'nom': examen['nom_examen'],
            'prix': examen['prix_examen'],
          },
        )
        .toList();

    // 2. Calcul de la date et heure du RDV
    DateTime? finalRdvDate;
    if (_programmationRdv == 'programmer' &&
        _selectedRdvDate != null &&
        _selectedRdvTime != null) {
      finalRdvDate = DateTime(
        _selectedRdvDate!.year,
        _selectedRdvDate!.month,
        _selectedRdvDate!.day,
        _selectedRdvTime!.hour,
        _selectedRdvTime!.minute,
      );
    }

    // 3. Appel du service d'enregistrement
    try {
      await medecinService.saveConsultationData(
        idConsultation: widget.idConsultation,
        antecedents: _antecedentsController.text,
        signesSymptomes: _signesSymptomesController.text,
        diagnosticInitial: _diagnosticInitialController.text,
        statutConsultation: _statutConsultation ?? 'pas_examen',
        examensPrescrits: examensPrescrits,
        diagnosticFinal: _diagnosticFinalController.text,
        traitementPrescrit: _traitementPrescritController.text,
        programmationRdv: _programmationRdv == 'programmer'
            ? 'RDV_programmer'
            : null,
        rdvDate: finalRdvDate,
      );

      if (mounted) {
        // Utiliser context.go au lieu de context.push pour remplacer la route
        // Cela évite de revenir à la fiche de consultation lors du retour
        context.go('/Dashboard_Medecin/ConsultationList');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('fiche_save_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'fiche_db_error'.tr(namedArgs: {'msg': '${e.message}'}),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'fiche_unexpected_error'.tr(namedArgs: {'msg': '$e'}),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- WIDGETS DE CONSTRUCTION DE SECTION ---

  Widget _buildGeneralInfoSection() {
    // 🛑 VALIDATION : Les 3 champs principaux sont rendus obligatoires
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormField(
          hint: 'fiche_hint_antecedents'.tr(),
          controller: _antecedentsController,
          validator: (value) => value == null || value.isEmpty
              ? 'fiche_field_required'.tr()
              : null,
        ),
        _buildFormField(
          hint: 'fiche_hint_signs'.tr(),
          controller: _signesSymptomesController,
          validator: (value) => value == null || value.isEmpty
              ? 'fiche_field_required'.tr()
              : null,
        ),
        _buildFormField(
          hint: 'fiche_hint_diag_initial'.tr(),
          controller: _diagnosticInitialController,
          validator: (value) => value == null || value.isEmpty
              ? 'fiche_field_required'.tr()
              : null,
        ),
      ],
    );
  }

  Widget _buildExamStatusDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          hintStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: fieldBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: fieldBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primaryBlue.withOpacity(0.5)),
          ),
          errorStyle: const TextStyle(height: 0.5),
        ),
        hint: Text('fiche_dd_status_hint'.tr()),
        initialValue: _statutConsultation,
        validator: (value) =>
            value == null ? 'fiche_select_required'.tr() : null,
        items: [
          DropdownMenuItem(
            value: 'examen',
            child: Text('fiche_dd_status_exam'.tr()),
          ),
          DropdownMenuItem(
            value: 'pas_examen',
            child: Text('fiche_dd_status_no_exam'.tr()),
          ),
        ],
        onChanged: (String? newValue) {
          setState(() {
            _statutConsultation = newValue;
            _showExamens = (newValue == 'examen');
          });
        },
      ),
    );
  }

  Widget _buildFinalizationSection() {
    // 🛑 VALIDATION : Diagnostic et Traitement sont rendus obligatoires
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'fiche_finalization_section'.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        _buildFormField(
          hint: 'fiche_hint_diag_final'.tr(),
          controller: _diagnosticFinalController,
          validator: (value) => value == null || value.isEmpty
              ? 'fiche_field_required'.tr()
              : null,
        ),
        _buildFormField(
          hint: 'fiche_hint_treatment'.tr(),
          controller: _traitementPrescritController,
          validator: (value) => value == null || value.isEmpty
              ? 'fiche_field_required'.tr()
              : null,
        ),
      ],
    );
  }

  Widget _buildRdvDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          hintStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: fieldBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: fieldBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primaryBlue.withOpacity(0.5)),
          ),
          errorStyle: const TextStyle(height: 0.5),
        ),
        hint: Text('fiche_dd_rdv_hint'.tr()),
        initialValue: _programmationRdv,
        validator: (value) =>
            value == null ? 'fiche_select_required'.tr() : null,
        items: [
          DropdownMenuItem(
            value: 'programmer',
            child: Text('fiche_dd_rdv_yes'.tr()),
          ),
          DropdownMenuItem(
            value: 'pas_programmer',
            child: Text('fiche_dd_rdv_no'.tr()),
          ),
        ],
        onChanged: (String? newValue) {
          setState(() {
            _programmationRdv = newValue;
            _showRdvDateTime = (newValue == 'programmer');
            // Réinitialiser les champs de date/heure si on annule la programmation
            if (newValue == 'pas_programmer') {
              _selectedRdvDate = null;
              _selectedRdvTime = null;
              _rdvDateController.clear();
              _rdvHeureController.clear();
            }
          });
        },
      ),
    );
  }

  Widget _buildRdvDateTimeFields(BuildContext context) {
    // 🛑 VALIDATION : Si programmer est sélectionné, la date/heure devient obligatoire
    String? rdvValidator(String? value) {
      if (_programmationRdv == 'programmer' &&
          (value == null || value.isEmpty)) {
        return 'fiche_datetime_required'.tr();
      }
      return null;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 5.0, bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'fiche_pick_datetime'.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Champ Date
              Expanded(
                child: TextFormField(
                  // 🛑 Utilisation de TextFormField
                  controller: _rdvDateController,
                  validator:
                      rdvValidator, // 🛑 Ajout de la validation contextuelle
                  decoration: InputDecoration(
                    hintText: 'fiche_hint_date'.tr(),
                    errorStyle: const TextStyle(height: 0.5),
                    filled: true,
                    fillColor: fieldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: fieldBorderColor),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate:
                          _selectedRdvDate ??
                          DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedRdvDate = date;
                        _rdvDateController.text =
                            '${date.day}/${date.month}/${date.year}';
                      });
                      // Si la date change, forcer la revalidation du formulaire pour le champ
                      _formKey.currentState!.validate();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Champ Heure
              Expanded(
                child: TextFormField(
                  // 🛑 Utilisation de TextFormField
                  controller: _rdvHeureController,
                  validator:
                      rdvValidator, // 🛑 Ajout de la validation contextuelle
                  decoration: InputDecoration(
                    hintText: 'fiche_hint_time'.tr(),
                    errorStyle: const TextStyle(height: 0.5),
                    filled: true,
                    fillColor: fieldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: fieldBorderColor),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedRdvTime ?? TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _selectedRdvTime = time;
                        _rdvHeureController.text = time.format(context);
                      });
                      // Si l'heure change, forcer la revalidation du formulaire pour le champ
                      _formKey.currentState!.validate();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET PRINCIPAL ---

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: primaryPurple,
      appBar: AppBar(
        backgroundColor: primaryPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _patientNameLoaded ? _patientName : 'fiche_loading_name'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: !isDesktop,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => _showPatientInfoModal(context),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 1000 : double.infinity,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Titre "Formulire de Consultation"
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    decoration: BoxDecoration(
                      color: lightPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'fiche_form_title'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // --- Carte blanche principale (Formulaire) ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      // 🔑 Enveloppe tout le contenu du formulaire dans le widget Form
                      key: _formKey,
                      autovalidateMode: AutovalidateMode
                          .onUserInteraction, // Validation lors de l'interaction
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section 1: Infos générales (obligatoires)
                          _buildGeneralInfoSection(),

                          // Dropdown Statut Consultation (obligatoire)
                          _buildExamStatusDropdown(),

                          // Liste des examens (conditionnel)
                          if (_showExamens)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 15.0,
                                bottom: 8.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'fiche_exams_list_title'.tr(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  _examensLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: fieldBackgroundColor,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: fieldBorderColor,
                                            ),
                                          ),
                                          child: _examens.isEmpty
                                              ? Padding(
                                                  padding: const EdgeInsets.all(
                                                    16.0,
                                                  ),
                                                  child: Text(
                                                    'fiche_exams_empty'.tr(),
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                )
                                              : Column(
                                                  children: _examens
                                                      .asMap()
                                                      .entries
                                                      .map((entry) {
                                                        return _buildExamCheckbox(
                                                          examen: entry.value,
                                                          index: entry.key,
                                                        );
                                                      })
                                                      .toList(),
                                                ),
                                        ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 25),

                          // Section 2: Finalisation (obligatoire)
                          _buildFinalizationSection(),

                          // Dropdown Programmation RDV (obligatoire)
                          _buildRdvDropdown(),

                          // Date et Heure du RDV (conditionnel et obligatoire si 'programmer')
                          if (_showRdvDateTime)
                            _buildRdvDateTimeFields(context),

                          const SizedBox(height: 20),

                          // --- Bouton "Finaliser" ---
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _finalizeConsultation,
                              // 🛑 Déclenche la validation avant la sauvegarde
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                'fiche_finalize_button'.tr(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- Footer ---
                  Text(
                    'fiche_footer'.tr(),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
