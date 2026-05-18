import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hostoman/model_unifier.dart';
import 'detail_historique_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:hostoman/shared/receipt_pdf_generator.dart';

// Couleurs (mêmes que HistoriquePaiement.dart)
const Color npPrimaryColor = Color(0xFF4CAF50);
const Color npAccentColor = Color(0xFF378127);
const Color npSuccessColor = Color(0xFF4CAF50);
const Color npErrorColor = Color(0xFFD32F2F);
const Color npOrangeColor = Color(0xFFFF9800);
const Color npBlueColor = Color(0xFF2196F3);

class DetailHistoriqueUI extends StatefulWidget {
  final String? idPaiement;
  final String? idConsultation;

  const DetailHistoriqueUI({super.key, this.idPaiement, this.idConsultation})
    : assert(
        idPaiement != null || idConsultation != null,
        'Either idPaiement or idConsultation must be provided',
      );

  @override
  State<DetailHistoriqueUI> createState() => _DetailHistoriqueUIState();
}

class _DetailHistoriqueUIState extends State<DetailHistoriqueUI> {
  final DetailHistoriqueService detailService = DetailHistoriqueService(
    Supabase.instance.client,
  );

  Map<String, dynamic>? detailsData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    chargerDetails();
  }

  Future<void> chargerDetails() async {
    setState(() => isLoading = true);
    if (widget.idPaiement != null) {
      // Nouveau: Récupérer par ID de paiement
      detailsData = await detailService.getPaymentDetails(widget.idPaiement!);
    } else {
      // Ancien: Récupérer par ID de consultation (pour Statistique)
      detailsData = await detailService.getPatientPaymentDetails(
        widget.idConsultation!,
      );
    }
    setState(() => isLoading = false);
  }

  Future<void> _imprimerRecu() async {
    if (detailsData == null) return;

    Map<String, dynamic> consultationMap;
    if (widget.idPaiement != null) {
      consultationMap = detailsData!['Consultation'] as Map<String, dynamic>;
    } else {
      consultationMap = detailsData!;
    }

    final patientMap = consultationMap['Patient'] as Map<String, dynamic>;
    patientMap['id_patient'] = consultationMap['id_patient'];
    final patient = Patient.fromMap(patientMap);

    Paiement paiement;
    String motif;
    String statutPaiement;
    String datePaiementStr;

    if (widget.idPaiement != null) {
      paiement = Paiement.fromMap(detailsData!);
      motif = detailsData!['motif'] ?? 'hist_default_motif'.tr();
      statutPaiement = detailsData!['statut_paiement'] ?? 'en_attente';
      datePaiementStr =
          detailsData!['date_paiement'] ?? DateTime.now().toString();
    } else {
      final List<dynamic> paiementsList = detailsData!['paiement'] ?? [];
      Map<String, dynamic> paiementDataMap = {};
      if (paiementsList.isNotEmpty) {
        paiementDataMap = paiementsList.last as Map<String, dynamic>;
      }
      paiement = Paiement.fromMap(paiementDataMap);
      motif = paiementDataMap['motif'] ?? 'hist_default_motif'.tr();
      statutPaiement = paiementDataMap['statut_paiement'] ?? 'en_attente';
      datePaiementStr =
          paiementDataMap['date_paiement'] ?? DateTime.now().toString();
    }

    final typeService = consultationMap['type_service'] ?? 'Consultation';
    final idConsultation = consultationMap['id_consultation'].toString();
    final examensList =
        (consultationMap['examen_a_effectuer'] as List<dynamic>?) ?? [];

    String formattedDate = 'pay_value_na'.tr();
    try {
      final d = DateTime.parse(datePaiementStr);
      formattedDate = DateFormat('dd/MM/yyyy à HH:mm').format(d);
    } catch (_) {}

    final data = ReceiptPdfData(
      patientNom: patient.nom_complet,
      patientSexe: patient.sexe,
      patientAge: patient.age.toString(),
      patientTelephone: patient.telephone.toString(),
      idConsultation: idConsultation,
      serviceName: typeService,
      motif: motif,
      montant: (paiement.prix_a_paye ?? 0).toDouble(),
      datePaiement: formattedDate,
      statutPaiement: statutPaiement == 'payer'
          ? 'hist_badge_paid'.tr()
          : (statutPaiement == 'annuler'
                ? 'hist_badge_cancelled'.tr()
                : 'pay_status_pending'.tr()),
      examens: examensList,
    );

    await ReceiptPdfGenerator.printReceipt(context: context, data: data);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    String statutPaiement = 'en_attente';
    if (detailsData != null) {
      if (widget.idPaiement != null) {
        statutPaiement = detailsData!['statut_paiement'] ?? 'en_attente';
      } else {
        final List<dynamic> paiementsList = detailsData!['paiement'] ?? [];
        if (paiementsList.isNotEmpty) {
          final paiementDataMap = paiementsList.last as Map<String, dynamic>;
          statutPaiement = paiementDataMap['statut_paiement'] ?? 'en_attente';
        }
      }
    }

    return Scaffold(
      backgroundColor: Color(0XFFF5F3F3),
      appBar: AppBar(
        backgroundColor: Color(0xFF274621),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: npPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'hist_detail_title'.tr(),
          style: TextStyle(
            color: Color(0xFF26AE6C),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: !isDesktop,
        actions: [
          if (detailsData != null && statutPaiement != 'annuler')
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
              child: ElevatedButton.icon(
                onPressed: _imprimerRecu,
                icon: const Icon(Icons.print, size: 18),
                label: Text(
                  'pay_dlg_print_title'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: npPrimaryColor.withOpacity(0.1),
                  foregroundColor: npPrimaryColor,
                  elevation: 0,
                  side: const BorderSide(color: npPrimaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
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
                      'pay_loading'.tr(),
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
                      'pay_detail_load_error'.tr(),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPatientSection() {
    // Support both structures: payment-centric and consultation-centric
    Map<String, dynamic> consultationMap;
    if (widget.idPaiement != null) {
      // Payment-centric: Consultation is nested
      consultationMap = detailsData!['Consultation'] as Map<String, dynamic>;
    } else {
      // Consultation-centric: Data is at top level
      consultationMap = detailsData!;
    }
    final patientMap = consultationMap['Patient'] as Map<String, dynamic>;
    patientMap['id_patient'] = consultationMap['id_patient'];
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
            _buildInfoRow(
              Icons.cake,
              'pay_field_age'.tr(),
              'pay_field_age_value'.tr(namedArgs: {'age': '${patient.age}'}),
              npBlueColor,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.phone,
              'pay_field_phone'.tr(),
              patient.telephone.toString(),
              npSuccessColor,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.location_on,
              'pay_field_address'.tr(),
              patient.adresse,
              npOrangeColor,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.work,
              'pay_field_profession'.tr(),
              patient.profession,
              npPrimaryColor,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.family_restroom,
              'pay_field_marital'.tr(),
              patient.statut_matrimonial,
              npAccentColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    // Support both structures
    if (widget.idPaiement != null) {
      // Payment-centric: Direct access
      final paiement = Paiement.fromMap(detailsData!);
      final motif = detailsData!['motif'] ?? 'hist_default_motif'.tr();
      final statutPaiement = detailsData!['statut_paiement'] ?? 'en_attente';
      final datePaiement = detailsData!['date_paiement'];
      return _buildPaymentCard(paiement, motif, statutPaiement, datePaiement);
    } else {
      // Consultation-centric: From array
      final List<dynamic> paiementsList = detailsData!['paiement'] ?? [];
      if (paiementsList.isEmpty) return const SizedBox.shrink();
      final paiementDataMap = paiementsList.last as Map<String, dynamic>;
      final paiement = Paiement.fromMap(paiementDataMap);
      final motif = paiementDataMap['motif'] ?? 'hist_default_motif'.tr();
      final statutPaiement = paiementDataMap['statut_paiement'] ?? 'en_attente';
      final datePaiement = paiementDataMap['date_paiement'];
      return _buildPaymentCard(paiement, motif, statutPaiement, datePaiement);
    }
  }

  Widget _buildPaymentCard(
    Paiement paiement,
    String motif,
    String statutPaiement,
    String? datePaiement,
  ) {
    String dateFormatted = 'pay_value_na'.tr();
    if (datePaiement != null) {
      try {
        final date = DateTime.parse(datePaiement);
        dateFormatted = DateFormat('dd/MM/yyyy à HH:mm').format(date);
      } catch (e) {
        dateFormatted = 'pay_value_invalid_date'.tr();
      }
    }

    Color statutColor;
    IconData statutIcon;
    String statutLabel;
    switch (statutPaiement) {
      case 'payer':
        statutColor = npSuccessColor;
        statutIcon = Icons.check_circle;
        statutLabel = 'pay_status_paid'.tr();
        break;
      case 'annuler':
        statutColor = npErrorColor;
        statutIcon = Icons.cancel;
        statutLabel = 'pay_status_cancelled'.tr();
        break;
      default:
        statutColor = npOrangeColor;
        statutIcon = Icons.pending;
        statutLabel = 'pay_status_pending'.tr();
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
                  'pay_section_payment'.tr(),
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
              'pay_field_motif'.tr(),
              motif,
              npOrangeColor,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.attach_money,
              'pay_field_amount'.tr(),
              'pay_field_amount_value'.tr(
                namedArgs: {'value': '${paiement.prix_a_paye ?? 0}'},
              ),
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
                        'pay_field_status'.tr(),
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
                          statutLabel,
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
              'pay_field_date'.tr(),
              dateFormatted,
              npBlueColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationSection() {
    // Support both structures
    Map<String, dynamic> consultationMap;
    if (widget.idPaiement != null) {
      // Payment-centric: Consultation is nested
      consultationMap = detailsData!['Consultation'] as Map<String, dynamic>;
    } else {
      // Consultation-centric: Data is at top level
      consultationMap = detailsData!;
    }
    final typeService = consultationMap['type_service'] ?? 'Consultation';
    final dateEnregistrement = consultationMap['date_enregistrement'];

    String dateFormatted = 'pay_value_na'.tr();
    if (dateEnregistrement != null) {
      try {
        final date = DateTime.parse(dateEnregistrement);
        dateFormatted = DateFormat('dd/MM/yyyy à HH:mm').format(date);
      } catch (e) {
        dateFormatted = 'pay_value_invalid_date'.tr();
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
                  'pay_section_consultation'.tr(),
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
              'pay_field_service_type'.tr(),
              typeService,
              npPrimaryColor,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.access_time,
              'pay_field_registration_date'.tr(),
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
}
