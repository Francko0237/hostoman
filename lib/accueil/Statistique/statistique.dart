import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'service.dart';
import 'package:hostoman/model_unifier.dart';
import 'package:hostoman/shared/pdf_generator.dart';
import 'package:go_router/go_router.dart';

// Internal group ID -> localization key
const Map<String, String> _kGroupLabels = {
  'Consultation de 0 à 5 ans': 'accstat_group_0_5',
  'Consultation plus de 5 ans': 'accstat_group_5_plus',
  'Rendez-vous': 'accstat_group_rdv',
  'CPN': 'accstat_group_cpn',
};
String _groupLabel(String groupId) {
  final key = _kGroupLabels[groupId];
  return key != null ? key.tr() : groupId;
}

// --- CONSTANTES DE COULEURS (COHÉRENTES AVEC L'APP) ---
const Color npPrimaryColor = Color(0xFF1565C0);
const Color npAccentColor = Color(0xFF2196F3);
const Color npSuccessColor = Color(0xFF4CAF50);
const Color npErrorColor = Color(0xFFD32F2F);
const Color npWarningColor = Color(0xFFFF9800);
const Color npPageBackgroundStart = Color(0xFF0D47A1);
const Color npPageBackgroundEnd = Color(0xFF1976D2);

class RapportPatientPage extends StatefulWidget {
  const RapportPatientPage({super.key});

  @override
  State<RapportPatientPage> createState() => _RapportPatientPageState();
}

class _RapportPatientPageState extends State<RapportPatientPage> {
  final service = RapportPatientService(Supabase.instance.client);
  DateTime? _start;
  DateTime? _end;
  bool _loading = false;
  Map<String, List<Patient>> _grouped = {};

  final List<String> allGroups = [
    'Consultation de 0 à 5 ans',
    'Consultation plus de 5 ans',
    'Rendez-vous',
    'CPN',
  ];

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: npPrimaryColor, // Couleur harmonisée
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  Future<void> _generate() async {
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Text('accstat_pick_both'.tr()),
            ],
          ),
          backgroundColor: npWarningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
      _grouped = {};
    });

    final result = await service.fetchGroupedPatients(_start!, _end!);
    setState(() {
      _grouped = result;
      _loading = false;
    });

    if (result.values.every((list) => list.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              Text('accstat_none_found'.tr()),
            ],
          ),
          backgroundColor: npPrimaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  int _getTotalConsultations() {
    int total = 0;
    final consultations = _grouped['Consultation de 0 à 5 ans'] ?? [];
    final consultationsPlus = _grouped['Consultation plus de 5 ans'] ?? [];
    total += consultations.length;
    total += consultationsPlus.length;
    return total;
  }

  Widget _buildDateSelector(String label, DateTime? date, bool isStart) {
    return Expanded(
      child: InkWell(
        onTap: () => _pickDate(isStart),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: date != null ? npAccentColor : Colors.grey.shade300,
              width: date != null ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: date != null ? npPrimaryColor : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                date == null
                    ? 'accstat_pick_date'.tr()
                    : DateFormat('dd/MM/yyyy').format(date),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: date != null ? Colors.black87 : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientTile(Patient p) {
    String sexe = p.sexe.trim();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: () => context.pushNamed(
          'detail_patient',
          pathParameters: {'id': p.id_patient.toString()},
        ),
        leading: CircleAvatar(
          backgroundColor: npPrimaryColor.withOpacity(0.1),
          child: Text(
            p.nom_complet.isNotEmpty ? p.nom_complet[0].toUpperCase() : '?',
            style: const TextStyle(
              color: npPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          p.nom_complet,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Row(
          children: [
            sexe == 'Homme'
                ? const Icon(Icons.man, size: 16, color: npPrimaryColor)
                : const Icon(Icons.woman, size: 16, color: Colors.pink),
            const SizedBox(width: 4),
            Text(
              p.sexe.toString(),
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: npAccentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            DateFormat('dd/MM/yyyy').format(p.date_enregistrement),
            style: const TextStyle(
              fontSize: 12,
              color: npPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getGroupIcon(String group) {
    if (group.contains('0 à 5')) return Icons.child_care;
    if (group.contains('plus de 5')) return Icons.person;
    if (group.contains('Rendez-vous')) return Icons.event;
    if (group.contains('CPN')) return Icons.pregnant_woman;
    return Icons.medical_services;
  }

  Color _getGroupColor(String group) {
    // Couleurs plus professionnelles (bleu/sarcelle/gris)
    if (group.contains('0 à 5')) return Colors.teal.shade600;
    if (group.contains('plus de 5')) return npPrimaryColor;
    if (group.contains('Rendez-vous')) return Colors.blueGrey.shade700;
    if (group.contains('CPN')) return Colors.indigo.shade500;
    return npAccentColor;
  }

  Widget _buildGroup(String title, List<Patient> patients) {
    final color = _getGroupColor(title);
    final icon = _getGroupIcon(title);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey.shade800,
            ),
          ),
          subtitle: Text(
            (patients.length > 1
                    ? 'accstat_patient_many'
                    : 'accstat_patient_one')
                .tr(namedArgs: {'count': '${patients.length}'}),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${patients.length}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          children: patients.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'accstat_empty_group'.tr(),
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ]
              : [
                  const SizedBox(height: 8),
                  ...patients.map(_buildPatientTile),
                  const SizedBox(height: 12),
                ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAllGroups() {
    return allGroups.map((group) {
      final patients = _grouped[group] ?? [];
      return _buildGroup(_groupLabel(group), patients);
    }).toList();
  }

  int _getTotalCases() {
    int total = 0;
    for (var group in allGroups) {
      total += (_grouped[group] ?? []).length;
    }
    return total;
  }

  Future<void> _printPatientList() async {
    // Fusionner tous les patients, triés par catégorie
    final List<PatientPdfData> allPatients = [];
    for (var group in allGroups) {
      final patients = _grouped[group] ?? [];
      for (var p in patients) {
        allPatients.add(
          PatientPdfData(
            nom: p.nom_complet,
            sexe: p.sexe,
            age: 'list_age_years'.tr(namedArgs: {'age': '${p.age}'}),
            telephone: p.telephone.toString(),
            dateEnregistrement: DateFormat(
              'dd/MM/yyyy',
            ).format(p.date_enregistrement),
            categorie: _groupLabel(group),
          ),
        );
      }
    }

    final periodeLabel = (_start != null && _end != null)
        ? 'accstat_period_label'.tr(
            namedArgs: {
              'start': DateFormat('dd/MM/yyyy').format(_start!),
              'end': DateFormat('dd/MM/yyyy').format(_end!),
            },
          )
        : 'accstat_period_all'.tr();

    await PatientListPdfGenerator.previewAndPrint(
      context: context,
      serviceName: 'accstat_service_name'.tr(),
      periodeLabel: periodeLabel,
      patients: allPatients,
      showCategorie: true,
      categorieLabel: 'accstat_cat_label'.tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: npPageBackgroundStart, // Fond cohérent
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.analytics_outlined, color: npPrimaryColor),
            const SizedBox(width: 10),
            Text(
              'accstat_title'.tr(),
              style: const TextStyle(
                color: npPrimaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: npPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_grouped.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.print, color: npAccentColor),
              tooltip: 'accstat_print'.tr(),
              onPressed: _printPatientList,
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [npPageBackgroundStart, npPageBackgroundEnd],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 700;
            final maxW = isDesktop ? 960.0 : double.infinity;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: Column(
                  children: [
                    // Zone de sélection de date (Style "Card" flottante)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildDateSelector(
                                  'accstat_date_start'.tr(),
                                  _start,
                                  true,
                                ),
                                const SizedBox(width: 12),
                                _buildDateSelector(
                                  'accstat_date_end'.tr(),
                                  _end,
                                  false,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _loading ? null : _generate,
                                icon: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.search),
                                label: Text(
                                  _loading
                                      ? 'accstat_analyzing'.tr()
                                      : 'accstat_generate'.tr(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: npAccentColor,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Contenu principal (Résultats)
                    Expanded(
                      child: _grouped.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.bar_chart,
                                      size: 60,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'accstat_select_period'.tr(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                              child: Container(
                                color: Colors
                                    .grey
                                    .shade50, // Fond clair pour les listes
                                child: ListView(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  children: [
                                    // Cartes de statistiques
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Row(
                                        children: [
                                          _buildStatCard(
                                            'accstat_consultations'.tr(),
                                            '${_getTotalConsultations()}',
                                            Icons.medical_services,
                                            npPrimaryColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Titre de section
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 4,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: npAccentColor,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'accstat_details_by_cat'.tr(),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Groupes de patients
                                    ..._buildAllGroups(),
                                    const SizedBox(
                                      height: 80,
                                    ), // Espace pour le footer flottant
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      // Footer Flottant (Total)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _grouped.isNotEmpty
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, color: npPrimaryColor),
                  const SizedBox(width: 12),
                  Text(
                    'accstat_total_label'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_getTotalCases()}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: npAccentColor,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
