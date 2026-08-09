import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/shared/responsive_wrapper.dart';
import '../shared/pharmacie_theme.dart';
import '../Stock/stock_entree_service.dart';
import 'listemedicament_service.dart';

class GestionMedicaments extends StatefulWidget {
  const GestionMedicaments({super.key});

  @override
  State<GestionMedicaments> createState() => _GestionMedicamentsState();
}

class _GestionMedicamentsState extends State<GestionMedicaments> {
  final _service = ListeMedicamentService(Supabase.instance.client);
  final _stockService = StockEntreeService(Supabase.instance.client);

  List<Map<String, dynamic>> _items = [];
  Map<int, List<Map<String, dynamic>>> _expiredLotsByMed = {};
  bool _loading = true;
  String _search = '';
  String?
  _filter; // null=tous, 'actifs', 'inactifs', 'stock_bas', 'rupture', 'perimés'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getAll();
      if (mounted)
        setState(() {
          _items = data;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    // Chargement lots périmés avec détails (date, qty, lot)
    try {
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      final expired = await Supabase.instance.client
          .from('stock_entree')
          .select('id_medicament, quantite, date_peremption, numero_lot')
          .not('date_peremption', 'is', null)
          .lt('date_peremption', todayStr)
          .order('date_peremption', ascending: false);
      final Map<int, List<Map<String, dynamic>>> lotsByMed = {};
      for (final lot in (expired as List<dynamic>)) {
        final id = (lot as Map<String, dynamic>)['id_medicament'] as int;
        lotsByMed.putIfAbsent(id, () => []).add(lot);
      }
      if (mounted) setState(() => _expiredLotsByMed = lotsByMed);
    } catch (_) {
      // stock_entree absente — filtre périmés désactivé silencieusement
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _items;
    if (_search.isNotEmpty) {
      list = list
          .where(
            (m) => (m['nom_medicament'] ?? '')
                .toString()
                .toLowerCase()
                .contains(_search),
          )
          .toList();
    }
    if (_filter == 'actifs') {
      list = list.where((m) => m['actif'] == true).toList();
    } else if (_filter == 'inactifs') {
      list = list.where((m) => m['actif'] != true).toList();
    } else if (_filter == 'stock_bas') {
      list = list.where((m) {
        final s = (m['stock'] as num?)?.toInt() ?? 0;
        final a = (m['seuil_alerte'] as num?)?.toInt() ?? 0;
        return s <= a && s > 0;
      }).toList();
    } else if (_filter == 'rupture') {
      list = list
          .where((m) => ((m['stock'] as num?)?.toInt() ?? 0) == 0)
          .toList();
    } else if (_filter == 'perimés') {
      list = list.where((m) {
        final lots = _expiredLotsByMed[m['id_medicament'] as int] ?? [];
        final total = lots.fold<int>(
          0,
          (s, l) => s + ((l['quantite'] as num?)?.toInt() ?? 0),
        );
        return total > 0;
      }).toList();
    }
    return list;
  }

  Future<void> _showForm({Map<String, dynamic>? edit}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _MedicamentFormDialog(
        edit: edit,
        service: _service,
        stockService: _stockService,
      ),
    );
    if (result == true) await _load();
  }

  Future<void> _confirmDelete(Map<String, dynamic> m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('phar_med_delete_title'.tr()),
        content: Text(
          'phar_med_delete_msg'.tr(
            namedArgs: {'name': (m['nom_medicament'] ?? '').toString()},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('att_cancel_no'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmacieTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('phar_med_delete'.tr()),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.delete(m['id_medicament'] as int);
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
    }
  }

  Future<void> _ajouterStockDialog(Map<String, dynamic> m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _AjouterStockDialog(medicament: m, stockService: _stockService),
    );
    if (ok == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(mobile: _buildMobile(), pc: _buildPc());
  }

  Widget _buildMobile() {
    return Scaffold(
      backgroundColor: PharmacieTheme.background,
      appBar: PharmacieAppBar(
        title: 'phar_cat_title'.tr(),
        backRoute: '/Dashboard_Pharmacie',
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: PharmacieTheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: Text('phar_cat_add'.tr()),
      ),
      body: _buildBody(),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'phar_cat_title'.tr(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: PharmacieTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'phar_cat_subtitle'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: PharmacieTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add),
                label: Text('phar_cat_add'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PharmacieTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              TextField(
                onChanged: (v) =>
                    setState(() => _search = v.toLowerCase().trim()),
                decoration: InputDecoration(
                  hintText: 'phar_cat_search_hint'.tr(),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: PharmacieTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: PharmacieTheme.border),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(null, 'phar_filter_all'.tr()),
                    _filterChip('actifs', 'phar_filter_actifs'.tr()),
                    _filterChip('stock_bas', 'phar_filter_stock_bas'.tr()),
                    _filterChip('rupture', 'phar_filter_rupture'.tr()),
                    _filterChip('perimés', 'phar_filter_perimés'.tr()),
                    _filterChip('inactifs', 'phar_filter_inactifs'.tr()),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: PharmacieTheme.primary,
                  ),
                )
              : _filtered.isEmpty
              ? Center(
                  child: Text(
                    'phar_cat_empty'.tr(),
                    style: const TextStyle(color: PharmacieTheme.textMuted),
                  ),
                )
              : RefreshIndicator(
                  color: PharmacieTheme.primary,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final m = _filtered[i];
                      if (_filter == 'perimés') {
                        final lots =
                            _expiredLotsByMed[m['id_medicament'] as int] ?? [];
                        return _buildExpiredCard(m, lots);
                      }
                      return _buildCard(m);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String? value, String label) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: PharmacieTheme.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : PharmacieTheme.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        side: const BorderSide(color: PharmacieTheme.border),
        backgroundColor: Colors.white,
      ),
    );
  }

  // ── Helpers périmés ─────────────────────────────────────────────────────

  static String _nomMois(int m) {
    const n = [
      '',
      'Janv',
      'Févr',
      'Mars',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sept',
      'Oct',
      'Nov',
      'Déc',
    ];
    return n[m];
  }

  static Map<String, List<Map<String, dynamic>>> _groupByMonth(
    List<Map<String, dynamic>> lots,
  ) {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final lot in lots) {
      final date = DateTime.tryParse(lot['date_peremption'] ?? '');
      if (date == null) continue;
      final key = '${_nomMois(date.month)} ${date.year}';
      groups.putIfAbsent(key, () => []).add(lot);
    }
    return groups;
  }

  Widget _statBadge(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiredCard(
    Map<String, dynamic> m,
    List<Map<String, dynamic>> lots,
  ) {
    final stock = (m['stock'] as num?)?.toInt() ?? 0;
    final prix = (m['prix_unitaire'] as num?)?.toDouble() ?? 0;
    final totalPerime = lots.fold<int>(
      0,
      (s, l) => s + ((l['quantite'] as num?)?.toInt() ?? 0),
    );
    final utilisable = (stock - totalPerime).clamp(0, stock);
    final grouped = _groupByMonth(lots);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showForm(edit: m),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: PharmacieTheme.danger.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PharmacieTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.medication_outlined,
                      color: PharmacieTheme.danger,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (m['nom_medicament'] ?? '').toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: PharmacieTheme.textDark,
                          ),
                        ),
                        Text(
                          [
                            m['forme'] ?? '',
                            m['dosage'] ?? '',
                          ].where((s) => s.isNotEmpty).join(' • '),
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
                        'phar_amount_fcfa'.tr(
                          namedArgs: {'amount': prix.toStringAsFixed(0)},
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: PharmacieTheme.primary,
                          fontSize: 12,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: PharmacieTheme.textMuted,
                          size: 18,
                        ),
                        onSelected: (v) {
                          if (v == 'edit')
                            _showForm(edit: m);
                          else if (v == 'add_stock')
                            _ajouterStockDialog(m);
                          else if (v == 'delete')
                            _confirmDelete(m);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 16),
                                const SizedBox(width: 8),
                                Text('phar_med_edit'.tr()),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'add_stock',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.add_box_outlined,
                                  size: 16,
                                  color: PharmacieTheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text('phar_med_add_stock'.tr()),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: PharmacieTheme.danger,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'phar_med_delete'.tr(),
                                  style: const TextStyle(
                                    color: PharmacieTheme.danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 16),
              // Résumé
              Row(
                children: [
                  _statBadge(
                    Icons.warning_amber_rounded,
                    '$totalPerime unité${totalPerime > 1 ? 's' : ''} périmée${totalPerime > 1 ? 's' : ''}',
                    PharmacieTheme.danger,
                  ),
                  const SizedBox(width: 8),
                  _statBadge(
                    utilisable > 0 ? Icons.check_circle_outline : Icons.block,
                    '$utilisable utilisable${utilisable > 1 ? 's' : ''}',
                    utilisable > 0 ? PharmacieTheme.success : Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Lots par mois
              ...grouped.entries.map(
                (entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: PharmacieTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...entry.value.map((lot) {
                      final date = DateTime.tryParse(
                        lot['date_peremption'] ?? '',
                      );
                      final fmtDate = date != null
                          ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                          : '—';
                      final qty = (lot['quantite'] as num?)?.toInt() ?? 0;
                      final lotNum = (lot['numero_lot'] ?? '').toString();
                      return Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 3),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 5,
                              color: PharmacieTheme.danger,
                            ),
                            const SizedBox(width: 6),
                            if (lotNum.isNotEmpty) ...[
                              Text(
                                'Lot $lotNum',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: PharmacieTheme.textDark,
                                ),
                              ),
                              const Text(
                                ' • ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: PharmacieTheme.textMuted,
                                ),
                              ),
                            ],
                            Text(
                              fmtDate,
                              style: const TextStyle(
                                fontSize: 11,
                                color: PharmacieTheme.textMuted,
                              ),
                            ),
                            const Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 11,
                                color: PharmacieTheme.textMuted,
                              ),
                            ),
                            Text(
                              '$qty unité${qty > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: PharmacieTheme.danger,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> m) {
    final stock = (m['stock'] as num?)?.toInt() ?? 0;
    final seuil = (m['seuil_alerte'] as num?)?.toInt() ?? 0;
    final actif = m['actif'] == true;
    final stockBas = stock <= seuil;
    final prix = (m['prix_unitaire'] as num?)?.toDouble() ?? 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showForm(edit: m),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: !actif
                  ? Colors.grey.shade300
                  : stockBas
                  ? PharmacieTheme.danger.withValues(alpha: 0.3)
                  : PharmacieTheme.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: actif
                      ? PharmacieTheme.primary.withValues(alpha: 0.1)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.medication_outlined,
                  color: actif ? PharmacieTheme.primary : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (m['nom_medicament'] ?? '').toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: actif
                            ? PharmacieTheme.textDark
                            : Colors.grey.shade600,
                        decoration: actif
                            ? TextDecoration.none
                            : TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if ((m['forme'] ?? '').toString().isNotEmpty)
                          m['forme'],
                        if ((m['dosage'] ?? '').toString().isNotEmpty)
                          m['dosage'],
                      ].join(' • '),
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
                          text: 'phar_stock_value'.tr(
                            namedArgs: {'stock': '$stock', 'seuil': '$seuil'},
                          ),
                          color: stockBas
                              ? PharmacieTheme.danger
                              : PharmacieTheme.success,
                          icon: stockBas
                              ? Icons.warning_amber_rounded
                              : Icons.inventory_2_outlined,
                        ),
                        if (!actif)
                          const PharmacieStatusBadge(
                            text: 'Inactif',
                            color: Colors.grey,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'phar_amount_fcfa'.tr(
                      namedArgs: {'amount': prix.toStringAsFixed(0)},
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: PharmacieTheme.primary,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: PharmacieTheme.textMuted,
                    ),
                    onSelected: (v) {
                      if (v == 'edit') {
                        _showForm(edit: m);
                      } else if (v == 'add_stock') {
                        _ajouterStockDialog(m);
                      } else if (v == 'delete') {
                        _confirmDelete(m);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text('phar_med_edit'.tr()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'add_stock',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add_box_outlined,
                              size: 18,
                              color: PharmacieTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text('phar_med_add_stock'.tr()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: PharmacieTheme.danger,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'phar_med_delete'.tr(),
                              style: const TextStyle(
                                color: PharmacieTheme.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dialog ajout de stock rapide ────────────────────────────────────────────

class _AjouterStockDialog extends StatefulWidget {
  final Map<String, dynamic> medicament;
  final StockEntreeService stockService;
  const _AjouterStockDialog({
    required this.medicament,
    required this.stockService,
  });

  @override
  State<_AjouterStockDialog> createState() => _AjouterStockDialogState();
}

class _AjouterStockDialogState extends State<_AjouterStockDialog> {
  final _qtyCtrl = TextEditingController(text: '1');
  final _lotCtrl = TextEditingController();
  final _fournCtrl = TextEditingController();
  DateTime? _datePeremption;
  bool _saving = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _lotCtrl.dispose();
    _fournCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _datePeremption ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: PharmacieTheme.primary),
        ),
        child: child!,
      ),
    );
    if (p != null) setState(() => _datePeremption = p);
  }

  Future<void> _save() async {
    final qty = int.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= 0) return;
    setState(() => _saving = true);
    try {
      await widget.stockService.creerEntree(
        idMedicament: widget.medicament['id_medicament'] as int,
        quantite: qty,
        numeroLot: _lotCtrl.text.trim(),
        datePeremption: _datePeremption,
        fournisseur: _fournCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nom = (widget.medicament['nom_medicament'] ?? '').toString();
    final stockActuel = (widget.medicament['stock'] as num?)?.toInt() ?? 0;
    final fmtDate = _datePeremption == null
        ? 'phar_stock_pick_date'.tr()
        : '${_datePeremption!.day.toString().padLeft(2, '0')}/${_datePeremption!.month.toString().padLeft(2, '0')}/${_datePeremption!.year}';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.add_box_outlined, color: PharmacieTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'phar_med_add_stock_title'.tr(namedArgs: {'name': nom}),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: PharmacieTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'phar_stock_actuel'.tr(namedArgs: {'n': '$stockActuel'}),
                style: const TextStyle(
                  color: PharmacieTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'phar_med_quantity_to_add'.tr(),
                prefixIcon: const Icon(
                  Icons.add_circle_outline,
                  color: PharmacieTheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _lotCtrl,
              decoration: InputDecoration(
                labelText: 'phar_stock_lot_label'.tr(),
                prefixIcon: const Icon(
                  Icons.tag,
                  color: PharmacieTheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: PharmacieTheme.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event,
                      color: PharmacieTheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
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
                        onTap: () => setState(() => _datePeremption = null),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: PharmacieTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _fournCtrl,
              decoration: InputDecoration(
                labelText: 'phar_stock_fournisseur'.tr(),
                prefixIcon: const Icon(
                  Icons.local_shipping_outlined,
                  color: PharmacieTheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('att_cancel_no'.tr()),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: PharmacieTheme.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text('phar_save'.tr()),
        ),
      ],
    );
  }
}

/// Formulaire de création/édition d'un médicament.
class _MedicamentFormDialog extends StatefulWidget {
  final Map<String, dynamic>? edit;
  final ListeMedicamentService service;
  final StockEntreeService stockService;
  const _MedicamentFormDialog({
    this.edit,
    required this.service,
    required this.stockService,
  });

  @override
  State<_MedicamentFormDialog> createState() => _MedicamentFormDialogState();
}

class _MedicamentFormDialogState extends State<_MedicamentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomCtrl;
  late TextEditingController _formeCtrl;
  late TextEditingController _dosageCtrl;
  late TextEditingController _prixCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _seuilCtrl;
  final _lotCtrl = TextEditingController();
  DateTime? _datePeremption;
  bool _actif = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _nomCtrl = TextEditingController(text: e?['nom_medicament'] ?? '');
    _formeCtrl = TextEditingController(text: e?['forme'] ?? '');
    _dosageCtrl = TextEditingController(text: e?['dosage'] ?? '');
    _prixCtrl = TextEditingController(
      text: e?['prix_unitaire']?.toString() ?? '',
    );
    _stockCtrl = TextEditingController(text: e?['stock']?.toString() ?? '0');
    _seuilCtrl = TextEditingController(
      text: e?['seuil_alerte']?.toString() ?? '5',
    );
    _actif = e?['actif'] ?? true;
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _formeCtrl.dispose();
    _dosageCtrl.dispose();
    _prixCtrl.dispose();
    _stockCtrl.dispose();
    _seuilCtrl.dispose();
    _lotCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _datePeremption ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: PharmacieTheme.primary),
        ),
        child: child!,
      ),
    );
    if (p != null) setState(() => _datePeremption = p);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final prix = double.parse(_prixCtrl.text.trim().replaceAll(',', '.'));
      final stock = int.parse(_stockCtrl.text.trim());
      final seuil = int.parse(_seuilCtrl.text.trim());

      if (widget.edit == null) {
        final newId = await widget.service.create(
          nom: _nomCtrl.text.trim(),
          forme: _formeCtrl.text.trim().isEmpty ? null : _formeCtrl.text.trim(),
          dosage: _dosageCtrl.text.trim().isEmpty
              ? null
              : _dosageCtrl.text.trim(),
          prix: prix,
          stock: stock,
          seuilAlerte: seuil,
        );
        // Créer un stock_entree si stock initial > 0
        if (stock > 0) {
          await widget.stockService.creerEntree(
            idMedicament: newId,
            quantite: stock,
            numeroLot: _lotCtrl.text.trim().isEmpty
                ? null
                : _lotCtrl.text.trim(),
            datePeremption: _datePeremption,
          );
        }
      } else {
        await widget.service.update(
          idMedicament: widget.edit!['id_medicament'] as int,
          nom: _nomCtrl.text.trim(),
          forme: _formeCtrl.text.trim().isEmpty ? null : _formeCtrl.text.trim(),
          dosage: _dosageCtrl.text.trim().isEmpty
              ? null
              : _dosageCtrl.text.trim(),
          prix: prix,
          stock: stock,
          seuilAlerte: seuil,
          actif: _actif,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: PharmacieTheme.danger,
            content: Text('phar_action_error'.tr()),
          ),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.edit != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: PharmacieTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.medication_outlined,
                          color: PharmacieTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEdit
                              ? 'phar_form_edit_title'.tr()
                              : 'phar_form_add_title'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: PharmacieTheme.textDark,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _field(
                    controller: _nomCtrl,
                    label: 'phar_form_name'.tr(),
                    required: true,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          controller: _formeCtrl,
                          label: 'phar_form_forme'.tr(),
                          required: false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _field(
                          controller: _dosageCtrl,
                          label: 'phar_form_dosage'.tr(),
                          required: false,
                        ),
                      ),
                    ],
                  ),
                  _field(
                    controller: _prixCtrl,
                    label: 'phar_form_price'.tr(),
                    required: true,
                    isNumber: true,
                    decimal: true,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          controller: _stockCtrl,
                          label: 'phar_form_stock'.tr(),
                          required: true,
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _field(
                          controller: _seuilCtrl,
                          label: 'phar_form_seuil'.tr(),
                          required: true,
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),
                  if (!isEdit) ...[
                    _field(
                      controller: _lotCtrl,
                      label: 'phar_stock_lot_label'.tr(),
                      required: false,
                    ),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: PharmacieTheme.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.event,
                              color: PharmacieTheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _datePeremption == null
                                  ? 'phar_stock_pick_date'.tr()
                                  : '${_datePeremption!.day.toString().padLeft(2, '0')}/${_datePeremption!.month.toString().padLeft(2, '0')}/${_datePeremption!.year}',
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
                                onTap: () =>
                                    setState(() => _datePeremption = null),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: PharmacieTheme.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (isEdit)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('phar_form_actif'.tr()),
                      subtitle: Text(
                        'phar_form_actif_help'.tr(),
                        style: const TextStyle(fontSize: 11),
                      ),
                      activeThumbColor: PharmacieTheme.primary,
                      value: _actif,
                      onChanged: (v) => setState(() => _actif = v),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('att_cancel_no'.tr()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PharmacieTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text('phar_save'.tr()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required bool required,
    bool isNumber = false,
    bool decimal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber
            ? TextInputType.numberWithOptions(decimal: decimal)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) {
            return 'fiche_field_required'.tr();
          }
          if (isNumber && v != null && v.trim().isNotEmpty) {
            final cleaned = v.trim().replaceAll(',', '.');
            final n = decimal
                ? double.tryParse(cleaned)
                : int.tryParse(cleaned);
            if (n == null || n < 0) {
              return 'fiche_field_required'.tr();
            }
          }
          return null;
        },
      ),
    );
  }
}
