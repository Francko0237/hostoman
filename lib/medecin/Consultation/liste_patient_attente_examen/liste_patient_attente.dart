import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

// Imports
import 'package:hostoman/model_unifier.dart';
import 'service_patient_attente.dart';

// Couleurs - Thème Médecin
const Color medPrimaryColor = Color(0xFF5A47C9);
const Color medAccentColor = Color(0xFF5A47C9);
const Color medSuccessColor = Color(0xFF4CAF50);
const Color medErrorColor = Color(0xFFD32F2F);
const Color medOrangeColor = Color(0xFFFF9800);

class EnattenteExam extends StatefulWidget {
  const EnattenteExam({super.key});

  @override
  State<EnattenteExam> createState() => _EnattenteExamState();
}

class _EnattenteExamState extends State<EnattenteExam> {
  final ConsultationService consultationService = ConsultationService(
    Supabase.instance.client,
  );
  List<Map<String, dynamic>> consultations = [];
  List<Map<String, dynamic>> filteredConsultations = [];
  bool isLoading = true;
  String searchQuery = '';
  String sortOption = 'date_desc';
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    chargerConsultations();
  }

  Future<void> chargerConsultations() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      consultations = await consultationService.getPatientsEnAttente();
      _applyFilters();
    } catch (e) {
      print('❌ Erreur de chargement: $e');
      setState(() {
        errorMessage = 'att_error_loading'.tr(namedArgs: {'msg': '$e'});
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> temp = [...consultations];

    if (searchQuery.isNotEmpty) {
      temp = temp.where((item) {
        final patientMap = item['Patient'] as Map<String, dynamic>;
        final nom = (patientMap['nom_complet'] ?? '').toString().toLowerCase();
        return nom.contains(searchQuery.toLowerCase());
      }).toList();
    }

    switch (sortOption) {
      case 'name_asc':
        temp.sort((a, b) {
          final nomA = (a['Patient']['nom_complet'] ?? '')
              .toString()
              .toLowerCase();
          final nomB = (b['Patient']['nom_complet'] ?? '')
              .toString()
              .toLowerCase();
          return nomA.compareTo(nomB);
        });
        break;
      case 'name_desc':
        temp.sort((a, b) {
          final nomA = (a['Patient']['nom_complet'] ?? '')
              .toString()
              .toLowerCase();
          final nomB = (b['Patient']['nom_complet'] ?? '')
              .toString()
              .toLowerCase();
          return nomB.compareTo(nomA);
        });
        break;
      case 'date_desc':
        temp.sort((a, b) {
          final dateA =
              DateTime.tryParse(a['date_enregistrement'] ?? '') ??
              DateTime(2000);
          final dateB =
              DateTime.tryParse(b['date_enregistrement'] ?? '') ??
              DateTime(2000);
          return dateB.compareTo(dateA);
        });
        break;
      case 'date_asc':
        temp.sort((a, b) {
          final dateA =
              DateTime.tryParse(a['date_enregistrement'] ?? '') ??
              DateTime(2000);
          final dateB =
              DateTime.tryParse(b['date_enregistrement'] ?? '') ??
              DateTime(2000);
          return dateA.compareTo(dateB);
        });
        break;
    }

    setState(() {
      filteredConsultations = temp;
    });
  }

  Future<void> _annulerConsultation(
    String idConsultation,
    String nomPatient,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: medErrorColor),
            const SizedBox(width: 12),
            Text('att_cancel_title'.tr()),
          ],
        ),
        content: Text('att_cancel_msg'.tr(namedArgs: {'nom': nomPatient})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('att_cancel_no'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: medErrorColor),
            child: Text(
              'att_cancel_yes'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await consultationService.annulerConsultation(idConsultation);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'att_cancel_success'.tr(namedArgs: {'nom': nomPatient}),
            ),
            backgroundColor: medErrorColor,
          ),
        );
        await chargerConsultations();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('att_cancel_error'.tr(namedArgs: {'msg': '$e'})),
            backgroundColor: medErrorColor,
          ),
        );
      }
    }
  }

  // Fonction pour déterminer la couleur selon le statut
  Color _getStatutColor(String? statutExamen) {
    switch (statutExamen) {
      case 'en-attente-examen':
        return Colors.grey.shade500; // Gris moins foncé (style désactivé)
      case 'en-attente-resultat':
        return medOrangeColor; // Orange
      case 'resultat-disponible':
        return medSuccessColor; // Vert
      case 'Annuler':
        return medErrorColor; // Rouge
      default:
        return Colors.grey.shade400;
    }
  }

  // Fonction pour obtenir le libellé du statut
  String _getStatutLabel(String? statutExamen) {
    switch (statutExamen) {
      case 'en-attente-examen':
        return 'att_status_waiting_exam'.tr();
      case 'en-attente-resultat':
        return 'att_status_waiting_result'.tr();
      case 'resultat-disponible':
        return 'att_status_result_available'.tr();
      case 'Annuler':
        return 'att_status_cancelled'.tr();
      default:
        return 'att_status_unknown'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: medPrimaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const SizedBox(width: 40),
            Text(
              'att_title'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
              onPressed: chargerConsultations,
              tooltip: 'pay_refresh'.tr(),
            ),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF5F3F3),
        child: Column(
          children: [
            // Barre de recherche + filtres
            Container(
              padding: EdgeInsets.all(isDesktop ? 20 : 16),
              decoration: const BoxDecoration(color: Color(0xFFF5F3F3)),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 900 : double.infinity,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'pay_search_hint'.tr(),
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              prefixIcon: Icon(
                                Icons.search,
                                color: medPrimaryColor,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onChanged: (value) {
                              searchQuery = value;
                              _applyFilters();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: medPrimaryColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: medPrimaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: PopupMenuButton<String>(
                          icon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.filter_list,
                                color: Colors.white,
                                size: 20,
                              ),
                              if (isTablet) ...[
                                const SizedBox(width: 8),
                                Text(
                                  _getSortLabel(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          tooltip: 'pay_sort_tooltip'.tr(),
                          color: Colors.white,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            setState(() => sortOption = value);
                            _applyFilters();
                          },
                          itemBuilder: (context) => [
                            _buildFilterMenuItem(
                              value: 'name_asc',
                              icon: Icons.sort_by_alpha,
                              label: 'pay_sort_name_asc'.tr(),
                              isSelected: sortOption == 'name_asc',
                            ),
                            const PopupMenuDivider(),
                            _buildFilterMenuItem(
                              value: 'name_desc',
                              icon: Icons.sort_by_alpha,
                              label: 'pay_sort_name_desc'.tr(),
                              isSelected: sortOption == 'name_desc',
                            ),
                            const PopupMenuDivider(),
                            _buildFilterMenuItem(
                              value: 'date_desc',
                              icon: Icons.access_time,
                              label: 'pay_sort_date_desc'.tr(),
                              isSelected: sortOption == 'date_desc',
                            ),
                            const PopupMenuDivider(),
                            _buildFilterMenuItem(
                              value: 'date_asc',
                              icon: Icons.access_time,
                              label: 'pay_sort_date_asc'.tr(),
                              isSelected: sortOption == 'date_asc',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Compteur
            if (!isLoading && filteredConsultations.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 900 : double.infinity,
                    ),
                    child: Text(
                      (filteredConsultations.length > 1
                              ? 'att_count_many'
                              : 'att_count_one')
                          .tr(
                            namedArgs: {
                              'count': '${filteredConsultations.length}',
                            },
                          ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: medPrimaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

            // Liste
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 900 : double.infinity,
                  ),
                  child: isLoading
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: medPrimaryColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'att_loading'.tr(),
                                  style: const TextStyle(
                                    color: medPrimaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: medErrorColor,
                              ),
                              const SizedBox(height: 16),
                              Text(errorMessage!),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: chargerConsultations,
                                child: Text('att_retry'.tr()),
                              ),
                            ],
                          ),
                        )
                      : filteredConsultations.isEmpty
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            margin: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
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
                                    color: medPrimaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: medPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'att_empty_title'.tr(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: medPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'att_empty_msg'.tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.all(isDesktop ? 20 : 16),
                          itemCount: filteredConsultations.length,
                          itemBuilder: (context, index) {
                            final item = filteredConsultations[index];
                            final patientMap =
                                item['Patient'] as Map<String, dynamic>;
                            patientMap['id_patient'] = item['id_patient'];
                            final patient = Patient.fromMap(patientMap);
                            final idConsultation = item['id_consultation']
                                .toString();
                            final statutExamen =
                                item['Statut_Consultation'] as String?;
                            final Color statutColor = _getStatutColor(
                              statutExamen,
                            );
                            final String statutLabel = _getStatutLabel(
                              statutExamen,
                            );

                            // Extraire les noms des examens (Gestion ultra-sécurisée)
                            final dynamic rawExamens =
                                item['examen_a_effectuer'];
                            final List<dynamic> examensData =
                                (rawExamens is List)
                                ? rawExamens
                                : (rawExamens is Map ? [rawExamens] : []);

                            final String examensList = examensData
                                .map((e) {
                                  if (e is Map) return e['nom_examen'] ?? '';
                                  return e.toString(); // Cas imprévu
                                })
                                .where((name) => name.isNotEmpty)
                                .join(', ');

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: statutColor.withOpacity(0.8),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: statutColor.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    // Si le patient a des résultats disponibles, aller à la finalisation
                                    // Sinon, aller à la fiche de consultation

                                    context.push(
                                      '/Dashboard_Medecin/FinalisationConsultation/$idConsultation',
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                statutColor,
                                                statutColor.withOpacity(0.8),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              patient.nom_complet[0]
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                patient.nom_complet,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  Icon(
                                                    patient.sexe == 'Homme'
                                                        ? Icons.man
                                                        : Icons.woman,
                                                    size: 15,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Flexible(
                                                    child: Text(
                                                      patient.sexe,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              // Badge statut ici pour
                                              // éviter le débordement
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: statutColor
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            statutExamen ==
                                                                    'resultat-disponible'
                                                                ? Icons
                                                                      .check_circle
                                                                : (statutExamen ==
                                                                          'Annuler'
                                                                      ? Icons
                                                                            .cancel
                                                                      : Icons
                                                                            .science),
                                                            size: 13,
                                                            color: statutColor,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Flexible(
                                                            child: Text(
                                                              statutLabel,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    statutColor,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        Container(
                                          decoration: BoxDecoration(
                                            color: medErrorColor.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          child: IconButton(
                                            onPressed: () {
                                              _annulerConsultation(
                                                idConsultation,
                                                patient.nom_complet,
                                              );
                                            },
                                            icon: Icon(
                                              Icons.close_rounded,
                                              color: medErrorColor,
                                              size: 25,
                                            ),
                                            tooltip: 'att_cancel_tooltip'.tr(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel() {
    switch (sortOption) {
      case 'name_asc':
        return 'pay_sort_short_az'.tr();
      case 'name_desc':
        return 'pay_sort_short_za'.tr();
      case 'date_desc':
        return 'pay_sort_short_recent'.tr();
      case 'date_asc':
        return 'pay_sort_short_old'.tr();
      default:
        return 'pay_sort_tooltip'.tr();
    }
  }

  PopupMenuItem<String> _buildFilterMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? medAccentColor : Colors.grey[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? medAccentColor : Colors.grey[800],
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          if (isSelected) Icon(Icons.check, color: medAccentColor, size: 20),
        ],
      ),
    );
  }
}
