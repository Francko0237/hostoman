import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/shared/responsive_wrapper.dart';
import '../shared/pharmacie_theme.dart';
import '../Dashboard/listemedicament_service.dart';
import 'stock_entree_service.dart';

class StockEntreePage extends StatefulWidget {
  const StockEntreePage({super.key});

  @override
  State<StockEntreePage> createState() => _StockEntreePageState();
}

class _StockEntreePageState extends State<StockEntreePage> {
  final _service = StockEntreeService(Supabase.instance.client);

  List<Map<String, dynamic>> _entrees = [];
  Map<String, int> _resume = {'total': 0, 'expires': 0, 'bientot': 0};
  bool _loading = true;
  String _filter = 'tous'; // tous | bientot | expires

  // Realtime
  late final RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _channel = Supabase.instance.client
        .channel('stock_entree_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'stock_entree',
          callback: (_) => _load(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel.unsubscribe();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final List<Map<String, dynamic>> data;
      if (_filter == 'bientot') {
        data = await _service.getLotsExpirantBientot();
      } else if (_filter == 'expires') {
        data = await _service.getLotsExpires();
      } else {
        data = await _service.getEntrees();
      }
      final resume = await _service.getResume();
      if (mounted) {
        setState(() {
          _entrees = data;
          _resume = resume;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _NouvelleEntreeDialog(service: _service),
    );
    if (ok == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(mobile: _mobile(), pc: _pc());
  }

  Widget _mobile() {
    return Scaffold(
      backgroundColor: PharmacieTheme.background,
      appBar: PharmacieAppBar(
        title: 'phar_stock_title'.tr(),
        backRoute: '/Dashboard_Pharmacie',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'phar_stock_nouvelle_entree'.tr(),
            onPressed: _openForm,
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _pc() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'phar_stock_title'.tr(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: PharmacieTheme.textDark,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _openForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PharmacieTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text('phar_stock_nouvelle_entree'.tr()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    return Column(
      children: [
        // ── Résumé ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              _resumeChip(
                'phar_stock_total'.tr(),
                '${_resume['total']}',
                PharmacieTheme.primary,
                Icons.inventory_2_outlined,
              ),
              const SizedBox(width: 8),
              _resumeChip(
                'phar_stock_bientot'.tr(),
                '${_resume['bientot']}',
                const Color(0xFFF57C00),
                Icons.schedule_rounded,
              ),
              const SizedBox(width: 8),
              _resumeChip(
                'phar_stock_expires'.tr(),
                '${_resume['expires']}',
                PharmacieTheme.danger,
                Icons.warning_amber_rounded,
              ),
            ],
          ),
        ),
        // ── Filtres ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('tous', 'phar_filter_all'.tr()),
                const SizedBox(width: 8),
                _filterChip('bientot', 'phar_stock_filter_bientot'.tr()),
                const SizedBox(width: 8),
                _filterChip('expires', 'phar_stock_filter_expires'.tr()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // ── Liste ──
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: PharmacieTheme.primary))
              : _entrees.isEmpty
                  ? Center(
                      child: Text(
                        'phar_stock_empty'.tr(),
                        style: const TextStyle(color: PharmacieTheme.textMuted),
                      ),
                    )
                  : RefreshIndicator(
                      color: PharmacieTheme.primary,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _entrees.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) => _lotCard(_entrees[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _resumeChip(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: color)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10, color: PharmacieTheme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _filter = value);
        _load();
      },
      selectedColor: PharmacieTheme.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : PharmacieTheme.textDark,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      side: const BorderSide(color: PharmacieTheme.border),
    );
  }

  Widget _lotCard(Map<String, dynamic> e) {
    final med = e['listemedicament'] as Map<String, dynamic>? ?? {};
    final nom = (med['nom_medicament'] ?? '—').toString();
    final forme = (med['forme'] ?? '').toString();
    final dosage = (med['dosage'] ?? '').toString();
    final lot = (e['numero_lot'] ?? '—').toString();
    final fournisseur = (e['fournisseur'] ?? '—').toString();
    final qty = (e['quantite'] as num?)?.toInt() ?? 0;
    final prixAchat = (e['prix_achat'] as num?)?.toDouble();

    final dateEntree = DateTime.tryParse(e['date_entree'] ?? '');
    final datePeremption = e['date_peremption'] != null
        ? DateTime.tryParse(e['date_peremption'])
        : null;

    final now = DateTime.now();
    Color expiryColor = PharmacieTheme.primary;
    String expiryLabel = 'phar_stock_no_expiry'.tr();
    IconData expiryIcon = Icons.check_circle_outline;

    if (datePeremption != null) {
      final diff = datePeremption.difference(now).inDays;
      if (diff < 0) {
        expiryColor = PharmacieTheme.danger;
        expiryIcon = Icons.cancel_outlined;
        expiryLabel = 'phar_stock_expired'.tr();
      } else if (diff <= 90) {
        expiryColor = const Color(0xFFF57C00);
        expiryIcon = Icons.schedule_rounded;
        expiryLabel = 'phar_stock_expires_in'
            .tr(namedArgs: {'days': '$diff'});
      } else {
        expiryLabel =
            'phar_stock_expires_date'.tr(namedArgs: {
          'date':
              '${datePeremption.day.toString().padLeft(2, '0')}/${datePeremption.month.toString().padLeft(2, '0')}/${datePeremption.year}',
        });
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PharmacieTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Ligne 1 : Nom + Qty ──
          Row(
            children: [
              Expanded(
                child: Text(
                  nom,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: PharmacieTheme.textDark,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: PharmacieTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+$qty ${'phar_stock_units'.tr()}',
                  style: const TextStyle(
                    color: PharmacieTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (forme.isNotEmpty || dosage.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              [forme, dosage].where((s) => s.isNotEmpty).join(' — '),
              style: const TextStyle(
                  fontSize: 12, color: PharmacieTheme.textMuted),
            ),
          ],
          const SizedBox(height: 10),
          // ── Ligne 2 : Lot + Fournisseur ──
          Row(
            children: [
              _infoTag(Icons.tag, 'phar_stock_lot'.tr(namedArgs: {'n': lot}),
                  PharmacieTheme.accent),
              const SizedBox(width: 8),
              Expanded(
                child: _infoTag(
                    Icons.local_shipping_outlined,
                    fournisseur,
                    PharmacieTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // ── Ligne 3 : Péremption + date entrée ──
          Row(
            children: [
              Icon(expiryIcon, size: 14, color: expiryColor),
              const SizedBox(width: 4),
              Text(
                expiryLabel,
                style: TextStyle(
                    fontSize: 12,
                    color: expiryColor,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (prixAchat != null)
                Text(
                  '${prixAchat.toStringAsFixed(0)} FCFA/${'phar_stock_unit'.tr()}',
                  style: const TextStyle(
                      fontSize: 11, color: PharmacieTheme.textMuted),
                ),
            ],
          ),
          if (dateEntree != null) ...[
            const SizedBox(height: 4),
            Text(
              'phar_stock_recu_le'.tr(namedArgs: {
                'date':
                    '${dateEntree.day.toString().padLeft(2, '0')}/${dateEntree.month.toString().padLeft(2, '0')}/${dateEntree.year}',
              }),
              style: const TextStyle(
                  fontSize: 10, color: PharmacieTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoTag(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(fontSize: 12, color: color),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

// ── Dialogue nouvelle entrée ───────────────────────────────────────────────

class _NouvelleEntreeDialog extends StatefulWidget {
  final StockEntreeService service;
  const _NouvelleEntreeDialog({required this.service});

  @override
  State<_NouvelleEntreeDialog> createState() => _NouvelleEntreeDialogState();
}

class _NouvelleEntreeDialogState extends State<_NouvelleEntreeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _medService = ListeMedicamentService(Supabase.instance.client);

  List<Map<String, dynamic>> _medicaments = [];
  Map<String, dynamic>? _selectedMed;
  String _searchMed = '';

  final _qtyCtrl = TextEditingController(text: '1');
  final _lotCtrl = TextEditingController();
  final _fournCtrl = TextEditingController();
  final _prixCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _datePeremption;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadMeds();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _lotCtrl.dispose();
    _fournCtrl.dispose();
    _prixCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMeds() async {
    final data = await _medService.getAll(actifsSeulement: true);
    if (mounted) setState(() => _medicaments = data);
  }

  List<Map<String, dynamic>> get _filteredMeds {
    if (_searchMed.isEmpty) return _medicaments;
    return _medicaments
        .where((m) => (m['nom_medicament'] ?? '')
            .toString()
            .toLowerCase()
            .contains(_searchMed.toLowerCase()))
        .toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: PharmacieTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _datePeremption = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedMed == null) return;
    setState(() => _saving = true);
    try {
      await widget.service.creerEntree(
        idMedicament: _selectedMed!['id_medicament'] as int,
        quantite: int.parse(_qtyCtrl.text.trim()),
        numeroLot: _lotCtrl.text.trim(),
        datePeremption: _datePeremption,
        fournisseur: _fournCtrl.text.trim(),
        prixAchat: double.tryParse(_prixCtrl.text.trim()),
        notes: _notesCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    final fmtDate = _datePeremption == null
        ? 'phar_stock_pick_date'.tr()
        : '${_datePeremption!.day.toString().padLeft(2, '0')}/${_datePeremption!.month.toString().padLeft(2, '0')}/${_datePeremption!.year}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── En-tête ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              decoration: const BoxDecoration(
                color: PharmacieTheme.primary,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_box_outlined,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'phar_stock_nouvelle_entree'.tr(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // ── Formulaire ──
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sélection médicament
                      Text('phar_stock_medicament'.tr(),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: PharmacieTheme.textDark,
                              fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        decoration: _inputDeco(
                            'phar_stock_search_med'.tr(),
                            Icons.search),
                        onChanged: (v) =>
                            setState(() => _searchMed = v),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        constraints:
                            const BoxConstraints(maxHeight: 150),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: PharmacieTheme.border),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: _filteredMeds.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('—'),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _filteredMeds.length,
                                itemBuilder: (_, i) {
                                  final m = _filteredMeds[i];
                                  final sel = _selectedMed?[
                                          'id_medicament'] ==
                                      m['id_medicament'];
                                  return ListTile(
                                    dense: true,
                                    selected: sel,
                                    selectedTileColor: PharmacieTheme
                                        .primary
                                        .withValues(alpha: 0.1),
                                    title: Text(
                                        m['nom_medicament'] ?? ''),
                                    subtitle: Text(
                                      [
                                        m['forme'] ?? '',
                                        m['dosage'] ?? ''
                                      ]
                                          .where(
                                              (s) => s.isNotEmpty)
                                          .join(' '),
                                      style: const TextStyle(
                                          fontSize: 11),
                                    ),
                                    onTap: () => setState(
                                        () => _selectedMed = m),
                                  );
                                },
                              ),
                      ),
                      if (_selectedMed == null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'phar_stock_select_required'.tr(),
                          style: const TextStyle(
                              color: PharmacieTheme.danger,
                              fontSize: 11),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Quantité
                      TextFormField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _inputDeco(
                            'phar_stock_quantite'.tr(),
                            Icons.add_circle_outline),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n <= 0) {
                            return 'phar_stock_qty_error'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Numéro de lot
                      TextFormField(
                        controller: _lotCtrl,
                        decoration: _inputDeco(
                            'phar_stock_lot_label'.tr(),
                            Icons.tag),
                      ),
                      const SizedBox(height: 12),
                      // Date de péremption
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                                color: PharmacieTheme.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event,
                                  color: PharmacieTheme.primary,
                                  size: 18),
                              const SizedBox(width: 10),
                              Text(
                                fmtDate,
                                style: TextStyle(
                                  color: _datePeremption == null
                                      ? PharmacieTheme.textMuted
                                      : PharmacieTheme.textDark,
                                  fontSize: 14,
                                ),
                              ),
                              if (_datePeremption != null) ...[
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => setState(
                                      () => _datePeremption = null),
                                  child: const Icon(Icons.close,
                                      size: 16,
                                      color:
                                          PharmacieTheme.textMuted),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Fournisseur
                      TextFormField(
                        controller: _fournCtrl,
                        decoration: _inputDeco(
                            'phar_stock_fournisseur'.tr(),
                            Icons.local_shipping_outlined),
                      ),
                      const SizedBox(height: 12),
                      // Prix d'achat
                      TextFormField(
                        controller: _prixCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        decoration: _inputDeco(
                            'phar_stock_prix_achat'.tr(),
                            Icons.payments_outlined),
                      ),
                      const SizedBox(height: 12),
                      // Notes
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        decoration: _inputDeco(
                            'phar_stock_notes'.tr(),
                            Icons.notes),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ── Actions ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PharmacieTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(
                  _saving
                      ? 'phar_saving'.tr()
                      : 'phar_stock_enregistrer'.tr(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: PharmacieTheme.primary),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: PharmacieTheme.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: PharmacieTheme.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: PharmacieTheme.primary, width: 1.5)),
      );
}
