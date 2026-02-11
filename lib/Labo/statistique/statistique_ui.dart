import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/model_unifier.dart';
import 'package:intl/intl.dart';
import 'statistique_service.dart';
import 'package:go_router/go_router.dart';

// Couleurs - Thème Laboratoire
const Color labPrimaryColor = Color(0xFF212031);
const Color labAccentColor = Color(0xFF212031);
const Color labBlueColor = Color(0xFF2196F3);
const Color labGreenColor = Color(0xFF4CAF50);
const Color labGreyColor = Color(0xFF9E9E9E);

class StatistiqueLaboUI extends StatefulWidget {
  const StatistiqueLaboUI({super.key});

  @override
  State<StatistiqueLaboUI> createState() => _StatistiqueLaboUIState();
}

class _StatistiqueLaboUIState extends State<StatistiqueLaboUI> {
  final StatistiqueLaboService statistiqueService = StatistiqueLaboService(
    Supabase.instance.client,
  );

  // Dates par défaut
  DateTime dateDebut = DateTime.now().subtract(const Duration(days: 90));
  DateTime dateFin = DateTime.now();

  // Données
  Map<String, int> statistiques = {'termines': 0, 'annules': 0};
  List<Map<String, dynamic>> patients = [];
  bool isLoading = true;
  bool showFilters = false;
  String? statutFiltre; // null = tous, 'Terminé', 'Annulé'

  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }

  Future<void> chargerDonnees() async {
    setState(() => isLoading = true);
    try {
      final stats = await statistiqueService.getStatistiques(
        dateDebut,
        dateFin,
      );
      final patientsList = await statistiqueService.getPatientsAvecExamens(
        dateDebut,
        dateFin,
        statutFiltre: statutFiltre,
      );

      setState(() {
        statistiques = stats;
        patients = patientsList;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDebut) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDebut ? dateDebut : dateFin,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      setState(() {
        if (isDebut) {
          dateDebut = picked;
        } else {
          dateFin = picked;
        }
      });
      chargerDonnees();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F3),
      appBar: AppBar(
        backgroundColor: labPrimaryColor,
        leading: const Icon(Icons.bar_chart, color: Colors.white),
        title: const Text(
          'Statistiques Laboratoire',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: chargerDonnees,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: labBlueColor))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildPeriodeSection(),
                  const SizedBox(height: 16),
                  _buildFiltresSection(),
                  const SizedBox(height: 16),
                  _buildStatistiquesCards(),
                  const SizedBox(height: 24),
                  _buildPatientsSection(),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildPeriodeSection() {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 20,
                color: labPrimaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Période',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Début',
                  date: dateFormat.format(dateDebut),
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, color: Colors.grey),
              ),
              Expanded(
                child: _buildDateField(
                  label: 'Fin',
                  date: dateFormat.format(dateFin),
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltresSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() => showFilters = !showFilters);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.filter_list, size: 20, color: labPrimaryColor),
              const SizedBox(width: 8),
              const Text(
                'Filtres optionnels',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Icon(
                showFilters ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatistiquesCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              label: 'Terminés',
              count: statistiques['termines'] ?? 0,
              color: labGreenColor,
              icon: Icons.check_circle,
              isActive: statutFiltre == 'Terminé',
              onTap: () {
                setState(() {
                  statutFiltre = statutFiltre == 'Terminé' ? null : 'Terminé';
                });
                chargerDonnees();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              label: 'Annulés',
              count: statistiques['annules'] ?? 0,
              color: Colors.red,
              icon: Icons.cancel,
              isActive: statutFiltre == 'Annulé',
              onTap: () {
                setState(() {
                  statutFiltre = statutFiltre == 'Annulé' ? null : 'Annulé';
                });
                chargerDonnees();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? color : color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: isActive ? Colors.white : color),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isActive ? Colors.white : color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            statutFiltre == null
                ? 'Liste des patients (${patients.length})'
                : 'Patients - ${statutFiltre}s (${patients.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (patients.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'Aucun patient pour cette période',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...patients.map((item) {
              final patientMap = item['Patient'] as Map<String, dynamic>;
              patientMap['id_patient'] = item['id_patient'];
              // Ajouter date_enregistrement depuis la consultation si absent
              if (!patientMap.containsKey('date_enregistrement') ||
                  patientMap['date_enregistrement'] == null) {
                patientMap['date_enregistrement'] =
                    item['date_enregistrement'] ??
                    DateTime.now().toIso8601String();
              }
              final patient = Patient.fromMap(patientMap);
              final nombreExamens = item['nombre_examens'] ?? 0;
              final dateEnregistrement = item['date_enregistrement'];

              return _buildPatientCard(
                patient: patient,
                nombreExamens: nombreExamens,
                dateEnregistrement: dateEnregistrement,
              );
            }),
          const SizedBox(height: 80), // Space for bottom nav
        ],
      ),
    );
  }

  Widget _buildPatientCard({
    required Patient patient,
    required int nombreExamens,
    required String dateEnregistrement,
  }) {
    final date = DateTime.parse(dateEnregistrement);
    final dateFormatted = DateFormat('dd/MM/yyyy').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: labGreenColor,
            child: Text(
              patient.nom_complet[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Infos patient
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.nom_complet,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      patient.sexe == 'Homme' ? Icons.male : Icons.female,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${patient.sexe}, ${patient.age} ans',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateFormatted,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.science, size: 12, color: labGreenColor),
                    const SizedBox(width: 4),
                    Text(
                      '$nombreExamens examen${nombreExamens > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: labGreenColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 1, // Statistiques
      backgroundColor: Colors.white,
      selectedItemColor: labPrimaryColor,
      unselectedItemColor: Colors.grey.shade500,
      showUnselectedLabels: true,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/Dashboard_Laboratoire');
            break;
          case 1:
            // Already on statistics
            break;
          case 2:
            context.push('/Dashboard_Laboratoire/Historique');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Statistiques',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Historiques',
        ),
      ],
    );
  }
}
