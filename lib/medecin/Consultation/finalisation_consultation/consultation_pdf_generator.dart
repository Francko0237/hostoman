import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' show BuildContext, Color;
import 'package:flutter/services.dart' show rootBundle;
import '../../../shared/pdf_loading_overlay.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Données complètes nécessaires pour la fiche PDF de consultation.
class ConsultationPdfData {
  final String idConsultation;

  // Patient
  final String patientNom;
  final String patientSexe;
  final String patientAge;
  final String patientTelephone;
  final String patientAdresse;
  final String patientProfession;
  final String patientStatutMatrimonial;

  // Paramètres vitaux (peuvent être vides)
  final String? temperature;
  final String? tension;
  final String? poids;
  final String? statutVih;
  final String? vaccination;
  final String? motif;

  // Consultation
  final String antecedents;
  final String signesSymptomes;
  final String diagnosticInitial;
  final String diagnosticFinal;
  final String traitementPrescrit;

  // RDV
  final DateTime? rdvDate;

  // Examens (résultats déjà effectués + nouveaux examens prescrits)
  final List<Map<String, dynamic>> examensResultats;
  final List<Map<String, dynamic>> nouveauxExamens;

  // Médicaments prescrits
  final List<Map<String, dynamic>> medicaments;

  ConsultationPdfData({
    required this.idConsultation,
    required this.patientNom,
    required this.patientSexe,
    required this.patientAge,
    required this.patientTelephone,
    required this.patientAdresse,
    required this.patientProfession,
    required this.patientStatutMatrimonial,
    this.temperature,
    this.tension,
    this.poids,
    this.statutVih,
    this.vaccination,
    this.motif,
    required this.antecedents,
    required this.signesSymptomes,
    required this.diagnosticInitial,
    required this.diagnosticFinal,
    required this.traitementPrescrit,
    this.rdvDate,
    this.examensResultats = const [],
    this.nouveauxExamens = const [],
    this.medicaments = const [],
  });
}

/// Générateur PDF de la fiche de consultation médecin.
class ConsultationPdfGenerator {
  static const _kPrimary = PdfColor.fromInt(0xFF6A5ACD); // primaryPurple
  static const _kPrimaryLight = PdfColor.fromInt(0xFFEFEDFB);

  static Future<String> _getDoctorName() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return 'consult_pdf_doctor_unknown'.tr();
      final data = await client
          .from('Personnel_hopital')
          .select('Nom, Prenom')
          .eq('id_personnel', user.id)
          .single();
      final nom = data['Nom']?.toString() ?? '';
      final prenom = data['Prenom']?.toString() ?? '';
      final full = '$prenom $nom'.trim();
      if (full.isEmpty) return 'consult_pdf_doctor_unknown'.tr();
      return 'Dr. $full';
    } catch (_) {
      return 'consult_pdf_doctor_unknown'.tr();
    }
  }

  static Future<void> previewAndPrint({
    required BuildContext context,
    required ConsultationPdfData data,
  }) async {
    // Verrouille l'écran (polices Google + logo + rendu A4 = 1-3 s sur mobile
    // lent). Le loader est fermé automatiquement avant l'ouverture de la
    // prévisualisation native.
    final built = await runWithPdfLoadingOverlay<_BuiltConsultation>(
      context: context,
      spinnerColor: const Color(0xFF6A5ACD),
      messageKey: 'consult_pdf_generating',
      work: () async {
        final doc = pw.Document();
        final doctorName = await _getDoctorName();

        final ttf = await PdfGoogleFonts.notoSansRegular();
        final ttfBold = await PdfGoogleFonts.notoSansBold();
        final ttfItalic = await PdfGoogleFonts.notoSansItalic();

        pw.MemoryImage? logoImage;
        try {
          final bytes = await rootBundle.load('assets/images/logo.png');
          logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
        } catch (_) {
          logoImage = null;
        }

        final now = DateTime.now();
        final dateImpression = DateFormat("dd/MM/yyyy 'à' HH:mm").format(now);
        final numFiche = data.idConsultation.length > 8
            ? data.idConsultation.substring(0, 8).toUpperCase()
            : data.idConsultation.toUpperCase();

        doc.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(28),
            header: (ctx) => _buildHeader(
              ttf: ttf,
              ttfBold: ttfBold,
              ttfItalic: ttfItalic,
              logo: logoImage,
              numFiche: numFiche,
            ),
            footer: (ctx) => _buildFooter(
              ttf: ttf,
              ttfItalic: ttfItalic,
              doctorName: doctorName,
              dateImpression: dateImpression,
              pageNumber: ctx.pageNumber,
              totalPages: ctx.pagesCount,
            ),
            build: (ctx) => [
              pw.SizedBox(height: 6),
              _titleBanner(ttfBold, 'consult_pdf_title'.tr()),
              pw.SizedBox(height: 10),

              // ===== INFOS PATIENT =====
              _sectionTitle(ttfBold, 'consult_pdf_section_patient'.tr()),
              pw.SizedBox(height: 4),
              _infoGrid(
                ttf,
                ttfBold,
                fullWidthRows: [
                  ['consult_pdf_label_name'.tr(), data.patientNom],
                ],
                pairedRows: [
                  ['consult_pdf_label_sex'.tr(), data.patientSexe],
                  ['consult_pdf_label_age'.tr(), data.patientAge],
                  ['consult_pdf_label_phone'.tr(), data.patientTelephone],
                  ['consult_pdf_label_address'.tr(), data.patientAdresse],
                  ['consult_pdf_label_profession'.tr(), data.patientProfession],
                  ['consult_pdf_label_marital'.tr(), data.patientStatutMatrimonial],
                ],
              ),
              pw.SizedBox(height: 10),

              // ===== PARAMÈTRES VITAUX =====
              if (_hasVitals(data)) ...[
                _sectionTitle(ttfBold, 'consult_pdf_section_vitals'.tr()),
                pw.SizedBox(height: 4),
                _infoGrid(
                  ttf,
                  ttfBold,
                  pairedRows: [
                    if ((data.temperature ?? '').isNotEmpty)
                      ['consult_pdf_label_temp'.tr(), data.temperature!],
                    if ((data.tension ?? '').isNotEmpty)
                      ['consult_pdf_label_tension'.tr(), data.tension!],
                    if ((data.poids ?? '').isNotEmpty)
                      ['consult_pdf_label_weight'.tr(), data.poids!],
                    if ((data.statutVih ?? '').isNotEmpty)
                      ['consult_pdf_label_hiv'.tr(), data.statutVih!],
                    if ((data.vaccination ?? '').isNotEmpty)
                      ['consult_pdf_label_vacc'.tr(), data.vaccination!],
                    if ((data.motif ?? '').isNotEmpty)
                      ['consult_pdf_label_motif'.tr(), data.motif!],
                  ],
                ),
                pw.SizedBox(height: 10),
              ],

              // ===== ANAMNÈSE =====
              _sectionTitle(ttfBold, 'consult_pdf_section_anamnese'.tr()),
              pw.SizedBox(height: 4),
              _textBlock(
                ttf,
                ttfBold,
                'consult_pdf_label_antecedents'.tr(),
                data.antecedents,
              ),
              pw.SizedBox(height: 6),
              _textBlock(
                ttf,
                ttfBold,
                'consult_pdf_label_signs'.tr(),
                data.signesSymptomes,
              ),
              pw.SizedBox(height: 6),
              _textBlock(
                ttf,
                ttfBold,
                'consult_pdf_label_diag_initial'.tr(),
                data.diagnosticInitial,
              ),
              pw.SizedBox(height: 10),

              // ===== EXAMENS EFFECTUÉS (résultats) =====
              if (data.examensResultats.isNotEmpty) ...[
                _sectionTitle(ttfBold, 'consult_pdf_section_exams_done'.tr()),
                pw.SizedBox(height: 4),
                _examensResultsTable(ttf, ttfBold, data.examensResultats),
                pw.SizedBox(height: 10),
              ],

              // ===== DIAGNOSTIC + TRAITEMENT =====
              _sectionTitle(ttfBold, 'consult_pdf_section_diagnostic'.tr()),
              pw.SizedBox(height: 4),
              _textBlock(
                ttf,
                ttfBold,
                'consult_pdf_label_diag_final'.tr(),
                data.diagnosticFinal,
              ),
              pw.SizedBox(height: 6),
              _textBlock(
                ttf,
                ttfBold,
                'consult_pdf_label_treatment'.tr(),
                data.traitementPrescrit,
              ),
              pw.SizedBox(height: 10),

              // ===== NOUVEAUX EXAMENS PRESCRITS =====
              if (data.nouveauxExamens.isNotEmpty) ...[
                _sectionTitle(ttfBold, 'consult_pdf_section_exams_new'.tr()),
                pw.SizedBox(height: 4),
                _examensPrescritsTable(ttf, ttfBold, data.nouveauxExamens),
                pw.SizedBox(height: 10),
              ],

              // ===== MÉDICAMENTS =====
              if (data.medicaments.isNotEmpty) ...[
                _sectionTitle(ttfBold, 'consult_pdf_section_medicaments'.tr()),
                pw.SizedBox(height: 4),
                _medicamentsTable(ttf, ttfBold, data.medicaments),
                pw.SizedBox(height: 10),
              ],

              // ===== RDV =====
              if (data.rdvDate != null) ...[
                _sectionTitle(ttfBold, 'consult_pdf_section_rdv'.tr()),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: _kPrimaryLight,
                    border: pw.Border.all(color: _kPrimary, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                  child: pw.Text(
                    DateFormat(
                      "EEEE dd MMMM yyyy 'à' HH:mm",
                      'fr_FR',
                    ).format(data.rdvDate!),
                    style: pw.TextStyle(
                      font: ttfBold,
                      fontSize: 10,
                      color: _kPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );

        return _BuiltConsultation(doc: doc, numFiche: numFiche, fileDate: now);
      },
    );

    await Printing.layoutPdf(
      onLayout: (format) async => built.doc.save(),
      name:
          'Fiche_Consultation_${built.numFiche}_${DateFormat('yyyyMMdd').format(built.fileDate)}.pdf',
    );
  }

  // ============================== HELPERS ==============================

  static bool _hasVitals(ConsultationPdfData d) {
    return (d.temperature ?? '').isNotEmpty ||
        (d.tension ?? '').isNotEmpty ||
        (d.poids ?? '').isNotEmpty ||
        (d.statutVih ?? '').isNotEmpty ||
        (d.vaccination ?? '').isNotEmpty ||
        (d.motif ?? '').isNotEmpty;
  }

  static pw.Widget _titleBanner(pw.Font ttfBold, String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      decoration: const pw.BoxDecoration(color: _kPrimary),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: ttfBold,
          fontSize: 12,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _sectionTitle(pw.Font ttfBold, String txt) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      decoration: const pw.BoxDecoration(color: _kPrimaryLight),
      child: pw.Text(
        txt,
        style: pw.TextStyle(font: ttfBold, fontSize: 10, color: _kPrimary),
      ),
    );
  }

  static pw.Widget _infoBox(
    pw.Font ttf,
    pw.Font ttfBold, {
    required List<List<String>> rows,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: rows
            .map(
              (r) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 120,
                      child: pw.Text(
                        '${r[0]} :',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        r[1].isEmpty ? '—' : r[1],
                        style: pw.TextStyle(font: ttfBold, fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  /// Renders a compact 2-column grid.
  /// [fullWidthRows]: rows that span both columns (e.g. patient name).
  /// [pairedRows]: placed 2 per row side-by-side.
  static pw.Widget _infoGrid(
    pw.Font ttf,
    pw.Font ttfBold, {
    List<List<String>> fullWidthRows = const [],
    List<List<String>> pairedRows = const [],
  }) {
    // Build paired rows (chunks of 2)
    final List<pw.Widget> gridRows = [];

    // Full-width rows first
    for (final r in fullWidthRows) {
      gridRows.add(
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 90,
                child: pw.Text(
                  '${r[0]} :',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  r[1].isEmpty ? '\u2014' : r[1],
                  style: pw.TextStyle(font: ttfBold, fontSize: 9),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Divider after full-width rows if needed
    if (fullWidthRows.isNotEmpty && pairedRows.isNotEmpty) {
      gridRows.add(
        pw.Divider(height: 4, thickness: 0.3, color: PdfColors.grey400),
      );
    }

    // Pair the remaining rows in groups of 2
    for (int i = 0; i < pairedRows.length; i += 2) {
      final left = pairedRows[i];
      final right = i + 1 < pairedRows.length ? pairedRows[i + 1] : null;

      gridRows.add(
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left cell
              pw.Expanded(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 75,
                      child: pw.Text(
                        '${left[0]} :',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        left[1].isEmpty ? '\u2014' : left[1],
                        style: pw.TextStyle(font: ttfBold, fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ),
              // Vertical separator
              pw.SizedBox(
                width: 1,
                child: pw.Container(color: PdfColors.grey300),
              ),
              pw.SizedBox(width: 8),
              // Right cell (may be empty)
              pw.Expanded(
                child: right != null
                    ? pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.SizedBox(
                            width: 75,
                            child: pw.Text(
                              '${right[0]} :',
                              style: pw.TextStyle(
                                font: ttf,
                                fontSize: 9,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              right[1].isEmpty ? '\u2014' : right[1],
                              style: pw.TextStyle(font: ttfBold, fontSize: 9),
                            ),
                          ),
                        ],
                      )
                    : pw.SizedBox(),
              ),
            ],
          ),
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: gridRows,
      ),
    );
  }

  static pw.Widget _textBlock(
    pw.Font ttf,
    pw.Font ttfBold,
    String label,
    String content,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: ttfBold,
            fontSize: 9,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Text(
            content.trim().isEmpty ? '—' : content,
            style: pw.TextStyle(font: ttf, fontSize: 9),
          ),
        ),
      ],
    );
  }

  static pw.Widget _examensResultsTable(
    pw.Font ttf,
    pw.Font ttfBold,
    List<Map<String, dynamic>> rows,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(4),
        3: pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _kPrimaryLight),
          children: [
            _th(ttfBold, 'consult_pdf_col_exam'.tr()),
            _th(ttfBold, 'consult_pdf_col_status'.tr()),
            _th(ttfBold, 'consult_pdf_col_result'.tr()),
            _th(ttfBold, 'consult_pdf_col_price'.tr()),
          ],
        ),
        ...rows.map(
          (e) => pw.TableRow(
            children: [
              _td(ttf, (e['nom_examen'] ?? '').toString()),
              _td(ttf, (e['statut_examen'] ?? '').toString()),
              _td(ttf, (e['resultat'] ?? '—').toString()),
              _td(ttf, '${e['prix_examen'] ?? 0}', align: pw.TextAlign.right),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _examensPrescritsTable(
    pw.Font ttf,
    pw.Font ttfBold,
    List<Map<String, dynamic>> rows,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(5),
        1: pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _kPrimaryLight),
          children: [
            _th(ttfBold, 'consult_pdf_col_exam'.tr()),
            _th(ttfBold, 'consult_pdf_col_price'.tr()),
          ],
        ),
        ...rows.map(
          (e) => pw.TableRow(
            children: [
              _td(ttf, (e['nom'] ?? '').toString()),
              _td(ttf, '${e['prix'] ?? 0}', align: pw.TextAlign.right),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _medicamentsTable(
    pw.Font ttf,
    pw.Font ttfBold,
    List<Map<String, dynamic>> rows,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(3.5),
        3: pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _kPrimaryLight),
          children: [
            _th(ttfBold, 'consult_pdf_col_medicament'.tr()),
            _th(ttfBold, 'consult_pdf_col_qty'.tr()),
            _th(ttfBold, 'consult_pdf_col_posologie'.tr()),
            _th(ttfBold, 'consult_pdf_col_unit_price'.tr()),
          ],
        ),
        ...rows.map(
          (m) => pw.TableRow(
            children: [
              _td(ttf, (m['nom_medicament'] ?? '').toString()),
              _td(ttf, '${m['quantite'] ?? 1}', align: pw.TextAlign.center),
              _td(ttf, (m['posologie'] ?? '').toString()),
              _td(
                ttf,
                m['prix_unitaire'] != null ? '${m['prix_unitaire']}' : '—',
                align: pw.TextAlign.right,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _th(pw.Font ttfBold, String t) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 5),
    child: pw.Text(
      t,
      style: pw.TextStyle(font: ttfBold, fontSize: 8.5, color: _kPrimary),
    ),
  );

  static pw.Widget _td(
    pw.Font ttf,
    String t, {
    pw.TextAlign align = pw.TextAlign.left,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 5),
    child: pw.Text(
      t,
      style: pw.TextStyle(font: ttf, fontSize: 8.5),
      textAlign: align,
    ),
  );

  static pw.Widget _buildHeader({
    required pw.Font ttf,
    required pw.Font ttfBold,
    required pw.Font ttfItalic,
    required String numFiche,
    pw.MemoryImage? logo,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 60,
            height: 60,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: logo == null ? _kPrimary : PdfColors.white,
              border: logo == null
                  ? null
                  : pw.Border.all(color: _kPrimary, width: 1),
            ),
            padding: logo == null
                ? pw.EdgeInsets.zero
                : const pw.EdgeInsets.all(3),
            child: logo != null
                ? pw.ClipOval(child: pw.Image(logo, fit: pw.BoxFit.cover))
                : pw.Center(
                    child: pw.Text(
                      'HDM',
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 14,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'consult_pdf_header_republic'.tr(),
                  style: pw.TextStyle(font: ttfBold, fontSize: 9),
                ),
                pw.Text(
                  'consult_pdf_header_motto'.tr(),
                  style: pw.TextStyle(
                    font: ttfItalic,
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'consult_pdf_header_hospital'.tr(),
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 11,
                    color: _kPrimary,
                  ),
                ),
                pw.Text(
                  'consult_pdf_header_app'.tr(),
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 7,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Container(
            width: 110,
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _kPrimary, width: 0.5),
              color: _kPrimaryLight,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'consult_pdf_box_num'.tr(),
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 6.5,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  numFiche,
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 9,
                    color: _kPrimary,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'consult_pdf_box_date'.tr(),
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 6.5,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  DateFormat('dd/MM/yyyy').format(DateTime.now()),
                  style: pw.TextStyle(font: ttf, fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter({
    required pw.Font ttf,
    required pw.Font ttfItalic,
    required String doctorName,
    required String dateImpression,
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
              'consult_pdf_doctor_signed'.tr(namedArgs: {'name': doctorName}),
              style: pw.TextStyle(font: ttf, fontSize: 7.5),
            ),
            pw.Text(
              'consult_pdf_printed_on'.tr(namedArgs: {'date': dateImpression}),
              style: pw.TextStyle(
                font: ttf,
                fontSize: 7.5,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(
              'consult_pdf_page'.tr(
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
        pw.SizedBox(height: 2),
        pw.Text(
          'consult_pdf_confidential'.tr(),
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

/// Conteneur interne : document PDF construit + numéro de fiche + date.
class _BuiltConsultation {
  final pw.Document doc;
  final String numFiche;
  final DateTime fileDate;
  _BuiltConsultation({
    required this.doc,
    required this.numFiche,
    required this.fileDate,
  });
}
