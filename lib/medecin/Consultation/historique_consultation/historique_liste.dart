import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'historique_service.dart';

import 'historique_patient_page.dart';

const Color medPrimaryColor = Color(0xFF6A5ACD);
const Color medAccentColor = Color(0xFF6A5ACD);
const Color medSuccessColor = Color(0xFF4CAF50);

class HistoriqueConsultationPage extends StatefulWidget {
  const HistoriqueConsultationPage({super.key});

  @override
  State<HistoriqueConsultationPage> createState() =>
      _HistoriqueConsultationPageState();
}

class _HistoriqueConsultationPageState
    extends State<HistoriqueConsultationPage> {
  late final HistoriqueConsultationService _service;
  List<Map<String, dynamic>> _consultations = [];
  List<Map<String, dynamic>> _filteredConsultations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortOrder = 'date';

  @override
  void initState() {
    super.initState();
    _service = HistoriqueConsultationService(Supabase.instance.client);
    _loadConsultations();
  }

  Future<void> _loadConsultations() async {
    setState(() => _isLoading = true);
    try {
      final consultations = await _service.getConsultationsTerminees();
      if (mounted) {
        setState(() {
          _consultations = consultations;
          _applyFilters();
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

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_consultations);
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((c) {
        final nom =
            (c['Patient'] as Map?)?['nom_complet']?.toString().toLowerCase() ??
            '';
        return nom.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Regrouper par patient unique (ne conserver que la visite la plus récente)
    final Map<String, Map<String, dynamic>> uniquePatients = {};
    for (var c in filtered) {
      final patient = c['Patient'] as Map<String, dynamic>?;
      if (patient != null) {
        final idPatient = patient['id_patient']?.toString();
        if (idPatient != null) {
          if (!uniquePatients.containsKey(idPatient)) {
            uniquePatients[idPatient] = c;
          } else {
            final dateA =
                DateTime.tryParse(
                  c['date_derniere_mise_ajour']?.toString() ?? '',
                ) ??
                DateTime(2000);
            final dateB =
                DateTime.tryParse(
                  uniquePatients[idPatient]!['date_derniere_mise_ajour']
                          ?.toString() ??
                      '',
                ) ??
                DateTime(2000);
            if (dateA.isAfter(dateB)) {
              uniquePatients[idPatient] = c;
            }
          }
        }
      }
    }
    filtered = uniquePatients.values.toList();

    if (_sortOrder == 'a-z') {
      filtered.sort(
        (a, b) => ((a['Patient'] as Map?)?['nom_complet'] ?? '').compareTo(
          (b['Patient'] as Map?)?['nom_complet'] ?? '',
        ),
      );
    } else if (_sortOrder == 'z-a') {
      filtered.sort(
        (a, b) => ((b['Patient'] as Map?)?['nom_complet'] ?? '').compareTo(
          (a['Patient'] as Map?)?['nom_complet'] ?? '',
        ),
      );
    } else {
      filtered.sort(
        (a, b) =>
            DateTime.tryParse(
              b['date_derniere_mise_ajour']?.toString() ?? '',
            )!.compareTo(
              DateTime.tryParse(
                a['date_derniere_mise_ajour']?.toString() ?? '',
              )!,
            ),
      );
    }
    setState(() => _filteredConsultations = filtered);
  }

  String _getSortLabel() {
    switch (_sortOrder) {
      case 'a-z':
        return 'pay_sort_short_az'.tr();
      case 'z-a':
        return 'pay_sort_short_za'.tr();
      default:
        return 'pay_sort_short_recent'.tr();
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
        title: Text(
          'hclist_title'.tr(),
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
              onPressed: _loadConsultations,
              tooltip: 'pay_refresh'.tr(),
            ),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF5F3F3),
        child: Column(
          children: [
            // Barre de recherche + filtre
            Container(
              padding: EdgeInsets.all(isDesktop ? 20 : 16),
              color: const Color(0xFFF5F3F3),
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
                              prefixIcon: const Icon(
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
                              setState(() => _searchQuery = value);
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
                            setState(() => _sortOrder = value);
                            _applyFilters();
                          },
                          itemBuilder: (context) => [
                            _buildFilterMenuItem(
                              value: 'date',
                              icon: Icons.access_time,
                              label: 'pay_sort_date_desc'.tr(),
                              isSelected: _sortOrder == 'date',
                            ),
                            const PopupMenuDivider(),
                            _buildFilterMenuItem(
                              value: 'a-z',
                              icon: Icons.sort_by_alpha,
                              label: 'pay_sort_name_asc'.tr(),
                              isSelected: _sortOrder == 'a-z',
                            ),
                            const PopupMenuDivider(),
                            _buildFilterMenuItem(
                              value: 'z-a',
                              icon: Icons.sort_by_alpha,
                              label: 'pay_sort_name_desc'.tr(),
                              isSelected: _sortOrder == 'z-a',
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
            if (!_isLoading && _filteredConsultations.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 900 : double.infinity,
                    ),
                    child: Text(
                      (_filteredConsultations.length > 1
                              ? 'hclist_count_many'
                              : 'hclist_count_one')
                          .tr(
                            namedArgs: {
                              'count': '${_filteredConsultations.length}',
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
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: medPrimaryColor,
                          ),
                        )
                      : _filteredConsultations.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.all(isDesktop ? 20 : 16),
                          itemCount: _filteredConsultations.length,
                          itemBuilder: (context, index) =>
                              _buildPatientCard(_filteredConsultations[index]),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> consultation) {
    final patient = consultation['Patient'] as Map<String, dynamic>?;
    final nom = patient?['nom_complet'] ?? 'pay_value_na'.tr();
    final sexe = patient?['sexe'] ?? '';
    final age = patient?['age']?.toString() ?? '';
    final date = _formatDate(consultation['date_derniere_mise_ajour']);

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
            if (patient != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoriquePatientPage(
                    idPatient: patient['id_patient']?.toString() ?? '',
                    patientName: nom,
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar cercle — dégradé VERT
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        medPrimaryColor,
                        medPrimaryColor.withOpacity(0.7),
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

                // Badge dernière visite (violet) + flèche
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: medPrimaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: medPrimaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 12,
                            color: medPrimaryColor.withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: medPrimaryColor.withOpacity(0.9),
                            ),
                          ),
                        ],
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

  Widget _buildEmptyState() {
    return Center(
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
              child: const Icon(
                Icons.folder_open_rounded,
                size: 64,
                color: medPrimaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'hclist_empty_title'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: medPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'hclist_empty_msg'.tr(),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? d) {
    if (d == null) return 'pay_value_na'.tr();
    final date = DateTime.parse(d);
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}
