import 'package:flutter/material.dart';
import 'package:hostoman/model_unifier.dart';
import 'ServiceHistorique.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detail/detail_historique_ui.dart';

// Couleurs - Thème vert comme Paiements en attente
const Color npPrimaryColor = Color(0xFF4CAF50);
const Color npAccentColor = Color(0xFF378127);
const Color npSuccessColor = Color(0xFF4CAF50);
const Color npErrorColor = Color(0xFFD32F2F);
const Color npOrangeColor = Color(0xFFFF9800);

class PaiementHistorique extends StatefulWidget {
  const PaiementHistorique({super.key});

  @override
  State<PaiementHistorique> createState() => _PaiementHistoriqueState();
}

class _PaiementHistoriqueState extends State<PaiementHistorique> {
  final PaiementService paiementService = PaiementService(
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
    consultations = await paiementService.getPatientsNonPayes();
    _applyFilters();
    setState(() => isLoading = false);
  }

  void _applyFilters() {
    List<Map<String, dynamic>> temp = [...consultations];

    // Filtre par recherche
    if (searchQuery.isNotEmpty) {
      temp = temp.where((item) {
        final consultationMap = item['Consultation'] as Map<String, dynamic>;
        final patientMap = consultationMap['Patient'] as Map<String, dynamic>;
        final nom = (patientMap['nom_complet'] ?? '').toString().toLowerCase();
        return nom.contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Tri
    switch (sortOption) {
      case 'name_asc':
        temp.sort((a, b) {
          final nomA = (a['Consultation']['Patient']['nom_complet'] ?? '')
              .toString()
              .toLowerCase();
          final nomB = (b['Consultation']['Patient']['nom_complet'] ?? '')
              .toString()
              .toLowerCase();
          return nomA.compareTo(nomB);
        });
        break;
      case 'name_desc':
        temp.sort((a, b) {
          final nomA = (a['Consultation']['Patient']['nom_complet'] ?? '')
              .toString()
              .toLowerCase();
          final nomB = (b['Consultation']['Patient']['nom_complet'] ?? '')
              .toString()
              .toLowerCase();
          return nomB.compareTo(nomA);
        });
        break;
      case 'date_desc':
        temp.sort((a, b) {
          final dateA =
              DateTime.tryParse(a['date_paiement'] ?? '') ?? DateTime(2000);
          final dateB =
              DateTime.tryParse(b['date_paiement'] ?? '') ?? DateTime(2000);
          return dateB.compareTo(dateA);
        });
        break;
      case 'date_asc':
        temp.sort((a, b) {
          final dateA =
              DateTime.tryParse(a['date_paiement'] ?? '') ?? DateTime(2000);
          final dateB =
              DateTime.tryParse(b['date_paiement'] ?? '') ?? DateTime(2000);
          return dateA.compareTo(dateB);
        });
        break;
    }

    setState(() {
      filteredConsultations = temp;
    });
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
              'Historique des Paiements',
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
        color: Color(0xFFF5F3F3),
        child: Column(
          children: [
            // Barre de recherche + filtres
            Container(
              padding: EdgeInsets.all(isDesktop ? 20 : 16),
              decoration: BoxDecoration(color: Color(0xFFF5F3F3)),
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
                                      color: Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.history,
                                      size: 64,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Aucun historique',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: npPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Les paiements effectués apparaîtront ici',
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

                            // Accès aux données via la structure payment-centric
                            final consultationMap =
                                item['Consultation'] as Map<String, dynamic>;
                            final patientMap =
                                consultationMap['Patient']
                                    as Map<String, dynamic>;
                            patientMap['id_patient'] =
                                consultationMap['id_patient'];
                            final patient = Patient.fromMap(patientMap);

                            // Récupération du motif et statut depuis le paiement (top level)
                            String motif = item['motif'] ?? 'Consultation';
                            String statutPaiement =
                                item['statut_paiement'] ?? 'en_attente';

                            String sexe = patient.sexe.toString();

                            return InkWell(
                              onTap: () {
                                final idPaiement = item['id_paiement']
                                    .toString();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailHistoriqueUI(
                                      idPaiement: idPaiement,
                                    ),
                                  ),
                                );
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
                                  child: Row(
                                    children: [
                                      // Paiement Validé
                                      statutPaiement == 'payer'
                                          ? Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: npSuccessColor
                                                    .withOpacity(0.15),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: npSuccessColor
                                                      .withOpacity(0.3),
                                                  width: 2,
                                                ),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.check_circle,
                                                  color: npSuccessColor,
                                                  size: 28,
                                                ),
                                              ),
                                            )
                                          // Paiement Annuler
                                          : Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: Colors.redAccent
                                                    .withOpacity(0.15),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.red.withOpacity(
                                                    0.3,
                                                  ),
                                                  width: 2,
                                                ),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.cancel,
                                                  color: Colors.redAccent,
                                                  size: 28,
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
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                sexe == 'Homme'
                                                    ? Icon(
                                                        Icons.man,
                                                        size: 16,
                                                        color: Colors.grey[600],
                                                      )
                                                    : Icon(
                                                        Icons.woman,
                                                        size: 16,
                                                        color: Colors.grey[600],
                                                      ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  patient.sexe,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Icon(
                                                  Icons.medical_services,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  motif,
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
                                      statutPaiement == 'payer'
                                          ?
                                            //Badge "Paye"
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: npSuccessColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: npSuccessColor
                                                      .withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.check,
                                                    size: 14,
                                                    color: npSuccessColor,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Payé',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: npSuccessColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          // Badge "Annuler"
                                          : Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.redAccent
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.red.withOpacity(
                                                    0.3,
                                                  ),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.check,
                                                    size: 14,
                                                    color: Colors.redAccent,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Annuler',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.redAccent,
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
