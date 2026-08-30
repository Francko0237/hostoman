import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/shared/responsive_wrapper.dart';
import '../shared/pharmacie_theme.dart';
import '../Dashboard/listemedicament_service.dart';
import 'ordonnances_service.dart';

class OrdonnanceDetail extends StatefulWidget {
  final int idPrescription;
  const OrdonnanceDetail({super.key, required this.idPrescription});

  @override
  State<OrdonnanceDetail> createState() => _OrdonnanceDetailState();
}

class _OrdonnanceDetailState extends State<OrdonnanceDetail> {
  final _service = OrdonnancesService(Supabase.instance.client);
  final _medService = ListeMedicamentService(Supabase.instance.client);

  Map<String, dynamic>? _prescription;
  List<Map<String, dynamic>> _lignes = [];
  Map<String, dynamic>? _paiement;
  List<Map<String, dynamic>> _catalogue = [];
  bool _loading = true;
  String? _error;
  bool _busy = false;

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
          _paiement = detail['paiement'] as Map<String, dynamic>?;
          _catalogue = cat;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'phar_server_error'.tr();
        });
      }
    }
  }

  Future<void> _confirmerPaiement() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('phar_confirm_payment_title'.tr()),
        content: Text('phar_confirm_payment_msg'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('att_cancel_no'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmacieTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('phar_confirm_payment_btn'.tr()),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await _service.confirmerPaiement(widget.idPrescription);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: PharmacieTheme.success,
            content: Text('phar_payment_confirmed'.tr()),
          ),
        );
      }
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
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delivrerLigne(Map<String, dynamic> ligne) async {
    final idLigne = ligne['id_ligne'] as int;
    final idMed = ligne['id_medicament'];
    final prix = ligne['prix_unitaire'];
    final isCustom = idMed == null;

    // Si saisie libre sans prix, demander le prix avant délivrance
    if (isCustom && prix == null) {
      final saisi = await _demanderPrix(ligne);
      if (saisi == null) return;
      try {
        await _service.majPrixLigne(idLigne, saisi);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: PharmacieTheme.danger,
              content: Text('phar_action_error'.tr()),
            ),
          );
        }
        return;
      }
    }

    setState(() => _busy = true);
    try {
      // Substitution si nécessaire (médicament catalogue présent ?)
      final idSub = ligne['id_medicament_substitut'] as int?;
      await _service.delivrerLigne(
        idLigne: idLigne,
        idMedicamentSubstitut: idSub,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: PharmacieTheme.success,
            content: Text('phar_ligne_delivered'.tr()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: PharmacieTheme.danger,
            content: Text(
              e.toString().contains('Stock insuffisant')
                  ? 'phar_stock_insuffisant'.tr()
                  : 'phar_action_error'.tr(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _substituer(Map<String, dynamic> ligne) async {
    final int qteRequise = (ligne['quantite'] as num?)?.toInt() ?? 1;
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) =>
          SubstitutPicker(catalogue: _catalogue, quantiteRequise: qteRequise),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: PharmacieTheme.success,
            content: Text('phar_ligne_substituted'.tr()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: PharmacieTheme.danger,
            content: Text(
              e.toString().contains('Stock insuffisant')
                  ? 'phar_stock_insuffisant'.tr()
                  : 'phar_action_error'.tr(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _marquerRupture(Map<String, dynamic> ligne) async {
    setState(() => _busy = true);
    try {
      await _service.marquerRupture(ligne['id_ligne'] as int);
      await _load();
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
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<double?> _demanderPrix(Map<String, dynamic> ligne) async {
    final ctrl = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'phar_set_price_title'.tr(
            namedArgs: {'name': (ligne['nom_medicament'] ?? '').toString()},
          ),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'phar_set_price_label'.tr(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('att_cancel_no'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmacieTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
              if (v != null && v > 0) Navigator.pop(ctx, v);
            },
            child: Text('phar_save'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(mobile: _buildMobile(), pc: _buildPc());
  }

  Widget _buildMobile() {
    return Scaffold(
      backgroundColor: PharmacieTheme.background,
      appBar: PharmacieAppBar(
        title: 'phar_ordo_detail_title'.tr(),
        showBack: true,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildPc() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              Text(
                'phar_ordo_detail_title'.tr(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: PharmacieTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildContent(isPc: true)),
        ],
      ),
    );
  }

  Widget _buildContent({bool isPc = false}) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: PharmacieTheme.primary),
      );
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_prescription == null) {
      return Center(child: Text('phar_ordo_not_found'.tr()));
    }

    final p = _prescription!;
    final patient = p['Patient'] as Map<String, dynamic>?;
    final consult = p['Consultation'] as Map<String, dynamic>?;
    final statut = (p['statut_prescription'] ?? '').toString();
    final type = (p['type_prescription'] ?? 'consultation').toString();
    final total = (p['total_prix'] as num?)?.toDouble() ?? 0;
    final statutPaiement = _paiement?['statut_paiement']?.toString();
    final canConfirmPaiement = statut == 'en_attente_paiement';
    final canDelivrer = statut == 'paye' || statut == 'partiellement_delivre';

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isPc ? 0 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carte patient + statut
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PharmacieTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: PharmacieTheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: PharmacieTheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patient?['nom_complet'] ??
                                    'phar_ordo_no_patient'.tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: PharmacieTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  if (patient?['sexe'] != null)
                                    patient!['sexe'].toString(),
                                  if (patient?['age'] != null)
                                    'phar_age'.tr(
                                      namedArgs: {'age': '${patient!['age']}'},
                                    ),
                                  'N° ${p['id_prescription']}',
                                ].join(' • '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: PharmacieTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PharmacieStatusBadge(
                          text: StatutHelper.labelOf(statut),
                          color: StatutHelper.colorOf(statut),
                          icon: StatutHelper.iconOf(statut),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: PharmacieTheme.border),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _info(
                          icon: type == 'vente_libre'
                              ? Icons.point_of_sale_outlined
                              : Icons.medical_services_outlined,
                          label: type == 'vente_libre'
                              ? 'phar_type_vente_libre'.tr()
                              : 'phar_type_consultation'.tr(),
                        ),
                        if ((consult?['Parametres_vitaux']
                                as Map?)?['motif_de_consultation'] !=
                            null)
                          _info(
                            icon: Icons.healing_outlined,
                            label:
                                (consult!['Parametres_vitaux']
                                        as Map)['motif_de_consultation']
                                    .toString(),
                          ),
                        if (patient?['telephone'] != null)
                          _info(
                            icon: Icons.phone_outlined,
                            label: patient!['telephone'].toString(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Carte paiement
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PharmacieTheme.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PharmacieTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        color: PharmacieTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'phar_total_label'.tr(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: PharmacieTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'phar_amount_fcfa'.tr(
                              namedArgs: {'amount': total.toStringAsFixed(0)},
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: PharmacieTheme.primary,
                            ),
                          ),
                          if (statutPaiement != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'phar_payment_status'.tr(
                                namedArgs: {
                                  'status': statutPaiement == 'paye'
                                      ? 'phar_status_paye'.tr()
                                      : 'phar_status_attente_paiement'.tr(),
                                },
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: statutPaiement == 'paye'
                                    ? PharmacieTheme.success
                                    : PharmacieTheme.warn,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (canConfirmPaiement)
                      ElevatedButton.icon(
                        onPressed: _busy ? null : _confirmerPaiement,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text('phar_confirm_payment_btn'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PharmacieTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'phar_lignes_title'.tr(
                  namedArgs: {'count': '${_lignes.length}'},
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: PharmacieTheme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              ..._lignes.map((l) => _ligneCard(l, canDelivrer)),
              const SizedBox(height: 80),
            ],
          ),
        ),
        if (_busy)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _info({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: PharmacieTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: PharmacieTheme.textMuted),
        ),
      ],
    );
  }

  Widget _ligneCard(Map<String, dynamic> l, bool canDelivrer) {
    final statut = (l['statut_ligne'] ?? '').toString();
    final isCustom = l['id_medicament'] == null;
    final disponible = l['disponible_initialement'] == true;
    final prix = (l['prix_unitaire'] as num?)?.toDouble();
    final qte = (l['quantite'] as num?)?.toInt() ?? 1;
    final isDelivered = statut == 'delivre' || statut == 'substitue';
    final isRupture = statut == 'rupture';
    final isAnnule = statut == 'annule';

    Color statutColor;
    String statutLabel;
    IconData statutIcon;
    switch (statut) {
      case 'delivre':
        statutColor = PharmacieTheme.success;
        statutLabel = 'phar_ligne_status_delivre'.tr();
        statutIcon = Icons.check_circle;
        break;
      case 'substitue':
        statutColor = Colors.deepPurple;
        statutLabel = 'phar_ligne_status_substitue'.tr();
        statutIcon = Icons.swap_horiz;
        break;
      case 'rupture':
        statutColor = PharmacieTheme.danger;
        statutLabel = 'phar_ligne_status_rupture'.tr();
        statutIcon = Icons.block;
        break;
      case 'annule':
        statutColor = Colors.grey;
        statutLabel = 'phar_status_annule'.tr();
        statutIcon = Icons.cancel_outlined;
        break;
      default:
        statutColor = PharmacieTheme.warn;
        statutLabel = 'phar_ligne_status_attente'.tr();
        statutIcon = Icons.schedule;
    }

    // Infos stock depuis le join listemedicament
    final medData =
        l['listemedicament'] as Map<String, dynamic>?;
    final int? stockActuel =
        medData != null ? (medData['stock'] as num?)?.toInt() : null;
    final int seuilAlerte =
        medData != null ? (medData['seuil_alerte'] as num?)?.toInt() ?? 5 : 5;
    // Insuffisant = stock réel < quantité prescrite
    final bool stockInsuffisant =
        stockActuel != null && stockActuel < qte;
    final bool stockBas =
        stockActuel != null && !stockInsuffisant && stockActuel <= seuilAlerte;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAnnule
            ? Colors.grey.shade50
            : stockInsuffisant && !isDelivered
                ? Colors.red.shade50
                : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAnnule
              ? Colors.grey.shade300
              : stockInsuffisant && !isDelivered
                  ? Colors.red.shade200
                  : isDelivered
                      ? PharmacieTheme.success.withValues(alpha: 0.3)
                      : PharmacieTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (l['nom_medicament'] ?? '').toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isAnnule ? Colors.grey : PharmacieTheme.textDark,
                        decoration: isAnnule
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (l['posologie'] ?? '').toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: PharmacieTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        PharmacieStatusBadge(
                          text: statutLabel,
                          color: statutColor,
                          icon: statutIcon,
                        ),
                        if (isCustom)
                          PharmacieStatusBadge(
                            text: 'fiche_med_badge_custom'.tr(),
                            color: Colors.deepPurple,
                          ),
                        if (!isCustom && !disponible)
                          PharmacieStatusBadge(
                            text: 'fiche_med_badge_unavailable'.tr(),
                            color: PharmacieTheme.danger,
                          ),
                        // 🛒 Indicateur de stock en temps réel
                        if (stockActuel != null && !isDelivered && !isAnnule)
                          PharmacieStatusBadge(
                            text: stockInsuffisant
                                ? 'Stock insuffisant ($stockActuel dispo)'
                                : stockBas
                                    ? 'Stock bas ($stockActuel restant)'
                                    : 'Stock : $stockActuel',
                            color: stockInsuffisant
                                ? PharmacieTheme.danger
                                : stockBas
                                    ? PharmacieTheme.warn
                                    : PharmacieTheme.success,
                            icon: stockInsuffisant
                                ? Icons.warning_amber_rounded
                                : stockBas
                                    ? Icons.warning_outlined
                                    : Icons.inventory_2_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'phar_qte_x'.tr(namedArgs: {'qte': '$qte'}),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PharmacieTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prix != null
                        ? 'phar_amount_fcfa'.tr(
                            namedArgs: {
                              'amount': (prix * qte).toStringAsFixed(0),
                            },
                          )
                        : '—',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: PharmacieTheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (canDelivrer && !isDelivered && !isAnnule && !isRupture) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ||
                            (stockInsuffisant && !isCustom)
                        ? null
                        : () => _delivrerLigne(l),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text('phar_action_delivrer'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PharmacieTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _substituer(l),
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: Text('phar_action_substituer'.tr()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    side: const BorderSide(color: Colors.deepPurple),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'phar_action_rupture'.tr(),
                  onPressed: _busy ? null : () => _marquerRupture(l),
                  icon: const Icon(Icons.block, color: PharmacieTheme.danger),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Mini-dialog pour choisir un médicament de substitution.
class SubstitutPicker extends StatefulWidget {
  final List<Map<String, dynamic>> catalogue;
  final int quantiteRequise;
  const SubstitutPicker({
    required this.catalogue,
    required this.quantiteRequise,
  });

  @override
  State<SubstitutPicker> createState() => _SubstitutPickerState();
}

class _SubstitutPickerState extends State<SubstitutPicker> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _search.isEmpty
        ? widget.catalogue
        : widget.catalogue
              .where(
                (m) => (m['nom_medicament'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(_search),
              )
              .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
              decoration: const BoxDecoration(
                color: PharmacieTheme.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'phar_subst_title'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                onChanged: (v) =>
                    setState(() => _search = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'phar_subst_search'.tr(),
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text('fiche_med_empty'.tr()))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final m = filtered[i];
                        final stock = (m['stock'] as num?)?.toInt() ?? 0;
                        // Disponible uniquement si le stock couvre la quantité prescrite
                        final dispo = stock >= widget.quantiteRequise;
                        return ListTile(
                          title: Text(
                            (m['nom_medicament'] ?? '').toString(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            [
                              if ((m['forme'] ?? '').toString().isNotEmpty)
                                m['forme'],
                              if ((m['dosage'] ?? '').toString().isNotEmpty)
                                m['dosage'],
                              'phar_stock_label'.tr(
                                namedArgs: {'stock': '$stock'},
                              ),
                            ].join(' • '),
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: PharmacieStatusBadge(
                            text: dispo
                                ? 'fiche_med_badge_available'.tr()
                                : stock > 0
                                    ? 'Stock insuffisant ($stock)'
                                    : 'fiche_med_badge_unavailable'.tr(),
                            color: dispo
                                ? PharmacieTheme.success
                                : PharmacieTheme.danger,
                          ),
                          onTap: dispo ? () => Navigator.pop(context, m) : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
