import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'statistiques_service.dart';
import 'package:intl/intl.dart';
import 'package:hostoman/shared/pdf_generator.dart';

const Color medPrimaryColor = Color(0xFF6A5ACD);
const Color medSuccessColor = Color(0xFF4CAF50);
const Color medErrorColor = Color(0xFFF44336);
const Color medInfoColor = Color(0xFF2196F3);

class StatistiquesPage extends StatefulWidget {
  const StatistiquesPage({super.key});

  @override
  State<StatistiquesPage> createState() => _StatistiquesPageState();
}

class _StatistiquesPageState extends State<StatistiquesPage> {
  late final StatistiquesService _service;

  DateTime? _dateDebut;
  DateTime? _dateFin;
  bool _isLoading = false;

  int _nbTerminees = 0;
  int _nbAnnulees = 0;
  int _nbRdvTermines = 0;

  String _selectedCategory = 'tous';
  List<Map<String, dynamic>> _patients = [];

  // ---- Logique métier inchangée ----

  @override
  void initState() {
    super.initState();
    _service = StatistiquesService(Supabase.instance.client);
    final now = DateTime.now();
    _dateDebut = DateTime(now.year, now.month, now.day - 7);
    _dateFin = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _selectedCategory = 'tous';
    _loadStatistiques();
  }

  Future<void> _loadStatistiques() async {
    if (_dateDebut == null || _dateFin == null) return;
    setState(() => _isLoading = true);
    try {
      final terminees = await _service.getConsultationsTerminees(
        _dateDebut!,
        _dateFin!,
      );
      final annulees = await _service.getConsultationsAnnulees(
        _dateDebut!,
        _dateFin!,
      );
      final rdv = await _service.getRendezVousTermines(_dateDebut!, _dateFin!);
      if (mounted) {
        setState(() {
          _nbTerminees = terminees;
          _nbAnnulees = annulees;
          _nbRdvTermines = rdv;
          _isLoading = false;
        });
        await _loadPatients();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('hclist_error_snack'.tr(namedArgs: {'msg': '$e'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadPatients() async {
    if (_dateDebut == null || _dateFin == null) return;
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> patients;
      if (_selectedCategory == 'tous') {
        patients = await _service.getPatientsParStatut(
          'tous',
          _dateDebut!,
          _dateFin!,
        );
      } else if (_selectedCategory == 'terminees') {
        patients = await _service.getPatientsParStatut(
          'terminer',
          _dateDebut!,
          _dateFin!,
        );
      } else if (_selectedCategory == 'annulees') {
        patients = await _service.getPatientsParStatut(
          'annuler',
          _dateDebut!,
          _dateFin!,
        );
      } else {
        patients = await _service.getPatientsRdvTermines(
          _dateDebut!,
          _dateFin!,
        );
      }
      if (mounted) {
        setState(() {
          _patients = patients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('hclist_error_snack'.tr(namedArgs: {'msg': '$e'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDebut) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDebut
          ? (_dateDebut ?? DateTime.now())
          : (_dateFin ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: medPrimaryColor,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = DateTime(picked.year, picked.month, picked.day);
        } else {
          _dateFin = DateTime(
            picked.year,
            picked.month,
            picked.day,
            23,
            59,
            59,
          );
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'stats_date_pick'.tr();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color get _categoryColor {
    if (_selectedCategory == 'annulees') return medErrorColor;
    if (_selectedCategory == 'rdv') return medInfoColor;
    return medSuccessColor;
  }

  // ---- BUILD ----

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F3),
      appBar: AppBar(
        backgroundColor: medPrimaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'stats_title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: !isDesktop,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.refresh, color: Colors.white),
              ),
              onPressed: _loadStatistiques,
              tooltip: 'pay_refresh'.tr(),
            ),
          ),
          if (_patients.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.print, color: Colors.white),
              tooltip: 'stats_print_tooltip'.tr(),
              onPressed: _printPatientList,
            ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 900 : double.infinity,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(isDesktop ? 20 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateSelector(),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: medPrimaryColor),
                    ),
                  )
                else ...[
                  _buildStatCards(),
                  const SizedBox(height: 20),
                  _buildPatientList(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Sélecteur de dates ----

  Widget _buildDateSelector() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: medPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.date_range_rounded,
                  color: medPrimaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'stats_period_section'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 14),

          // Boutons date
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  label: 'stats_date_start'.tr(),
                  date: _dateDebut,
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateButton(
                  label: 'stats_date_end'.tr(),
                  date: _dateFin,
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bouton valider
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadStatistiques,
              icon: const Icon(
                Icons.bar_chart_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                'stats_btn_show'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: medPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 13,
                  color: medPrimaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(date),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C2E),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- Cartes statistiques ----

  Widget _buildStatCards() {
    final int nbTotal = _nbTerminees + _nbAnnulees;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFilterButton(
                label: 'Tout',
                count: nbTotal,
                color: medPrimaryColor,
                category: 'tous',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFilterButton(
                label: 'Valider',
                count: _nbTerminees,
                color: medSuccessColor,
                category: 'terminees',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildFilterButton(
                label: 'Annuler',
                count: _nbAnnulees,
                color: medErrorColor,
                category: 'annulees',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFilterButton(
                label: 'Rendez-vous',
                count: _nbRdvTermines,
                color: medInfoColor,
                category: 'rdv',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterButton({
    required String label,
    required int count,
    required Color color,
    required String category,
  }) {
    final isSelected = _selectedCategory == category;

    return InkWell(
      onTap: () {
        setState(() => _selectedCategory = category);
        _loadPatients();
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black87,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Liste patients ----

  Widget _buildPatientList() {
    // Grouper par patient unique
    final Map<dynamic, Map<String, dynamic>> uniquePatients = {};
    for (var c in _patients) {
      final patient = c['Patient'] as Map<String, dynamic>?;
      final idPatient = patient?['id_patient']?.toString();
      if (idPatient == null) continue;
      if (!uniquePatients.containsKey(idPatient)) {
        uniquePatients[idPatient] = {...c, 'nombre_sessions': 1};
      } else {
        uniquePatients[idPatient]!['nombre_sessions'] =
            (uniquePatients[idPatient]!['nombre_sessions'] as int) + 1;
      }
    }
    final patientsList = uniquePatients.values.toList();

    String categoryLabel = 'stats_label_completed'.tr();
    if (_selectedCategory == 'annulees') {
      categoryLabel = 'stats_label_cancelled'.tr();
    }
    if (_selectedCategory == 'rdv') categoryLabel = 'stats_label_rdv'.tr();

    if (patientsList.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.only(top: 40),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_search, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'stats_empty_title'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'stats_empty_msg'.tr(),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête liste
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  Icons.people_rounded,
                  size: 16,
                  color: _categoryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${patientsList.length} ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _categoryColor,
                        ),
                      ),
                      TextSpan(
                        text: categoryLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1C1C2E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Cards patients
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: patientsList.length,
          itemBuilder: (context, index) =>
              _buildPatientCard(patientsList[index]),
        ),
      ],
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> consultation) {
    final patient = consultation['Patient'] as Map<String, dynamic>?;
    final nom = patient?['nom_complet'] ?? 'pay_value_na'.tr();
    final sexe = patient?['sexe'] ?? '';
    final age = patient?['age']?.toString() ?? '';
    final idPatient = patient?['id_patient']?.toString() ?? '';
    final sessions = consultation['nombre_sessions'] as int? ?? 1;
    final color = _categoryColor;
    final initial = nom.isNotEmpty ? nom[0].toUpperCase() : '?';

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(
            '/Dashboard_Medecin/HistoriquePatient/$idPatient',
            extra: {'nom': nom},
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Infos patient
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

                // Badge sessions + flèche
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$sessions consultation${sessions > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _printPatientList() async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final periodeLabel = (_dateDebut != null && _dateFin != null)
        ? 'stats_pdf_period'.tr(
            namedArgs: {
              'start': dateFormat.format(_dateDebut!),
              'end': dateFormat.format(_dateFin!),
            },
          )
        : 'stats_pdf_all_dates'.tr();

    String categorieLabel;
    switch (_selectedCategory) {
      case 'terminees':
        categorieLabel = 'stats_pdf_cat_completed'.tr();
        break;
      case 'annulees':
        categorieLabel = 'stats_pdf_cat_cancelled'.tr();
        break;
      default:
        categorieLabel = 'stats_pdf_cat_rdv'.tr();
    }

    final pdfPatients = _patients.map((consultation) {
      final patient = consultation['Patient'] as Map<String, dynamic>?;
      final nom = patient?['nom_complet'] ?? 'pay_value_na'.tr();
      final sexe = patient?['sexe'] ?? '';
      final age = patient?['age']?.toString() ?? '';
      final telephone = patient?['telephone']?.toString() ?? '';
      final dateBrute =
          DateTime.tryParse(
            consultation['date_derniere_mise_ajour']?.toString() ?? '',
          ) ??
          DateTime.now();

      return PatientPdfData(
        nom: nom,
        sexe: sexe,
        age: 'clist_age_value'.tr(namedArgs: {'age': age}),
        telephone: telephone,
        dateEnregistrement: dateFormat.format(dateBrute),
        categorie: categorieLabel,
      );
    }).toList();

    await PatientListPdfGenerator.previewAndPrint(
      context: context,
      serviceName: 'stats_pdf_service'.tr(),
      periodeLabel: periodeLabel,
      patients: pdfPatients,
      showCategorie: true,
      categorieLabel: 'stats_pdf_cat_label'.tr(),
    );
  }
}
