import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../shared/pharmacie_theme.dart';
import '../Ordonnances/ordonnances_service.dart';

class VenteDetailPage extends StatefulWidget {
  final int idPrescription;
  const VenteDetailPage({super.key, required this.idPrescription});

  @override
  State<VenteDetailPage> createState() => _VenteDetailPageState();
}

class _VenteDetailPageState extends State<VenteDetailPage> {
  final _service = OrdonnancesService(Supabase.instance.client);

  Map<String, dynamic>? _prescription;
  List<Map<String, dynamic>> _lignes = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final detail = await _service.getDetail(widget.idPrescription);
      if (mounted) {
        setState(() {
          _prescription = detail['prescription'] as Map<String, dynamic>;
          _lignes = (detail['lignes'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'phar_server_error'.tr();
        });
      }
    }
  }

  Future<void> _encaisser() async {
    setState(() => _saving = true);
    try {
      await _service.confirmerPaiement(widget.idPrescription);
      for (final ligne in _lignes) {
        final idLigne = ligne['id_ligne'] as int;
        try {
          await _service.delivrerLigne(idLigne: idLigne);
        } catch (_) {}
      }
      if (!mounted) return;
      await _showReceiptDialog();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: PharmacieTheme.danger,
            content: Text('phar_action_error'.tr()),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showReceiptDialog() async {
    final shouldPrint = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('phar_vd_receipt_title'.tr()),
        content: Text('phar_vd_receipt_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'phar_vd_receipt_no'.tr(),
              style: const TextStyle(color: PharmacieTheme.textMuted),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.print_outlined, size: 18),
            label: Text('phar_vd_receipt_yes'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmacieTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (shouldPrint == true) await _printReceipt();
    if (mounted) context.go('/Dashboard_Pharmacie/VenteLibre');
  }

  Future<void> _printReceipt() async {
    try {
      final patient = _prescription?['Patient'] as Map<String, dynamic>? ?? {};
      final nom = (patient['nom_complet'] ?? '—').toString();
      final idStr = 'HST-${widget.idPrescription.toString().padLeft(6, '0')}';
      final total = (_prescription?['total_prix'] as num?)?.toDouble() ?? 0;
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}  '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final logoBytes = await rootBundle.load('assets/images/logo.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

      await Printing.layoutPdf(
        name: 'recu_$idStr',
        onLayout: (PdfPageFormat format) async {
          final doc = pw.Document();
          doc.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a5,
              margin: const pw.EdgeInsets.all(24),
              build: (pw.Context ctx) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Image(
                      logoImage,
                      width: 72,
                      height: 72,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Center(
                    child: pw.Text(
                      'PHARMACIE',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Center(child: pw.Text('Reçu de paiement')),
                  pw.SizedBox(height: 4),
                  pw.Center(
                    child: pw.Text(
                      idStr,
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ),
                  pw.Center(
                    child: pw.Text(
                      dateStr,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Divider(),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Patient : $nom',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Médicaments :',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  ..._lignes.map((l) {
                    final nomMed = (l['nom_medicament'] ?? '').toString();
                    final qte = (l['quantite'] as num?)?.toInt() ?? 1;
                    final prix = (l['prix_unitaire'] as num?)?.toDouble() ?? 0;
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('$nomMed  x$qte'),
                          pw.Text('${(prix * qte).toStringAsFixed(0)} FCFA'),
                        ],
                      ),
                    );
                  }),
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TOTAL',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      pw.Text(
                        '${total.toStringAsFixed(0)} XAF',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Center(
                    child: pw.Text(
                      'Merci de votre visite',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          );
          return doc.save();
        },
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: PharmacieTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/Dashboard_Pharmacie/VenteLibre'),
        ),
        title: Text(
          'phar_vd_title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: PharmacieTheme.primary),
            )
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: PharmacieTheme.danger),
              ),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final patient = _prescription?['Patient'] as Map<String, dynamic>? ?? {};
    final nom = (patient['nom_complet'] ?? '—').toString();
    final sexe = (patient['sexe'] ?? '—').toString();
    final age = patient['age']?.toString() ?? '—';
    final total = (_prescription?['total_prix'] as num?)?.toDouble() ?? 0;
    final idStr = 'HST-${widget.idPrescription.toString().padLeft(6, '0')}';
    final initial = nom.isNotEmpty ? nom[0].toUpperCase() : '?';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête patient
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: PharmacieTheme.primary,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      nom,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: PharmacieTheme.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: PharmacieTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoLine('ID: $idStr'),
                      _infoLine('${_key('phar_vd_sexe')}: $sexe'),
                      _infoLine(
                        '${_key('phar_vd_age')}: $age ${_key('phar_vd_ans')}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_key('phar_vd_motif_paiement')}: ${_key('phar_vd_motif_value')}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: PharmacieTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            '${_key('phar_vd_prix')}:',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: PharmacieTheme.textDark,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${total.toStringAsFixed(0)} XAF',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: PharmacieTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Liste médicaments
                ..._lignes.map(_medicamentCard),
              ],
            ),
          ),
        ),

        // Bouton Encaisser
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _encaisser,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.point_of_sale_rounded),
              label: Text(
                'phar_vd_encaisser'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: PharmacieTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: PharmacieTheme.primary),
      ),
    );
  }

  Widget _medicamentCard(Map<String, dynamic> ligne) {
    final nom = (ligne['nom_medicament'] ?? '').toString();
    final initial = nom.isNotEmpty ? nom[0].toUpperCase() : '?';
    final qte = (ligne['quantite'] as num?)?.toInt() ?? 1;
    final prix = (ligne['prix_unitaire'] as num?)?.toDouble() ?? 0;
    final posologie = (ligne['posologie'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PharmacieTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: PharmacieTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nom,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: PharmacieTheme.textDark,
                    ),
                  ),
                  if (posologie.isNotEmpty && posologie != '-')
                    Text(
                      posologie,
                      style: const TextStyle(
                        fontSize: 11,
                        color: PharmacieTheme.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${prix.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: PharmacieTheme.primary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'x$qte',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: PharmacieTheme.primary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _key(String k) => k.tr();
}
