import 'package:flutter/material.dart';
import 'package:hostoman/model_unifier.dart';
import 'Service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detail/detail_ui.dart';

// Couleurs
const Color npPrimaryColor = Color(0xFF4CAF50);
const Color npAccentColor = Color(0xFF378127);
const Color npSuccessColor = Color(0xFF4CAF50);
const Color npErrorColor = Color(0xFFD32F2F);
const Color npOrangeColor = Color(0xFFFF9800);
const Color npPageBackgroundStart = Color(0xFF0D47A1);
const Color npPageBackgroundEnd = Color(0xFF1976D2);

class Paiementlist extends StatefulWidget {
  const Paiementlist({super.key});

  @override
  State<Paiementlist> createState() => _PaiementlistState();
}

class _PaiementlistState extends State<Paiementlist> {
  final PaiementService paiementService = PaiementService(
    Supabase.instance.client,
  );
  List<Map<String, dynamic>> consultations = [];
  List<Map<String, dynamic>> examen = [];
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
    consultations = await paiementService.getPatientsNonPayes();
    _applyFilters();
    setState(() => isLoading = false);
  }

  Future<void> chargerExamen() async {
    setState(() => isLoading = true);
    examen = await paiementService.getPatientsNonPayes();
    _applyFilters();
    setState(() => isLoading = false);
  }

  void _applyFilters() {
    List<Map<String, dynamic>> temp = [...consultations];

    // Filtre par recherche
    if (searchQuery.isNotEmpty) {
      temp = temp.where((item) {
        final patientMap = item['Patient'] as Map<String, dynamic>;
        final nom = (patientMap['nom_complet'] ?? '').toString().toLowerCase();
        return nom.contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Tri
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
              DateTime.tryParse(
                a['date_derniere_mise_ajour']?.toString() ??
                    a['date_enregistrement']?.toString() ??
                    '',
              ) ??
              DateTime(2000);
          final dateB =
              DateTime.tryParse(
                b['date_derniere_mise_ajour']?.toString() ??
                    b['date_enregistrement']?.toString() ??
                    '',
              ) ??
              DateTime(2000);
          return dateB.compareTo(dateA);
        });
        break;
      case 'date_asc':
        temp.sort((a, b) {
          final dateA =
              DateTime.tryParse(
                a['date_derniere_mise_ajour']?.toString() ??
                    a['date_enregistrement']?.toString() ??
                    '',
              ) ??
              DateTime(2000);
          final dateB =
              DateTime.tryParse(
                b['date_derniere_mise_ajour']?.toString() ??
                    b['date_enregistrement']?.toString() ??
                    '',
              ) ??
              DateTime(2000);
          return dateA.compareTo(dateB);
        });
        break;
    }

    setState(() {
      filteredConsultations = temp;
    });
  }

  Future<void> validerPaiement(String idConsultation) async {
    await paiementService.validerPaiement(idConsultation);
    await chargerConsultations();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            const Text(
              '✅ Paiement validé',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: npSuccessColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 6,
      ),
    );
  }

  Future<void> AnnulerPaiement(String idConsultation) async {
    final confirm = await _confirmerAnnulation();
    if (confirm != true) return;

    await paiementService.AnnulerPaiement(idConsultation);
    await chargerConsultations();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.white),
            const SizedBox(width: 12),
            const Text(
              'Paiement annulé',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: npErrorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 6,
      ),
    );
  }

  Future<bool?> _confirmerAnnulation() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: npErrorColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cancel,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Annuler le paiement',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Êtes-vous sûr de vouloir annuler ce paiement ?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey[800]),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: Colors.grey.shade400,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Non',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: npErrorColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Oui, annuler',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
        backgroundColor: Color(0xFF274621),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: npPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const SizedBox(width: 12),
            Text(
              'Paiements en attente',
              style: TextStyle(
                color: Color(0xFF26AE6C),
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
                  color: npSuccessColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.refresh, color: npSuccessColor),
              ),
              onPressed: chargerConsultations,
              tooltip: 'Actualiser',
            ),
          ),
        ],
      ),
      body: Container(
        color: Color(0XFFF5F3F3),
        child: Column(
          children: [
            // Barre de recherche + filtres
            Container(
              padding: EdgeInsets.all(isDesktop ? 20 : 16),
              decoration: BoxDecoration(color: Color(0XFFF5F3F3)),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 1200 : double.infinity,
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
                              hintText: 'Rechercher un patient par nom...',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Color(0xFF378127),
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
                          color: Color(0xFF378127),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF378127).withOpacity(0.3),
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
                          tooltip: 'Trier',
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
                              label: 'Nom A → Z',
                              isSelected: sortOption == 'name_asc',
                            ),
                            const PopupMenuDivider(),
                            _buildFilterMenuItem(
                              value: 'name_desc',
                              icon: Icons.sort_by_alpha,
                              label: 'Nom Z → A',
                              isSelected: sortOption == 'name_desc',
                            ),
                            const PopupMenuDivider(),
                            _buildFilterMenuItem(
                              value: 'date_desc',
                              icon: Icons.access_time,
                              label: 'Plus récent',
                              isSelected: sortOption == 'date_desc',
                            ),
                            const PopupMenuDivider(),
                            _buildFilterMenuItem(
                              value: 'date_asc',
                              icon: Icons.access_time,
                              label: 'Plus ancien',
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
                      maxWidth: isDesktop ? 1200 : double.infinity,
                    ),
                    child: Text(
                      '${filteredConsultations.length} patient${filteredConsultations.length > 1 ? 's' : ''} en attente',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4CAF50),
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
                    maxWidth: isDesktop ? 1200 : double.infinity,
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
                                  color: npPrimaryColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Chargement...',
                                  style: TextStyle(
                                    color: npPrimaryColor,
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
                                if (searchQuery.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Aucun résultat trouvé',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Aucun patient ne correspond à "$searchQuery"',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: npSuccessColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_outline,
                                      size: 64,
                                      color: npSuccessColor,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Aucun paiement en attente',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: npPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tous les paiements sont à jour',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
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
                            final List<dynamic> paiementsList =
                                item['paiement'] ?? [];
                            patientMap['id_patient'] = item['id_patient'];
                            final patient = Patient.fromMap(patientMap);

                            // Prendre le dernier paiement (le plus récent)
                            final paiementDataMap =
                                paiementsList.last as Map<String, dynamic>;
                            final finalPaiement = Paiement.fromMap(
                              paiementDataMap,
                            );
                            final idConsultation = item['id_consultation']
                                .toString();

                            // Utiliser le motif du paiement au lieu du type_service
                            final motif =
                                paiementDataMap['motif'] ??
                                'Frais de Consultation';
                            String Sexe = patient.sexe.toString();
                            String prixAPayer =
                                finalPaiement.prix_a_paye?.toString() ??
                                '0.0'; // Prix à payer
                            return InkWell(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailUI(
                                      idConsultation: idConsultation,
                                    ),
                                  ),
                                );
                                // Recharger la liste si le paiement a été modifié
                                if (result == true) {
                                  chargerConsultations();
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  npPrimaryColor,
                                                  npAccentColor,
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
                                                    Sexe == 'Homme'
                                                        ? Icon(
                                                            Icons.man,
                                                            size: 17,
                                                            color: Colors
                                                                .grey[600],
                                                          )
                                                        : Icon(
                                                            Icons.woman,
                                                            size: 17,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      patient.sexe,
                                                      style: TextStyle(
                                                        fontSize: 13,
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

                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 9,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: npOrangeColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.medical_services,
                                                    size: 16,
                                                    color: npOrangeColor,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      motif,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: npOrangeColor,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 45),
                                          //Affichage du paiement a effectuer
                                          Container(
                                            child: Text(
                                              'Prix : $prixAPayer',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => AnnulerPaiement(
                                                idConsultation,
                                              ),
                                              icon: const Icon(
                                                Icons.cancel,
                                                size: 20,
                                              ),
                                              label: const Text('Annuler'),
                                              style: OutlinedButton.styleFrom(
                                                backgroundColor: npErrorColor,
                                                foregroundColor: Colors.white,
                                                side: BorderSide(
                                                  color: npErrorColor,
                                                  width: 2,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => validerPaiement(
                                                idConsultation,
                                              ),
                                              icon: const Icon(
                                                Icons.check,
                                                size: 18,
                                              ),
                                              label: const Text('Valider'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: npSuccessColor,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                elevation: 2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.02)),
              child: Text(
                '© 2025 Yamgai Mokube Franck Daniel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.95),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
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
        return 'A → Z';
      case 'name_desc':
        return 'Z → A';
      case 'date_desc':
        return 'Récent';
      case 'date_asc':
        return 'Ancien';
      default:
        return 'Trier';
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
}
