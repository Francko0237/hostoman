import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/model_unifier.dart';
import 'detail_historique_service.dart';

// Couleurs - Thème Laboratoire
const Color labPrimaryColor = Color(0xFF212031);
const Color labAccentColor = Color(0xFF212031);
const Color labBlueColor = Color(0xFF009688);
const Color darkBackground = Color(0xFF2C3E50);

class DetailHistoriqueLaboUI extends StatefulWidget {
  final int idConsultation;

  const DetailHistoriqueLaboUI({super.key, required this.idConsultation});

  @override
  State<DetailHistoriqueLaboUI> createState() => _DetailHistoriqueLaboUIState();
}

class _DetailHistoriqueLaboUIState extends State<DetailHistoriqueLaboUI> {
  final DetailHistoriqueLaboService detailService = DetailHistoriqueLaboService(
    Supabase.instance.client,
  );

  Map<String, dynamic>? detailsData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    chargerDetails();
  }

  Future<void> chargerDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      detailsData = await detailService.getDetailsConsultation(
        widget.idConsultation,
      );
      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage =
            'Impossible de se connecter au serveur.\nVeuillez vérifier votre connexion internet.';
      });
      print('Erreur de chargement détails: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Détails de la Consultation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: chargerDetails,
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
          : detailsData == null
          ? const Center(
              child: Text(
                'Aucun détail trouvé',
                style: TextStyle(color: Colors.white),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPatientSection(),
                  const SizedBox(height: 20),
                  _buildExamensSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildPatientSection() {
    final patientMap = detailsData!['Patient'] as Map<String, dynamic>;
    patientMap['id_patient'] = detailsData!['id_patient'];
    final patient = Patient.fromMap(patientMap);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar + Nom
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: labBlueColor,
                  child: Text(
                    patient.nom_complet[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    patient.nom_complet,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 32),

            // Informations
            _buildInfoRow(Icons.cake, 'Âge:', '${patient.age} ans'),
            const SizedBox(height: 12),
            _buildInfoRow(
              patient.sexe == 'Homme' ? Icons.male : Icons.female,
              'Sexe:',
              patient.sexe,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.phone,
              'Téléphone:',
              patient.telephone.toString(),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.medical_services,
              'Consultation ID:',
              widget.idConsultation.toString(),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.check_circle,
              'Statut:',
              'TERMINÉE',
              valueColor: labBlueColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor ?? Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExamensSection() {
    final List<dynamic> examensList = detailsData!['examen_a_effectuer'] ?? [];

    // Filtrer uniquement les examens terminés
    final examensTermines = examensList
        .where((examen) => examen['statut_examen'] == 'Terminé')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Liste des Examens (${examensTermines.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        if (examensTermines.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Aucun examen terminé',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          )
        else
          ...examensTermines.map((examen) {
            return _buildExamenCard(examen as Map<String, dynamic>);
          }),
      ],
    );
  }

  Widget _buildExamenCard(Map<String, dynamic> examen) {
    final nomExamen = examen['nom_examen'] ?? 'Examen';
    final resultat = examen['resultat_examen'] ?? 'N/A';
    final statut = examen['statut_examen'] ?? 'En cours';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom de l'examen
          Text(
            nomExamen,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Résultat
          Row(
            children: [
              Text(
                'Résultat:',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  resultat,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Statut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Statut:',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: labBlueColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statut.toUpperCase(),
                  style: const TextStyle(
                    color: labBlueColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
