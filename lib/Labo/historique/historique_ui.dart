import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/model_unifier.dart';
import 'historique_service.dart';

// Couleurs - Thème Laboratoire
const Color labPrimaryColor = Color(0xFF212031);
const Color labAccentColor = Color(0xFF212031);
const Color labBlueColor = Color(0xFF009688); // Teal color for a medical feel

class HistoriqueLaboUI extends StatefulWidget {
  const HistoriqueLaboUI({super.key});

  @override
  State<HistoriqueLaboUI> createState() => _HistoriqueLaboUIState();
}

class _HistoriqueLaboUIState extends State<HistoriqueLaboUI> {
  final HistoriqueLaboService historiqueService = HistoriqueLaboService(
    Supabase.instance.client,
  );

  List<Map<String, dynamic>> consultations = [];
  List<Map<String, dynamic>> filteredConsultations = [];
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    chargerHistorique();
  }

  Future<void> chargerHistorique() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final data = await historiqueService.getPatientsAvecExamensTermines();
      setState(() {
        consultations = data;
        filteredConsultations = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage =
            'Impossible de se connecter au serveur.\nVeuillez vérifier votre connexion internet.';
      });
      print('Erreur de chargement historique: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      filteredConsultations = consultations.where((item) {
        final patientMap = item['Patient'] as Map<String, dynamic>;
        final nom = (patientMap['nom_complet'] ?? '').toString().toLowerCase();
        return nom.contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F3),
      appBar: AppBar(
        backgroundColor: labPrimaryColor,
        leading: IconButton(
          icon: const Icon(
            Icons.history,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
          onPressed: () {},
        ),
        title: const Text(
          'Historique',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: chargerHistorique,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: labBlueColor))
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: chargerHistorique,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: labBlueColor,
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
          : Column(
              children: [
                // Barre de recherche
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher un patient...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: labPrimaryColor,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => searchQuery = value);
                      _applyFilters();
                    },
                  ),
                ),

                // Compteur
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    '${filteredConsultations.length} dossier${filteredConsultations.length > 1 ? 's' : ''} archivé${filteredConsultations.length > 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),

                const SizedBox(height: 16),

                // Liste des patients
                Expanded(
                  child: filteredConsultations.isEmpty
                      ? Center(
                          child: Text(
                            'Aucun dossier archivé',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredConsultations.length,
                          itemBuilder: (context, index) {
                            final item = filteredConsultations[index];
                            final patientMap =
                                item['Patient'] as Map<String, dynamic>;
                            patientMap['id_patient'] = item['id_patient'];
                            final patient = Patient.fromMap(patientMap);
                            final idConsultation = item['id_consultation'];

                            return _buildPatientCard(
                              patient: patient,
                              idConsultation: idConsultation,
                              dateEnregistrement: item['date_enregistrement'],
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildPatientCard({
    required Patient patient,
    required int idConsultation,
    required String dateEnregistrement,
  }) {
    final date = DateTime.parse(dateEnregistrement);
    final dateFormatted =
        '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () {
        context.push('/Dashboard_Laboratoire/HistoriqueDetail/$idConsultation');
      },
      child: Container(
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
              radius: 28,
              backgroundColor: labBlueColor,
              child: Text(
                patient.nom_complet[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
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
                    patient.nom_complet,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        patient.sexe == 'Homme' ? Icons.male : Icons.female,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        patient.sexe,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.cake, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${patient.age} ans',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateFormatted,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Badge Terminé
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: labBlueColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Terminé',
                style: TextStyle(
                  color: labBlueColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 2, // Historique
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
            context.push('/Dashboard_Laboratoire/Statistiques');
            break;
          case 2:
            // Already on historique
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
