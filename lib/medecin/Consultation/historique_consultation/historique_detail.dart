import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'historique_service.dart';
import '../finalisation_consultation/consultation_pdf_generator.dart';

const Color medPrimaryColor = Color(0xFF6A5ACD);
const Color medAccentColor = Color(0xFF6A5ACD);
const Color medSuccessColor = Color(0xFF4CAF50);

class HistoriqueDetailPage extends StatefulWidget {
  final int idConsultation;
  const HistoriqueDetailPage({super.key, required this.idConsultation});

  @override
  State<HistoriqueDetailPage> createState() => _HistoriqueDetailPageState();
}

class _HistoriqueDetailPageState extends State<HistoriqueDetailPage>
    with SingleTickerProviderStateMixin {
  late final HistoriqueConsultationService _service;
  late TabController _tabController;

  Map<String, dynamic>? _consultationData;
  Map<String, dynamic>? _patientData;
  Map<String, dynamic>? _parametresVitaux;
  List<Map<String, dynamic>> _examens = [];
  List<Map<String, dynamic>> _medicaments = [];

  bool _isLoading = true;
  String _patientName = '';
  bool _patientNameLoaded = false;

  @override
  void initState() {
    super.initState();
    _service = HistoriqueConsultationService(Supabase.instance.client);
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---- Logique métier inchangée ----

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final consultation = await _service.getConsultationDetail(
        widget.idConsultation,
      );
      final examens = await _service.getExamensConsultation(
        widget.idConsultation,
      );
      final medicaments = await _service.getMedicamentsConsultation(
        widget.idConsultation,
      );

      if (mounted && consultation != null) {
        setState(() {
          _consultationData = consultation;
          _patientData = consultation['Patient'] as Map<String, dynamic>?;
          _parametresVitaux =
              consultation['Parametres_vitaux'] as Map<String, dynamic>?;
          _examens = examens;
          _medicaments = medicaments;
          _patientName = _patientData?['nom_complet']?.toString() ?? '';
          _patientNameLoaded = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('hcdet_load_error'.tr(namedArgs: {'msg': '$e'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printConsultationPdf() async {
    final p = _patientData ?? {};
    final v = _parametresVitaux ?? {};
    final c = _consultationData ?? {};

    DateTime? rdvDate;
    final rdvRaw = c['date_rdv_prevu'];
    if (rdvRaw != null) {
      try {
        rdvDate = DateTime.parse(rdvRaw.toString());
      } catch (_) {}
    }

    final data = ConsultationPdfData(
      idConsultation: '${widget.idConsultation}',
      patientNom: p['nom_complet']?.toString() ?? '—',
      patientSexe: p['sexe']?.toString() ?? '—',
      patientAge: p['age']?.toString() ?? '—',
      patientTelephone: p['telephone']?.toString() ?? '—',
      patientAdresse: p['adresse']?.toString() ?? '—',
      patientProfession: p['profession']?.toString() ?? '—',
      patientStatutMatrimonial: p['statut_matrimonial']?.toString() ?? '—',
      temperature: v['temperature']?.toString(),
      tension: (v['systolique'] != null && v['diastolique'] != null)
          ? '${v['systolique']}/${v['diastolique']}'
          : null,
      poids: v['poid']?.toString(),
      statutVih: v['statut_VIH']?.toString(),
      vaccination: v['vaccination']?.toString(),
      motif: v['motif_de_consultation']?.toString(),
      antecedents: c['antecedents']?.toString() ?? '—',
      signesSymptomes: c['signes_symptomes']?.toString() ?? '—',
      diagnosticInitial: c['diagnostic_initial']?.toString() ?? '—',
      diagnosticFinal: c['diagnostic_final']?.toString() ?? '—',
      traitementPrescrit: c['traitement_prescrit']?.toString() ?? '—',
      rdvDate: rdvDate,
      examensResultats: _examens,
      medicaments: _medicaments,
    );

    try {
      await ConsultationPdfGenerator.previewAndPrint(
        context: context,
        data: data,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('consult_pdf_error'.tr(namedArgs: {'msg': '$e'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ---- ONGLET CONSULTATION ----

  Widget _buildConsultationTab() {
    if (_consultationData == null) {
      return Center(child: Text('hcdet_no_data'.tr()));
    }

    final fieldsWidgets = <MapEntry<String, String>>[];

    // 1. Map des champs par défaut
    final defaultLabels = {
      'antecedents': 'Antécédents',
      'signes_symptomes': 'Signes & Symptômes',
      'diagnostic_initial': 'Diagnostic Initial',
      'diagnostic_final': 'Diagnostic Final',
      'traitement_prescrit': 'Traitement Prescrit',
    };

    defaultLabels.forEach((cle, label) {
      final value = _consultationData![cle]?.toString();
      if (value != null && value.trim().isNotEmpty) {
        fieldsWidgets.add(MapEntry(label, value));
      }
    });

    // 2. Champs supplémentaires (JSONB)
    final extra = _consultationData!['champs_supplementaires'];
    if (extra is Map) {
      extra.forEach((key, value) {
        if (value is Map) {
          final label = value['label']?.toString() ?? key;
          final valeur = value['valeur']?.toString() ?? '';
          if (valeur.trim().isNotEmpty) {
            fieldsWidgets.add(MapEntry(label, valeur));
          }
        }
      });
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (fieldsWidgets.isNotEmpty)
            _buildSectionCard(
              title: 'Informations Cliniques',
              icon: Icons.medical_services_rounded,
              children: List.generate(fieldsWidgets.length, (idx) {
                final entry = fieldsWidgets[idx];
                return _buildReadOnlyField(
                  entry.key,
                  entry.value,
                  isLast: idx == fieldsWidgets.length - 1,
                );
              }),
            ),
          const SizedBox(height: 12),
          _buildSectionCard(
            title: 'hcdet_section_rdv'.tr(),
            icon: Icons.event_rounded,
            children: [
              _buildReadOnlyField(
                'hcdet_field_rdv_status'.tr(),
                _consultationData!['programmation_rdv']?.toString() ==
                        'programmer'
                    ? 'hcdet_rdv_yes'.tr()
                    : 'hcdet_rdv_no'.tr(),
                isLast: _consultationData!['date_rdv_prevu'] == null,
              ),
              if (_consultationData!['date_rdv_prevu'] != null)
                _buildReadOnlyField(
                  'hcdet_field_rdv_date'.tr(),
                  _formatDateTime(_consultationData!['date_rdv_prevu']),
                  isLast: true,
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ---- ONGLET EXAMENS ----

  Widget _buildExamensTab() {
    if (_examens.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: medPrimaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.science_rounded,
                  size: 56,
                  color: medPrimaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'hcdet_exams_empty_title'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: medPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'hcdet_exams_empty_msg'.tr(),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _examens.length,
      itemBuilder: (context, index) {
        final examen = _examens[index];
        final nomExamen =
            examen['nom_examen']?.toString() ?? 'hcdet_exam_unknown'.tr();
        final resultatExamen = examen['resultat_examen']?.toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar cercle vert
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        medSuccessColor,
                        medSuccessColor.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.science_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Contenu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              nomExamen,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Badge terminé vert
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: medSuccessColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 12,
                                  color: medSuccessColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'hcdet_exam_done_badge'.tr(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: medSuccessColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'hcdet_exam_results_label'.tr(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        resultatExamen ?? 'hcdet_exam_no_result'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: resultatExamen != null
                              ? Colors.grey[800]
                              : Colors.grey[400],
                          fontStyle: resultatExamen == null
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
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
  }

  // ---- ONGLET INFOS ----

  Widget _buildInfosTab() {
    if (_patientData == null) {
      return Center(child: Text('hcdet_no_data'.tr()));
    }

    final nom = _patientData!['nom_complet']?.toString() ?? 'pay_value_na'.tr();
    final sexe = _patientData!['sexe']?.toString() ?? '';
    final age = _patientData!['age']?.toString() ?? '';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // En-tête patient — même style card avec avatar vert
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        medSuccessColor,
                        medSuccessColor.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nom,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            sexe == 'Homme' ? Icons.man : Icons.woman,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sexe,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.cake_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'clist_age_value'.tr(namedArgs: {'age': age}),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
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
          const SizedBox(height: 12),

          // Infos administratives
          _buildSectionCard(
            title: 'hcdet_section_admin'.tr(),
            icon: Icons.person_rounded,
            children: [
              _buildInfoRow(
                Icons.phone_rounded,
                'hcdet_field_phone'.tr(),
                _patientData!['telephone'],
                iconColor: Colors.blue,
              ),
              _buildInfoRow(
                Icons.work_rounded,
                'hcdet_field_profession'.tr(),
                _patientData!['profession'],
                iconColor: Colors.orange,
              ),
              _buildInfoRow(
                Icons.favorite_rounded,
                'hcdet_field_marital'.tr(),
                _patientData!['statut_matrimonial'],
                iconColor: Colors.pink,
              ),
              _buildInfoRow(
                Icons.location_on_rounded,
                'hcdet_field_address'.tr(),
                _patientData!['adresse'],
                iconColor: Colors.green,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Paramètres vitaux
          if (_parametresVitaux != null)
            _buildSectionCard(
              title: 'hcdet_section_vitals'.tr(),
              icon: Icons.favorite_border_rounded,
              children: [
                _buildInfoRow(
                  Icons.thermostat_rounded,
                  'hcdet_field_temperature'.tr(),
                  _parametresVitaux!['temperature'] != null
                      ? 'hcdet_temperature_value'.tr(
                          namedArgs: {
                            'value': '${_parametresVitaux!['temperature']}',
                          },
                        )
                      : 'pay_value_na'.tr(),
                  iconColor: Colors.orange,
                ),
                _buildInfoRow(
                  Icons.monitor_heart_rounded,
                  'hcdet_field_tension'.tr(),
                  (_parametresVitaux!['systolique'] != null &&
                          _parametresVitaux!['diastolique'] != null)
                      ? 'hcdet_tension_value'.tr(
                          namedArgs: {
                            'value':
                                '${_parametresVitaux!['systolique']}/${_parametresVitaux!['diastolique']}',
                          },
                        )
                      : 'pay_value_na'.tr(),
                  iconColor: Colors.red,
                ),
                _buildInfoRow(
                  Icons.monitor_weight_rounded,
                  'hcdet_field_weight'.tr(),
                  _parametresVitaux!['poid'] != null
                      ? 'hcdet_weight_value'.tr(
                          namedArgs: {'value': '${_parametresVitaux!['poid']}'},
                        )
                      : 'pay_value_na'.tr(),
                  iconColor: Colors.blue,
                ),
                _buildInfoRow(
                  Icons.health_and_safety_rounded,
                  'hcdet_field_hiv'.tr(),
                  _parametresVitaux!['statut_VIH'],
                  iconColor: Colors.purple,
                ),
                _buildInfoRow(
                  Icons.vaccines_rounded,
                  'hcdet_field_vaccination'.tr(),
                  _parametresVitaux!['vaccination'],
                  iconColor: Colors.teal,
                ),
                _buildInfoRow(
                  Icons.description_rounded,
                  'hcdet_field_motif'.tr(),
                  _parametresVitaux!['motif_de_consultation'],
                  iconColor: Colors.indigo,
                  isLast: true,
                ),
              ],
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ---- WIDGETS HELPER ----

  /// Card section avec titre + icône
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: medPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: medPrimaryColor, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C2E),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          ...children,
        ],
      ),
    );
  }

  /// Champ lecture seule
  Widget _buildReadOnlyField(
    String label,
    String? value, {
    bool isLast = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  value?.isNotEmpty == true
                      ? value!
                      : 'hcdet_not_provided'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: value?.isNotEmpty == true
                        ? const Color(0xFF1C1C2E)
                        : Colors.grey[400],
                    fontStyle: value?.isNotEmpty == true
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }

  /// Ligne info (onglet Infos)
  Widget _buildInfoRow(
    IconData icon,
    String label,
    dynamic value, {
    bool isLast = false,
    Color? iconColor,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: (iconColor ?? medSuccessColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: iconColor ?? medSuccessColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value?.toString() ?? 'pay_value_na'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1C1C2E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null) return 'pay_value_na'.tr();
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'pay_value_na'.tr();
    }
  }

  /// Vérifie si la consultation n'est pas encore terminée
  bool _isConsultationEnCours() {
    final statut = _consultationData?['Statut_Consultation'] as String? ?? '';
    return statut != 'terminer';
  }

  /// Écran affiché quand la consultation n'est pas encore terminée
  Widget _buildNotAvailable() {
    final statut = _consultationData?['Statut_Consultation'] as String? ?? '';

    String statusLabel;
    IconData statusIcon;
    Color statusColor;

    switch (statut) {
      case 'en-attente-consultation':
        statusLabel = 'Consultation pas encore commencée';
        statusIcon = Icons.hourglass_empty_rounded;
        statusColor = medPrimaryColor;
        break;
      case 'en-attente-examen':
        statusLabel = 'En attente des résultats d\'examen';
        statusIcon = Icons.biotech_outlined;
        statusColor = const Color(0xFFFF9800);
        break;
      case 'en-attente-resultat':
        statusLabel = 'Résultats d\'examen en cours d\'analyse';
        statusIcon = Icons.science_outlined;
        statusColor = const Color(0xFFFF9800);
        break;
      case 'resultat-disponible':
        statusLabel = 'Résultats disponibles, consultation en cours';
        statusIcon = Icons.pending_actions_outlined;
        statusColor = const Color(0xFF2196F3);
        break;
      case 'En cours':
        statusLabel = 'Consultation en cours';
        statusIcon = Icons.medical_services_outlined;
        statusColor = const Color(0xFF2196F3);
        break;
      default:
        statusLabel = 'Détails pas encore disponibles';
        statusIcon = Icons.info_outline_rounded;
        statusColor = Colors.grey;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, size: 56, color: statusColor),
              ),
              const SizedBox(height: 20),
              const Text(
                'Résultats pas encore disponibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Les détails complets seront disponibles une fois la consultation terminée.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- BUILD ----

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: medPrimaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _patientNameLoaded ? _patientName : 'fiche_loading_name'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (!_isLoading && _consultationData != null)
            IconButton(
              icon: const Icon(Icons.print_rounded, color: Colors.white),
              tooltip: 'consult_pdf_prompt_yes'.tr(),
              onPressed: _printConsultationPdf,
            ),
        ],
        centerTitle: !isDesktop,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          tabs: [
            Tab(text: 'hcdet_tab_consultation'.tr()),
            Tab(text: 'hcdet_tab_exams'.tr()),
            Tab(text: 'hcdet_tab_infos'.tr()),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: medPrimaryColor),
            )
          : _consultationData == null
          ? _buildNotAvailable()
          : _isConsultationEnCours()
          ? _buildNotAvailable()
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 1000 : double.infinity,
                ),
                child: Container(
                  color: const Color(0xFFF5F3F3),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildConsultationTab(),
                      _buildExamensTab(),
                      _buildInfosTab(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
