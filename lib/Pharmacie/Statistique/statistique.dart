import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:hostoman/shared/responsive_wrapper.dart';
import '../shared/pharmacie_theme.dart';
import 'statistique_service.dart';

class StatistiquePharmacie extends StatefulWidget {
  const StatistiquePharmacie({super.key});

  @override
  State<StatistiquePharmacie> createState() => _StatistiquePharmacieState();
}

class _StatistiquePharmacieState extends State<StatistiquePharmacie> {
  final _service = StatistiquePharmacieService(Supabase.instance.client);

  DateTime _dateDebut = DateTime.now().subtract(const Duration(days: 6));
  DateTime _dateFin = DateTime.now();
  Map<String, dynamic> _stats = {};
  bool _loading = false;
  bool _generated = false;

  @override
  void initState() {
    super.initState();
    _generer();
  }

  Future<void> _pickDate(bool isDebut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDebut ? _dateDebut : _dateFin,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: PharmacieTheme.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isDebut) {
        _dateDebut = picked;
        if (_dateDebut.isAfter(_dateFin)) _dateFin = _dateDebut;
      } else {
        _dateFin = picked;
        if (_dateFin.isBefore(_dateDebut)) _dateDebut = _dateFin;
      }
    });
  }

  Future<void> _generer() async {
    setState(() {
      _loading = true;
      _generated = true;
    });
    try {
      final s = await _service.getStatsParPlage(_dateDebut, _dateFin);
      if (mounted)
        setState(() {
          _stats = s;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(mobile: _mobile(), pc: _pc());
  }

  Widget _mobile() {
    return Scaffold(
      backgroundColor: PharmacieTheme.background,
      appBar: PharmacieAppBar(
        title: 'phar_stats_title'.tr(),
        backRoute: '/Dashboard_Pharmacie',
        actions: [
          if (_generated && !_loading)
            IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'phar_stats_print'.tr(),
              onPressed: _printRapport,
            ),
        ],
      ),
      body: _scrollBody(),
    );
  }

  Widget _pc() {
    return PharmaciePcLayout(
      activeRoute: '/Dashboard_Pharmacie/Statistiques',
      breadcrumbKey: 'phar_breadcrumb_stats',
      body: _scrollBody(isPc: true),
    );
  }

  Widget _scrollBody({bool isPc = false}) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isPc ? 28 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPc) ...[
            Text(
              'phar_stats_title'.tr(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: PharmacieTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'phar_stats_subtitle'.tr(),
              style: const TextStyle(
                fontSize: 14,
                color: PharmacieTheme.textMuted,
              ),
            ),
            const SizedBox(height: 20),
          ],
          // ── Sélecteur de plage ──
          _dateRangeCard(),
          const SizedBox(height: 20),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: PharmacieTheme.primary),
              ),
            )
          else if (_generated) ...[
            // ── Graphique ──
            Text(
              'phar_stats_section_par_jour'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: PharmacieTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: PharmacieTheme.border),
              ),
              child: _barChart(
                (_stats['par_jour'] as Map<String, double>?) ?? {},
              ),
            ),
            const SizedBox(height: 20),
            // ── Cartes Rupture / Stock bas (cliquables) ──
            Row(
              children: [
                Expanded(
                  child: _kpiCard(
                    icon: Icons.block,
                    label: 'phar_stats_kpi_rupture'.tr(),
                    value: '${_stats['rupture'] ?? 0}',
                    color: PharmacieTheme.danger,
                    onTap: () => context.go('/Dashboard_Pharmacie/Catalogue'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _kpiCard(
                    icon: Icons.warning_amber_rounded,
                    label: 'phar_stats_kpi_stock_bas'.tr(),
                    value: '${_stats['stock_bas'] ?? 0}',
                    color: PharmacieTheme.warn,
                    onTap: () => context.go('/Dashboard_Pharmacie/Catalogue'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // ── Pills résumé ──
            _pill(
              icon: Icons.medication_outlined,
              label: 'phar_stats_total_produit'.tr(
                namedArgs: {'n': '${_stats['total_catalogue'] ?? 0}'},
              ),
            ),
            const SizedBox(height: 10),
            _pill(
              icon: Icons.point_of_sale_outlined,
              label: 'phar_stats_total_vente'.tr(
                namedArgs: {
                  'montant': ((_stats['total_vente'] as double?) ?? 0)
                      .toStringAsFixed(0),
                },
              ),
            ),
            const SizedBox(height: 10),
            // ── Pills navigables ──
            _pillNav(
              icon: Icons.history_outlined,
              label: 'phar_stats_med_vendus'.tr(
                namedArgs: {'n': '${_stats['total_med_vendus'] ?? 0}'},
              ),
              onTap: () => context.go('/Dashboard_Pharmacie/Historique'),
            ),
            const SizedBox(height: 10),
            _pillNav(
              icon: Icons.receipt_long_outlined,
              label: 'phar_stats_ordonnances'.tr(
                namedArgs: {'n': '${_stats['total_ordonnances'] ?? 0}'},
              ),
              onTap: () => context.go('/Dashboard_Pharmacie/Ordonnances'),
            ),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  // ── Sélecteur de plage ──────────────────────────────────
  Widget _dateRangeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PharmacieTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _dateButton(isDebut: true)),
              const SizedBox(width: 12),
              Expanded(child: _dateButton(isDebut: false)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generer,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'phar_stats_generer'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: PharmacieTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateButton({required bool isDebut}) {
    final date = isDebut ? _dateDebut : _dateFin;
    return OutlinedButton(
      onPressed: () => _pickDate(isDebut),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: PharmacieTheme.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_month_rounded,
            color: PharmacieTheme.primary,
            size: 26,
          ),
          const SizedBox(height: 6),
          Text(
            _fmtDate(date),
            style: const TextStyle(
              fontSize: 12,
              color: PharmacieTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            isDebut ? 'phar_stats_date_debut'.tr() : 'phar_stats_date_fin'.tr(),
            style: const TextStyle(
              fontSize: 11,
              color: PharmacieTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ── KPI card cliquable ───────────────────────────────────
  Widget _kpiCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: PharmacieTheme.textMuted,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: PharmacieTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pill affichage (non-cliquable) ───────────────────────
  Widget _pill({required IconData icon, required String label}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: PharmacieTheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pill navigable ───────────────────────────────────────
  Widget _pillNav({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: PharmacieTheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ── Impression PDF ───────────────────────────────────────
  Future<void> _printRapport() async {
    if (_stats.isEmpty) return;
    try {
      final logoBytes = await rootBundle.load('assets/images/logo.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

      final totalVente = ((_stats['total_vente'] as double?) ?? 0)
          .toStringAsFixed(0);
      final totalCat = '${_stats['total_catalogue'] ?? 0}';
      final totalMed = '${_stats['total_med_vendus'] ?? 0}';
      final totalOrdo = '${_stats['total_ordonnances'] ?? 0}';
      final rupture = '${_stats['rupture'] ?? 0}';
      final stockBas = '${_stats['stock_bas'] ?? 0}';
      final top = (_stats['top_medicaments'] as List<dynamic>?) ?? [];
      final parJour = (_stats['par_jour'] as Map<String, double>?) ?? {};
      final entries = parJour.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      await Printing.layoutPdf(
        name: 'rapport_stats_${_fmtDate(_dateDebut)}_${_fmtDate(_dateFin)}',
        onLayout: (PdfPageFormat format) async {
          final doc = pw.Document();
          final primary = PdfColor.fromHex('#1B7A3E');
          final muted = PdfColor.fromHex('#888888');
          final lightGreen = PdfColor.fromHex('#E8F5E9');

          pw.Widget _sectionTitle(String text) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: primary,
              ),
            ),
          );

          pw.Widget _kpiRow(
            String label,
            String value, {
            PdfColor? valueColor,
          }) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(label, style: pw.TextStyle(fontSize: 11, color: muted)),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: valueColor ?? PdfColors.black,
                ),
              ),
            ],
          );

          doc.addPage(
            pw.MultiPage(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(28),
              build: (pw.Context ctx) => [
                // ── En-tête ──
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Image(logoImage, width: 60, height: 60),
                    pw.SizedBox(width: 16),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PHARMACIE',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: primary,
                          ),
                        ),
                        pw.Text(
                          'phar_stats_title'.tr(),
                          style: pw.TextStyle(fontSize: 14, color: muted),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${'phar_stats_date_debut'.tr()} : ${_fmtDate(_dateDebut)}   '
                          '${'phar_stats_date_fin'.tr()} : ${_fmtDate(_dateFin)}',
                          style: pw.TextStyle(fontSize: 10, color: muted),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Divider(color: primary, thickness: 1.5),

                // ── Résumé ──
                _sectionTitle('phar_stats_section_resume'.tr()),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: lightGreen,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      _kpiRow(
                        'phar_stats_total_vente'.tr(namedArgs: {'montant': ''}),
                        '$totalVente FCFA',
                        valueColor: primary,
                      ),
                      pw.SizedBox(height: 4),
                      _kpiRow(
                        'phar_stats_total_produit'.tr(namedArgs: {'n': ''}),
                        totalCat,
                      ),
                      pw.SizedBox(height: 4),
                      _kpiRow(
                        'phar_stats_med_vendus'.tr(namedArgs: {'n': ''}),
                        totalMed,
                      ),
                      pw.SizedBox(height: 4),
                      _kpiRow(
                        'phar_stats_ordonnances'.tr(namedArgs: {'n': ''}),
                        totalOrdo,
                      ),
                    ],
                  ),
                ),

                // ── Stock ──
                _sectionTitle('phar_stats_section_stock'.tr()),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColor.fromHex('#E53935'),
                            width: 1,
                          ),
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(6),
                          ),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'phar_stats_kpi_rupture'.tr(),
                              style: pw.TextStyle(fontSize: 10, color: muted),
                            ),
                            pw.Text(
                              rupture,
                              style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#E53935'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColor.fromHex('#F57C00'),
                            width: 1,
                          ),
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(6),
                          ),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'phar_stats_kpi_stock_bas'.tr(),
                              style: pw.TextStyle(fontSize: 10, color: muted),
                            ),
                            pw.Text(
                              stockBas,
                              style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#F57C00'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Ventes par jour ──
                if (entries.isNotEmpty) ...[
                  _sectionTitle('phar_stats_section_par_jour'.tr()),
                  pw.Table(
                    border: pw.TableBorder.all(
                      color: PdfColor.fromHex('#DDDDDD'),
                      width: 0.5,
                    ),
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: primary),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'Date',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'Montant (FCFA)',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      ...entries.map((e) {
                        final parts = e.key.split('-');
                        final label = parts.length == 3
                            ? '${parts[2]}/${parts[1]}/${parts[0]}'
                            : e.key;
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                label,
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                e.value.toStringAsFixed(0),
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: e.value > 0
                                      ? pw.FontWeight.bold
                                      : pw.FontWeight.normal,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ],

                // ── Top médicaments ──
                if (top.isNotEmpty) ...[
                  _sectionTitle('phar_stats_section_top'.tr()),
                  pw.Table(
                    border: pw.TableBorder.all(
                      color: PdfColor.fromHex('#DDDDDD'),
                      width: 0.5,
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(2),
                    },
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: primary),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'Médicament',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'Qté',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'CA (FCFA)',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      ...top.map((m) {
                        final med = m as Map<String, dynamic>;
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                (med['nom'] ?? '').toString(),
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                '${med['quantite']}',
                                style: const pw.TextStyle(fontSize: 10),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                (med['ca'] as double).toStringAsFixed(0),
                                style: const pw.TextStyle(fontSize: 10),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ],

                // ── Pied de page ──
                pw.SizedBox(height: 20),
                pw.Divider(color: muted),
                pw.Center(
                  child: pw.Text(
                    'phar_stats_pdf_footer'.tr(
                      namedArgs: {'date': _fmtDate(DateTime.now())},
                    ),
                    style: pw.TextStyle(fontSize: 9, color: muted),
                  ),
                ),
              ],
            ),
          );
          return doc.save();
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: PharmacieTheme.danger,
            content: Text(e.toString()),
          ),
        );
      }
    }
  }

  Widget _barChart(Map<String, double> parJour) {
    final entries = parJour.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (entries.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: Text('—', style: TextStyle(color: PharmacieTheme.textMuted)),
        ),
      );
    }
    final maxVal = entries.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    const barW = 42.0;

    return SizedBox(
      height: 180,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: entries.map((e) {
            final ratio = maxVal == 0 ? 0.0 : e.value / maxVal;
            final parts = e.key.split('-');
            final dayLabel = parts.length == 3
                ? '${parts[2]}/${parts[1]}'
                : e.key;
            return SizedBox(
              width: barW,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (e.value > 0)
                      Text(
                        e.value.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: PharmacieTheme.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      height: 110 * ratio + 4,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            PharmacieTheme.accent,
                            PharmacieTheme.primary,
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dayLabel,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: PharmacieTheme.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
