import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
        errorMessage = 'lex_server_error'.tr();
      });
      print('Erreur de chargement détails: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: labPrimaryColor,
      appBar: AppBar(
        backgroundColor: labPrimaryColor,
        centerTitle: !isDesktop,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'lhistd_title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
                    label: Text('lex_retry'.tr()),
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
          ? Center(
              child: Text(
                'lhistd_no_data'.tr(),
                style: const TextStyle(color: Colors.white),
              ),
            )
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 1000 : double.infinity,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPatientSection(),
                      const SizedBox(height: 20),
                      _buildExamensSection(),
                    ],
                  ),
                ),
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
            _buildInfoRow(
              Icons.cake,
              'lhistd_field_age'.tr(),
              'lhistd_age_value'.tr(namedArgs: {'age': '${patient.age}'}),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              patient.sexe == 'Homme' ? Icons.male : Icons.female,
              'lhistd_field_sex'.tr(),
              patient.sexe,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.phone,
              'lhistd_field_phone'.tr(),
              patient.telephone.toString(),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.medical_services,
              'lhistd_field_consult_id'.tr(),
              widget.idConsultation.toString(),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.check_circle,
              'lhistd_field_status'.tr(),
              'lhistd_status_done'.tr(),
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

    // Filtrer uniquement les examens terminés et annulés
    final examensAffiches = examensList
        .where(
          (examen) =>
              examen['statut_examen'] == 'Terminé' ||
              examen['statut_examen'] == 'Annulé' ||
              examen['statut_examen'] == 'annuler',
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'lhistd_section_exams'.tr(
            namedArgs: {'count': '${examensAffiches.length}'},
          ),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        if (examensAffiches.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'lhistd_exams_empty'.tr(),
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          )
        else
          ...examensAffiches.map((examen) {
            return _buildExamenCard(examen as Map<String, dynamic>);
          }),
      ],
    );
  }

  Widget _buildExamenCard(Map<String, dynamic> examen) {
    final nomExamen = examen['nom_examen'] ?? 'lhistd_default_exam_name'.tr();
    final resultat = examen['resultat_examen'] ?? 'pay_value_na'.tr();
    final statut = examen['statut_examen'] ?? 'En cours';

    final bool isAnnule = statut.toString().toLowerCase().contains('annul');
    final statutColor = isAnnule ? Colors.red : labBlueColor;
    final String statutLabel = isAnnule
        ? 'lhistd_exam_status_cancelled'.tr()
        : 'lhistd_exam_status_done'.tr();

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
                'lhistd_field_result'.tr(),
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
                'lhistd_field_exam_status'.tr(),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statutColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statutLabel,
                  style: TextStyle(
                    color: statutColor,
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
