import 'package:flutter/material.dart';
import 'package:hostoman/model_unifier.dart';
import 'detail_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// Couleurs (mêmes que paiementList.dart)
const Color npPrimaryColor = Color(0xFF4CAF50);
const Color npAccentColor = Color(0xFF378127);
const Color npSuccessColor = Color(0xFF4CAF50);
const Color npErrorColor = Color(0xFFD32F2F);
const Color npOrangeColor = Color(0xFFFF9800);
const Color npBlueColor = Color(0xFF2196F3);

class DetailUI extends StatefulWidget {
  final String idConsultation;

  const DetailUI({super.key, required this.idConsultation});

  @override
  State<DetailUI> createState() => _DetailUIState();
}

class _DetailUIState extends State<DetailUI> {
  final DetailService detailService = DetailService(Supabase.instance.client);

  Map<String, dynamic>? detailsData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    chargerDetails();
  }

  Future<void> chargerDetails() async {
    setState(() => isLoading = true);
    detailsData = await detailService.getPatientPaymentDetails(
      widget.idConsultation,
    );
    setState(() => isLoading = false);
  }

  Future<void> validerPaiement() async {
    await detailService.validerPaiement(widget.idConsultation);
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
    Navigator.pop(context, true); // Retour à la liste avec refresh
  }

  Future<void> annulerPaiement() async {
    final confirm = await _confirmerAnnulation();
    if (confirm != true) return;

    await detailService.annulerPaiement(widget.idConsultation);
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
    Navigator.pop(context, true); // Retour à la liste avec refresh
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

    return Scaffold(
      backgroundColor: Color(0XFFF5F3F3),
      appBar: AppBar(
        backgroundColor: Color(0xFF274621),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: npPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Détails du Paiement',
          style: TextStyle(
            color: Color(0xFF26AE6C),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: !isDesktop,
      ),
      body: isLoading
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
                    CircularProgressIndicator(color: npPrimaryColor),
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
          : detailsData == null
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
                    Icon(Icons.error_outline, size: 64, color: npErrorColor),
                    const SizedBox(height: 20),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: npErrorColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 900 : double.infinity,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isDesktop ? 24 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPatientSection(),
                        const SizedBox(height: 16),
                        _buildPaymentSection(),
                        const SizedBox(height: 16),
                        _buildConsultationSection(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
                    ),
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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Avatar + Nom
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [npPrimaryColor, npAccentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      patient.nom_complet[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.nom_complet,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            patient.sexe == 'Homme' ? Icons.man : Icons.woman,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            patient.sexe,
                            style: TextStyle(
                              fontSize: 14,
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
            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 16),
            // Détails
            _buildInfoRow(Icons.cake, 'Âge', '${patient.age} ans', npBlueColor),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.phone,
              'Téléphone',
              patient.telephone.toString(),
              npSuccessColor,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.location_on,
              'Adresse',
              patient.adresse,
              npOrangeColor,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.work,
              'Profession',
              patient.profession,
              npPrimaryColor,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.family_restroom,
              'Statut matrimonial',
              patient.statut_matrimonial,
              npAccentColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    final List<dynamic> paiementsList = detailsData!['paiement'] ?? [];
    if (paiementsList.isEmpty) return const SizedBox.shrink();

    // Prendre le dernier paiement (le plus récent) au lieu du premier
    // Cela permet d'afficher le paiement d'examens plutôt que le paiement de consultation
    final paiementDataMap = paiementsList.last as Map<String, dynamic>;
    final paiement = Paiement.fromMap(paiementDataMap);
    final motif = paiementDataMap['motif'] ?? 'Frais de Consultation';
    final statutPaiement = paiementDataMap['statut_paiement'] ?? 'en_attente';
    final datePaiement = paiementDataMap['date_paiement'];

    String dateFormatted = 'N/A';
    if (datePaiement != null) {
      try {
        final date = DateTime.parse(datePaiement);
        dateFormatted = DateFormat('dd/MM/yyyy à HH:mm').format(date);
      } catch (e) {
        dateFormatted = 'Date invalide';
      }
    }

    Color statutColor;
    IconData statutIcon;
    switch (statutPaiement) {
      case 'payer':
        statutColor = npSuccessColor;
        statutIcon = Icons.check_circle;
        break;
      case 'annuler':
        statutColor = npErrorColor;
        statutIcon = Icons.cancel;
        break;
      default:
        statutColor = npOrangeColor;
        statutIcon = Icons.pending;
    }

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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: npOrangeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.payment, color: npOrangeColor, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Informations Paiement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: npOrangeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              Icons.medical_services,
              'Motif',
              motif,
              npOrangeColor,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.attach_money,
              'Montant',
              '${paiement.prix_a_paye ?? 0} FCFA',
              npSuccessColor,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statutIcon, color: statutColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statut',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statutColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statutPaiement.toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: statutColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.calendar_today,
              'Date',
              dateFormatted,
              npBlueColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationSection() {
    final typeService = detailsData!['type_service'] ?? 'Consultation';
    final dateEnregistrement = detailsData!['date_enregistrement'];

    String dateFormatted = 'N/A';
    if (dateEnregistrement != null) {
      try {
        final date = DateTime.parse(dateEnregistrement);
        dateFormatted = DateFormat('dd/MM/yyyy à HH:mm').format(date);
      } catch (e) {
        dateFormatted = 'Date invalide';
      }
    }

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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: npBlueColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_hospital,
                    color: npBlueColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Informations Consultation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: npBlueColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              Icons.medical_services,
              'Type de service',
              typeService,
              npPrimaryColor,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.access_time,
              'Date d\'enregistrement',
              dateFormatted,
              npBlueColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: annulerPaiement,
            icon: const Icon(Icons.cancel, size: 20),
            label: const Text('Annuler'),
            style: OutlinedButton.styleFrom(
              backgroundColor: npErrorColor,
              foregroundColor: Colors.white,
              side: BorderSide(color: npErrorColor, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: validerPaiement,
            icon: const Icon(Icons.check, size: 20),
            label: const Text('Valider le paiement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: npSuccessColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ),
      ],
    );
  }
}
