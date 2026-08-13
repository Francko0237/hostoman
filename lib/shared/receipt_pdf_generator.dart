import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart' show BuildContext, Color;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pdf_loading_overlay.dart';

/// Données nécessaires pour générer le reçu
class ReceiptPdfData {
  final String patientNom;
  final String patientSexe;
  final String patientAge;
  final String patientTelephone;
  final String idConsultation;
  final String serviceName;
  final String motif;
  final double montant;
  final String datePaiement;
  final String statutPaiement;
  final List<dynamic> examens;

  ReceiptPdfData({
    required this.patientNom,
    required this.patientSexe,
    required this.patientAge,
    required this.patientTelephone,
    required this.idConsultation,
    required this.serviceName,
    required this.motif,
    required this.montant,
    required this.datePaiement,
    required this.statutPaiement,
    this.examens = const [],
  });
}

/// Générateur PDF pour un Reçu de Caissier
class ReceiptPdfGenerator {
  /// Récupère le nom formaté de l'agent connecté
  static Future<String> _getAgentNameFromDb() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return 'rcpt_agent_unknown'.tr();

      // Essai 1 : colonne auth_id (pharmaciens, caissiers, etc.)
      Map<String, dynamic>? data = await client
          .from('Personnel_hopital')
          .select('Nom, Prenom')
          .eq('auth_id', user.id)
          .maybeSingle();

      // Essai 2 : colonne id_personnel (médecins et autres)
      data ??= await client
          .from('Personnel_hopital')
          .select('Nom, Prenom')
          .eq('id_personnel', user.id)
          .maybeSingle();

      if (data == null) throw Exception('Aucun personnel trouvé');

      final nom = data['Nom']?.toString() ?? '';
      final prenom = data['Prenom']?.toString() ?? '';

      final fullName = '$prenom $nom'.trim();
      if (fullName.isEmpty) throw Exception('Nom vide');
      return fullName;
    } catch (e) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return 'rcpt_agent_unknown'.tr();
      final meta = user.userMetadata;
      if (meta != null) {
        final nom = meta['Nom'] ?? meta['nom'] ?? meta['name'];
        final prenom = meta['Prenom'] ?? meta['prenom'];
        if (nom != null && prenom != null) return '$prenom $nom';
        if (nom != null) return nom.toString();
      }
      return user.email ?? 'rcpt_agent_unknown'.tr();
    }
  }

  /// Génère et ouvre la prévisualisation PDF du reçu
  static Future<void> printReceipt({
    required BuildContext context,
    required ReceiptPdfData data,
  }) async {
    // Verrouille l'écran pendant la construction du document.
    final built = await runWithPdfLoadingOverlay<_BuiltReceipt>(
      context: context,
      spinnerColor: const Color(0xFF2E7D32),
      work: () async {
        final doc = pw.Document();
        final agentName = await _getAgentNameFromDb();

        // Polices intégrées au PDF (instantané)
        final ttf = pw.Font.helvetica();
        final ttfBold = pw.Font.helveticaBold();
        final ttfItalic = pw.Font.helveticaOblique();

        // Logo (silencieux si l'asset est introuvable)
        pw.MemoryImage? logoImage;
        try {
          final bytes = await rootBundle.load('assets/images/logo.png');
          logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
        } catch (_) {
          logoImage = null;
        }

        final now = DateTime.now();
        final dateImpression = DateFormat('rcpt_date_format'.tr()).format(now);

        // UUID court (8 caractères) pour le N° de Reçu
        final numRecu = data.idConsultation.length > 8
            ? data.idConsultation.substring(0, 8).toUpperCase()
            : data.idConsultation.toUpperCase();

        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a5, // A5 pour un reçu
            margin: const pw.EdgeInsets.all(30),
            build: (pw.Context ctx) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // ========== EN-TÊTE ==========
                  _buildHeader(
                    ttf: ttf,
                    ttfBold: ttfBold,
                    ttfItalic: ttfItalic,
                    logo: logoImage,
                  ),
                  pw.SizedBox(height: 15),

                  // ========== TITRE REÇU ==========
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF2E7D32), // Vert caisse
                    ),
                    padding: const pw.EdgeInsets.symmetric(vertical: 8),
                    child: pw.Text(
                      'rcpt_title'.tr(),
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 14,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(height: 5),

                  pw.Center(
                    child: pw.Text(
                      'rcpt_number'.tr(namedArgs: {'num': numRecu}),
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 10,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // ========== INFOS PATIENT ==========
                  pw.Text(
                    'rcpt_section_patient'.tr(),
                    style: pw.TextStyle(
                      font: ttfBold,
                      fontSize: 10,
                      color: const PdfColor.fromInt(0xFF2E7D32),
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                  pw.SizedBox(height: 8),

                  _buildInfoRow(
                    ttf,
                    ttfBold,
                    'rcpt_label_name'.tr(),
                    data.patientNom,
                  ),
                  _buildInfoRow(
                    ttf,
                    ttfBold,
                    'rcpt_label_age_sex'.tr(),
                    'rcpt_value_age_sex'.tr(
                      namedArgs: {
                        'age': data.patientAge,
                        'sexe': data.patientSexe,
                      },
                    ),
                  ),
                  _buildInfoRow(
                    ttf,
                    ttfBold,
                    'rcpt_label_phone'.tr(),
                    data.patientTelephone,
                  ),
                  pw.SizedBox(height: 15),

                  // ========== DÉTAILS DU PAIEMENT ==========
                  pw.Text(
                    'rcpt_section_payment'.tr(),
                    style: pw.TextStyle(
                      font: ttfBold,
                      fontSize: 10,
                      color: const PdfColor.fromInt(0xFF2E7D32),
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                  pw.SizedBox(height: 8),

                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.grey400,
                        width: 0.5,
                      ),
                      color: const PdfColor.fromInt(
                        0xFFF1F8E9,
                      ), // Vert très clair
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          ttf,
                          ttfBold,
                          'rcpt_label_motif'.tr(),
                          data.motif,
                        ),
                        pw.SizedBox(height: 4),
                        _buildInfoRow(
                          ttf,
                          ttfBold,
                          'rcpt_label_service'.tr(),
                          data.serviceName,
                        ),
                        pw.SizedBox(height: 4),
                        _buildInfoRow(
                          ttf,
                          ttfBold,
                          'rcpt_label_datetime'.tr(),
                          data.datePaiement,
                        ),
                        pw.SizedBox(height: 4),
                        _buildInfoRow(
                          ttf,
                          ttfBold,
                          'rcpt_label_status'.tr(),
                          data.statutPaiement.toUpperCase(),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Divider(color: PdfColors.grey500, thickness: 0.5),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'rcpt_total_label'.tr(),
                              style: pw.TextStyle(font: ttfBold, fontSize: 11),
                            ),
                            pw.Text(
                              'rcpt_amount_value'.tr(
                                namedArgs: {
                                  'amount': data.montant.toStringAsFixed(0),
                                },
                              ),
                              style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 13,
                                color: const PdfColor.fromInt(
                                  0xFF2E7D32,
                                ), // Vert foncé
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (data.examens.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'rcpt_section_exams'.tr(),
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 10,
                        color: const PdfColor.fromInt(0xFF2E7D32),
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.grey400,
                          width: 0.5,
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: data.examens.map((exam) {
                          final nom =
                              exam['nom_examen']?.toString() ??
                              'rcpt_exam_unknown'.tr();
                          final prix = exam['prix_examen']?.toString() ?? '0';
                          return pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 2),
                            child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Expanded(
                                  child: pw.Text(
                                    '- $nom',
                                    style: pw.TextStyle(
                                      font: ttf,
                                      fontSize: 9,
                                      color: PdfColors.grey800,
                                    ),
                                  ),
                                ),
                                pw.Text(
                                  'rcpt_amount_value'.tr(
                                    namedArgs: {'amount': prix},
                                  ),
                                  style: pw.TextStyle(
                                    font: ttfBold,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  pw.Spacer(),

                  // ========== SIGNATURES ==========
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'rcpt_sign_agent'.tr(),
                            style: pw.TextStyle(font: ttfBold, fontSize: 9),
                          ),
                          pw.SizedBox(height: 25),
                          pw.Text(
                            agentName,
                            style: pw.TextStyle(font: ttf, fontSize: 9),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'rcpt_sign_stamp'.tr(),
                            style: pw.TextStyle(font: ttfBold, fontSize: 9),
                          ),
                          pw.SizedBox(height: 25),
                          pw.Text(
                            '________________________',
                            style: pw.TextStyle(font: ttf, fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 20),

                  // ========== PIED DE PAGE ==========
                  pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                  pw.SizedBox(height: 5),
                  pw.Center(
                    child: pw.Text(
                      'rcpt_footer_printed'.tr(
                        namedArgs: {'date': dateImpression},
                      ),
                      style: pw.TextStyle(
                        font: ttfItalic,
                        fontSize: 7,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Center(
                    child: pw.Text(
                      'rcpt_footer_note'.tr(),
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 7,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );

        return _BuiltReceipt(doc: doc, numRecu: numRecu, fileDate: now);
      },
    );

    // Lancer la prévisualisation et l'impression
    await Printing.layoutPdf(
      onLayout: (format) async => built.doc.save(),
      name:
          'Recu_Paiement_${built.numRecu}_${DateFormat('yyyyMMdd').format(built.fileDate)}.pdf',
    );
  }

  // Ligne de clé-valeur dans le reçu
  static pw.Widget _buildInfoRow(
    pw.Font ttf,
    pw.Font ttfBold,
    String label,
    String value,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              '$label :',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: ttfBold, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  /// Génère et ouvre la prévisualisation PDF du reçu pour la pharmacie
  static Future<void> printPharmacyReceipt({
    required BuildContext context,
    required String patientNom,
    required String idPrescription,
    required double total,
    required List<dynamic> lignes,
    bool isVenteLibre = false,
  }) async {
    final built = await runWithPdfLoadingOverlay<_BuiltReceipt>(
      context: context,
      spinnerColor: const Color(0xFF2E7D5B),
      work: () async {
        final doc = pw.Document();
        final agentName = await _getAgentNameFromDb();

        final ttf = pw.Font.helvetica();
        final ttfBold = pw.Font.helveticaBold();
        final ttfItalic = pw.Font.helveticaOblique();

        pw.MemoryImage? logoImage;
        try {
          final bytes = await rootBundle.load('assets/images/logo.png');
          logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
        } catch (_) {
          logoImage = null;
        }

        final now = DateTime.now();
        final dateImpression = DateFormat('rcpt_date_format'.tr()).format(now);
        final numRecu = 'HST-${idPrescription.toString().padLeft(6, '0')}';

        const kPharmacyColor = PdfColor.fromInt(0xFF2E7D5B); // Vert Pharmacie

        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a5,
            margin: const pw.EdgeInsets.all(30),
            build: (pw.Context ctx) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // En-tête hôpital
                  _buildHeader(
                    ttf: ttf,
                    ttfBold: ttfBold,
                    ttfItalic: ttfItalic,
                    logo: logoImage,
                  ),
                  pw.SizedBox(height: 15),

                  // Titre
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                      color: kPharmacyColor,
                    ),
                    padding: const pw.EdgeInsets.symmetric(vertical: 8),
                    child: pw.Text(
                      isVenteLibre ? 'REÇU DE PHARMACIE (VENTE DIRECTE)' : 'REÇU DE PHARMACIE',
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(height: 5),

                  pw.Center(
                    child: pw.Text(
                      'Reçu N° : $numRecu',
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 10,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 15),

                  // Infos Patient/Vente
                  pw.Text(
                    'INFORMATIONS DE VENTE',
                    style: pw.TextStyle(
                      font: ttfBold,
                      fontSize: 9,
                      color: kPharmacyColor,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  _buildInfoRow(ttf, ttfBold, 'Client / Patient', patientNom),
                  _buildInfoRow(ttf, ttfBold, 'Date / Heure', dateImpression),
                  _buildInfoRow(ttf, ttfBold, 'Type de vente', isVenteLibre ? 'Vente Libre (sans ordonnance)' : 'Ordonnance médicale'),

                  pw.SizedBox(height: 15),

                  // Tableau des médicaments
                  pw.Text(
                    'MÉDICAMENTS LIVRÉS',
                    style: pw.TextStyle(
                      font: ttfBold,
                      fontSize: 9,
                      color: kPharmacyColor,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                  pw.SizedBox(height: 6),

                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                    ),
                    child: pw.Column(
                      children: [
                        // En-tête tableau
                        pw.Container(
                          color: PdfColors.grey200,
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Row(
                            children: [
                              pw.Expanded(
                                flex: 3,
                                child: pw.Text('Désignation', style: pw.TextStyle(font: ttfBold, fontSize: 8)),
                              ),
                              pw.Expanded(
                                flex: 1,
                                child: pw.Text('Qte', style: pw.TextStyle(font: ttfBold, fontSize: 8), textAlign: pw.TextAlign.center),
                              ),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Text('P.U.', style: pw.TextStyle(font: ttfBold, fontSize: 8), textAlign: pw.TextAlign.right),
                              ),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Text('Total', style: pw.TextStyle(font: ttfBold, fontSize: 8), textAlign: pw.TextAlign.right),
                              ),
                            ],
                          ),
                        ),
                        // Lignes
                        ...lignes.map((l) {
                          final nomMed = (l['nom_medicament'] ?? '').toString();
                          final qte = (l['quantite'] as num?)?.toInt() ?? 1;
                          final pu = (l['prix_unitaire'] as num?)?.toDouble() ?? 0;
                          final tot = pu * qte;
                          return pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                            ),
                            child: pw.Row(
                              children: [
                                pw.Expanded(
                                  flex: 3,
                                  child: pw.Text(nomMed, style: pw.TextStyle(font: ttf, fontSize: 8)),
                                ),
                                pw.Expanded(
                                  flex: 1,
                                  child: pw.Text('$qte', style: pw.TextStyle(font: ttf, fontSize: 8), textAlign: pw.TextAlign.center),
                                ),
                                pw.Expanded(
                                  flex: 2,
                                  child: pw.Text('${pu.toStringAsFixed(0)}', style: pw.TextStyle(font: ttf, fontSize: 8), textAlign: pw.TextAlign.right),
                                ),
                                pw.Expanded(
                                  flex: 2,
                                  child: pw.Text('${tot.toStringAsFixed(0)}', style: pw.TextStyle(font: ttfBold, fontSize: 8), textAlign: pw.TextAlign.right),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 10),

                  // Total
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text('NET À PAYER : ', style: pw.TextStyle(font: ttfBold, fontSize: 10)),
                      pw.Text(
                        '${total.toStringAsFixed(0)} FCFA',
                        style: pw.TextStyle(font: ttfBold, fontSize: 12, color: kPharmacyColor),
                      ),
                    ],
                  ),

                  pw.Spacer(),

                  // Signatures
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Le Pharmacien :', style: pw.TextStyle(font: ttfBold, fontSize: 9)),
                          pw.SizedBox(height: 25),
                          pw.Text(agentName, style: pw.TextStyle(font: ttf, fontSize: 9)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('Cachet / Signature :', style: pw.TextStyle(font: ttfBold, fontSize: 9)),
                          pw.SizedBox(height: 25),
                          pw.Text('________________________', style: pw.TextStyle(font: ttf, fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 15),

                  // Pied de page
                  pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                  pw.SizedBox(height: 5),
                  pw.Center(
                    child: pw.Text(
                      'Imprimé le $dateImpression',
                      style: pw.TextStyle(font: ttfItalic, fontSize: 7, color: PdfColors.grey600),
                    ),
                  ),
                  pw.Center(
                    child: pw.Text(
                      'Les médicaments vendus ne sont ni repris ni échangés.',
                      style: pw.TextStyle(font: ttf, fontSize: 7, color: PdfColors.grey600),
                    ),
                  ),
                ],
              );
            },
          ),
        );

        return _BuiltReceipt(doc: doc, numRecu: numRecu, fileDate: now);
      },
    );

    await Printing.layoutPdf(
      onLayout: (format) async => built.doc.save(),
      name: 'Recu_Pharmacie_${built.numRecu}_${DateFormat('yyyyMMdd').format(built.fileDate)}.pdf',
    );
  }

  // En-tête de l'hôpital (très similaire à pdf_generator.dart)
  static pw.Widget _buildHeader({
    required pw.Font ttf,
    required pw.Font ttfBold,
    required pw.Font ttfItalic,
    pw.MemoryImage? logo,
  }) {
    const kPrimary = PdfColor.fromInt(0xFF2E7D32); // Vert caisse
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo (image réelle si disponible, sinon fallback texte)
        pw.Container(
          width: 50,
          height: 50,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            color: logo == null ? kPrimary : PdfColors.white,
            border: logo == null
                ? null
                : pw.Border.all(color: kPrimary, width: 1),
          ),
          padding: logo == null
              ? pw.EdgeInsets.zero
              : const pw.EdgeInsets.all(3),
          child: logo != null
              ? pw.ClipOval(child: pw.Image(logo, fit: pw.BoxFit.cover))
              : pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        'HDM',
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 13,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'MANJO',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 6,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        pw.SizedBox(width: 10),

        // Infos hôpital
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'rcpt_header_republic'.tr(),
                style: pw.TextStyle(font: ttfBold, fontSize: 8),
              ),
              pw.Text(
                'rcpt_header_motto'.tr(),
                style: pw.TextStyle(
                  font: ttfItalic,
                  fontSize: 6.5,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'rcpt_header_hospital'.tr(),
                style: pw.TextStyle(
                  font: ttfBold,
                  fontSize: 10,
                  color: const PdfColor.fromInt(0xFF2E7D32),
                ),
              ),
              pw.Text(
                'rcpt_header_app'.tr(),
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 6.5,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Conteneur interne : reçu PDF construit + numéro + date de génération.
class _BuiltReceipt {
  final pw.Document doc;
  final String numRecu;
  final DateTime fileDate;
  _BuiltReceipt({
    required this.doc,
    required this.numRecu,
    required this.fileDate,
  });
}
