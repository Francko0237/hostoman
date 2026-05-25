import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/shared/responsive_wrapper.dart';
import '../shared/pharmacie_theme.dart';
import 'historique_service.dart';

class HistoriquePharmacie extends StatefulWidget {
  const HistoriquePharmacie({super.key});

  @override
  State<HistoriquePharmacie> createState() => _HistoriquePharmacieState();
}

class _HistoriquePharmacieState extends State<HistoriquePharmacie> {
  final _service = HistoriquePharmacieService(Supabase.instance.client);
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _search = '';
  String? _typeFilter; // null=tous, 'consultation', 'vente_libre'
  String? _statutFilter;
  DateTimeRange? _periode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.lister(
        debut: _periode?.start,
        fin: _periode?.end.add(const Duration(days: 1)),
        typePrescription: _typeFilter,
        statut: _statutFilter,
      );
      if (mounted) {
        setState(() {
          _items = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _items;
    return _items.where((p) {
      final n = (p['Patient']?['nom_complet'] ?? '').toString().toLowerCase();
      final id = (p['id_prescription'] ?? '').toString();
      return n.contains(_search) || id.contains(_search);
    }).toList();
  }

  Future<void> _pickPeriode() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _periode,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: PharmacieTheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (r != null) {
      setState(() => _periode = r);
      _load();
    }
  }

  double get _totalPeriode {
    double total = 0;
    for (final p in _filtered) {
      if (p['statut_prescription'] != 'annule') {
        total += (p['total_prix'] as num?)?.toDouble() ?? 0;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(mobile: _mobile(), pc: _pc());
  }

  Widget _mobile() {
    return Scaffold(
      backgroundColor: PharmacieTheme.background,
      drawer: const PharmacieDrawer(
        activeRoute: '/Dashboard_Pharmacie/Historique',
      ),
      appBar: PharmacieAppBar(
        title: 'phar_hist_title'.tr(),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _body(),
    );
  }

  Widget _pc() {
    return PharmaciePcLayout(
      activeRoute: '/Dashboard_Pharmacie/Historique',
      breadcrumbKey: 'phar_breadcrumb_historique',
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'phar_hist_title'.tr(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: PharmacieTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'phar_hist_subtitle'.tr(),
              style: const TextStyle(
                fontSize: 14,
                color: PharmacieTheme.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
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
                  hintText: 'phar_hist_search_hint'.tr(),
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
                    ActionChip(
                      avatar: const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: PharmacieTheme.primary,
                      ),
                      label: Text(
                        _periode == null
                            ? 'phar_hist_period_all'.tr()
                            : '${_fmtD(_periode!.start)} - ${_fmtD(_periode!.end)}',
                      ),
                      onPressed: _pickPeriode,
                    ),
                    if (_periode != null)
                      IconButton(
                        onPressed: () {
                          setState(() => _periode = null);
                          _load();
                        },
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    const SizedBox(width: 8),
                    _chip(
                      null,
                      'phar_filter_all'.tr(),
                      () => _typeFilter,
                      (v) => _typeFilter = v,
                    ),
                    _chip(
                      'consultation',
                      'phar_type_consultation'.tr(),
                      () => _typeFilter,
                      (v) => _typeFilter = v,
                    ),
                    _chip(
                      'vente_libre',
                      'phar_type_vente_libre'.tr(),
                      () => _typeFilter,
                      (v) => _typeFilter = v,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Bandeau total
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PharmacieTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: PharmacieTheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.functions, color: PharmacieTheme.primary),
              const SizedBox(width: 8),
              Text(
                'phar_hist_count'.tr(
                  namedArgs: {'count': '${_filtered.length}'},
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: PharmacieTheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                'phar_amount_fcfa'.tr(
                  namedArgs: {'amount': _totalPeriode.toStringAsFixed(0)},
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: PharmacieTheme.primary,
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
                    'phar_hist_empty'.tr(),
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
                    itemBuilder: (_, i) => _card(_filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _chip(
    String? value,
    String label,
    String? Function() getter,
    void Function(String?) setter,
  ) {
    final selected = getter() == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => setter(value));
          _load();
        },
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

  Widget _card(Map<String, dynamic> p) {
    final patient = p['Patient'] as Map<String, dynamic>?;
    final nom = patient?['nom_complet'] ?? 'phar_ordo_no_patient'.tr();
    final date = DateTime.tryParse(p['date_prescription'] ?? '');
    final total = (p['total_prix'] as num?)?.toDouble() ?? 0;
    final statut = (p['statut_prescription'] ?? '').toString();
    final type = (p['type_prescription'] ?? 'consultation').toString();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          '/Dashboard_Pharmacie/Ordonnances/${p['id_prescription']}',
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PharmacieTheme.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: StatutHelper.colorOf(statut).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  StatutHelper.iconOf(statut),
                  color: StatutHelper.colorOf(statut),
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
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: PharmacieTheme.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        type == 'vente_libre'
                            ? 'phar_type_vente_libre'.tr()
                            : 'phar_type_consultation'.tr(),
                        if (date != null) _fmtDate(date),
                        'N° ${p['id_prescription']}',
                      ].join(' • '),
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
                      namedArgs: {'amount': total.toStringAsFixed(0)},
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: PharmacieTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  PharmacieStatusBadge(
                    text: StatutHelper.labelOf(statut),
                    color: StatutHelper.colorOf(statut),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _fmtD(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}
