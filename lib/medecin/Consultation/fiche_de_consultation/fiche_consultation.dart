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

  /// Ouvre un modal centré responsif pour cocher les examens
  Future<void> _showExamensPicker() async {
    if (_examensLoading) return;
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width < 500 ? width * 0.92 : 460.0;

    // Copie locale pour permettre l'annulation
    final List<Map<String, dynamic>> working = _examens
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    String search = '';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final filtered = search.isEmpty
                ? working
                : working
                      .where(
                        (e) => (e['nom_examen'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(search),
                      )
                      .toList();
            final selectedCount = working
                .where((e) => e['selected'] == true)
                .length;
            final total = working
                .where((e) => e['selected'] == true)
                .fold<double>(
                  0,
                  (sum, e) =>
                      sum + ((e['prix_examen'] as num?)?.toDouble() ?? 0),
                );

            Future<void> openCustomExamDialog() async {
              final nomCtrl = TextEditingController();
              final prixCtrl = TextEditingController();
              final formKey = GlobalKey<FormState>();

              final added = await showDialog<bool>(
                context: ctx,
                builder: (ctx2) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  title: Text('fiche_exam_custom_title'.tr()),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: nomCtrl,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: 'fiche_exam_field_name'.tr(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'fiche_field_required'.tr()
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: prixCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'fiche_exam_field_price'.tr(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (v) {
                              final n = double.tryParse(
                                (v ?? '').trim().replaceAll(',', '.'),
                              );
                              if (n == null || n < 0) {
                                return 'fiche_field_required'.tr();
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx2, false),
                      child: Text('att_cancel_no'.tr()),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(ctx2, true);
                        }
                      },
                      child: Text('fiche_exam_custom_add'.tr()),
                    ),
                  ],
                ),
              );

              if (added == true) {
                final prix = double.parse(
                  prixCtrl.text.trim().replaceAll(',', '.'),
                );
                setLocal(() {
                  working.add({
                    'id_examlist': null,
                    'nom_examen': nomCtrl.text.trim(),
                    'prix_examen': prix,
                    'selected': true,
                    'is_custom': true,
                  });
                });
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogWidth,
                  maxHeight: MediaQuery.of(ctx).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                      decoration: BoxDecoration(
                        color: lightPurple,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.science_outlined,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'fiche_exams_modal_title'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            icon: const Icon(Icons.close, color: Colors.white),
                            tooltip: 'fiche_modal_close'.tr(),
                          ),
                        ],
                      ),
                    ),
                    // Search
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        onChanged: (v) =>
                            setLocal(() => search = v.trim().toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'fiche_exams_search_hint'.tr(),
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          filled: true,
                          fillColor: fieldBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: fieldBorderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: fieldBorderColor),
                          ),
                        ),
                      ),
                    ),
                    // List
                    Flexible(
                      child: working.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'fiche_exams_empty'.tr(),
                                style: const TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final examen = filtered[i];
                                final isSelected = examen['selected'] == true;
                                return CheckboxListTile(
                                  dense: true,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  activeColor: primaryPurple,
                                  value: isSelected,
                                  onChanged: (v) {
                                    setLocal(() {
                                      examen['selected'] = v ?? false;
                                    });
                                  },
                                  title: Text(
                                    (examen['nom_examen'] ?? '').toString(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'fiche_exam_price'.tr(
                                      namedArgs: {
                                        'price':
                                            '${examen['prix_examen'] ?? 0}',
                                      },
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              },
                            ),
                    ),
                    // Footer (résumé + actions)
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      decoration: BoxDecoration(
                        color: fieldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(18),
                        ),
                        border: Border(
                          top: BorderSide(color: fieldBorderColor),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'fiche_exams_selected_count'.tr(
                                    namedArgs: {'count': '$selectedCount'},
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                'fiche_exams_total'.tr(
                                  namedArgs: {
                                    'total': total.toStringAsFixed(0),
                                  },
                                ),
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text('att_cancel_no'.tr()),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryPurple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'fiche_exams_validate'.tr(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() {
        _examens = working;
      });
    }
  }

  /// Bouton/carte d'accès au modal de sélection des examens
  Widget _buildExamsPickerButton() {
    final selectedCount = _examens.where((e) => e['selected'] == true).length;
    final total = _examens
        .where((e) => e['selected'] == true)
        .fold<double>(
          0,
          (sum, e) => sum + ((e['prix_examen'] as num?)?.toDouble() ?? 0),
        );

    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'fiche_exams_list_title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Material(
            color: fieldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _examensLoading ? null : _showExamensPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: fieldBorderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: lightPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.science_outlined,
                        color: primaryPurple,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'fiche_exams_pick_button'.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _examensLoading
                                ? 'fiche_exams_loading'.tr()
                                : (selectedCount == 0
                                      ? 'fiche_exams_pick_hint'.tr()
                                      : 'fiche_exams_pick_summary'.tr(
                                          namedArgs: {
                                            'count': '$selectedCount',
                                            'total': total.toStringAsFixed(0),
                                          },
                                        )),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selectedCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: primaryPurple,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$selectedCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====================== MÉDICAMENTS (Pharmacie) ======================

  /// Ouvre un modal centré responsif pour sélectionner les médicaments
  Future<void> _showMedicamentsPicker() async {
    if (_medicamentsLoading) return;
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width < 500 ? width * 0.94 : 520.0;

    // Copie locale (catalogue + saisies libres)
    final List<Map<String, dynamic>> working = _medicaments
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    String search = '';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final filtered = search.isEmpty
                ? working
                : working
                      .where(
                        (m) => (m['nom_medicament'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(search),
                      )
                      .toList();
            final selectedItems = working
                .where((m) => m['selected'] == true)
                .toList();
            final selectedCount = selectedItems.length;
            final total = selectedItems.fold<double>(0, (sum, m) {
              final p = (m['prix_unitaire'] as num?)?.toDouble() ?? 0;
              final q = (m['quantite'] as num?)?.toInt() ?? 1;
              return sum + p * q;
            });

            Future<void> openCustomDialog() async {
              final nomCtrl = TextEditingController();
              final qteCtrl = TextEditingController(text: '1');
              final posoCtrl = TextEditingController();
              final formKey = GlobalKey<FormState>();

              final added = await showDialog<bool>(
                context: ctx,
                builder: (ctx2) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  title: Text('fiche_med_custom_title'.tr()),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: nomCtrl,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: 'fiche_med_field_name'.tr(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'fiche_field_required'.tr()
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: qteCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'fiche_med_field_quantity'.tr(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (v) {
                              final n = int.tryParse((v ?? '').trim());
                              if (n == null || n <= 0) {
                                return 'fiche_field_required'.tr();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: posoCtrl,
                            minLines: 2,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'fiche_med_field_posologie'.tr(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'fiche_field_required'.tr()
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx2, false),
                      child: Text('att_cancel_no'.tr()),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(ctx2, true);
                        }
                      },
                      child: Text('fiche_med_custom_add'.tr()),
                    ),
                  ],
                ),
              );

              if (added == true) {
                setLocal(() {
                  working.add({
                    'id_medicament': null,
                    'nom_medicament': nomCtrl.text.trim(),
                    'forme': null,
                    'dosage': null,
                    'prix_unitaire': null,
                    'stock': 0,
                    'disponible': false,
                    'selected': true,
                    'quantite': int.parse(qteCtrl.text.trim()),
                    'posologie': posoCtrl.text.trim(),
                    'is_custom': true,
                  });
                });
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogWidth,
                  maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                      decoration: BoxDecoration(
                        color: lightPurple,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.medication_outlined,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'fiche_med_modal_title'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            icon: const Icon(Icons.close, color: Colors.white),
                            tooltip: 'fiche_modal_close'.tr(),
                          ),
                        ],
                      ),
                    ),
                    // Search + bouton custom
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (v) => setLocal(
                                () => search = v.trim().toLowerCase(),
                              ),
                              decoration: InputDecoration(
                                hintText: 'fiche_med_search_hint'.tr(),
                                prefixIcon: const Icon(Icons.search),
                                isDense: true,
                                filled: true,
                                fillColor: fieldBackgroundColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: fieldBorderColor,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: fieldBorderColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: openCustomDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: Text('fiche_med_custom_btn'.tr()),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryPurple,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // List
                    Flexible(
                      child: working.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'fiche_med_empty'.tr(),
                                style: const TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final m = filtered[i];
                                return _buildMedTile(
                                  m: m,
                                  onChanged: () => setLocal(() {}),
                                  onRemoveCustom: () => setLocal(() {
                                    working.remove(m);
                                  }),
                                );
                              },
                            ),
                    ),
                    // Footer
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      decoration: BoxDecoration(
                        color: fieldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(18),
                        ),
                        border: Border(
                          top: BorderSide(color: fieldBorderColor),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'fiche_exams_selected_count'.tr(
                                    namedArgs: {'count': '$selectedCount'},
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                'fiche_med_total_estim'.tr(
                                  namedArgs: {
                                    'total': total.toStringAsFixed(0),
                                  },
                                ),
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text('att_cancel_no'.tr()),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Validation rapide : toutes les lignes cochées doivent
                                    // avoir une posologie + quantité valide.
                                    final invalid = working.firstWhere(
                                      (m) =>
                                          m['selected'] == true &&
                                          ((m['posologie'] ?? '')
                                                  .toString()
                                                  .trim()
                                                  .isEmpty ||
                                              ((m['quantite'] as num?) ?? 0) <=
                                                  0),
                                      orElse: () => {},
                                    );
                                    if (invalid.isNotEmpty) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'fiche_med_validation_error'.tr(),
                                          ),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }
                                    Navigator.pop(ctx, true);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryPurple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'fiche_exams_validate'.tr(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() {
        _medicaments = working;
      });
    }
  }

  /// Tuile d'un médicament dans le picker (avec dispo, qte, posologie inline)
  Widget _buildMedTile({
    required Map<String, dynamic> m,
    required VoidCallback onChanged,
    required VoidCallback onRemoveCustom,
  }) {
    final isSelected = m['selected'] == true;
    final isCustom = m['is_custom'] == true;
    final disponible = m['disponible'] == true;
    final prix = (m['prix_unitaire'] as num?)?.toDouble();
    final dosage = (m['dosage'] ?? '').toString();
    final forme = (m['forme'] ?? '').toString();
    final subtitle = [
      if (forme.isNotEmpty) forme,
      if (dosage.isNotEmpty) dosage,
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: isSelected,
                activeColor: primaryPurple,
                onChanged: (v) {
                  m['selected'] = v ?? false;
                  onChanged();
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (m['nom_medicament'] ?? '').toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _availabilityBadge(
                          disponible: disponible,
                          isCustom: isCustom,
                        ),
                      ],
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    if (prix != null)
                      Text(
                        'fiche_med_price'.tr(
                          namedArgs: {'price': prix.toStringAsFixed(0)},
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 4, 8, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          initialValue: (m['quantite'] ?? 1).toString(),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'fiche_med_field_quantity'.tr(),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (v) {
                            final n = int.tryParse(v.trim());
                            m['quantite'] = (n != null && n > 0) ? n : 1;
                            onChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: (m['posologie'] ?? '').toString(),
                          decoration: InputDecoration(
                            labelText: 'fiche_med_field_posologie'.tr(),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (v) {
                            m['posologie'] = v;
                          },
                        ),
                      ),
                      if (isCustom)
                        IconButton(
                          tooltip: 'fiche_med_remove_custom'.tr(),
                          onPressed: onRemoveCustom,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _availabilityBadge({
    required bool disponible,
    required bool isCustom,
  }) {
    if (isCustom) {
      return _badge(
        text: 'fiche_med_badge_custom'.tr(),
        color: Colors.deepPurple,
      );
    }
    return _badge(
      text: disponible
          ? 'fiche_med_badge_available'.tr()
          : 'fiche_med_badge_unavailable'.tr(),
      color: disponible ? Colors.green : Colors.redAccent,
    );
  }

  Widget _badge({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  /// Bouton/carte d'accès au modal de sélection des médicaments
  Widget _buildMedicamentsPickerButton() {
    final selected = _medicaments.where((m) => m['selected'] == true).toList();
    final selectedCount = selected.length;
    final total = selected.fold<double>(0, (sum, m) {
      final p = (m['prix_unitaire'] as num?)?.toDouble() ?? 0;
      final q = (m['quantite'] as num?)?.toInt() ?? 1;
      return sum + p * q;
    });

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'fiche_med_section_title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Material(
            color: fieldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _medicamentsLoading ? null : _showMedicamentsPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: fieldBorderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: lightPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.medication_outlined,
                        color: primaryPurple,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'fiche_med_pick_button'.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _medicamentsLoading
                                ? 'fiche_med_loading'.tr()
                                : (selectedCount == 0
                                      ? 'fiche_med_pick_hint'.tr()
                                      : 'fiche_med_pick_summary'.tr(
                                          namedArgs: {
                                            'count': '$selectedCount',
                                            'total': total.toStringAsFixed(0),
                                          },
                                        )),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selectedCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: primaryPurple,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$selectedCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
