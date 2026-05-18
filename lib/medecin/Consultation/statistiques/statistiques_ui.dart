import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'statistiques_service.dart';
import 'package:intl/intl.dart';
import 'package:hostoman/shared/pdf_generator.dart';

const Color medPrimaryColor = Color(0xFF6A5ACD);
const Color medSuccessColor = Color(0xFF4CAF50);
const Color medErrorColor = Color(0xFFF44336);
const Color medInfoColor = Color(0xFF2196F3);

class StatistiquesPage extends StatefulWidget {
  const StatistiquesPage({super.key});

  @override
  State<StatistiquesPage> createState() => _StatistiquesPageState();
}

class _StatistiquesPageState extends State<StatistiquesPage> {
  late final StatistiquesService _service;

  DateTime? _dateDebut;
  DateTime? _dateFin;
  bool _isLoading = false;

  int _nbTerminees = 0;
  int _nbAnnulees = 0;
  int _nbRdvTermines = 0;

  String _selectedCategory = 'terminees';
  List<Map<String, dynamic>> _patients = [];

  // ---- Logique métier inchangée ----

  @override
  void initState() {
    super.initState();
    _service = StatistiquesService(Supabase.instance.client);
    final now = DateTime.now();
    _dateDebut = DateTime(now.year, now.month, now.day - 7);
    _dateFin = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _loadStatistiques();
  }

  Future<void> _loadStatistiques() async {
    if (_dateDebut == null || _dateFin == null) return;
    setState(() => _isLoading = true);
    try {
      final terminees = await _service.getConsultationsTerminees(
        _dateDebut!,
        _dateFin!,
      );
      final annulees = await _service.getConsultationsAnnulees(
        _dateDebut!,
        _dateFin!,
      );
      final rdv = await _service.getRendezVousTermines(_dateDebut!, _dateFin!);
      if (mounted) {
        setState(() {
          _nbTerminees = terminees;
          _nbAnnulees = annulees;
          _nbRdvTermines = rdv;
          _isLoading = false;
        });
        await _loadPatients();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadPatients() async {
    if (_dateDebut == null || _dateFin == null) return;
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> patients;
      if (_selectedCategory == 'terminees') {
        patients = await _service.getPatientsParStatut(
          'terminer',
          _dateDebut!,
          _dateFin!,
        );
      } else if (_selectedCategory == 'annulees') {
        patients = await _service.getPatientsParStatut(
          'annuler',
          _dateDebut!,
          _dateFin!,
        );
      } else {
        patients = await _service.getPatientsRdvTermines(
          _dateDebut!,
          _dateFin!,
        );
      }
      if (mounted) {
        setState(() {
          _patients = patients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDebut) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDebut
          ? (_dateDebut ?? DateTime.now())
          : (_dateFin ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: medPrimaryColor,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = DateTime(picked.year, picked.month, picked.day);
        } else {
          _dateFin = DateTime(
            picked.year,
            picked.month,
            picked.day,
            23,
            59,
            59,
          );
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sélectionner';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color get _categoryColor {
    if (_selectedCategory == 'annulees') return medErrorColor;
    if (_selectedCategory == 'rdv') return medInfoColor;
    return medSuccessColor;
  }

  // ---- BUILD ----

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F3),
      appBar: AppBar(
        backgroundColor: medPrimaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Statistiques',
          style: TextStyle(
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
              onPressed: _loadStatistiques,
              tooltip: 'Actualiser',
            ),
          ),
          if (_patients.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.print, color: Colors.white),
              tooltip: 'Imprimer la liste',
              onPressed: _printPatientList,
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 900 : double.infinity,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(isDesktop ? 20 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateSelector(),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: medPrimaryColor),
                    ),
                  )
                else ...[
                  _buildStatCards(),
                  const SizedBox(height: 20),
                  _buildPatientList(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Sélecteur de dates ----

  Widget _buildDateSelector() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: medPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.date_range_rounded,
                  color: medPrimaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Période d\'analyse',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 14),

          // Boutons date
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  label: 'Date début',
                  date: _dateDebut,
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateButton(
                  label: 'Date fin',
                  date: _dateFin,
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bouton valider
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadStatistiques,
              icon: const Icon(
                Icons.bar_chart_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Afficher les statistiques',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: medPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 13,
                  color: medPrimaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(date),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C2E),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- Cartes statistiques ----

  Widget _buildStatCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Terminées',
                count: _nbTerminees,
                icon: Icons.check_circle_rounded,
                color: medSuccessColor,
                category: 'terminees',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Annulées',
                count: _nbAnnulees,
                icon: Icons.cancel_rounded,
                color: medErrorColor,
                category: 'annulees',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          title: 'Rendez-vous terminés',
          count: _nbRdvTermines,
          icon: Icons.event_available_rounded,
          color: medInfoColor,
          category: 'rdv',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required String category,
  }) {
    final isSelected = _selectedCategory == category;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _selectedCategory = category);
          _loadPatients();
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? color.withOpacity(0.2)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icône dégradé
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),

              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),

              // Indicateur sélection
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSelected
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 16,
                  color: isSelected ? color : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Liste patients ----

  Widget _buildPatientList() {
    // Label selon catégorie
    String categoryLabel = 'consultations terminées';
    if (_selectedCategory == 'annulees') {
      categoryLabel = 'consultations annulées';
    }
    if (_selectedCategory == 'rdv') categoryLabel = 'rendez-vous terminés';

    if (_patients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
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
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: medPrimaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 56,
                color: medPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun patient trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: medPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune donnée pour cette période',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête liste
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  Icons.people_rounded,
                  size: 16,
                  color: _categoryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${_patients.length} ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _categoryColor,
                        ),
                      ),
                      TextSpan(
                        text: categoryLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1C1C2E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Cards patients
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _patients.length,
          itemBuilder: (context, index) => _buildPatientCard(_patients[index]),
        ),
      ],
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> consultation) {
    final patient = consultation['Patient'] as Map<String, dynamic>?;
    final nom = patient?['nom_complet'] ?? 'N/A';
    final sexe = patient?['sexe'] ?? '';
    final age = patient?['age']?.toString() ?? '';
    final idConsultation = consultation['id_consultation'];
    final date = _formatDate(
      DateTime.tryParse(
        consultation['date_derniere_mise_ajour']?.toString() ?? '',
      ),
    );
    final color = _categoryColor;

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
          onTap: () => context.push(
            '/Dashboard_Medecin/HistoriqueDetail/$idConsultation',
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar cercle dégradé (couleur de catégorie)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
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

                // Badge date + flèche
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 12,
                            color: color.withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.black26,
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

  Future<void> _printPatientList() async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final periodeLabel = (_dateDebut != null && _dateFin != null)
        ? 'Du ${dateFormat.format(_dateDebut!)} au ${dateFormat.format(_dateFin!)}'
        : 'Toutes dates';

    String categorieLabel;
    switch (_selectedCategory) {
      case 'terminees':
        categorieLabel = 'Terminées';
        break;
      case 'annulees':
        categorieLabel = 'Annulées';
        break;
      default:
        categorieLabel = 'Rendez-vous terminés';
    }

    final pdfPatients = _patients.map((consultation) {
      final patient = consultation['Patient'] as Map<String, dynamic>?;
      final nom = patient?['nom_complet'] ?? 'N/A';
      final sexe = patient?['sexe'] ?? '';
      final age = patient?['age']?.toString() ?? '';
      final telephone = patient?['telephone']?.toString() ?? '';
      final dateBrute = DateTime.tryParse(
            consultation['date_derniere_mise_ajour']?.toString() ?? '',
          ) ??
          DateTime.now();

      return PatientPdfData(
        nom: nom,
        sexe: sexe,
        age: '$age ans',
        telephone: telephone,
        dateEnregistrement: dateFormat.format(dateBrute),
        categorie: categorieLabel,
      );
    }).toList();

    await PatientListPdfGenerator.previewAndPrint(
      context: context,
      serviceName: 'Médecin',
      periodeLabel: periodeLabel,
      patients: pdfPatients,
      showCategorie: true,
      categorieLabel: 'Statut consultation',
    );
  }
}
