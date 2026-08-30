import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/shared/responsive_wrapper.dart';
import 'package:hostoman/shared/receipt_pdf_generator.dart';
import '../shared/pharmacie_theme.dart';
import '../Dashboard/listemedicament_service.dart';
import '../Ordonnances/ordonnances_service.dart';
import '../Ordonnances/ordonnance_detail.dart' show SubstitutPicker;

class VenteDetailPage extends StatefulWidget {
  final int idPrescription;
  const VenteDetailPage({super.key, required this.idPrescription});

  @override
  State<VenteDetailPage> createState() => _VenteDetailPageState();
}

class _VenteDetailPageState extends State<VenteDetailPage> {
  final _service = OrdonnancesService(Supabase.instance.client);
  final _medService = ListeMedicamentService(Supabase.instance.client);

  Map<String, dynamic>? _prescription;
  List<Map<String, dynamic>> _lignes = [];
  List<Map<String, dynamic>> _catalogue = [];
  bool _loading = true;
  bool _saving = false;
  bool _busy = false;
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
      final cat = await _medService.getAll(actifsSeulement: true);
      if (mounted) {
        setState(() {
          _prescription = detail['prescription'] as Map<String, dynamic>;
          _lignes = (detail['lignes'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
          _catalogue = cat;
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

  // ───────── Logique métier ─────────

  /// Encaisse (confirme paiement si non payé) PUIS délivre toutes les lignes
  /// en attente en une seule action.
  Future<void> _encaisser() async {
    setState(() => _saving = true);
    try {
      final statut = _prescription?['statut_prescription']?.toString();
      final isAlreadyPaid =
          statut == 'paye' || statut == 'partiellement_delivre';

      if (!isAlreadyPaid) {
        await _service.confirmerPaiement(widget.idPrescription);
      }

      for (final ligne in _lignes) {
        final idLigne = ligne['id_ligne'] as int;
        final statutLigne = ligne['statut_ligne']?.toString();
        if (statutLigne == 'delivre' ||
            statutLigne == 'substitue' ||
            statutLigne == 'annule') {
          continue;
        }
        try {
          await _service.delivrerLigne(idLigne: idLigne);
        } catch (_) {
          // Stock insuffisant : marquer en rupture
          await _service.marquerRupture(idLigne);
        }
      }

      if (!mounted) return;
      await _load();
      await _showReceiptDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: PharmacieTheme.danger,
            content: Text(e.toString()),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Ouvre le sélecteur de substitut et délivre avec le substitut choisi.
  Future<void> _substituer(Map<String, dynamic> ligne) async {
    final qte = (ligne['quantite'] as num?)?.toInt() ?? 1;
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) =>
          SubstitutPicker(catalogue: _catalogue, quantiteRequise: qte),
    );
    if (selected == null) return;

    setState(() => _busy = true);
    try {
      await _service.delivrerLigne(
        idLigne: ligne['id_ligne'] as int,
        idMedicamentSubstitut: selected['id_medicament'] as int,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: PharmacieTheme.success,
          content: Text('phar_ligne_substituted'.tr()),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: PharmacieTheme.danger,
          content: Text(
            e.toString().contains('Stock insuffisant')
                ? 'phar_stock_insuffisant'.tr()
                : 'phar_action_error'.tr(),
          ),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Annule une ligne individuelle (statut → annule).
  Future<void> _annulerLigne(Map<String, dynamic> ligne) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('phar_vl_cancel_title'.tr()),
        content: Text(
          'phar_vl_cancel_line_message'.tr(namedArgs: {
            'nom': (ligne['nom_medicament'] ?? '').toString(),
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('phar_vd_receipt_no'.tr(),
                style: const TextStyle(color: PharmacieTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmacieTheme.danger,
              foregroundColor: Colors.white,
            ),
            child: Text('phar_vl_cancel_yes'.tr()),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await _service.annulerLigne(ligne['id_ligne'] as int);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: PharmacieTheme.danger,
          content: Text('phar_action_error'.tr()),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Annule toute la prescription.
  Future<void> _annulerTout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('phar_vl_cancel_title'.tr()),
        content: Text('phar_vl_cancel_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('phar_vd_receipt_no'.tr(),
                style: const TextStyle(color: PharmacieTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmacieTheme.danger,
              foregroundColor: Colors.white,
            ),
            child: Text('phar_vl_cancel_yes'.tr()),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      await _service.annulerPrescription(widget.idPrescription);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: PharmacieTheme.success,
          content: Text('phar_vl_cancelled_success'.tr()),
        ));
        context.go('/Dashboard_Pharmacie/VenteLibre');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: PharmacieTheme.danger,
          content: Text(e.toString()),
        ));
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
            child: Text('phar_vd_receipt_no'.tr(),
                style: const TextStyle(color: PharmacieTheme.textMuted)),
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
    if (shouldPrint == true) await _printReceipt();
    if (mounted) context.go('/Dashboard_Pharmacie/VenteLibre');
  }

  Future<void> _printReceipt() async {
    if (!mounted) return;
    try {
      final patient =
          _prescription?['Patient'] as Map<String, dynamic>? ?? {};
      final nom = (patient['nom_complet'] ?? 'Client').toString();
      final total =
          (_prescription?['total_prix'] as num?)?.toDouble() ?? 0;
      await ReceiptPdfGenerator.printPharmacyReceipt(
        context: context,
        patientNom: nom,
        idPrescription: widget.idPrescription.toString(),
        total: total,
        lignes: _lignes,
        isVenteLibre: true,
      );
    } catch (_) {}
  }

  // ───────── UI ─────────

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(mobile: _buildMobile(), pc: _buildPc());
  }

  Widget _buildMobile() {
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
        title: Text('phar_vd_title'.tr(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: PharmacieTheme.primary))
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style:
                          const TextStyle(color: PharmacieTheme.danger)))
              : _buildBody(),
    );
  }

  Widget _buildPc() {
    return _loading
        ? const Center(
            child: CircularProgressIndicator(color: PharmacieTheme.primary))
        : _error != null
            ? Center(
                child: Text(_error!,
                    style: const TextStyle(color: PharmacieTheme.danger)))
            : Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () =>
                              context.go('/Dashboard_Pharmacie/VenteLibre'),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'phar_vd_title'.tr(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: PharmacieTheme.textDark,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                            icon: const Icon(Icons.refresh), onPressed: _load),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(child: _buildBody()),
                  ],
                ),
              );
  }

  Widget _buildBody() {
    final patient =
        _prescription?['Patient'] as Map<String, dynamic>? ?? {};
    final nom = (patient['nom_complet'] ?? '—').toString();
    final sexe = (patient['sexe'] ?? '—').toString();
    final age = patient['age']?.toString() ?? '—';
    final total = (_prescription?['total_prix'] as num?)?.toDouble() ?? 0;
    final idStr =
        'HST-${widget.idPrescription.toString().padLeft(6, '0')}';
    final initial = nom.isNotEmpty ? nom[0].toUpperCase() : '?';
    final statut =
        (_prescription?['statut_prescription'] ?? '').toString();
    final isPaid = statut == 'paye' || statut == 'partiellement_delivre';
    final isDelivered = statut == 'delivre' || statut == 'annule';

    // Les lignes actives (non annulées)
    final lignesActives = _lignes
        .where((l) => l['statut_ligne']?.toString() != 'annule')
        .toList();
    final lignesAnnulees = _lignes
        .where((l) => l['statut_ligne']?.toString() == 'annule')
        .toList();

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
                      child: Text(initial,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 22)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nom,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: PharmacieTheme.textDark)),
                          const SizedBox(height: 2),
                          _statutBadge(statut),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Info paiement
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
                          '${_key('phar_vd_age')}: $age ${_key('phar_vd_ans')}'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('${_key('phar_vd_prix')}:',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: PharmacieTheme.textDark)),
                          const SizedBox(width: 16),
                          Text(
                            '${total.toStringAsFixed(0)} XAF',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: PharmacieTheme.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // En-tête liste médicaments
                if (lignesActives.isNotEmpty) ...[
                  Text('phar_ordo_lignes_title'.tr(),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: PharmacieTheme.textDark)),
                  const SizedBox(height: 8),
                ],

                // Lignes actives avec actions
                ...lignesActives.map((l) => _medicamentCard(l, isPaid)),

                // Lignes annulées (affichage informatif)
                if (lignesAnnulees.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('phar_lignes_annulees'.tr(),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: PharmacieTheme.danger)),
                  const SizedBox(height: 6),
                  ...lignesAnnulees.map((l) => _medicamentCardAnnule(l)),
                ],
              ],
            ),
          ),
        ),

        // Boutons globaux
        if (!isDelivered)
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (_saving || _busy) ? null : _annulerTout,
                    icon: const Icon(Icons.cancel_outlined,
                        color: PharmacieTheme.danger),
                    label: Text('phar_vd_annuler'.tr(),
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: PharmacieTheme.danger)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: PharmacieTheme.danger, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_saving || _busy) ? null : _encaisser,
                    icon: (_saving || _busy)
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.point_of_sale_rounded),
                    label: Text(
                      'phar_vd_encaisser'.tr(),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PharmacieTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ───────── Cartes médicament ─────────

  Widget _medicamentCard(Map<String, dynamic> ligne, bool isPaid) {
    final nom = (ligne['nom_medicament'] ?? '').toString();
    final initial = nom.isNotEmpty ? nom[0].toUpperCase() : '?';
    final qte = (ligne['quantite'] as num?)?.toInt() ?? 1;
    final prix = (ligne['prix_unitaire'] as num?)?.toDouble() ?? 0;
    final posologie = (ligne['posologie'] ?? '').toString();
    final statutLigne = (ligne['statut_ligne'] ?? 'en_attente').toString();
    final isTerminee = statutLigne == 'delivre' || statutLigne == 'substitue';
    final isEnAttente = statutLigne == 'en_attente' || statutLigne == 'rupture';

    // Stock en temps réel
    final medInfo = ligne['listemedicament'] as Map<String, dynamic>?;
    final stockActuel = (medInfo?['stock'] as num?)?.toInt() ?? 0;
    final stockInsuffisant = stockActuel < qte;

    Color cardBorder = PharmacieTheme.border;
    Color avatarColor = PharmacieTheme.primary;
    if (isTerminee) {
      cardBorder = PharmacieTheme.success;
      avatarColor = PharmacieTheme.success;
    } else if (stockInsuffisant && isEnAttente) {
      cardBorder = PharmacieTheme.warn;
      avatarColor = PharmacieTheme.warn;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne principale
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: avatarColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(initial,
                      style: TextStyle(
                          color: avatarColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nom,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: PharmacieTheme.textDark)),
                      if (posologie.isNotEmpty && posologie != '-')
                        Text(posologie,
                            style: const TextStyle(
                                fontSize: 11,
                                color: PharmacieTheme.textMuted)),
                      if (stockInsuffisant && isEnAttente)
                        Text(
                          'Stock: $stockActuel / demandé: $qte',
                          style: const TextStyle(
                              fontSize: 11,
                              color: PharmacieTheme.warn,
                              fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${prix.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: PharmacieTheme.primary,
                            fontSize: 13)),
                    Text('x$qte',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: PharmacieTheme.textMuted,
                            fontSize: 12)),
                  ],
                ),
              ],
            ),

            // Badge statut
            const SizedBox(height: 8),
            _ligneBadge(statutLigne),

            // Boutons d'action par ligne (Substituer + Annuler uniquement)
            if (isEnAttente) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  // Substituer
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _busy ? null : () => _substituer(ligne),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                      label: Text('phar_substituer'.tr(),
                          style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PharmacieTheme.primary,
                        side:
                            const BorderSide(color: PharmacieTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Annuler ligne
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _annulerLigne(ligne),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: Text('phar_vl_cancel_yes'.tr(),
                        style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PharmacieTheme.danger,
                      side: const BorderSide(color: PharmacieTheme.danger),
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _medicamentCardAnnule(Map<String, dynamic> ligne) {
    final nom = (ligne['nom_medicament'] ?? '').toString();
    final initial = nom.isNotEmpty ? nom[0].toUpperCase() : '?';
    final qte = (ligne['quantite'] as num?)?.toInt() ?? 1;
    final prix = (ligne['prix_unitaire'] as num?)?.toDouble() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PharmacieTheme.danger.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: PharmacieTheme.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(initial,
                  style: const TextStyle(
                      color: PharmacieTheme.danger,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(nom,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: PharmacieTheme.danger,
                      decoration: TextDecoration.lineThrough)),
            ),
            Text('${prix.toStringAsFixed(0)} FCFA × $qte',
                style: const TextStyle(
                    fontSize: 11,
                    color: PharmacieTheme.danger,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ───────── Helpers UI ─────────

  Widget _statutBadge(String statut) {
    Color color;
    String label;
    switch (statut) {
      case 'paye':
        color = PharmacieTheme.primary;
        label = 'phar_statut_paye'.tr();
        break;
      case 'partiellement_delivre':
        color = PharmacieTheme.warn;
        label = 'phar_statut_partiellement_delivre'.tr();
        break;
      case 'delivre':
        color = PharmacieTheme.success;
        label = 'phar_statut_delivre'.tr();
        break;
      case 'annule':
        color = PharmacieTheme.danger;
        label = 'phar_statut_annule'.tr();
        break;
      default:
        color = PharmacieTheme.textMuted;
        label = statut;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _ligneBadge(String statut) {
    Color color;
    String label;
    switch (statut) {
      case 'delivre':
        color = PharmacieTheme.success;
        label = 'phar_statut_delivre'.tr();
        break;
      case 'substitue':
        color = PharmacieTheme.primary;
        label = 'phar_substitue'.tr();
        break;
      case 'rupture':
        color = PharmacieTheme.warn;
        label = 'phar_statut_rupture'.tr();
        break;
      case 'annule':
        color = PharmacieTheme.danger;
        label = 'phar_statut_annule'.tr();
        break;
      default:
        color = PharmacieTheme.textMuted;
        label = 'phar_statut_en_attente'.tr();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _infoLine(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13, color: PharmacieTheme.primary)),
      );

  String _key(String k) => k.tr();
}
