import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/model_unifier.dart';
import 'package:intl/intl.dart';
import 'statistique_service.dart';
import 'package:go_router/go_router.dart';
import 'package:hostoman/shared/pdf_generator.dart';

// Couleurs - Thème Laboratoire
const Color labPrimaryColor = Color(0xFF212031);
const Color labAccentColor = Color(0xFF212031);
const Color labBlueColor = Color(0xFF2196F3);
const Color labGreenColor = Color(0xFF4CAF50);
const Color labGreyColor = Color(0xFF9E9E9E);

class StatistiqueLaboUI extends StatefulWidget {
  const StatistiqueLaboUI({super.key});

  @override
  State<StatistiqueLaboUI> createState() => _StatistiqueLaboUIState();
}

class _StatistiqueLaboUIState extends State<StatistiqueLaboUI> {
  final StatistiqueLaboService statistiqueService = StatistiqueLaboService(
    Supabase.instance.client,
  );

  // Dates par défaut
  DateTime dateDebut = DateTime.now().subtract(const Duration(days: 90));
  DateTime dateFin = DateTime.now();

  // Données
  Map<String, int> statistiques = {'termines': 0, 'annules': 0};
  List<Map<String, dynamic>> patients = [];
  bool isLoading = true;
  String? errorMessage;
  String? statutFiltre; // null = tout, 'Terminé', 'Annulé'

  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }

  Future<void> chargerDonnees() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final stats = await statistiqueService.getStatistiques(
        dateDebut,
        dateFin,
      );
      final patientsList = await statistiqueService.getPatientsAvecExamens(
        dateDebut,
        dateFin,
        statutFiltre: statutFiltre,
      );

      setState(() {
        statistiques = stats;
        patients = patientsList;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'lex_server_error'.tr();
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDebut) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDebut ? dateDebut : dateFin,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: context.locale,
    );

    if (picked != null) {
      setState(() {
        if (isDebut) {
          dateDebut = picked;
        } else {
          dateFin = picked;
        }
      });
      chargerDonnees();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F3),
      appBar: AppBar(
        backgroundColor: labPrimaryColor,
        centerTitle: !isDesktop,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'lstat_title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: chargerDonnees,
          ),
          if (patients.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.print, color: Colors.white),
              tooltip: 'lstat_print_tooltip'.tr(),
              onPressed: _printPatientList,
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: labBlueColor))
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: chargerDonnees,
                    icon: const Icon(Icons.refresh),
                    label: Text('lex_retry'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: labBlueColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 900 : double.infinity,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildPeriodeSection(),
                      const SizedBox(height: 16),
                      _buildStatistiquesCards(),
                      const SizedBox(height: 24),
                      _buildPatientsSection(),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: isDesktop ? null : _buildBottomNav(),
    );
  }

  Widget _buildPeriodeSection() {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 20,
                color: labPrimaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'lstat_period_title'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'lstat_date_start'.tr(),
                  date: dateFormat.format(dateDebut),
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, color: Colors.grey),
              ),
              Expanded(
                child: _buildDateField(
                  label: 'lstat_date_end'.tr(),
                  date: dateFormat.format(dateFin),
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistiquesCards() {
    final int nbTermines = statistiques['termines'] ?? 0;
    final int nbAnnules = statistiques['annules'] ?? 0;
    final int nbTotal = nbTermines + nbAnnules;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterButton(
              label: 'Tout',
              count: nbTotal,
              color: labPrimaryColor,
              isSelected: statutFiltre == null,
              onTap: () {
                setState(() => statutFiltre = null);
                chargerDonnees();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterButton(
              label: 'Valider',
              count: nbTermines,
              color: labGreenColor,
              isSelected: statutFiltre == 'Terminé',
              onTap: () {
                setState(() => statutFiltre = 'Terminé');
                chargerDonnees();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterButton(
              label: 'Annuler',
              count: nbAnnules,
              color: Colors.red,
              isSelected: statutFiltre == 'Annulé',
              onTap: () {
                setState(() => statutFiltre = 'Annulé');
                chargerDonnees();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required int count,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientsSection() {
    // Grouper les patients : un seul enregistrement par id_patient
    final Map<dynamic, Map<String, dynamic>> uniquePatients = {};
    for (var item in patients) {
      final idPatient = item['id_patient'];
      if (!uniquePatients.containsKey(idPatient)) {
        uniquePatients[idPatient] = {
          ...item,
          'nombre_sessions': 1,
        };
      } else {
        uniquePatients[idPatient]!['nombre_sessions'] =
            (uniquePatients[idPatient]!['nombre_sessions'] as int) + 1;
      }
    }
    final patientsList = uniquePatients.values.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'lstat_section_all'.tr(
              namedArgs: {'count': '${patientsList.length}'},
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (patientsList.isEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 40),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_search, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'lstat_empty'.tr(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...patientsList.map((item) {
              final patientMap = Map<String, dynamic>.from(
                item['Patient'] as Map<String, dynamic>,
              );
              patientMap['id_patient'] = item['id_patient'];
              if (!patientMap.containsKey('date_enregistrement') ||
                  patientMap['date_enregistrement'] == null) {
                patientMap['date_enregistrement'] =
                    item['date_enregistrement'] ??
                    DateTime.now().toIso8601String();
              }
              final patient = Patient.fromMap(patientMap);
              final sessions = item['nombre_sessions'] as int? ?? 1;

              return _buildPatientCard(
                patient: patient,
                nombreSessions: sessions,
                idPatient: item['id_patient']?.toString() ?? '',
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPatientCard({
    required Patient patient,
    required int nombreSessions,
    required String idPatient,
  }) {
    final initial = patient.nom_complet.isNotEmpty
        ? patient.nom_complet[0].toUpperCase()
        : 'P';

    return InkWell(
      onTap: () {
        context.push(
          '/Dashboard_Laboratoire/HistoriquePatient/$idPatient',
          extra: {
            'nom': patient.nom_complet,
            'sexe': patient.sexe,
            'age': patient.age,
          },
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: labGreenColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: labGreenColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Infos patient
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.nom_complet,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        patient.sexe == 'Homme' ? Icons.male : Icons.female,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'lstat_sex_age'.tr(
                          namedArgs: {
                            'sexe': patient.sexe,
                            'age': '${patient.age}',
                          },
                        ),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Badge sessions
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: labGreenColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$nombreSessions session${nombreSessions > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: labGreenColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printPatientList() async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final periodeLabel = 'lstat_pdf_period'.tr(
      namedArgs: {
        'start': dateFormat.format(dateDebut),
        'end': dateFormat.format(dateFin),
      },
    );
    final statutLabel = statutFiltre == null
        ? 'lstat_pdf_status_all'.tr()
        : (statutFiltre == 'Terminé'
              ? 'lstat_pdf_status_done'.tr()
              : 'lstat_pdf_status_cancelled'.tr());

    final pdfPatients = patients.map((item) {
      final patientMap = Map<String, dynamic>.from(
        item['Patient'] as Map<String, dynamic>,
      );
      patientMap['id_patient'] = item['id_patient'];
      if (!patientMap.containsKey('date_enregistrement') ||
          patientMap['date_enregistrement'] == null) {
        patientMap['date_enregistrement'] =
            item['date_enregistrement'] ?? DateTime.now().toIso8601String();
      }
      final patient = Patient.fromMap(patientMap);
      final nombreExamens = item['nombre_examens'] ?? 0;
      final dateConsult =
          DateTime.tryParse(item['date_enregistrement'] ?? '') ??
          DateTime.now();

      return PatientPdfData(
        nom: patient.nom_complet,
        sexe: patient.sexe,
        age: 'lex_age_value'.tr(namedArgs: {'age': '${patient.age}'}),
        telephone: patient.telephone.toString(),
        dateEnregistrement: dateFormat.format(dateConsult),
        categorie:
            (nombreExamens > 1
                    ? 'lstat_pdf_cat_value_many'
                    : 'lstat_pdf_cat_value_one')
                .tr(
                  namedArgs: {'count': '$nombreExamens', 'statut': statutLabel},
                ),
      );
    }).toList();

    await PatientListPdfGenerator.previewAndPrint(
      context: context,
      serviceName: 'lstat_pdf_service'.tr(),
      periodeLabel: periodeLabel,
      patients: pdfPatients,
      showCategorie: true,
      categorieLabel: 'lstat_pdf_cat_label'.tr(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 1, // Statistiques
      backgroundColor: Colors.white,
      selectedItemColor: labPrimaryColor,
      unselectedItemColor: Colors.grey.shade500,
      showUnselectedLabels: true,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/Dashboard_Laboratoire');
            break;
          case 1:
            // Already on statistics
            break;
          case 2:
            context.push('/Dashboard_Laboratoire/Historique');
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard),
          label: 'labd_bottom_dashboard'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.bar_chart),
          label: 'labd_bottom_stats'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.history),
          label: 'labd_bottom_history'.tr(),
        ),
      ],
    );
  }
}
