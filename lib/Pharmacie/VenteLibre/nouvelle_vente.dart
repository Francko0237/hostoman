import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../shared/pharmacie_theme.dart';
import '../Dashboard/listemedicament_service.dart';
import 'vente_libre_service.dart';

class NouvelleVentePage extends StatefulWidget {
  const NouvelleVentePage({super.key});

  @override
  State<NouvelleVentePage> createState() => _NouvelleVentePageState();
}

class _NouvelleVentePageState extends State<NouvelleVentePage> {
  final _medService = ListeMedicamentService(Supabase.instance.client);
  final _venteService = VenteLibreService(Supabase.instance.client);

  List<Map<String, dynamic>> _catalogue = [];
  final List<Map<String, dynamic>> _panier = [];
  bool _loading = true;
  bool _saving = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cat = await _medService.getAll(actifsSeulement: true);
      if (mounted) {
        setState(() {
          _catalogue = cat;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _ajouter(Map<String, dynamic> m) {
    final stock = (m['stock'] as num?)?.toInt() ?? 0;
    if (stock <= 0) return;
    final idx = _panier.indexWhere(
        (p) => p['id_medicament'] == m['id_medicament']);
    setState(() {
      if (idx >= 0) {
        final q = (_panier[idx]['quantite'] as int) + 1;
        if (q <= stock) _panier[idx]['quantite'] = q;
      } else {
        _panier.add({
          'id_medicament': m['id_medicament'],
          'nom_medicament': m['nom_medicament'],
          'prix_unitaire': (m['prix_unitaire'] as num).toDouble(),
          'quantite': 1,
          'posologie': '',
          'stock_max': stock,
        });
      }
    });
  }

  void _changerQte(int i, int delta) {
    setState(() {
      final q = (_panier[i]['quantite'] as int) + delta;
      if (q <= 0) {
        _panier.removeAt(i);
      } else if (q <= (_panier[i]['stock_max'] as int)) {
        _panier[i]['quantite'] = q;
      }
    });
  }

  double get _total => _panier.fold(
      0,
      (s, p) =>
          s + (p['prix_unitaire'] as double) * (p['quantite'] as int));

  int get _articleCount =>
      _panier.fold(0, (s, p) => s + (p['quantite'] as int));

  Future<void> _encaisser() async {
    if (_panier.isEmpty) return;
    setState(() => _saving = true);
    try {
      final idPrescription =
          await _venteService.creerVente(lignes: _panier);
      if (!mounted) return;
      await _showReceiptDialog(idPrescription);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: PharmacieTheme.danger,
          content: Text('phar_action_error'.tr()),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showReceiptDialog(int idPrescription) async {
    final lignesSnapshot =
        List<Map<String, dynamic>>.from(_panier);
    final totalSnapshot = _total;

    final shouldPrint = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('phar_vd_receipt_title'.tr()),
        content: Text('phar_vd_receipt_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('phar_vd_receipt_no'.tr(),
                style: const TextStyle(
                    color: PharmacieTheme.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.print_outlined, size: 18),
            label: Text('phar_vd_receipt_yes'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmacieTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (shouldPrint == true) {
      await _printReceipt(
          idPrescription, lignesSnapshot, totalSnapshot);
    }
    if (mounted) {
      setState(() => _panier.clear());
      _load();
    }
  }

  Future<void> _printReceipt(int idPrescription,
      List<Map<String, dynamic>> lignes, double total) async {
    try {
      final idStr =
          'HST-${idPrescription.toString().padLeft(6, '0')}';
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}  '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final logoBytes =
          await rootBundle.load('assets/images/logo.png');
      final logoImage =
          pw.MemoryImage(logoBytes.buffer.asUint8List());

      await Printing.layoutPdf(
        name: 'recu_$idStr',
        onLayout: (PdfPageFormat format) async {
          final doc = pw.Document();
          doc.addPage(pw.Page(
            pageFormat: PdfPageFormat.a5,
            margin: const pw.EdgeInsets.all(24),
            build: (pw.Context ctx) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Image(logoImage,
                      width: 72,
                      height: 72,
                      fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(height: 6),
                pw.Center(
                  child: pw.Text('PHARMACIE',
                      style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold)),
                ),
                pw.Center(child: pw.Text('Reçu de paiement')),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(idStr,
                      style: const pw.TextStyle(fontSize: 11)),
                ),
                pw.Center(
                  child: pw.Text(dateStr,
                      style: const pw.TextStyle(fontSize: 10)),
                ),
                pw.Divider(),
                pw.SizedBox(height: 4),
                pw.Text('Vente directe',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Médicaments :',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                ...lignes.map((l) {
                  final nomMed =
                      (l['nom_medicament'] ?? '').toString();
                  final qte =
                      (l['quantite'] as num?)?.toInt() ?? 1;
                  final prix =
                      (l['prix_unitaire'] as num?)?.toDouble() ??
                          0;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      mainAxisAlignment:
                          pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('$nomMed  x$qte'),
                        pw.Text(
                            '${(prix * qte).toStringAsFixed(0)} FCFA'),
                      ],
                    ),
                  );
                }),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment:
                      pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14)),
                    pw.Text(
                        '${total.toStringAsFixed(0)} XAF',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14)),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text('Merci de votre visite',
                      style:
                          const pw.TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ));
          return doc.save();
        },
      );
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _catalogue;
    return _catalogue
        .where((m) => (m['nom_medicament'] ?? '')
            .toString()
            .toLowerCase()
            .contains(_search))
        .toList();
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
          onPressed: () =>
              context.go('/Dashboard_Pharmacie/VenteLibre'),
        ),
        title: Text(
          'phar_nv_title'.tr(),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (v) =>
                  setState(() => _search = v.toLowerCase().trim()),
              decoration: InputDecoration(
                hintText: 'phar_vl_search_patient'.tr(),
                prefixIcon: const Icon(Icons.search,
                    color: PharmacieTheme.textMuted),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: PharmacieTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: PharmacieTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: PharmacieTheme.primary),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: PharmacieTheme.primary))
                : _filtered.isEmpty
                    ? Center(
                        child: Text('fiche_med_empty'.tr(),
                            style: const TextStyle(
                                color: PharmacieTheme.textMuted)))
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) =>
                            _medicineCard(_filtered[i]),
                      ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _medicineCard(Map<String, dynamic> m) {
    final nom = (m['nom_medicament'] ?? '').toString();
    final initial = nom.isNotEmpty ? nom[0].toUpperCase() : '?';
    final stock = (m['stock'] as num?)?.toInt() ?? 0;
    final prix = (m['prix_unitaire'] as num?)?.toDouble() ?? 0;
    final forme = (m['forme'] ?? '').toString();
    final dosage = (m['dosage'] ?? '').toString();
    final dispo = stock > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: dispo ? () => _ajouter(m) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: dispo
                      ? PharmacieTheme.primary
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
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
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (forme.isNotEmpty) forme,
                        if (dosage.isNotEmpty) dosage,
                        'stock $stock',
                      ].join('  '),
                      style: const TextStyle(
                          fontSize: 11,
                          color: PharmacieTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${prix.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: PharmacieTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: dispo
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      dispo
                          ? 'phar_nv_disponible'.tr()
                          : 'phar_nv_rupture'.tr(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: dispo
                            ? PharmacieTheme.primary
                            : PharmacieTheme.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return Material(
      elevation: 6,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: PharmacieTheme.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart_outlined,
                    color: PharmacieTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'phar_nv_articles'
                      .tr(namedArgs: {'count': '$_articleCount'}),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '${_total.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: PharmacieTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _panier.isEmpty ? null : _showPanier,
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(
                          color: PharmacieTheme.primary),
                      foregroundColor: PharmacieTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('phar_nv_voir_panier'.tr()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed:
                        _panier.isEmpty || _saving ? null : _encaisser,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.point_of_sale_rounded),
                    label: Text(
                      'phar_vd_encaisser'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PharmacieTheme.primary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPanier() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 12),
              Text('phar_nv_panier_title'.tr(),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (_panier.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('phar_vl_empty'.tr(),
                      style: const TextStyle(
                          color: PharmacieTheme.textMuted)),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _panier.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (_, i) => _panierLine(i, () {
                      setLocal(() {});
                      setState(() {});
                    }),
                  ),
                ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('phar_total_label'.tr(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700)),
                  Text(
                    '${_total.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: PharmacieTheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panierLine(int i, VoidCallback onChanged) {
    final p = _panier[i];
    final qte = p['quantite'] as int;
    final prix = p['prix_unitaire'] as double;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (p['nom_medicament'] ?? '').toString(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                ),
                Text(
                  '${(prix * qte).toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                      fontSize: 11,
                      color: PharmacieTheme.primary,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              _changerQte(i, -1);
              onChanged();
            },
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            color: PharmacieTheme.danger,
          ),
          Text('$qte',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          IconButton(
            onPressed: () {
              _changerQte(i, 1);
              onChanged();
            },
            icon: const Icon(Icons.add_circle_outline, size: 20),
            color: PharmacieTheme.primary,
          ),
          IconButton(
            onPressed: () {
              _panier.removeAt(i);
              onChanged();
            },
            icon: const Icon(Icons.delete_outline, size: 20),
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}
