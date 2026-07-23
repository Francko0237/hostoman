import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'fiche_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../shared/consultation_pickers.dart';
import '../historique_consultation/historique_patient_page.dart';

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

  // FocusNodes pour le focus et défilement automatique lors de la validation
  final FocusNode _antecedentsFocusNode = FocusNode();
  final FocusNode _signesSymptomesFocusNode = FocusNode();
  final FocusNode _diagnosticInitialFocusNode = FocusNode();
  final FocusNode _statutConsultationFocusNode = FocusNode();
  final FocusNode _diagnosticFinalFocusNode = FocusNode();
  final FocusNode _traitementPrescritFocusNode = FocusNode();
  final FocusNode _programmationRdvFocusNode = FocusNode();
  final FocusNode _rdvDateFocusNode = FocusNode();
  final FocusNode _rdvHeureFocusNode = FocusNode();

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

  // État des médicaments (Catalogue chargé depuis la BD)
  List<Map<String, dynamic>> _medicaments = [];
  bool _medicamentsLoading = true;
  String? _idPatient;

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
    _loadMedicaments();
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

    _antecedentsFocusNode.dispose();
    _signesSymptomesFocusNode.dispose();
    _diagnosticInitialFocusNode.dispose();
    _statutConsultationFocusNode.dispose();
    _diagnosticFinalFocusNode.dispose();
    _traitementPrescritFocusNode.dispose();
    _programmationRdvFocusNode.dispose();
    _rdvDateFocusNode.dispose();
    _rdvHeureFocusNode.dispose();
    super.dispose();
  }

  // --- LOGIQUE DE CHARGEMENT ET D'AFFICHAGE ---

  Future<void> _loadPatientName() async {
    try {
      final data = await medecinService.infosPatient(widget.idConsultation);
      if (data.isNotEmpty) {
        final patient = data[0]['Patient'] as Map<String, dynamic>;
        final String nomComplet = (patient['nom_complet']?.toString() ?? '');
        final String? idPatient = patient['id_patient']?.toString();
        if (mounted) {
          setState(() {
            _patientName = nomComplet;
            _patientNameLoaded = true;
            _idPatient = idPatient;
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
              'is_custom': false,
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

  Future<void> _loadMedicaments() async {
    try {
      final data = await medecinService.getListeMedicaments();
      if (mounted) {
        setState(() {
          _medicaments = data.map((m) {
            final stock = (m['stock'] as num?)?.toInt() ?? 0;
            final actif = m['actif'] == true;
            return {
              'id_medicament': m['id_medicament'],
              'nom_medicament': m['nom_medicament'],
              'forme': m['forme'],
              'dosage': m['dosage'],
              'prix_unitaire': m['prix_unitaire'],
              'stock': stock,
              'disponible': actif && stock > 0,
              'selected': false,
              'quantite': 1,
              'posologie': '',
              // Pour les saisies libres on ajoutera des entrées via le modal
              'is_custom': false,
            };
          }).toList();
          _medicamentsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _medicamentsLoading = false);
      }
      print('Erreur de chargement des médicaments: $e');
    }
  }

  void _showPatientInfoModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 460,
            ),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: medecinService.infosPatient(widget.idConsultation),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 180,
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF6A5ACD)),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'fiche_modal_load_error'.tr(
                            namedArgs: {'msg': '${snapshot.error}'},
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A5ACD),
                            foregroundColor: Colors.white,
                          ),
                          child: Text('fiche_modal_close'.tr()),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.grey, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'fiche_modal_no_info'.tr(),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('fiche_modal_close'.tr()),
                        ),
                      ],
                    ),
                  );
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
                final statutMatrimonial = patient['statut_matrimonial'] ?? 'fiche_value_unknown'.tr();

                final temperature = parametresVitaux['temperature'];
                final poid = parametresVitaux['poid'];
                final systolique = parametresVitaux['systolique'];
                final diastolique = parametresVitaux['diastolique'];
                final statutVih = parametresVitaux['statut_VIH'];
                final vaccination = parametresVitaux['vaccination'];
                final motif = parametresVitaux['motif_de_consultation'];

                Widget buildSimpleInfoRow(String label, String value) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 150,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Simple
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'fiche_modal_title'.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.black54),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section 1: Admin
                            Text(
                              'fiche_modal_admin_section'.tr(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6A5ACD),
                              ),
                            ),
                            const SizedBox(height: 8),
                            buildSimpleInfoRow('Nom complet', nomComplet),
                            buildSimpleInfoRow('Sexe', sexe),
                            buildSimpleInfoRow('Âge', age != null ? '$age ans' : 'fiche_value_unknown'.tr()),
                            buildSimpleInfoRow('Téléphone', telephone),
                            buildSimpleInfoRow('Statut matrimonial', '$statutMatrimonial'),
                            buildSimpleInfoRow('Profession', '$profesion'),
                            buildSimpleInfoRow('Adresse', adresse),

                            const SizedBox(height: 20),
                            const Divider(height: 1),
                            const SizedBox(height: 15),

                            // Section 2: Vitals
                            Text(
                              'fiche_modal_vitals_section'.tr(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6A5ACD),
                              ),
                            ),
                            const SizedBox(height: 8),
                            buildSimpleInfoRow('Température', temperature != null ? '$temperature °C' : 'fiche_value_na'.tr()),
                            buildSimpleInfoRow(
                              'Tension (mmHg)',
                              (systolique != null && diastolique != null)
                                  ? '$systolique/$diastolique'
                                  : 'fiche_value_na'.tr(),
                            ),
                            buildSimpleInfoRow('Poids', poid != null ? '$poid kg' : 'fiche_value_na'.tr()),
                            buildSimpleInfoRow('Statut VIH', statutVih != null ? '$statutVih' : 'fiche_value_na'.tr()),
                            buildSimpleInfoRow('Vaccination', vaccination != null ? '$vaccination' : 'fiche_value_na'.tr()),
                            buildSimpleInfoRow('Motif de consultation', motif != null ? '$motif' : 'fiche_value_na'.tr()),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),

                    // Actions / Footer
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6A5ACD),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text(
                              'fiche_modal_close'.tr(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
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
    FocusNode? focusNode,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        // 🛑 Utilisation de TextFormField pour la validation
        controller: controller,
        focusNode: focusNode,
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

  PickerTheme get _pickerTheme => PickerTheme(
    primary: primaryPurple,
    light: lightPurple,
    fieldBg: fieldBackgroundColor,
    fieldBorder: fieldBorderColor,
    blue: primaryBlue,
  );

  /// Ouvre le picker des examens (catalogue + saisies libres).
  Future<void> _showExamensPicker() async {
    if (_examensLoading) return;
    final updated = await showExamensPickerDialog(
      context: context,
      current: _examens,
      theme: _pickerTheme,
    );
    if (updated != null && mounted) {
      setState(() => _examens = updated);
    }
  }

  /// Bouton/carte d'accès au modal de sélection des examens
  Widget _buildExamsPickerButton() {
    return buildExamsPickerCard(
      context: context,
      examens: _examens,
      loading: _examensLoading,
      theme: _pickerTheme,
      onTap: _showExamensPicker,
    );
  }

  // ====================== MÉDICAMENTS (Pharmacie) ======================

  /// Ouvre le picker des médicaments (catalogue + saisies libres).
  Future<void> _showMedicamentsPicker() async {
    if (_medicamentsLoading) return;
    final updated = await showMedicamentsPickerDialog(
      context: context,
      current: _medicaments,
      theme: _pickerTheme,
    );
    if (updated != null && mounted) {
      setState(() => _medicaments = updated);
    }
  }

  /// Bouton/carte d'accès au modal de sélection des médicaments
  Widget _buildMedicamentsPickerButton() {
    return buildMedicamentsPickerCard(
      context: context,
      medicaments: _medicaments,
      loading: _medicamentsLoading,
      theme: _pickerTheme,
      onTap: _showMedicamentsPicker,
    );
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
    if (_antecedentsController.text.trim().isEmpty) {
      _focusAndScrollTo(_antecedentsFocusNode);
      return;
    }
    if (_signesSymptomesController.text.trim().isEmpty) {
      _focusAndScrollTo(_signesSymptomesFocusNode);
      return;
    }
    if (_diagnosticInitialController.text.trim().isEmpty) {
      _focusAndScrollTo(_diagnosticInitialFocusNode);
      return;
    }
    if (_statutConsultation == null) {
      _focusAndScrollTo(_statutConsultationFocusNode);
      return;
    }
    if (_diagnosticFinalController.text.trim().isEmpty) {
      _focusAndScrollTo(_diagnosticFinalFocusNode);
      return;
    }
    if (_traitementPrescritController.text.trim().isEmpty) {
      _focusAndScrollTo(_traitementPrescritFocusNode);
      return;
    }
    if (_programmationRdv == null) {
      _focusAndScrollTo(_programmationRdvFocusNode);
      return;
    }
    if (_programmationRdv == 'programmer') {
      if (_rdvDateController.text.trim().isEmpty) {
        _focusAndScrollTo(_rdvDateFocusNode);
        return;
      }
      if (_rdvHeureController.text.trim().isEmpty) {
        _focusAndScrollTo(_rdvHeureFocusNode);
        return;
      }
    }
  }

  Future<void> _finalizeConsultation() async {
    // 🛑 VALIDATION: Tente de valider tous les champs du formulaire
    if (!_formKey.currentState!.validate()) {
      _focusOnFirstInvalidField();
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

    // 1.b Collecte des médicaments prescrits
    final List<Map<String, dynamic>> medicamentsPrescrits = _medicaments
        .where((m) => m['selected'] == true)
        .map(
          (m) => {
            'id_medicament': m['id_medicament'], // null si saisie libre
            'nom_medicament': m['nom_medicament'],
            'posologie': (m['posologie'] ?? '').toString(),
            'quantite': m['quantite'] ?? 1,
            'prix_unitaire': m['is_custom'] == true ? null : m['prix_unitaire'],
            'disponible_initialement': m['disponible'] == true,
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
        medicamentsPrescrits: medicamentsPrescrits,
        idPatient: _idPatient,
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
          focusNode: _antecedentsFocusNode,
          validator: (value) => value == null || value.isEmpty
              ? 'fiche_field_required'.tr()
              : null,
        ),
        _buildFormField(
          hint: 'fiche_hint_signs'.tr(),
          controller: _signesSymptomesController,
          focusNode: _signesSymptomesFocusNode,
          validator: (value) => value == null || value.isEmpty
              ? 'fiche_field_required'.tr()
              : null,
        ),
        _buildFormField(
          hint: 'fiche_hint_diag_initial'.tr(),
          controller: _diagnosticInitialController,
          focusNode: _diagnosticInitialFocusNode,
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
      child: Focus(
        focusNode: _statutConsultationFocusNode,
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
          focusNode: _diagnosticFinalFocusNode,
          validator: (value) => value == null || value.isEmpty
              ? 'fiche_field_required'.tr()
              : null,
        ),
        _buildFormField(
          hint: 'fiche_hint_treatment'.tr(),
          controller: _traitementPrescritController,
          focusNode: _traitementPrescritFocusNode,
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
      child: Focus(
        focusNode: _programmationRdvFocusNode,
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
                  focusNode: _rdvDateFocusNode,
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
                  focusNode: _rdvHeureFocusNode,
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
          if (_idPatient != null)
            IconButton(
              icon: const Icon(Icons.history_rounded, color: Colors.white),
              tooltip: 'hist_btn'.tr(),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoriquePatientPage(
                    idPatient: _idPatient!,
                    patientName: _patientName,
                    excludeIdConsultation: widget.idConsultation,
                  ),
                ),
              ),
            ),
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

                          // Liste des examens (conditionnel) -> bouton qui ouvre un modal
                          if (_showExamens) _buildExamsPickerButton(),

                          const SizedBox(height: 25),

                          // Section 2: Finalisation (obligatoire)
                          _buildFinalizationSection(),

                          // Sélection des médicaments (Pharmacie)
                          _buildMedicamentsPickerButton(),

                          const SizedBox(height: 15),

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
