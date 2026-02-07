import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/model_unifier.dart';
import 'service_detail.dart';
import 'package:hostoman/date_formatter.dart';

// Couleurs
const Color npPrimaryColor = Color(0xFF1565C0);
const Color npAccentColor = Color(0xFF2196F3);
const Color npSuccessColor = Color(0xFF4CAF50);
const Color npErrorColor = Color(0xFFD32F2F);
const Color npPageBackgroundStart = Color(0xFF0D47A1);
const Color npPageBackgroundEnd = Color(0xFF1976D2);

class DetailPatientPage extends StatefulWidget {
  final String idPatient;
  const DetailPatientPage({super.key, required this.idPatient});

  @override
  State<DetailPatientPage> createState() => _DetailPatientPageState();
}

class _DetailPatientPageState extends State<DetailPatientPage> {
  final supabase = Supabase.instance.client;
  final service = DetailPatientService(Supabase.instance.client);
  Patient? _patient;
  List<Parametres_vitaux> _parametres = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final patient = await service.fetchPatientById(widget.idPatient);
    final parametres = await service.fetchParametresVitaux(widget.idPatient);

    setState(() {
      _patient = patient;
      _parametres = parametres;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;
    final isTablet = size.width > 400;

    final double contentWidth = isDesktop
        ? (1200 - 80) / 2
        : (size.width - (isTablet ? 40 : 32) - 40 - 12) / 2;

    String Sexe = _patient?.sexe ?? 'Non défini';

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
            Icon(Icons.person, color: npPrimaryColor, size: 24),
            const SizedBox(width: 12),
            Text(
              'Détails du Patient',
              style: TextStyle(
                color: npPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: !isDesktop,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [npPageBackgroundStart, npPageBackgroundEnd],
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.white))
            : _patient == null
            ? const Center(
                child: Text("Erreur", style: TextStyle(color: Colors.white)),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 1200 : double.infinity,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.all(isDesktop ? 24 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. En-tête Patient
                        _buildPatientHeader(isDesktop),
                        const SizedBox(height: 20),

                        // 2. Infos Personnelles
                        Container(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(
                                'Informations Personnelles',
                                Icons.person_outline,
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _buildInfoTile(
                                    contentWidth,
                                    'Sexe',
                                    _patient!.sexe,
                                    Sexe == 'Homme' ? Icons.man : Icons.woman_2,
                                  ),
                                  _buildInfoTile(
                                    contentWidth,
                                    'Âge',
                                    '${_patient!.age} ans',
                                    Icons.cake,
                                  ),
                                  _buildInfoTile(
                                    contentWidth,
                                    'Téléphone',
                                    '${_patient!.telephone}',
                                    Icons.phone,
                                  ),
                                  _buildInfoTile(
                                    contentWidth,
                                    'Adresse',
                                    _patient!.adresse,
                                    Icons.house,
                                  ),
                                  _buildInfoTile(
                                    contentWidth,
                                    'Profession',
                                    _patient!.profession,
                                    Icons.work,
                                  ),
                                  _buildInfoTile(
                                    contentWidth,
                                    'Statut',
                                    _patient!.statut_matrimonial,
                                    Icons.favorite,
                                  ),
                                  _buildInfoTile(
                                    double.infinity,
                                    'Enregistrement',
                                    DateFormatter.formatLong(
                                      _patient!.date_enregistrement,
                                    ),
                                    Icons.calendar_month,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 3. BLOC COMBINÉ : TITRE + PREMIER HISTORIQUE
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Le Titre
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: _buildSectionTitle(
                                  'Historique des Paramètres Vitaux',
                                  Icons.monitor_heart,
                                  count: _parametres.length,
                                ),
                              ),

                              // Contenu : Soit vide, soit le premier élément
                              if (_parametres.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 20),
                                  child: Text(
                                    "Aucun historique disponible",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              else ...[
                                // Une petite ligne de séparation discrète
                                Divider(height: 1, color: Colors.grey.shade200),
                                // Le contenu du premier élément (SANS nouvelle boite blanche autour)
                                _buildCardContent(
                                  _parametres[0],
                                  isFirstItem: true,
                                ),
                              ],
                            ],
                          ),
                        ),

                        // 4. LES AUTRES HISTORIQUES (Détachés)
                        if (_parametres.length > 1) ...[
                          const SizedBox(
                            height: 16,
                          ), // Espace entre le bloc titre/premier et le suivant
                          Column(
                            children: _parametres
                                .skip(1)
                                .map((pv) => _buildStandaloneCard(pv))
                                .toList(),
                          ),
                        ],

                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            '© 2025 Yamgai Mokube Franck Daniel',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // --- WIDGET : Carte Détachée (pour les items suivants) ---
  Widget _buildStandaloneCard(Parametres_vitaux pv) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildCardContent(pv), // Réutilisation du contenu
    );
  }

  // --- WIDGET : Contenu Interne d'une Carte (Date + Grille) ---
  Widget _buildCardContent(Parametres_vitaux pv, {bool isFirstItem = false}) {
    return Column(
      children: [
        // En-tête Date
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isFirstItem
                ? Colors.white
                : Colors
                      .grey
                      .shade50, // Fond blanc si collé au titre, gris sinon
            // Si c'est le premier item collé, pas d'arrondi en haut (car collé au titre), sinon arrondi
            borderRadius: isFirstItem
                ? BorderRadius.zero
                : const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              // Petit badge pour distinguer visuellement la date
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: npPrimaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: npPrimaryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                DateFormatter.formatLong(pv.date_enregistrement),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: npPrimaryColor,
                ),
              ),
            ],
          ),
        ),

        // Grille des valeurs
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildParamItemV2(
                      'Poids',
                      '${pv.poid} kg',
                      Icons.scale,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildParamItemV2(
                      'Température',
                      '${pv.temperature} °C',
                      Icons.thermostat,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildParamItemV2(
                      'Tension',
                      '${pv.systolique}/${pv.diastolique} mmHg',
                      Icons.monitor_heart,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildParamItemV2(
                      'Statut VIH',
                      pv.statut_VIH,
                      Icons.bloodtype,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildParamItemV2(
                      'Vaccination',
                      pv.vaccination,
                      Icons.vaccines,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildParamItemV2(
                      'Service',
                      pv.type_service ?? 'Non spécifié',
                      Icons.local_hospital,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildParamItemV2(
                'Motif de consultation',
                pv.motif_de_consultation,
                Icons.medical_information,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper Items (Inchangé)
  Widget _buildParamItemV2(
    String label,
    String value,
    IconData icon, {
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: npAccentColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
              ),
              maxLines: isFullWidth ? 10 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Helpers existants (Inchangés)
  Widget _buildInfoTile(
    double width,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: npAccentColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[900],
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientHeader(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [npPrimaryColor, npAccentColor]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: npAccentColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Center(
              child: Text(
                _patient!.nom_complet[0].toUpperCase(),
                style: TextStyle(
                  color: npPrimaryColor,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _patient!.nom_complet,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ID: ${widget.idPatient}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, {int? count}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: npAccentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, color: npAccentColor, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: npPrimaryColor,
            ),
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: npAccentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: npAccentColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
