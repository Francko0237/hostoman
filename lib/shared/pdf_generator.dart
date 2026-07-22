import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart' show BuildContext, Color;
import 'package:flutter/services.dart' show rootBundle;
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pdf_loading_overlay.dart';

/// Modèle universel pour un patient dans la liste PDF
class PatientPdfData {
  final String nom;
  final String sexe;
  final String age;
  final String telephone;
  final String dateEnregistrement;
  final String? categorie;
  final String? montant;

  PatientPdfData({
    required this.nom,
    required this.sexe,
    required this.age,
    required this.telephone,
    required this.dateEnregistrement,
    this.categorie,
    this.montant,
  });
}

/// Service de génération et prévisualisation PDF
class PatientListPdfGenerator {
  /// Récupère le nom formaté (titre + nom complet) depuis Personnel_hopital
  static Future<String> _getAgentNameFromDb() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return 'pdf_unknown_agent'.tr();

      final data = await client
          .from('Personnel_hopital')
          .select('Nom, Prenom, Specialite')
          .eq('id_personnel', user.id)
          .single();

      final nom = data['Nom']?.toString() ?? '';
      final prenom = data['Prenom']?.toString() ?? '';
      final specialite = data['Specialite']?.toString() ?? '';

      // Détermination du titre selon la spécialité
      String titre;
      if (specialite.toLowerCase().contains('médecin') ||
          specialite.toLowerCase().contains('medecin') ||
          specialite.toLowerCase().contains('docteur') ||
          specialite.toLowerCase().contains('dr')) {
        titre = 'Dr.';
      } else {
        titre = 'M.';
      }

      final fullName = '$prenom $nom'.trim();
      if (fullName.isEmpty) return 'pdf_unknown_agent'.tr();
      return '$titre $fullName';
    } catch (e) {
      // Fallback sur les métadonnées Auth
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return 'pdf_unknown_agent'.tr();
      final meta = user.userMetadata;
      if (meta != null) {
        final nom = meta['Nom'] ?? meta['nom'] ?? meta['name'];
        final prenom = meta['Prenom'] ?? meta['prenom'];
        if (nom != null && prenom != null) return '$prenom $nom';
        if (nom != null) return nom.toString();
      }
      return user.email ?? 'pdf_unknown_agent'.tr();
    }
  }

  /// Génère et ouvre la prévisualisation PDF
  static Future<void> previewAndPrint({
    required BuildContext context,
    required String serviceName,
    required String periodeLabel,
    required List<PatientPdfData> patients,
    bool showMontant = false,
    bool showCategorie = false,
    String? categorieLabel,
  }) async {
    // Verrouille l'écran pendant la phase de construction du document
    // (chargement des polices Google + logo + pages). Le loader sera fermé
    // automatiquement avant l'ouverture de la prévisualisation native.
    final result = await runWithPdfLoadingOverlay<_BuiltDoc>(
      context: context,
      spinnerColor: const Color(0xFF0D47A1),
      work: () async {
        final doc = pw.Document();
        final agentName = await _getAgentNameFromDb();
        final effectiveCategorieLabel =
            categorieLabel ?? 'pdf_default_category'.tr();

        // Polices
        final ttf = await PdfGoogleFonts.notoSansRegular();
        final ttfBold = await PdfGoogleFonts.notoSansBold();
        final ttfItalic = await PdfGoogleFonts.notoSansItalic();

        // Logo (silencieux si l'asset est introuvable)
        pw.MemoryImage? logoImage;
        try {
          final bytes = await rootBundle.load('assets/images/logo.png');
          logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
        } catch (_) {
          logoImage = null;
        }

        // Découpage en pages de 25 patients
        const int perPage = 25;
        final pages = <List<PatientPdfData>>[];
        for (int i = 0; i < patients.length; i += perPage) {
          pages.add(
            patients.sublist(
              i,
              i + perPage > patients.length ? patients.length : i + perPage,
            ),
          );
        }
        if (pages.isEmpty) pages.add([]);

        final now = DateTime.now();
        final dateImpression = DateFormat("dd/MM/yyyy 'à' HH:mm").format(now);
        final int totalPages = pages.length;

        for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
          final pagePatients = pages[pageIndex];
          final startIndex = pageIndex * perPage;

          doc.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(28),
              build: (pw.Context ctx) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // ========== EN-TÊTE ==========
                    _buildHeader(
                      ttf: ttf,
                      ttfBold: ttfBold,
                      ttfItalic: ttfItalic,
                      serviceName: serviceName,
                      logo: logoImage,
                    ),
                    pw.SizedBox(height: 14),

                    // ========== BANDEAU TITRE ==========
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF0D47A1),
                      ),
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: pw.Text(
                        'pdf_title_banner'.tr(
                          namedArgs: {'service': serviceName.toUpperCase()},
                        ),
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 11,
                          color: PdfColors.white,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF1565C0),
                      ),
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 16,
                      ),
                      child: pw.Text(
                        (patients.length > 1
                                ? 'pdf_period_total_many'
                                : 'pdf_period_total_one')
                            .tr(
                              namedArgs: {
                                'periode': periodeLabel,
                                'count': '${patients.length}',
                              },
                            ),
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 8,
                          color: PdfColors.white,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.SizedBox(height: 10),

                    // ========== TABLEAU ==========
                    _buildTable(
                      ttf: ttf,
                      ttfBold: ttfBold,
                      patients: pagePatients,
                      startIndex: startIndex,
                      showMontant: showMontant,
                      showCategorie: showCategorie,
                      categorieLabel: effectiveCategorieLabel,
                    ),

                    pw.Spacer(),

                    // ========== RÉCAPITULATIF TOTAL (dernière page) ==========
                    if (pageIndex == totalPages - 1) ...[
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
                        ),
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFFE3F2FD),
                          border: pw.Border.all(
                            color: const PdfColor.fromInt(0xFF1565C0),
                            width: 0.5,
                          ),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              (patients.length > 1
                                      ? 'pdf_total_many'
                                      : 'pdf_total_one')
                                  .tr(
                                    namedArgs: {'count': '${patients.length}'},
                                  ),
                              style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 9,
                                color: const PdfColor.fromInt(0xFF0D47A1),
                              ),
                            ),
                            if (showMontant)
                              pw.Text(
                                'pdf_amounts_included'.tr(),
                                style: pw.TextStyle(
                                  font: ttfItalic,
                                  fontSize: 8,
                                  color: const PdfColor.fromInt(0xFF1565C0),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],

                    pw.SizedBox(height: 6),

                    // ========== PIED DE PAGE ==========
                    _buildFooter(
                      ttf: ttf,
                      ttfItalic: ttfItalic,
                      totalPatients: patients.length,
                      dateImpression: dateImpression,
                      agentName: agentName,
                      pageNumber: pageIndex + 1,
                      totalPages: totalPages,
                    ),
                  ],
                );
              },
            ),
          );
        }

        return _BuiltDoc(doc: doc, fileDate: now);
      },
    );

    await Printing.layoutPdf(
      onLayout: (format) async => result.doc.save(),
      name:
          '${'pdf_filename_prefix'.tr()}_${serviceName}_${DateFormat('yyyyMMdd').format(result.fileDate)}.pdf',
    );
  }

  // ─────────────────────────────────────────────────

  static pw.Widget _buildHeader({
    required pw.Font ttf,
    required pw.Font ttfBold,
    required pw.Font ttfItalic,
    required String serviceName,
    pw.MemoryImage? logo,
  }) {
    const kPrimary = PdfColor.fromInt(0xFF0D47A1);
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Colonne gauche — Logo (image réelle si disponible, sinon fallback texte)
        pw.Container(
          width: 72,
          height: 72,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            color: logo == null ? kPrimary : PdfColors.white,
            border: logo == null
                ? null
                : pw.Border.all(color: kPrimary, width: 1),
          ),
          padding: logo == null
              ? pw.EdgeInsets.zero
              : const pw.EdgeInsets.all(4),
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
                          fontSize: 16,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'MANJO',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 7,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        pw.SizedBox(width: 14),

        // Colonne centrale — infos hôpital
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'pdf_republic'.tr(),
                style: pw.TextStyle(font: ttfBold, fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'pdf_motto'.tr(),
                style: pw.TextStyle(
                  font: ttfItalic,
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.Divider(thickness: 0.5, color: PdfColors.grey),
              pw.Text(
                'pdf_republic_en'.tr(),
                style: pw.TextStyle(font: ttfBold, fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'pdf_motto_en'.tr(),
                style: pw.TextStyle(
                  font: ttfItalic,
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                '— ✦ —',
                style: pw.TextStyle(font: ttf, fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'pdf_hospital_name'.tr(),
                style: pw.TextStyle(
                  font: ttfBold,
                  fontSize: 11,
                  color: const PdfColor.fromInt(0xFF0D47A1),
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'pdf_system'.tr(),
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 7.5,
                  color: PdfColors.grey700,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 14),

        // Colonne droite — infos document
        pw.Container(
          width: 110,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: const PdfColor.fromInt(0xFF1565C0),
              width: 0.5,
            ),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            color: const PdfColor.fromInt(0xFFF5F9FF),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'pdf_box_service'.tr(),
                style: pw.TextStyle(
                  font: ttfBold,
                  fontSize: 6.5,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                serviceName.toUpperCase(),
                style: pw.TextStyle(
                  font: ttfBold,
                  fontSize: 8.5,
                  color: const PdfColor.fromInt(0xFF0D47A1),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'pdf_box_date'.tr(),
                style: pw.TextStyle(
                  font: ttfBold,
                  fontSize: 6.5,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                DateFormat('dd/MM/yyyy').format(DateTime.now()),
                style: pw.TextStyle(font: ttf, fontSize: 7.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTable({
    required pw.Font ttf,
    required pw.Font ttfBold,
    required List<PatientPdfData> patients,
    required int startIndex,
    required bool showMontant,
    required bool showCategorie,
    required String categorieLabel,
  }) {
    final columns = <String>[
      'pdf_col_num'.tr(),
      'pdf_col_name'.tr(),
      'pdf_col_sex'.tr(),
      'pdf_col_age'.tr(),
      'pdf_col_phone'.tr(),
      'pdf_col_date'.tr(),
    ];
    if (showCategorie) columns.insert(columns.length - 1, categorieLabel);
    if (showMontant) columns.add('pdf_col_amount'.tr());

    final widths = <double>[0.05, 0.22, 0.07, 0.06, 0.14, 0.12];
    if (showCategorie) widths.insert(widths.length - 1, 0.15);
    if (showMontant) widths.add(0.13);

    final total = widths.fold(0.0, (sum, w) => sum + w);
    final normWidths = widths.map((w) => w / total).toList();

    final headerCells = columns
        .asMap()
        .entries
        .map(
          (e) => pw.Expanded(
            flex: (normWidths[e.key] * 100).round(),
            child: pw.Container(
              color: const PdfColor.fromInt(0xFF0D47A1),
              padding: const pw.EdgeInsets.symmetric(
                vertical: 5,
                horizontal: 3,
              ),
              child: pw.Text(
                e.value,
                style: pw.TextStyle(
                  font: ttfBold,
                  fontSize: 7.5,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),
        )
        .toList();

    final dataRows = patients.asMap().entries.map((entry) {
      final i = entry.key;
      final p = entry.value;
      final isEven = i % 2 == 0;
      final bg = isEven ? const PdfColor.fromInt(0xFFF5F9FF) : PdfColors.white;

      final cells = [
        '${startIndex + i + 1}',
        p.nom,
        p.sexe,
        p.age,
        p.telephone,
        p.dateEnregistrement,
      ];
      if (showCategorie) cells.insert(cells.length - 1, p.categorie ?? '-');
      if (showMontant) cells.add(p.montant ?? '-');

      return pw.Row(
        children: cells
            .asMap()
            .entries
            .map(
              (e) => pw.Expanded(
                flex: (normWidths[e.key] * 100).round(),
                child: pw.Container(
                  color: bg,
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 3,
                  ),
                  child: pw.Text(
                    e.value,
                    style: pw.TextStyle(font: ttf, fontSize: 7),
                    textAlign: e.key == 0
                        ? pw.TextAlign.center
                        : pw.TextAlign.left,
                  ),
                ),
              ),
            )
            .toList(),
      );
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(children: headerCells),
        ...dataRows,
        pw.Container(height: 1, color: const PdfColor.fromInt(0xFF0D47A1)),
      ],
    );
  }

  static pw.Widget _buildFooter({
    required pw.Font ttf,
    required pw.Font ttfItalic,
    required int totalPatients,
    required String dateImpression,
    required String agentName,
    required int pageNumber,
    required int totalPages,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'pdf_printed_by'.tr(namedArgs: {'name': agentName}),
              style: pw.TextStyle(
                font: ttf,
                fontSize: 7.5,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(
              'pdf_printed_on'.tr(namedArgs: {'date': dateImpression}),
              style: pw.TextStyle(
                font: ttf,
                fontSize: 7.5,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(
              'pdf_page_indicator'.tr(
                namedArgs: {'n': '$pageNumber', 'total': '$totalPages'},
              ),
              style: pw.TextStyle(
                font: ttf,
                fontSize: 7.5,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'pdf_confidential'.tr(),
          style: pw.TextStyle(
            font: ttfItalic,
            fontSize: 6.5,
            color: PdfColors.grey500,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }
}

/// Conteneur interne : document PDF construit + date de fin de génération
/// (utilisée pour nommer le fichier).
class _BuiltDoc {
  final pw.Document doc;
  final DateTime fileDate;
  _BuiltDoc({required this.doc, required this.fileDate});
}
