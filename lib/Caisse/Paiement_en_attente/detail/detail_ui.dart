import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hostoman/model_unifier.dart';
import 'detail_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:hostoman/shared/receipt_pdf_generator.dart';

// Couleurs (mêmes que paiementList.dart)
const Color npPrimaryColor = Color(0xFF4CAF50);
const Color npAccentColor = Color(0xFF378127);
const Color npSuccessColor = Color(0xFF4CAF50);
const Color npErrorColor = Color(0xFFD32F2F);
const Color npOrangeColor = Color(0xFFFF9800);
const Color npBlueColor = Color(0xFF2196F3);

class DetailUI extends StatefulWidget {
  final int idPaiement;

  const DetailUI({super.key, required this.idPaiement});

  @override
  State<DetailUI> createState() => _DetailUIState();
}

class _DetailUIState extends State<DetailUI> {
  final DetailService detailService = DetailService(Supabase.instance.client);

  Map<String, dynamic>? detailsData;
  bool isLoading = true;
  /// Prix reflété en temps réel lors des annulations/restaurations
  double _currentPrixAPaye = 0;
  /// Map id_examen/id_ligne -> bool (true = en cours de traitement)
  final Map<int, bool> _itemLoading = {};

  @override
  void initState() {
    super.initState();
    chargerDetails();
  }

  Future<void> chargerDetails() async {
    setState(() => isLoading = true);
    detailsData = await detailService.getPatientPaymentDetails(
      widget.idPaiement,
    );
    _currentPrixAPaye = (detailsData?['prix_a_paye'] as num?)?.toDouble() ?? 0;
    setState(() => isLoading = false);
  }

  Future<void> validerPaiement() async {
    await detailService.validerPaiement(widget.idPaiement);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              'pay_validated'.tr(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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

    final printConfirm = await _proposerImpressionRecu();
    if (printConfirm == true) {
      await _imprimerRecu();
    }

    if (mounted) Navigator.pop(context, true); // Retour à la liste avec refresh
  }

  // ─────────────────────────────────────────────────────
  // Toggle Examen (Annulé ↔ en attente)
  // ─────────────────────────────────────────────────────
  Future<void> _toggleExamen(Map<String, dynamic> examen) async {
    final idExamen = examen['id_examen'] as int;
    final prix = (examen['prix_examen'] as num?)?.toDouble() ?? 0;
    final isAnnule = (examen['statut_examen'] ?? '') == 'Annulé';

    setState(() => _itemLoading[idExamen] = true);
    try {
      if (isAnnule) {
        await detailService.restaurerExamen(
          idExamen: idExamen,
          idPaiement: widget.idPaiement,
          prixExamen: prix,
        );
      } else {
        await detailService.annulerExamen(
          idExamen: idExamen,
          idPaiement: widget.idPaiement,
          prixExamen: prix,
        );
      }
      // Met à jour l'état local sans recharger toute la page
      setState(() {
        examen['statut_examen'] = isAnnule ? 'en attente' : 'Annulé';
        _currentPrixAPaye = isAnnule
            ? _currentPrixAPaye + prix
            : (_currentPrixAPaye - prix).clamp(0, double.infinity);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: npErrorColor),
        );
      }
    } finally {
      setState(() => _itemLoading.remove(idExamen));
    }
  }

  // ─────────────────────────────────────────────────────
  // Toggle Ligne Prescription (annule ↔ en_attente)
  // ─────────────────────────────────────────────────────
  Future<void> _toggleLignePrescription(Map<String, dynamic> ligne) async {
    final idLigne = ligne['id_ligne'] as int;
    final idPrescription = detailsData!['id_prescription'] as int;
    final prix = (ligne['prix_unitaire'] as num?)?.toDouble() ?? 0;
    final qte = (ligne['quantite'] as num?)?.toInt() ?? 1;
    final montant = prix * qte;
    final isAnnule = (ligne['statut_ligne'] ?? '') == 'annule';

    setState(() => _itemLoading[idLigne] = true);
    try {
      if (isAnnule) {
        await detailService.restaurerLignePrescription(
          idLigne: idLigne,
          idPaiement: widget.idPaiement,
          idPrescription: idPrescription,
          montantLigne: montant,
        );
      } else {
        await detailService.annulerLignePrescription(
          idLigne: idLigne,
          idPaiement: widget.idPaiement,
          idPrescription: idPrescription,
          montantLigne: montant,
        );
      }
      setState(() {
        ligne['statut_ligne'] = isAnnule ? 'en_attente' : 'annule';
        _currentPrixAPaye = isAnnule
            ? _currentPrixAPaye + montant
            : (_currentPrixAPaye - montant).clamp(0, double.infinity);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: npErrorColor),
        );
      }
    } finally {
      setState(() => _itemLoading.remove(idLigne));
    }
  }

  Future<void> _imprimerRecu() async {
    if (detailsData == null) return;

    final consultationMap = detailsData!['Consultation'] as Map<String, dynamic>? ?? {};
    final patientMap = (consultationMap['Patient'] as Map<String, dynamic>?) ?? {};
    patientMap['id_patient'] = consultationMap['id_patient'];
    final patient = Patient.fromMap(patientMap);

    final motif = detailsData!['motif'] ?? 'pay_default_motif'.tr();
    final examensList = (consultationMap['examen_a_effectuer'] as List<dynamic>?) ?? [];
    final typeService = consultationMap['type_service'] ?? 'Consultation';
    final montant = (detailsData!['prix_a_paye'] as num?)?.toDouble() ?? 0.0;
    final currentIdConsultation = (detailsData!['id_consultation'] ?? consultationMap['id_consultation']).toString();

    final data = ReceiptPdfData(
      patientNom: patient.nom_complet,
      patientSexe: patient.sexe,
      patientAge: patient.age.toString(),
      patientTelephone: patient.telephone.toString(),
      idConsultation: currentIdConsultation,
      serviceName: typeService,
      motif: motif,
      montant: montant,
      datePaiement: DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now()),
      statutPaiement: 'Payé',
      examens: examensList,
    );

    await ReceiptPdfGenerator.printReceipt(context: context, data: data);
  }

  Future<bool?> _proposerImpressionRecu() async {
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
                decoration: const BoxDecoration(
                  color: npPrimaryColor,
                  borderRadius: BorderRadius.only(
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
                        Icons.print,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'pay_dlg_print_title'.tr(),
                        style: const TextStyle(
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
                  'pay_dlg_print_msg'.tr(),
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
                          'pay_dlg_print_later'.tr(),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, true),
                        icon: const Icon(Icons.print, size: 18),
                        label: Text('pay_dlg_print_now'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: npPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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

  Future<void> annulerPaiement() async {
    final confirm = await _confirmerAnnulation();
    if (confirm != true) return;

    await detailService.annulerPaiement(widget.idPaiement);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              'pay_cancelled'.tr(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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
    if (mounted) Navigator.pop(context, true); // Retour à la liste avec refresh
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
                    Expanded(
                      child: Text(
                        'pay_dlg_cancel_title'.tr(),
                        style: const TextStyle(
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
                  'pay_dlg_cancel_msg'.tr(),
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
                          'pay_dlg_cancel_no'.tr(),
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
                        child: Text(
                          'pay_dlg_cancel_yes'.tr(),
                          style: const TextStyle(
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
          'pay_detail_title'.tr(),
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
                        _buildItemsSection(),
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
    final consultationMap = detailsData!['Consultation'] as Map<String, dynamic>? ?? {};
    final patientMap = (consultationMap['Patient'] as Map<String, dynamic>?) ?? {};
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
    final motif = detailsData!['motif'] ?? 'pay_default_motif'.tr();
    final statutPaiement = detailsData!['statut_paiement'] ?? 'en_attente';
    final datePaiement = detailsData!['date_paiement'];
    // Utiliser le prix local (mis à jour à chaque toggle d'item)
    final prixAPaye = _currentPrixAPaye;

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
                namedArgs: {'value': prixAPaye.toStringAsFixed(0)},
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
                          _statutLabel(statutPaiement),
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

  // ─────────────────────────────────────────────────────
  // Section items (examens ou médicaments) avec bouton toggle
  // ─────────────────────────────────────────────────────
  Widget _buildItemsSection() {
    if (detailsData == null) return const SizedBox.shrink();

    final motif = (detailsData!['motif'] ?? '').toString();
    final consultationMap = detailsData!['Consultation'] as Map<String, dynamic>? ?? {};
    final idPrescription = detailsData!['id_prescription'];

    List<dynamic> items = [];
    bool isExamen = false;

    if (motif == 'Examens') {
      items = (consultationMap['examen_a_effectuer'] as List<dynamic>?) ?? [];
      isExamen = true;
    } else if (idPrescription != null) {
      items = (detailsData!['prescription_lignes'] as List<dynamic>?) ?? [];
    }

    if (items.isEmpty) return const SizedBox.shrink();

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
            // En-tête section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: npBlueColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isExamen ? Icons.science_rounded : Icons.medication,
                    color: npBlueColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isExamen ? 'Examens prescrits' : 'Médicaments prescrits',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: npBlueColor,
                    ),
                  ),
                ),
                // Nouveau total calculé
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: npSuccessColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_currentPrixAPaye.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: npSuccessColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 8),
            // Liste des items
            ...items.map<Widget>((item) {
              final int itemId = isExamen
                  ? (item['id_examen'] as int)
                  : (item['id_ligne'] as int);
              final bool isLoading = _itemLoading[itemId] == true;

              final String nom = isExamen
                  ? (item['nom_examen'] ?? '').toString()
                  : (item['nom_medicament'] ?? '').toString();

              final double prix = isExamen
                  ? (item['prix_examen'] as num?)?.toDouble() ?? 0
                  : (item['prix_unitaire'] as num?)?.toDouble() ?? 0;

              final int qte = isExamen
                  ? 1
                  : (item['quantite'] as num?)?.toInt() ?? 1;

              final String statut = isExamen
                  ? (item['statut_examen'] ?? '').toString()
                  : (item['statut_ligne'] ?? '').toString();

              final bool isAnnule = isExamen
                  ? statut == 'Annulé'
                  : statut == 'annule';

              // Les items déjà terminés/délivrés ne peuvent plus être modifiés
              final bool isLocked = isExamen
                  ? (statut == 'Terminé' || statut == 'En cours')
                  : (statut == 'delivre' || statut == 'substitue' || statut == 'rupture');

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isAnnule
                      ? Colors.grey.shade50
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isAnnule
                        ? Colors.grey.shade200
                        : npBlueColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    // Icône statut
                    Icon(
                      isAnnule
                          ? Icons.cancel_outlined
                          : isLocked
                              ? Icons.check_circle_outline
                              : Icons.radio_button_unchecked,
                      size: 18,
                      color: isAnnule
                          ? Colors.grey
                          : isLocked
                              ? npSuccessColor
                              : npBlueColor,
                    ),
                    const SizedBox(width: 10),
                    // Nom
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nom,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isAnnule ? Colors.grey : Colors.black87,
                              decoration: isAnnule
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          Text(
                            isExamen
                                ? '${prix.toStringAsFixed(0)} FCFA'
                                : 'x$qte — ${(prix * qte).toStringAsFixed(0)} FCFA',
                            style: TextStyle(
                              fontSize: 11,
                              color: isAnnule ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge annulé (si locked)
                    if (isLocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: npSuccessColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isExamen ? 'En cours' : 'Délivré',
                          style: TextStyle(
                            fontSize: 10,
                            color: npSuccessColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      // Bouton toggle Annuler / Restaurer
                      InkWell(
                        onTap: () => isExamen
                            ? _toggleExamen(item as Map<String, dynamic>)
                            : _toggleLignePrescription(item as Map<String, dynamic>),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isAnnule
                                ? npSuccessColor.withOpacity(0.1)
                                : npErrorColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isAnnule ? npSuccessColor : npErrorColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAnnule ? Icons.restore : Icons.close,
                                size: 13,
                                color: isAnnule ? npSuccessColor : npErrorColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isAnnule ? 'Restaurer' : 'Annuler',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isAnnule ? npSuccessColor : npErrorColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationSection() {
    final consultationMap = detailsData!['Consultation'] as Map<String, dynamic>? ?? {};
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

  String _statutLabel(String statut) {
    switch (statut) {
      case 'payer':
        return 'pay_status_paid'.tr();
      case 'annuler':
        return 'pay_status_cancelled'.tr();
      default:
        return 'pay_status_pending'.tr();
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: annulerPaiement,
            icon: const Icon(Icons.cancel, size: 20),
            label: Text('pay_btn_cancel'.tr()),
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
            label: Text('pay_btn_validate_full'.tr()),
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
