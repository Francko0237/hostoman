import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hostoman/model_unifier.dart';
import 'service_liste.dart';
import 'modifer_patient.dart';
import 'dart:ui';

// Couleurs
const Color npPrimaryColor = Color(0xFF1565C0);
const Color npAccentColor = Color(0xFF2196F3);
const Color npSuccessColor = Color(0xFF4CAF50);
const Color npErrorColor = Color(0xFFD32F2F);
const Color npPageBackgroundStart = Color(0xFF0D47A1);
const Color npPageBackgroundEnd = Color(0xFF1976D2);

class ListePatients extends StatefulWidget {
  const ListePatients({super.key});

  @override
  State<ListePatients> createState() => _ListePatientsState();
}

class _ListePatientsState extends State<ListePatients> {
  final service = PatientService(Supabase.instance.client);
  final ScrollController _scrollController = ScrollController();

  List<Patient> _allPatients = [];
  List<Patient> _filteredPatients = [];

  String _searchQuery = '';
  String _sortOption = 'date_desc';

  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadInitialPatients();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        if (!_isSearching) _loadMorePatients();
      }
    });
  }

  //Pour supprimer les patients
  Future<void> _supprimerPatient(String id) async {
    try {
      await service.supprimerPatient(id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(width: 12),
              Text(
                'list_delete_success'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: npSuccessColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
          elevation: 6,
        ),
      );

      _loadInitialPatients(); // recharge la liste
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'list_delete_error'.tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: npErrorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
          elevation: 6,
        ),
      );
      print('❌ Erreur suppression: $e');
    }
  }
  // Suprimmer les patients

  // N'oublie pas d'importer ceci pour le flou

  void _confirmerSuppression(Patient p) async {
    final confirm = await showDialog<bool>(
      context: context,
      // Rend l'arrière-plan un peu sombre mais transparent
      barrierColor: const Color(0xFF0F172A).withOpacity(0.4),
      builder: (context) => BackdropFilter(
        // L'effet de flou "Glassmorphism" moderne
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          backgroundColor:
              Colors.transparent, // Important pour l'effet flottant
          elevation: 0,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 380),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28), // Coins très arrondis
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 32),

                // 1. L'ICÔNE D'ALERTE (Style "Avatar")
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: npErrorColor.withOpacity(
                      0.1,
                    ), // Fond rouge très pâle
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: npErrorColor,
                      size: 32,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 2. LE TITRE & LE TEXTE
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        'list_delete_title'.tr(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(
                            0xFF1E293B,
                          ), // Gris très foncé (Slate 900)
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(text: 'list_delete_intro'.tr()),
                            TextSpan(
                              text: p.nom_complet,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            TextSpan(
                              text: 'list_delete_irreversible_part'.tr(),
                            ),
                            TextSpan(
                              text: 'list_delete_irreversible'.tr(),
                              style: TextStyle(
                                color: npErrorColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: 'list_delete_dot'.tr()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 3. LES BOUTONS (Séparateur + Actions)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Bouton Annuler
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(28),
                              ),
                            ),
                          ),
                          child: Text(
                            'list_delete_cancel'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),

                      // Ligne verticale de séparation
                      Container(
                        width: 1,
                        height: 60,
                        color: Colors.grey.shade100,
                      ),

                      // Bouton Supprimer
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(28),
                              ),
                            ),
                          ),
                          child: Text(
                            'list_delete_confirm'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: npErrorColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm == true) {
      await _supprimerPatient(p.id_patient!);
    }
  }

  Future<void> _loadInitialPatients() async {
    _currentPage = 0;
    _hasMore = true;
    final patients = await service.fetchPatientsPaginated(page: _currentPage);
    setState(() {
      _allPatients = patients;
      _currentPage++;
      _hasMore = patients.length == 10;
      _applyFilters();
    });
  }

  Future<void> _loadMorePatients() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final newPatients = await service.fetchPatientsPaginated(
      page: _currentPage,
    );
    setState(() {
      _allPatients.addAll(newPatients);
      _currentPage++;
      _hasMore = newPatients.length == 10;
      _applyFilters();
      _isLoadingMore = false;
    });
  }

  Future<void> _searchPatients(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _applyFilters();
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await service.searchPatientsByName(query);
    setState(() {
      _filteredPatients = results;
      _hasMore = false;
    });
  }

  void _applyFilters() {
    List<Patient> temp = [..._allPatients];

    switch (_sortOption) {
      case 'name_asc':
        temp.sort(
          (a, b) =>
              _normalize(a.nom_complet).compareTo(_normalize(b.nom_complet)),
        );
        break;
      case 'name_desc':
        temp.sort(
          (a, b) =>
              _normalize(b.nom_complet).compareTo(_normalize(a.nom_complet)),
        );
        break;
      case 'date_desc':
        temp.sort((a, b) {
          return b.date_enregistrement.compareTo(
            a.date_enregistrement,
          ); // ✅ plus simple et plus rapide
        });
        break;
    }

    setState(() {
      _filteredPatients = temp;
    });
  }

  String _normalize(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[éèêëàâäîïôöûüç]'), '');
  }

  void _handleAction(String action, Patient p) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ModifierPatientPage(patient: p)),
        );
        break;
      case 'delete':
        _confirmerSuppression(p);

        break;

        print('Supprimer ${p.nom_complet}');
        break;
    }
  }

  String _getSortLabel() {
    switch (_sortOption) {
      case 'name_asc':
        return 'list_sort_name_asc'.tr();
      case 'name_desc':
        return 'list_sort_name_desc'.tr();
      case 'date_desc':
        return 'list_sort_date_desc'.tr();
      default:
        return 'list_sort'.tr();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: npPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.people, color: npPrimaryColor, size: 24),
            const SizedBox(width: 12),
            Text(
              'list_title'.tr(),
              style: TextStyle(
                color: npPrimaryColor,
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
                  color: npAccentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.refresh, color: npAccentColor),
              ),
              onPressed: _loadInitialPatients,
              tooltip: 'list_refresh'.tr(),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [npPageBackgroundStart, npPageBackgroundEnd],
          ),
        ),
        child: Column(
          children: [
            // 🔍 Barre de recherche + filtre
            Container(
              padding: EdgeInsets.all(isDesktop ? 20 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
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
                              hintText: 'list_search_hint'.tr(),
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              prefixIcon: Icon(
                                Icons.search,
                                color: npPrimaryColor,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onChanged: (value) {
                              _searchQuery = value;
                              _searchPatients(value);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: npPrimaryColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: npPrimaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: PopupMenuButton<String>(
                          icon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
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
                          tooltip: 'list_sort'.tr(),
                          color: Colors.white,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            setState(() => _sortOption = value);
                            _isSearching
                                ? _searchPatients(_searchQuery)
                                : _applyFilters();
                          },
                          itemBuilder: (context) => [
                            _buildPopupMenuItem(
                              value: 'name_asc',
                              icon: Icons.sort_by_alpha,
                              label: 'list_sort_name_asc'.tr(),
                              isSelected: _sortOption == 'name_asc',
                            ),
                            const PopupMenuDivider(),
                            _buildPopupMenuItem(
                              value: 'name_desc',
                              icon: Icons.sort_by_alpha,
                              label: 'list_sort_name_desc'.tr(),
                              isSelected: _sortOption == 'name_desc',
                            ),
                            const PopupMenuDivider(),
                            _buildPopupMenuItem(
                              value: 'date_desc',
                              icon: Icons.access_time,
                              label: 'list_sort_date_desc'.tr(),
                              isSelected: _sortOption == 'date_desc',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Compteur de patients
            if (_filteredPatients.isNotEmpty)
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
                      (_filteredPatients.length > 1
                              ? 'list_count_many'
                              : 'list_count_one')
                          .tr(
                            namedArgs: {'count': '${_filteredPatients.length}'},
                          ),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

            // 📋 Liste des patients + loader + footer
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 900 : double.infinity,
                  ),
                  child: _filteredPatients.isEmpty
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
                                    color: npAccentColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: npAccentColor,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'list_empty_title'.tr(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: npPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'list_empty_subtitle'.tr(),
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
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.all(isDesktop ? 20 : 16),
                          itemCount:
                              _filteredPatients.length +
                              (_isLoadingMore ? 1 : 0) +
                              (_hasMore ? 0 : 1),
                          itemBuilder: (context, index) {
                            if (index >= _filteredPatients.length) {
                              if (_isLoadingMore) {
                                return Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                );
                              } else if (!_hasMore) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'list_copyright'.tr(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }

                            final p = _filteredPatients[index];
                            return _buildPatientCard(p, isDesktop);
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

  PopupMenuItem<String> _buildPopupMenuItem({
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
            color: isSelected ? npAccentColor : Colors.grey[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? npAccentColor : Colors.grey[800],
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          if (isSelected) Icon(Icons.check, color: npAccentColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildPatientCard(Patient p, bool isDesktop) {
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
            final id = p.id_patient; // id du patient depuis ton modèle
            context.push('/Dashboard_Accueil/Detail_Patient/${p.id_patient}');
            // ou context.push(...) selon ce que tu utilises
          },

          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [npPrimaryColor, npAccentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: npAccentColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      p.nom_complet[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nom_complet,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: npAccentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cake,
                                  size: 14,
                                  color: npAccentColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'list_age_years'.tr(
                                    namedArgs: {'age': '${p.age}'},
                                  ),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: npAccentColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${p.telephone}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Menu actions
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: npPrimaryColor),
                    tooltip: 'list_actions'.tr(),
                    color: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) => _handleAction(value, p),
                    itemBuilder: (context) => [
                      _buildActionMenuItem(
                        value: 'edit',
                        icon: Icons.edit_outlined,
                        label: 'list_action_edit'.tr(),
                        color: Colors.orange[700]!,
                      ),
                      const PopupMenuDivider(),
                      _buildActionMenuItem(
                        value: 'delete',
                        icon: Icons.delete_outline,
                        label: 'list_action_delete'.tr(),
                        color: npErrorColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildActionMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
