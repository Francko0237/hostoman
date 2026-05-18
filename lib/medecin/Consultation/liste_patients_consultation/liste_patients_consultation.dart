import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

// Imports
import 'package:hostoman/model_unifier.dart';
import 'service_liste_patients.dart';

// Couleurs - Thème Médecin
const Color medPrimaryColor = Color(0xFF5A47C9);
const Color medAccentColor = Color(0xFF5A47C9);
const Color medSuccessColor = Color(0xFF4CAF50);
const Color medErrorColor = Color(0xFFD32F2F);
const Color medOrangeColor = Color(0xFFFF9800);

class ConsultationList extends StatefulWidget {
  const ConsultationList({super.key});

  @override
  State<ConsultationList> createState() => _ConsultationListState();
}

class _ConsultationListState extends State<ConsultationList> {
  final ConsultationService consultationService = ConsultationService(
    Supabase.instance.client,
  );
  List<Map<String, dynamic>> consultations = [];
  List<Map<String, dynamic>> filteredConsultations = [];
  bool isLoading = true;
  String searchQuery = '';
  String sortOption = 'date_desc';

  @override
  void initState() {
    super.initState();
    chargerConsultations();
  }

  Future<void> chargerConsultations() async {
    setState(() => isLoading = true);
    consultations = await consultationService.getPatientsEnAttente();
    _applyFilters();
    setState(() => isLoading = false);
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
            const Icon(Icons.warning_amber_rounded, color: medErrorColor),
            const SizedBox(width: 12),
            Text('clist_dlg_cancel_title'.tr()),
          ],
        ),
        content: Text(
          'clist_dlg_cancel_msg'.tr(namedArgs: {'name': nomPatient}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('pay_dlg_cancel_no'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: medErrorColor),
            child: Text(
              'pay_dlg_cancel_yes'.tr(),
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
              'clist_cancelled_snack'.tr(namedArgs: {'name': nomPatient}),
            ),
            backgroundColor: medErrorColor,
          ),
        );
        await chargerConsultations();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('clist_error_snack'.tr(namedArgs: {'msg': '$e'})),
            backgroundColor: medErrorColor,
          ),
        );
      }
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
            const SizedBox(width: 50),
            Text(
              'clist_title'.tr(),
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
                              ? 'pay_count_many'
                              : 'pay_count_one')
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
                                  'pay_loading'.tr(),
                                  style: TextStyle(
                                    color: medPrimaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
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
                                  'clist_empty_title'.tr(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: medPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'clist_empty_msg'.tr(),
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

                          // Pour récuperer les infos de la page services et l'uiliser dans l'ui et
                          //itemBuilder: (context, index) { permet de prendre element par element comme un compteur qui permet de recuperer les données de maniere final idConsultation = item['id_consultation'].toString();
                          itemBuilder: (context, index) {
                            final item = filteredConsultations[index];
                            final patientMap =
                                item['Patient'] as Map<String, dynamic>;
                            patientMap['id_patient'] = item['id_patient'];
                            final patient = Patient.fromMap(patientMap);
                            final idConsultation = item['id_consultation']
                                .toString();
                            final motif =
                                item['type_service'] ??
                                'clist_default_motif'.tr();

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
                                  onTap: () {
                                    context.push(
                                      '/Dashboard_Medecin/FicheConsultation/$idConsultation',
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
                                                medPrimaryColor,
                                                medAccentColor.withOpacity(0.7),
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
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    patient.sexe == 'Homme'
                                                        ? Icons.man
                                                        : Icons.woman,
                                                    size: 16,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    patient.sexe,
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
                                                    'clist_age_value'.tr(
                                                      namedArgs: {
                                                        'age': '${patient.age}',
                                                      },
                                                    ),
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
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: medOrangeColor.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.medical_services,
                                                size: 14,
                                                color: medOrangeColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                motif,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: medOrangeColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        IconButton(
                                          onPressed: () {
                                            _annulerConsultation(
                                              idConsultation,
                                              patient.nom_complet,
                                            );
                                          },
                                          icon: Icon(
                                            Icons.cancel,
                                            color: medErrorColor,
                                            size: 28,
                                          ),
                                          tooltip: 'clist_cancel_tooltip'.tr(),
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
        return 'pay_sort_short_default'.tr();
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
