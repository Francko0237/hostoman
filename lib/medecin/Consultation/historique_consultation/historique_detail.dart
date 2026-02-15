import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'historique_service.dart';

const Color medPrimaryColor = Color(0xFF6A5ACD);
const Color medAccentColor = Color(0xFF6A5ACD);
const Color medSuccessColor = Color(0xFF4CAF50);

class HistoriqueDetailPage extends StatefulWidget {
  final int idConsultation;
  const HistoriqueDetailPage({super.key, required this.idConsultation});

  @override
  State<HistoriqueDetailPage> createState() => _HistoriqueDetailPageState();
}

class _HistoriqueDetailPageState extends State<HistoriqueDetailPage>
    with SingleTickerProviderStateMixin {
  late final HistoriqueConsultationService _service;
  late TabController _tabController;

  Map<String, dynamic>? _consultationData;
  Map<String, dynamic>? _patientData;
  Map<String, dynamic>? _parametresVitaux;
  List<Map<String, dynamic>> _examens = [];

  bool _isLoading = true;
  String _patientName = 'Chargement...';

  @override
  void initState() {
    super.initState();
    _service = HistoriqueConsultationService(Supabase.instance.client);
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---- Logique métier inchangée ----

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final consultation = await _service.getConsultationDetail(
        widget.idConsultation,
      );
      final examens = await _service.getExamensConsultation(
        widget.idConsultation,
      );

      if (mounted && consultation != null) {
        setState(() {
          _consultationData = consultation;
          _patientData = consultation['Patient'] as Map<String, dynamic>?;
          _parametresVitaux =
              consultation['Parametres_vitaux'] as Map<String, dynamic>?;
          _examens = examens;
          _patientName =
              _patientData?['nom_complet']?.toString() ?? 'Patient Inconnu';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ---- ONGLET CONSULTATION ----

  Widget _buildConsultationTab() {
    if (_consultationData == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionCard(
            title: 'Diagnostic Initial',
            icon: Icons.manage_search_rounded,
            children: [
              _buildReadOnlyField(
                'Antécédent',
                _consultationData!['antecedents']?.toString(),
              ),
              _buildReadOnlyField(
                'Signes et symptômes',
                _consultationData!['signes_symptomes']?.toString(),
              ),
              _buildReadOnlyField(
                'Diagnostic initial',
                _consultationData!['diagnostic_initial']?.toString(),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            title: 'Diagnostic Final & Traitement',
            icon: Icons.medical_services_rounded,
            children: [
              _buildReadOnlyField(
                'Diagnostic final',
                _consultationData!['diagnostic_final']?.toString(),
              ),
              _buildReadOnlyField(
                'Traitement prescrit',
                _consultationData!['traitement_prescrit']?.toString(),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            title: 'Rendez-vous',
            icon: Icons.event_rounded,
            children: [
              _buildReadOnlyField(
                'Programmation',
                _consultationData!['programmation_rdv']?.toString() ==
                        'programmer'
                    ? 'Rendez-vous à effectuer'
                    : 'Pas de nouveau rendez-vous',
                isLast: _consultationData!['date_rdv_prevu'] == null,
              ),
              if (_consultationData!['date_rdv_prevu'] != null)
                _buildReadOnlyField(
                  'Date du RDV',
                  _formatDateTime(_consultationData!['date_rdv_prevu']),
                  isLast: true,
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ---- ONGLET EXAMENS ----

  Widget _buildExamensTab() {
    if (_examens.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
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
                  Icons.science_rounded,
                  size: 56,
                  color: medPrimaryColor,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aucun examen prescrit',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: medPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cette consultation n\'a pas d\'examens associés',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _examens.length,
      itemBuilder: (context, index) {
        final examen = _examens[index];
        final nomExamen = examen['nom_examen']?.toString() ?? 'Examen inconnu';
        final resultatExamen = examen['resultat_examen']?.toString();

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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar cercle vert
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        medSuccessColor,
                        medSuccessColor.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.science_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Contenu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              nomExamen,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Badge terminé vert
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: medSuccessColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 12,
                                  color: medSuccessColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Terminé',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: medSuccessColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Résultats',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        resultatExamen ?? 'Aucun résultat renseigné',
                        style: TextStyle(
                          fontSize: 13,
                          color: resultatExamen != null
                              ? Colors.grey[800]
                              : Colors.grey[400],
                          fontStyle: resultatExamen == null
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- ONGLET INFOS ----

  Widget _buildInfosTab() {
    if (_patientData == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    final nom = _patientData!['nom_complet']?.toString() ?? 'N/A';
    final sexe = _patientData!['sexe']?.toString() ?? '';
    final age = _patientData!['age']?.toString() ?? '';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // En-tête patient — même style card avec avatar vert
          Container(
            padding: const EdgeInsets.all(16),
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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        medSuccessColor,
                        medSuccessColor.withOpacity(0.7),
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
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
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
                            size: 15,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sexe,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.calendar_today,
                            size: 10,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$age ans',
                            style: TextStyle(
                              fontSize: 10,
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
          ),
          const SizedBox(height: 12),

          // Infos administratives
          _buildSectionCard(
            title: 'Informations administratives',
            icon: Icons.person_rounded,
            children: [
              _buildInfoRow(
                Icons.phone_rounded,
                'Téléphone',
                _patientData!['telephone'],
                iconColor: Colors.blue,
              ),
              _buildInfoRow(
                Icons.work_rounded,
                'Profession',
                _patientData!['profession'],
                iconColor: Colors.orange,
              ),
              _buildInfoRow(
                Icons.favorite_rounded,
                'Statut matrimonial',
                _patientData!['statut_matrimonial'],
                iconColor: Colors.pink,
              ),
              _buildInfoRow(
                Icons.location_on_rounded,
                'Adresse',
                _patientData!['adresse'],
                iconColor: Colors.green,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Paramètres vitaux
          if (_parametresVitaux != null)
            _buildSectionCard(
              title: 'Paramètres vitaux',
              icon: Icons.favorite_border_rounded,
              children: [
                _buildInfoRow(
                  Icons.thermostat_rounded,
                  'Température',
                  _parametresVitaux!['temperature'] != null
                      ? '${_parametresVitaux!['temperature']}°C'
                      : 'N/A',
                  iconColor: Colors.orange,
                ),
                _buildInfoRow(
                  Icons.monitor_heart_rounded,
                  'Tension artérielle',
                  (_parametresVitaux!['systolique'] != null &&
                          _parametresVitaux!['diastolique'] != null)
                      ? '${_parametresVitaux!['systolique']}/${_parametresVitaux!['diastolique']} mmHg'
                      : 'N/A',
                  iconColor: Colors.red,
                ),
                _buildInfoRow(
                  Icons.monitor_weight_rounded,
                  'Poids',
                  _parametresVitaux!['poid'] != null
                      ? '${_parametresVitaux!['poid']} kg'
                      : 'N/A',
                  iconColor: Colors.blue,
                ),
                _buildInfoRow(
                  Icons.health_and_safety_rounded,
                  'Statut VIH',
                  _parametresVitaux!['statut_VIH'],
                  iconColor: Colors.purple,
                ),
                _buildInfoRow(
                  Icons.vaccines_rounded,
                  'Vaccination',
                  _parametresVitaux!['vaccination'],
                  iconColor: Colors.teal,
                ),
                _buildInfoRow(
                  Icons.description_rounded,
                  'Motif de consultation',
                  _parametresVitaux!['motif_de_consultation'],
                  iconColor: Colors.indigo,
                  isLast: true,
                ),
              ],
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ---- WIDGETS HELPER ----

  /// Card section avec titre + icône
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: medPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: medPrimaryColor, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C2E),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          ...children,
        ],
      ),
    );
  }

  /// Champ lecture seule
  Widget _buildReadOnlyField(
    String label,
    String? value, {
    bool isLast = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  value?.isNotEmpty == true ? value! : 'Non renseigné',
                  style: TextStyle(
                    fontSize: 14,
                    color: value?.isNotEmpty == true
                        ? const Color(0xFF1C1C2E)
                        : Colors.grey[400],
                    fontStyle: value?.isNotEmpty == true
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }

  /// Ligne info (onglet Infos)
  Widget _buildInfoRow(
    IconData icon,
    String label,
    dynamic value, {
    bool isLast = false,
    Color? iconColor,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: (iconColor ?? medSuccessColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: iconColor ?? medSuccessColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value?.toString() ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1C1C2E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'N/A';
    }
  }

  // ---- BUILD ----

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: medPrimaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _patientName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: !isDesktop,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Consultation'),
            Tab(text: 'Examens'),
            Tab(text: 'Infos'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: medPrimaryColor),
            )
          : Container(
              color: const Color(0xFFF5F3F3),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildConsultationTab(),
                  _buildExamensTab(),
                  _buildInfosTab(),
                ],
              ),
            ),
    );
  }
}
