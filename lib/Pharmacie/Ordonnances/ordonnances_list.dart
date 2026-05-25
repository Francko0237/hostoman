import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/shared/responsive_wrapper.dart';
import '../shared/pharmacie_theme.dart';
import 'ordonnances_service.dart';

class OrdonnancesList extends StatefulWidget {
  const OrdonnancesList({super.key});

  @override
  State<OrdonnancesList> createState() => _OrdonnancesListState();
}

class _OrdonnancesListState extends State<OrdonnancesList>
    with SingleTickerProviderStateMixin {
  final _service = OrdonnancesService(Supabase.instance.client);
  late TabController _tab;

  List<Map<String, dynamic>> _enAttente = [];
  List<Map<String, dynamic>> _aDelivrer = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final attente = await _service.listerParStatut(['en_attente_paiement']);
      final aDelivrer = await _service.listerParStatut(
        ['paye', 'partiellement_delivre'],
      );
      if (mounted) {
        setState(() {
          _enAttente = attente;
          _aDelivrer = aDelivrer;
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

  List<Map<String, dynamic>> _applySearch(List<Map<String, dynamic>> list) {
    if (_search.isEmpty) return list;
    return list.where((p) {
      final patient =
          (p['Patient']?['nom_complet'] ?? '').toString().toLowerCase();
      final id = (p['id_prescription'] ?? '').toString();
      return patient.contains(_search) || id.contains(_search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobile(),
      pc: _buildPc(),
    );
  }

  Widget _buildMobile() {
    return Scaffold(
      backgroundColor: PharmacieTheme.background,
      drawer: const PharmacieDrawer(
          activeRoute: '/Dashboard_Pharmacie/Ordonnances'),
      appBar: PharmacieAppBar(
        title: 'phar_ordo_title'.tr(),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildPc() {
    return PharmaciePcLayout(
      activeRoute: '/Dashboard_Pharmacie/Ordonnances',
      breadcrumbKey: 'phar_breadcrumb_ordonnances',
      body: _buildContent(isPc: true),
    );
  }

  Widget _buildContent({bool isPc = false}) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: PharmacieTheme.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 60, color: PharmacieTheme.danger),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: PharmacieTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: Text('phar_retry'.tr()),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            isPc ? 28 : 16,
            isPc ? 24 : 12,
            isPc ? 28 : 16,
            8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPc) ...[
                Text(
                  'phar_ordo_title'.tr(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: PharmacieTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'phar_ordo_subtitle'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: PharmacieTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'phar_ordo_search_hint'.tr(),
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
            ],
          ),
        ),
        TabBar(
          controller: _tab,
          labelColor: PharmacieTheme.primary,
          unselectedLabelColor: PharmacieTheme.textMuted,
          indicatorColor: PharmacieTheme.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: [
            Tab(
              text: 'phar_ordo_tab_attente'
                  .tr(namedArgs: {'count': '${_enAttente.length}'}),
            ),
            Tab(
              text: 'phar_ordo_tab_delivrer'
                  .tr(namedArgs: {'count': '${_aDelivrer.length}'}),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _buildList(_applySearch(_enAttente), isAttente: true),
              _buildList(_applySearch(_aDelivrer), isAttente: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list,
      {required bool isAttente}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAttente ? Icons.schedule : Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isAttente
                  ? 'phar_ordo_empty_attente'.tr()
                  : 'phar_ordo_empty_delivrer'.tr(),
              style: const TextStyle(color: PharmacieTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: PharmacieTheme.primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildCard(list[i]),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> p) {
    final patient = p['Patient'] as Map<String, dynamic>?;
    final nom = patient?['nom_complet'] ?? 'phar_ordo_no_patient'.tr();
    final age = patient?['age'];
    final sexe = patient?['sexe'];
    final date = DateTime.tryParse(p['date_prescription'] ?? '');
    final total = (p['total_prix'] as num?)?.toDouble() ?? 0;
    final statut = (p['statut_prescription'] ?? '').toString();
    final type = (p['type_prescription'] ?? 'consultation').toString();
    final id = p['id_prescription'];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context
            .push('/Dashboard_Pharmacie/Ordonnances/$id')
            .then((_) => _load()),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PharmacieTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: PharmacieTheme.primary
                        .withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.person_outline,
                      color: PharmacieTheme.primary,
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
                            if (sexe != null) sexe.toString(),
                            if (age != null)
                              'phar_age'.tr(namedArgs: {'age': '$age'}),
                            'N° $id',
                          ].join(' • '),
                          style: const TextStyle(
                            fontSize: 11,
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
              const SizedBox(height: 10),
              const Divider(height: 1, color: PharmacieTheme.border),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    type == 'vente_libre'
                        ? Icons.point_of_sale_outlined
                        : Icons.medical_services_outlined,
                    size: 14,
                    color: PharmacieTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    type == 'vente_libre'
                        ? 'phar_type_vente_libre'.tr()
                        : 'phar_type_consultation'.tr(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: PharmacieTheme.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (date != null) ...[
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: PharmacieTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(date),
                      style: const TextStyle(
                        fontSize: 11,
                        color: PharmacieTheme.textMuted,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    'phar_amount_fcfa'.tr(
                      namedArgs: {'amount': total.toStringAsFixed(0)},
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: PharmacieTheme.primary,
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

  String _formatDate(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} $h:$m';
  }
}
