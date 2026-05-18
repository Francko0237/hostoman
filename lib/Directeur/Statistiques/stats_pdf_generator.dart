import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart' show BuildContext, Locale;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Type de fiche à exporter
enum StatsExportType {
  overview, // Vue Générale (KPI + activité + statuts)
  finance, // Finance détaillée
  patients, // Démographie patients
  full, // Tout (chaque section sur une page)
}

/// Couleurs cohérentes avec l'app
const _kPrimary = PdfColor.fromInt(0xFF1A237E);
const _kPrimaryLight = PdfColor.fromInt(0xFFE8EAF6);
const _kSuccess = PdfColor.fromInt(0xFF16A34A);
const _kSuccessLight = PdfColor.fromInt(0xFFDCFCE7);
const _kInfo = PdfColor.fromInt(0xFF0284C7);
const _kInfoLight = PdfColor.fromInt(0xFFE0F2FE);
const _kAccent = PdfColor.fromInt(0xFF7C3AED);
const _kWarning = PdfColor.fromInt(0xFFD97706);
const _kDanger = PdfColor.fromInt(0xFFDC2626);
const _kSlate = PdfColor.fromInt(0xFF64748B);
const _kSlateLight = PdfColor.fromInt(0xFFF1F5F9);

/// Pack i18n du PDF (toutes les chaînes utilisées dans le rapport).
class StatsPdfL10n {
  // Header
  final String republicLine;
  final String motto;
  final String hospitalName;
  final String appLine;
  final String typeLabel;
  final String periodLabel;
  // Banner
  final String reportPrefix; // "RAPPORT" ou "REPORT"
  // Section titles
  final String overviewTitle;
  final String financeTitle;
  final String patientsTitle;
  // Footer
  final String printedBy;
  final String printedOn;
  final String pageOf; // "Page %d / %d" (template)
  final String confidential;
  // Common
  final String
  dateFormatPrintedAt; // ex: "dd/MM/yyyy 'à' HH:mm" / "MM/dd/yyyy 'at' HH:mm"
  final String dateFormatLong; // ex: "dd MMM yyyy"
  final String currency; // "FCFA"

  // Overview labels
  final String kpiRevenue;
  final String kpiUniquePatients;
  final String kpiConsultations;
  final String opsStatus;
  final String opsFinished;
  final String opsOngoing;
  final String opsCancelled;
  final String dailyActivity;

  // Finance labels
  final String totalRevenuePeriod;
  final String paymentsCollected; // "X paiements encaissés"
  final String avgPayment;
  final String avgDaily;
  final String maxPayment;
  final String minPayment;
  final String bestDay;
  final String pending;
  final String pendingCount; // "X paiement(s)"
  final String revenueEvolution;

  // Patients labels
  final String patientsRegistered; // "PATIENTS UNIQUES ENREGISTRÉS"
  final String genderDist;
  final String men;
  final String women;
  final String ageDist;
  final String ageChildren;
  final String ageYoungAdults;
  final String ageAdults;
  final String ageSeniors;
  final String yearsSuffix; // " ans" ou " yrs"

  const StatsPdfL10n({
    required this.republicLine,
    required this.motto,
    required this.hospitalName,
    required this.appLine,
    required this.typeLabel,
    required this.periodLabel,
    required this.reportPrefix,
    required this.overviewTitle,
    required this.financeTitle,
    required this.patientsTitle,
    required this.printedBy,
    required this.printedOn,
    required this.pageOf,
    required this.confidential,
    required this.dateFormatPrintedAt,
    required this.dateFormatLong,
    required this.currency,
    required this.kpiRevenue,
    required this.kpiUniquePatients,
    required this.kpiConsultations,
    required this.opsStatus,
    required this.opsFinished,
    required this.opsOngoing,
    required this.opsCancelled,
    required this.dailyActivity,
    required this.totalRevenuePeriod,
    required this.paymentsCollected,
    required this.avgPayment,
    required this.avgDaily,
    required this.maxPayment,
    required this.minPayment,
    required this.bestDay,
    required this.pending,
    required this.pendingCount,
    required this.revenueEvolution,
    required this.patientsRegistered,
    required this.genderDist,
    required this.men,
    required this.women,
    required this.ageDist,
    required this.ageChildren,
    required this.ageYoungAdults,
    required this.ageAdults,
    required this.ageSeniors,
    required this.yearsSuffix,
  });

  /// Renvoie le pack adapté à la locale (fr / en / fallback fr).
  factory StatsPdfL10n.forLocale(Locale locale) {
    final lang = locale.languageCode.toLowerCase();
    if (lang == 'en') return _en;
    return _fr;
  }

  static const _fr = StatsPdfL10n(
    republicLine: 'REPUBLIQUE DU CAMEROUN',
    motto: 'Paix – Travail – Patrie',
    hospitalName: 'HÔPITAL DE DISTRICT DE MANJO',
    appLine: 'Système de Gestion Hospitalière — Hostoman',
    typeLabel: 'TYPE :',
    periodLabel: 'PÉRIODE :',
    reportPrefix: 'RAPPORT',
    overviewTitle: 'Vue Générale',
    financeTitle: 'Finance',
    patientsTitle: 'Patients',
    printedBy: 'Imprimé par',
    printedOn: 'Le',
    pageOf: 'Page',
    confidential:
        'Hôpital de District de Manjo — Document confidentiel, usage interne uniquement',
    dateFormatPrintedAt: "dd/MM/yyyy 'à' HH:mm",
    dateFormatLong: 'dd MMM yyyy',
    currency: 'FCFA',
    kpiRevenue: 'Revenu',
    kpiUniquePatients: 'Patients uniques',
    kpiConsultations: 'Consultations',
    opsStatus: 'STATUT DES OPÉRATIONS',
    opsFinished: 'Terminées',
    opsOngoing: 'En cours',
    opsCancelled: 'Annulées',
    dailyActivity: 'ACTIVITÉ QUOTIDIENNE (PATIENTS UNIQUES)',
    totalRevenuePeriod: 'REVENU TOTAL DE LA PÉRIODE',
    paymentsCollected: 'paiements encaissés',
    avgPayment: 'Paiement moyen',
    avgDaily: 'Revenu moyen / jour',
    maxPayment: 'Paiement max',
    minPayment: 'Paiement min',
    bestDay: 'Meilleur jour',
    pending: 'En attente',
    pendingCount: 'paiement(s)',
    revenueEvolution: 'ÉVOLUTION DU REVENU PAR JOUR',
    patientsRegistered: 'PATIENTS UNIQUES ENREGISTRÉS',
    genderDist: 'RÉPARTITION PAR GENRE',
    men: 'Hommes',
    women: 'Femmes',
    ageDist: "RÉPARTITION PAR TRANCHE D'ÂGE",
    ageChildren: 'Enfants',
    ageYoungAdults: 'Jeunes adultes',
    ageAdults: 'Adultes',
    ageSeniors: 'Seniors',
    yearsSuffix: 'ans',
  );

  static const _en = StatsPdfL10n(
    republicLine: 'REPUBLIC OF CAMEROON',
    motto: 'Peace – Work – Fatherland',
    hospitalName: 'MANJO DISTRICT HOSPITAL',
    appLine: 'Hospital Management System — Hostoman',
    typeLabel: 'TYPE:',
    periodLabel: 'PERIOD:',
    reportPrefix: 'REPORT',
    overviewTitle: 'Overview',
    financeTitle: 'Finance',
    patientsTitle: 'Patients',
    printedBy: 'Printed by',
    printedOn: 'On',
    pageOf: 'Page',
    confidential:
        'Manjo District Hospital — Confidential document, internal use only',
    dateFormatPrintedAt: "MM/dd/yyyy 'at' HH:mm",
    dateFormatLong: 'MMM dd, yyyy',
    currency: 'FCFA',
    kpiRevenue: 'Revenue',
    kpiUniquePatients: 'Unique patients',
    kpiConsultations: 'Consultations',
    opsStatus: 'OPERATIONS STATUS',
    opsFinished: 'Finished',
    opsOngoing: 'Ongoing',
    opsCancelled: 'Cancelled',
    dailyActivity: 'DAILY ACTIVITY (UNIQUE PATIENTS)',
    totalRevenuePeriod: 'TOTAL REVENUE FOR THE PERIOD',
    paymentsCollected: 'payments collected',
    avgPayment: 'Average payment',
    avgDaily: 'Daily average revenue',
    maxPayment: 'Max payment',
    minPayment: 'Min payment',
    bestDay: 'Best day',
    pending: 'Pending',
    pendingCount: 'payment(s)',
    revenueEvolution: 'DAILY REVENUE EVOLUTION',
    patientsRegistered: 'UNIQUE PATIENTS REGISTERED',
    genderDist: 'GENDER DISTRIBUTION',
    men: 'Men',
    women: 'Women',
    ageDist: 'AGE DISTRIBUTION',
    ageChildren: 'Children',
    ageYoungAdults: 'Young adults',
    ageAdults: 'Adults',
    ageSeniors: 'Seniors',
    yearsSuffix: 'yrs',
  );
}

/// Service de génération PDF des statistiques (style épuré, professionnel)
class StatsPdfGenerator {
  /// Génère et ouvre la prévisualisation PDF.
  /// La langue du document est calée sur `locale` (par défaut français).
  static Future<void> previewAndPrint({
    required BuildContext context,
    required StatsExportType type,
    required DateTime periodStart,
    required DateTime periodEnd,
    Locale locale = const Locale('fr', 'FR'),
    Map<String, dynamic>? overviewData,
    Map<String, dynamic>? financeData,
    Map<String, dynamic>? patientsData,
  }) async {
    final doc = pw.Document();
    final l10n = StatsPdfL10n.forLocale(locale);
    final localeTag = locale.languageCode == 'en' ? 'en_US' : 'fr_FR';
    final agentName = await _getAgentNameFromDb(locale);

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

    final now = DateTime.now();
    final dateImpression = DateFormat(
      l10n.dateFormatPrintedAt,
      localeTag,
    ).format(now);
    final periodLabel =
        '${DateFormat(l10n.dateFormatLong, localeTag).format(periodStart)}  →  ${DateFormat(l10n.dateFormatLong, localeTag).format(periodEnd)}';

    // Sections à inclure
    final sections = <_PdfSection>[];
    if ((type == StatsExportType.overview || type == StatsExportType.full) &&
        overviewData != null) {
      sections.add(_PdfSection.overview(overviewData, l10n));
    }
    if ((type == StatsExportType.finance || type == StatsExportType.full) &&
        financeData != null) {
      sections.add(_PdfSection.finance(financeData, l10n));
    }
    if ((type == StatsExportType.patients || type == StatsExportType.full) &&
        patientsData != null) {
      sections.add(_PdfSection.patients(patientsData, l10n));
    }

    // Une page par section
    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildHeader(
                ttf: ttf,
                ttfBold: ttfBold,
                ttfItalic: ttfItalic,
                docType: section.title,
                periodLabel: periodLabel,
                l10n: l10n,
                logo: logoImage,
              ),
              pw.SizedBox(height: 14),
              _buildTitleBanner(
                ttfBold: ttfBold,
                title: section.title,
                l10n: l10n,
              ),
              pw.SizedBox(height: 14),
              pw.Expanded(
                child: section.builder(
                  ttf: ttf,
                  ttfBold: ttfBold,
                  ttfItalic: ttfItalic,
                  l10n: l10n,
                ),
              ),
              pw.SizedBox(height: 6),
              _buildFooter(
                ttf: ttf,
                ttfItalic: ttfItalic,
                dateImpression: dateImpression,
                agentName: agentName,
                pageNumber: i + 1,
                totalPages: sections.length,
                l10n: l10n,
              ),
            ],
          ),
        ),
      );
    }

    final fileName =
        'Statistiques_${type.name}_${DateFormat('yyyyMMdd').format(now)}.pdf';
    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: fileName,
    );
  }

  // ==================== HEADER ====================
  static pw.Widget _buildHeader({
    required pw.Font ttf,
    required pw.Font ttfBold,
    required pw.Font ttfItalic,
    required String docType,
    required String periodLabel,
    required StatsPdfL10n l10n,
    pw.MemoryImage? logo,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo (image réelle si disponible, sinon fallback texte)
        pw.Container(
          width: 72,
          height: 72,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            color: logo == null ? _kPrimary : PdfColors.white,
            border: logo == null
                ? null
                : pw.Border.all(color: _kPrimary, width: 1),
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
                          fontSize: 14,
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
        // Centre
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                l10n.republicLine,
                style: pw.TextStyle(font: ttfBold, fontSize: 9.5),
              ),
              pw.Text(
                l10n.motto,
                style: pw.TextStyle(
                  font: ttfItalic,
                  fontSize: 7.5,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Container(width: 40, height: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
              pw.Text(
                l10n.hospitalName,
                style: pw.TextStyle(
                  font: ttfBold,
                  fontSize: 11,
                  color: _kPrimary,
                ),
              ),
              pw.Text(
                l10n.appLine,
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 7,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 14),
        // Document info
        pw.Container(
          width: 130,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _kPrimary, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            color: _kPrimaryLight,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                l10n.typeLabel,
                style: pw.TextStyle(
                  font: ttfBold,
                  fontSize: 6.5,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                docType.toUpperCase(),
                style: pw.TextStyle(
                  font: ttfBold,
                  fontSize: 8,
                  color: _kPrimary,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                l10n.periodLabel,
                style: pw.TextStyle(
                  font: ttfBold,
                  fontSize: 6.5,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(periodLabel, style: pw.TextStyle(font: ttf, fontSize: 7)),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== BANDEAU TITRE ====================
  static pw.Widget _buildTitleBanner({
    required pw.Font ttfBold,
    required String title,
    required StatsPdfL10n l10n,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 9, horizontal: 16),
      decoration: const pw.BoxDecoration(color: _kPrimary),
      child: pw.Text(
        '${l10n.reportPrefix} — ${title.toUpperCase()}',
        style: pw.TextStyle(
          font: ttfBold,
          fontSize: 11,
          color: PdfColors.white,
          letterSpacing: 1.2,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // ==================== FOOTER ====================
  static pw.Widget _buildFooter({
    required pw.Font ttf,
    required pw.Font ttfItalic,
    required String dateImpression,
    required String agentName,
    required int pageNumber,
    required int totalPages,
    required StatsPdfL10n l10n,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '${l10n.printedBy} : $agentName',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 7.5,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(
              '${l10n.printedOn} : $dateImpression',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 7.5,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(
              '${l10n.pageOf} $pageNumber / $totalPages',
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
          l10n.confidential,
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

  // ==================== AGENT ====================
  static Future<String> _getAgentNameFromDb(Locale locale) async {
    final isEn = locale.languageCode.toLowerCase() == 'en';
    final fallback = isEn ? 'Director' : 'Directeur';
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return fallback;
      final data = await client
          .from('Personnel_hopital')
          .select('Nom, Prenom, Specialite')
          .eq('id_personnel', user.id)
          .single();
      final nom = data['Nom']?.toString() ?? '';
      final prenom = data['Prenom']?.toString() ?? '';
      final spec = data['Specialite']?.toString().toLowerCase() ?? '';
      String titre = isEn ? 'Mr.' : 'M.';
      if (spec.contains('médecin') ||
          spec.contains('medecin') ||
          spec.contains('docteur') ||
          spec.contains('doctor') ||
          spec.contains('directeur') ||
          spec.contains('director')) {
        titre = 'Dr.';
      }
      final full = '$prenom $nom'.trim();
      return full.isEmpty ? fallback : '$titre $full';
    } catch (_) {
      return fallback;
    }
  }
}

// ==================== SECTIONS ====================
typedef _SectionBuilder =
    pw.Widget Function({
      required pw.Font ttf,
      required pw.Font ttfBold,
      required pw.Font ttfItalic,
      required StatsPdfL10n l10n,
    });

class _PdfSection {
  final String title;
  final _SectionBuilder builder;

  _PdfSection(this.title, this.builder);

  factory _PdfSection.overview(Map<String, dynamic> data, StatsPdfL10n l10n) {
    return _PdfSection(
      l10n.overviewTitle,
      ({required ttf, required ttfBold, required ttfItalic, required l10n}) =>
          _buildOverviewSection(data, ttf, ttfBold, ttfItalic, l10n),
    );
  }

  factory _PdfSection.finance(Map<String, dynamic> data, StatsPdfL10n l10n) {
    return _PdfSection(
      l10n.financeTitle,
      ({required ttf, required ttfBold, required ttfItalic, required l10n}) =>
          _buildFinanceSection(data, ttf, ttfBold, ttfItalic, l10n),
    );
  }

  factory _PdfSection.patients(Map<String, dynamic> data, StatsPdfL10n l10n) {
    return _PdfSection(
      l10n.patientsTitle,
      ({required ttf, required ttfBold, required ttfItalic, required l10n}) =>
          _buildPatientsSection(data, ttf, ttfBold, ttfItalic, l10n),
    );
  }
}

// ==================== OVERVIEW BUILDER ====================
pw.Widget _buildOverviewSection(
  Map<String, dynamic> d,
  pw.Font ttf,
  pw.Font ttfBold,
  pw.Font ttfItalic,
  StatsPdfL10n l10n,
) {
  final fmt = NumberFormat('#,###', 'fr_FR');
  final revenu = (d['revenu'] as num?)?.toDouble() ?? 0;
  final patients = d['patients'] ?? 0;
  final consultations = d['consultations'] ?? 0;
  final ops = (d['operationalStats'] as Map?)?.cast<String, int>() ?? {};
  final terminer = ops['terminer'] ?? 0;
  final enAttente = ops['en attente'] ?? 0;
  final annuler = ops['annuler'] ?? 0;
  final dailyActivity =
      (d['dailyActivity'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      // KPI principaux
      pw.Row(
        children: [
          pw.Expanded(
            child: _kpiBox(
              l10n.kpiRevenue,
              '${fmt.format(revenu.round())} ${l10n.currency}',
              _kSuccess,
              _kSuccessLight,
              ttf,
              ttfBold,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: _kpiBox(
              l10n.kpiUniquePatients,
              '$patients',
              _kPrimary,
              _kPrimaryLight,
              ttf,
              ttfBold,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: _kpiBox(
              l10n.kpiConsultations,
              '$consultations',
              _kInfo,
              _kInfoLight,
              ttf,
              ttfBold,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 16),

      // Statut des opérations
      _sectionLabel(l10n.opsStatus, ttfBold),
      pw.SizedBox(height: 8),
      pw.Row(
        children: [
          pw.Expanded(
            child: _miniStat(
              l10n.opsFinished,
              '$terminer',
              _kSuccess,
              ttf,
              ttfBold,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: _miniStat(
              l10n.opsOngoing,
              '$enAttente',
              _kWarning,
              ttf,
              ttfBold,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: _miniStat(
              l10n.opsCancelled,
              '$annuler',
              _kDanger,
              ttf,
              ttfBold,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 16),

      // Activité par jour (mini-tableau)
      if (dailyActivity.isNotEmpty) ...[
        _sectionLabel(l10n.dailyActivity, ttfBold),
        pw.SizedBox(height: 6),
        _activityTable(dailyActivity, ttf, ttfBold),
      ],
    ],
  );
}

// ==================== FINANCE BUILDER ====================
pw.Widget _buildFinanceSection(
  Map<String, dynamic> d,
  pw.Font ttf,
  pw.Font ttfBold,
  pw.Font ttfItalic,
  StatsPdfL10n l10n,
) {
  final fmt = NumberFormat('#,###', 'fr_FR');
  String f(num v) => '${fmt.format(v.round())} ${l10n.currency}';

  final totalRevenu = (d['totalRevenu'] as num?)?.toDouble() ?? 0;
  final nbPaiements = d['nbPaiements'] ?? 0;
  final moy = (d['moyennePaiement'] as num?)?.toDouble() ?? 0;
  final maxP = (d['maxPaiement'] as num?)?.toDouble() ?? 0;
  final minP = (d['minPaiement'] as num?)?.toDouble() ?? 0;
  final moyJour = (d['revenuMoyenJour'] as num?)?.toDouble() ?? 0;
  final nbAttente = d['nbEnAttente'] ?? 0;
  final montAttente = (d['montantEnAttente'] as num?)?.toDouble() ?? 0;
  final meilleur = (d['meilleurJour'] as Map?) ?? {};
  final meilleurDate = meilleur['date']?.toString() ?? '-';
  final meilleurMontant = (meilleur['montant'] as num?)?.toDouble() ?? 0;
  final trend = (d['dailyTrend'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      // Hero revenu
      pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: _kSuccessLight,
          border: pw.Border.all(color: _kSuccess, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  l10n.totalRevenuePeriod,
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  f(totalRevenu),
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 22,
                    color: _kSuccess,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '$nbPaiements ${l10n.paymentsCollected}',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 14),

      // KPI grid 3x2
      _financeRow(
        [
          _financeMini(l10n.avgPayment, f(moy), _kInfo),
          _financeMini(l10n.avgDaily, f(moyJour), _kAccent),
          _financeMini(l10n.maxPayment, f(maxP), _kSuccess),
        ],
        ttf,
        ttfBold,
      ),
      pw.SizedBox(height: 8),
      _financeRow(
        [
          _financeMini(l10n.minPayment, f(minP), _kWarning),
          _financeMini(
            l10n.bestDay,
            f(meilleurMontant),
            _kWarning,
            hint: meilleurDate,
          ),
          _financeMini(
            l10n.pending,
            f(montAttente),
            _kDanger,
            hint: '$nbAttente ${l10n.pendingCount}',
          ),
        ],
        ttf,
        ttfBold,
      ),
      pw.SizedBox(height: 14),

      // Évolution
      if (trend.isNotEmpty) ...[
        _sectionLabel(l10n.revenueEvolution, ttfBold),
        pw.SizedBox(height: 6),
        _trendTable(trend, ttf, ttfBold, l10n),
      ],
    ],
  );
}

// ==================== PATIENTS BUILDER ====================
pw.Widget _buildPatientsSection(
  Map<String, dynamic> d,
  pw.Font ttf,
  pw.Font ttfBold,
  pw.Font ttfItalic,
  StatsPdfL10n l10n,
) {
  final gender = (d['gender'] as Map?)?.cast<String, dynamic>() ?? {};
  final ageRanges = (d['ageRanges'] as Map?)?.cast<String, dynamic>() ?? {};
  final hommes = (gender['M'] as int?) ?? 0;
  final femmes = (gender['F'] as int?) ?? 0;
  final total = hommes + femmes;
  final pctH = total == 0 ? 0 : (hommes * 100 / total);
  final pctF = total == 0 ? 0 : (femmes * 100 / total);

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      // Total
      pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: _kPrimaryLight,
          border: pw.Border.all(color: _kPrimary, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              l10n.patientsRegistered,
              style: pw.TextStyle(font: ttfBold, fontSize: 9, color: _kPrimary),
            ),
            pw.Text(
              '$total',
              style: pw.TextStyle(
                font: ttfBold,
                fontSize: 22,
                color: _kPrimary,
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 16),

      // Genre
      _sectionLabel(l10n.genderDist, ttfBold),
      pw.SizedBox(height: 8),
      pw.Row(
        children: [
          pw.Expanded(
            child: _genderBox(
              l10n.men,
              hommes,
              pctH.toDouble(),
              const PdfColor.fromInt(0xFF1E40AF),
              const PdfColor.fromInt(0xFFDBEAFE),
              ttf,
              ttfBold,
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: _genderBox(
              l10n.women,
              femmes,
              pctF.toDouble(),
              const PdfColor.fromInt(0xFFBE185D),
              const PdfColor.fromInt(0xFFFCE7F3),
              ttf,
              ttfBold,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 16),

      // Tranches d'âge
      _sectionLabel(l10n.ageDist, ttfBold),
      pw.SizedBox(height: 8),
      _ageBreakdown(ageRanges, total, ttf, ttfBold, l10n),
    ],
  );
}

// ==================== HELPERS ====================

pw.Widget _kpiBox(
  String label,
  String value,
  PdfColor color,
  PdfColor bg,
  pw.Font ttf,
  pw.Font ttfBold,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: bg,
      border: pw.Border.all(color: color, width: 0.5),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(
            font: ttfBold,
            fontSize: 7,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(font: ttfBold, fontSize: 13, color: color),
        ),
      ],
    ),
  );
}

pw.Widget _miniStat(
  String label,
  String value,
  PdfColor color,
  pw.Font ttf,
  pw.Font ttfBold,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Row(
      children: [
        pw.Container(
          width: 6,
          height: 24,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(font: ttf, fontSize: 7.5, color: _kSlate),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(font: ttfBold, fontSize: 13, color: color),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _sectionLabel(String text, pw.Font ttfBold) {
  return pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 4),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _kPrimary, width: 1)),
    ),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        font: ttfBold,
        fontSize: 8.5,
        color: _kPrimary,
        letterSpacing: 0.8,
      ),
    ),
  );
}

pw.Widget _activityTable(
  List<Map<String, dynamic>> data,
  pw.Font ttf,
  pw.Font ttfBold,
) {
  // Affichage compact en colonnes (jusqu'à 15 jours par ligne)
  const maxPerRow = 15;
  final rows = <pw.Widget>[];
  for (int i = 0; i < data.length; i += maxPerRow) {
    final chunk = data.sublist(
      i,
      i + maxPerRow > data.length ? data.length : i + maxPerRow,
    );
    rows.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          children: chunk
              .map(
                (e) => pw.Expanded(
                  child: pw.Container(
                    margin: const pw.EdgeInsets.symmetric(horizontal: 1),
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 2,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _kSlateLight,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(3),
                      ),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          e['day']?.toString() ?? '',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 6,
                            color: _kSlate,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${e['count']}',
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 9,
                            color: _kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: rows,
  );
}

pw.Widget _financeRow(List<pw.Widget> kpis, pw.Font ttf, pw.Font ttfBold) {
  return pw.Row(
    children: [
      for (int i = 0; i < kpis.length; i++) ...[
        pw.Expanded(child: kpis[i]),
        if (i < kpis.length - 1) pw.SizedBox(width: 8),
      ],
    ],
  );
}

pw.Widget _financeMini(
  String label,
  String value,
  PdfColor color, {
  String? hint,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 22,
          height: 3,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 6.5,
            color: _kSlate,
            letterSpacing: 0.4,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (hint != null) ...[
          pw.SizedBox(height: 1),
          pw.Text(
            hint,
            style: pw.TextStyle(
              fontSize: 6,
              color: _kSlate,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ],
    ),
  );
}

pw.Widget _trendTable(
  List<Map<String, dynamic>> trend,
  pw.Font ttf,
  pw.Font ttfBold,
  StatsPdfL10n l10n,
) {
  // Trouver le max pour les barres
  double maxVal = 0;
  for (final e in trend) {
    final v = (e['amount'] as num).toDouble();
    if (v > maxVal) maxVal = v;
  }
  if (maxVal == 0) maxVal = 1;

  final fmt = NumberFormat('#,###', 'fr_FR');

  // Affichage en barres horizontales compactes
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: trend.map((e) {
      final amount = (e['amount'] as num).toDouble();
      final ratio = amount / maxVal;
      final isMax = amount == maxVal && maxVal > 0;
      final color = isMax ? _kWarning : _kSuccess;
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 60,
              child: pw.Text(
                e['date']?.toString() ?? '',
                style: pw.TextStyle(font: ttf, fontSize: 7.5),
              ),
            ),
            pw.Expanded(
              child: pw.Stack(
                children: [
                  pw.Container(
                    height: 12,
                    decoration: pw.BoxDecoration(
                      color: _kSlateLight,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(3),
                      ),
                    ),
                  ),
                  pw.LayoutBuilder(
                    builder: (ctx, c) => pw.Container(
                      width: (c?.maxWidth ?? 0) * ratio.clamp(0.0, 1.0),
                      height: 12,
                      decoration: pw.BoxDecoration(
                        color: color,
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 8),
            pw.SizedBox(
              width: 90,
              child: pw.Text(
                '${fmt.format(amount.round())} ${l10n.currency}',
                style: pw.TextStyle(font: ttfBold, fontSize: 7.5, color: color),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

pw.Widget _genderBox(
  String label,
  int count,
  double pct,
  PdfColor color,
  PdfColor bg,
  pw.Font ttf,
  pw.Font ttfBold,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      color: bg,
      border: pw.Border.all(color: color, width: 0.5),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(font: ttfBold, fontSize: 8, color: color),
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              '$count',
              style: pw.TextStyle(font: ttfBold, fontSize: 22, color: color),
            ),
            pw.SizedBox(width: 6),
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(
                '${pct.toStringAsFixed(1)} %',
                style: pw.TextStyle(font: ttf, fontSize: 9, color: color),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        // Barre de progression
        pw.Stack(
          children: [
            pw.Container(
              height: 4,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
              ),
            ),
            pw.LayoutBuilder(
              builder: (ctx, c) => pw.Container(
                width: (c?.maxWidth ?? 0) * (pct / 100).clamp(0.0, 1.0),
                height: 4,
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _ageBreakdown(
  Map<String, dynamic> ages,
  int total,
  pw.Font ttf,
  pw.Font ttfBold,
  StatsPdfL10n l10n,
) {
  final order = ['0-18', '19-35', '36-60', '60+'];
  final colors = [_kInfo, _kPrimary, _kAccent, _kWarning];
  final labels = [
    l10n.ageChildren,
    l10n.ageYoungAdults,
    l10n.ageAdults,
    l10n.ageSeniors,
  ];

  return pw.Column(
    children: List.generate(order.length, (i) {
      final key = order[i];
      final count = (ages[key] as int?) ?? 0;
      final pct = total == 0 ? 0.0 : count * 100 / total;
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 110,
              child: pw.Text(
                '${labels[i]} ($key ${l10n.yearsSuffix})',
                style: pw.TextStyle(font: ttf, fontSize: 8),
              ),
            ),
            pw.Expanded(
              child: pw.Stack(
                children: [
                  pw.Container(
                    height: 10,
                    decoration: pw.BoxDecoration(
                      color: _kSlateLight,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(3),
                      ),
                    ),
                  ),
                  pw.LayoutBuilder(
                    builder: (ctx, c) => pw.Container(
                      width:
                          (c?.maxWidth ?? 0) *
                          (pct / 100).clamp(0.0, 1.0).toDouble(),
                      height: 10,
                      decoration: pw.BoxDecoration(
                        color: colors[i],
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 8),
            pw.SizedBox(
              width: 80,
              child: pw.Text(
                '$count   (${pct.toStringAsFixed(1)} %)',
                style: pw.TextStyle(
                  font: ttfBold,
                  fontSize: 8,
                  color: colors[i],
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }),
  );
}
