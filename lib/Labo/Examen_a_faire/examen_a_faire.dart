import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

// Imports
import 'examen__faire_service.dart';

// Couleurs - Thème Laboratoire
const Color labPrimaryColor = Color(0xFF212031);
const Color labAccentColor = Color(0xFF212031);
const Color labOrangeColor = Color(0xFFFF9800);

// Classe Patient simplifiée
class Patient {
  final String nom_complet;
  final String sexe;
  final int age;

  Patient.fromMap(Map<String, dynamic> map)
    : nom_complet = map['nom_complet'] ?? 'N/A',
      sexe = map['sexe'] ?? 'N/A',
      age = map['age'] != null ? int.tryParse(map['age'].toString()) ?? 0 : 0;
}

// Info à transférer
class PatientDetailData {
  final String nomComplet;
  final String sexe;
  final String age;
  final String telephone;

  PatientDetailData({
    required this.nomComplet,
    required this.sexe,
    required this.age,
    required this.telephone,
  });
}

class ExamensAFaire extends StatefulWidget {
  const ExamensAFaire({super.key});

  @override
  State<ExamensAFaire> createState() => _ExamensAFaireState();
}

class _ExamensAFaireState extends State<ExamensAFaire> {
  final LaboExamensService laboService = LaboExamensService(
    Supabase.instance.client,
  );

  List<Map<String, dynamic>> examens = [];
  List<Map<String, dynamic>> filteredExamens = [];
  bool isLoading = true;
  String searchQuery = '';
  String sortOption = 'date_desc';
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    chargerExamens();
  }

  // 🔄 AJOUT : Auto-refresh quand on revient sur cette page
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharge automatiquement les données quand on revient sur cette page
    if (mounted) {
      chargerExamens();
    }
  }

  Future<void> chargerExamens() async {
    setState(() => isLoading = true);
    print('🔄 Chargement de la liste des examens...');

    try {
      final allExamens = await laboService.getPatientsEnAttenteExamen();

      // FILTRAGE STRICT : On ne garde que les 'en-attente-examen'
      examens = allExamens
          .where((item) => item['Statut_Consultation'] == 'en-attente-examen')
          .toList();

      print('✅ ${examens.length} patient(s) en attente d\'examen');

      _applyFilters();
      setState(() => isLoading = false);
    } catch (e) {
      print('❌ Erreur de chargement: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'lex_server_error'.tr();
      });
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> temp = [...examens];

    if (searchQuery.isNotEmpty) {
      temp = temp.where((item) {
        final patientMap = item['Patient'] as Map<String, dynamic>;
        final nom = (patientMap['nom_complet'] ?? '').toString().toLowerCase();
        return nom.contains(searchQuery.toLowerCase());
      }).toList();
    }

    switch (sortOption) {
      case 'name_asc':
        temp.sort(
          (a, b) => (a['Patient']['nom_complet'] ?? '')
              .toString()
              .toLowerCase()
              .compareTo(
                (b['Patient']['nom_complet'] ?? '').toString().toLowerCase(),
              ),
        );
        break;
      case 'name_desc':
        temp.sort(
          (a, b) => (b['Patient']['nom_complet'] ?? '')
              .toString()
              .toLowerCase()
              .compareTo(
                (a['Patient']['nom_complet'] ?? '').toString().toLowerCase(),
              ),
        );
        break;
      case 'date_desc':
        temp.sort(
          (a, b) =>
              (DateTime.tryParse(b['date_enregistrement'] ?? '') ??
                      DateTime(2000))
                  .compareTo(
                    DateTime.tryParse(a['date_enregistrement'] ?? '') ??
                        DateTime(2000),
                  ),
        );
        break;
      case 'date_asc':
        temp.sort(
          (a, b) =>
              (DateTime.tryParse(a['date_enregistrement'] ?? '') ??
                      DateTime(2000))
                  .compareTo(
                    DateTime.tryParse(b['date_enregistrement'] ?? '') ??
                        DateTime(2000),
                  ),
        );
        break;
    }

    setState(() {
      filteredExamens = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: labPrimaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.science, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              'lex_title'.tr(),
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
              onPressed: chargerExamens,
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
                                color: labPrimaryColor,
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
                          color: labPrimaryColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: labPrimaryColor.withOpacity(0.3),
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
            if (!isLoading && filteredExamens.isNotEmpty)
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
                      (filteredExamens.length > 1
                              ? 'lex_count_many'
                              : 'lex_count_one')
                          .tr(
                            namedArgs: {'count': '${filteredExamens.length}'},
                          ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: labPrimaryColor,
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
                                  color: labPrimaryColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'lex_loading'.tr(),
                                  style: const TextStyle(
                                    color: labPrimaryColor,
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
                                size: 60,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                child: Text(
                                  errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: chargerExamens,
                                icon: const Icon(Icons.refresh),
                                label: Text('lex_retry'.tr()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: labPrimaryColor,
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
                      : filteredExamens.isEmpty
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
                                    color: labPrimaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_circle_outline,
                                    size: 64,
                                    color: labPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'lex_empty_title'.tr(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: labPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'lex_empty_msg'.tr(),
                                  textAlign: TextAlign.center,
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
                          itemCount: filteredExamens.length,
                          itemBuilder: (context, index) {
                            final item = filteredExamens[index];
                            final patientMap =
                                item['Patient'] as Map<String, dynamic>;

                            final telephone =
                                patientMap['telephone']?.toString() ??
                                'pay_value_na'.tr();
                            final idConsultationInt =
                                item['id_consultation'] as int;
                            final idConsultation = idConsultationInt.toString();

                            patientMap['id_patient'] = item['id_patient'];

                            final patient = Patient.fromMap(patientMap);

                            final variableAPasser = PatientDetailData(
                              nomComplet: patient.nom_complet,
                              sexe: patient.sexe,
                              age: patient.age.toString(),
                              telephone: telephone,
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: labOrangeColor.withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: labOrangeColor.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    // Navigation avec await pour recharger au retour
                                    await context.push(
                                      '/Dashboard_Laboratoire/ExamenDetail/$idConsultation',
                                      extra: variableAPasser,
                                    );
                                    // Recharge automatiquement la liste au retour
                                    print(
                                      '🔄 Retour sur la liste → Rechargement...',
                                    );
                                    chargerExamens();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: labPrimaryColor.withOpacity(
                                              0.1,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              patient.nom_complet[0]
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: labPrimaryColor,
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
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.grey[900],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
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
                                                  const SizedBox(width: 8),
                                                  Icon(
                                                    Icons.cake_outlined,
                                                    size: 13,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Flexible(
                                                    child: Text(
                                                      'lex_age_value'.tr(
                                                        namedArgs: {
                                                          'age':
                                                              '${patient.age}',
                                                        },
                                                      ),
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
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 20,
                                          color: Colors.grey.shade400,
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
            color: isSelected ? labAccentColor : Colors.grey[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? labAccentColor : Colors.grey[800],
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          if (isSelected) Icon(Icons.check, color: labAccentColor, size: 20),
        ],
      ),
    );
  }
}
