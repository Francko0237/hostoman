import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/shared/responsive_wrapper.dart';
import '../shared/pharmacie_theme.dart';
import 'dashboard_service.dart';
import '../Ordonnances/ordonnances_service.dart';
import 'listemedicament_service.dart';

class DashboardPharmacie extends StatefulWidget {
  const DashboardPharmacie({super.key});

  @override
  State<DashboardPharmacie> createState() => _DashboardPharmacieState();
}

class _DashboardPharmacieState extends State<DashboardPharmacie> {
  final _kpiService = PharmacieDashboardService(Supabase.instance.client);
  final _ordoService = OrdonnancesService(Supabase.instance.client);
  final _medService = ListeMedicamentService(Supabase.instance.client);

  Map<String, dynamic> _kpis = {};
  List<Map<String, dynamic>> _stockBas = [];
  bool _loading = true;
  String? _error;
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _initialLoad();
    _refresh = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _initialLoad() async {
    // À l'ouverture de la pharmacie : annulation auto des ordonnances périmées
    await _ordoService.annulerPerimees();
    await _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final kpis = await _kpiService.getKpis();
      final stockBas = await _medService.getStockBas();
      if (mounted) {
        setState(() {
          _kpis = kpis;
          _stockBas = stockBas;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          if (!silent) _error = 'phar_server_error'.tr();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobile(),
      pc: _buildPc(),
    );
  }

  // ========== MOBILE ==========
  Widget _buildMobile() {
    return Scaffold(
      backgroundColor: PharmacieTheme.background,
      drawer:
          const PharmacieDrawer(activeRoute: '/Dashboard_Pharmacie'),
      appBar: PharmacieAppBar(
        title: 'phar_dashboard_title'.tr(),
        actions: [
          IconButton(
            onPressed: () => _load(),
            icon: const Icon(Icons.refresh),
            tooltip: 'phar_refresh'.tr(),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: PharmacieTheme.primary),
            )
          : _error != null
              ? _errorView()
              : _buildBody(),
    );
  }

  // ========== PC ==========
  Widget _buildPc() {
    return PharmaciePcLayout(
      activeRoute: '/Dashboard_Pharmacie',
      breadcrumbKey: 'phar_breadcrumb_dashboard',
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: PharmacieTheme.primary),
            )
          : _error != null
              ? _errorView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: _buildBody(isPc: true),
                ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              size: 60, color: PharmacieTheme.danger),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: PharmacieTheme.danger, fontSize: 16),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: Text('phar_retry'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmacieTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody({bool isPc = false}) {
    final attente = _kpis['en_attente_paiement'] ?? 0;
    final aDelivrer = _kpis['a_delivrer'] ?? 0;
    final ventesTotal = (_kpis['ventes_jour_total'] ?? 0).toDouble();
    final ventesCount = _kpis['ventes_jour_count'] ?? 0;
    final stockBasCount = _kpis['stock_bas'] ?? 0;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isPc) ...[
          Text(
            'phar_dashboard_title'.tr(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: PharmacieTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'phar_dashboard_subtitle'.tr(),
            style: const TextStyle(
              fontSize: 14,
              color: PharmacieTheme.textMuted,
            ),
          ),
          const SizedBox(height: 24),
        ],
        // KPIs
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            final cards = [
              PharmacieKpiCard(
                icon: Icons.schedule,
                label: 'phar_kpi_attente_paiement'.tr(),
                value: '$attente',
                color: PharmacieTheme.warn,
                onTap: () =>
                    context.go('/Dashboard_Pharmacie/Ordonnances'),
              ),
              PharmacieKpiCard(
                icon: Icons.local_shipping_outlined,
                label: 'phar_kpi_a_delivrer'.tr(),
                value: '$aDelivrer',
                color: Colors.blue,
                onTap: () =>
                    context.go('/Dashboard_Pharmacie/Ordonnances'),
              ),
              PharmacieKpiCard(
                icon: Icons.payments_outlined,
                label: 'phar_kpi_ventes_jour'.tr(
                  namedArgs: {'count': '$ventesCount'},
                ),
                value: '${ventesTotal.toStringAsFixed(0)} F',
                color: PharmacieTheme.success,
                onTap: () =>
                    context.go('/Dashboard_Pharmacie/Historique'),
              ),
              PharmacieKpiCard(
                icon: Icons.warning_amber_rounded,
                label: 'phar_kpi_stock_bas'.tr(),
                value: '$stockBasCount',
                color: PharmacieTheme.danger,
                onTap: () =>
                    context.go('/Dashboard_Pharmacie/Catalogue'),
              ),
            ];
            if (isWide) {
              return Row(
                children: cards
                    .map((c) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6),
                            child: c,
                          ),
                        ))
                    .toList(),
              );
            } else {
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
                children: cards,
              );
            }
          },
        ),
        const SizedBox(height: 24),
        // Actions rapides
        Text(
          'phar_quick_actions'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: PharmacieTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        _quickAction(
          icon: Icons.point_of_sale_outlined,
          title: 'phar_qa_vente_libre_title'.tr(),
          subtitle: 'phar_qa_vente_libre_sub'.tr(),
          color: PharmacieTheme.accent,
          onTap: () => context.go('/Dashboard_Pharmacie/VenteLibre'),
        ),
        const SizedBox(height: 10),
        _quickAction(
          icon: Icons.inventory_2_outlined,
          title: 'phar_qa_catalogue_title'.tr(),
          subtitle: 'phar_qa_catalogue_sub'.tr(),
          color: PharmacieTheme.primary,
          onTap: () => context.go('/Dashboard_Pharmacie/Catalogue'),
        ),
        const SizedBox(height: 24),
        // Stock bas (alerte)
        if (_stockBas.isNotEmpty) _buildStockBasSection(),
        const SizedBox(height: 24),
      ],
    );

    if (isPc) return body;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: body,
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PharmacieTheme.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: PharmacieTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: PharmacieTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockBasSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: PharmacieTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: PharmacieTheme.danger,
              ),
              const SizedBox(width: 8),
              Text(
                'phar_stock_bas_title'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: PharmacieTheme.danger,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    context.go('/Dashboard_Pharmacie/Catalogue'),
                child: Text(
                  'phar_view_all'.tr(),
                  style: const TextStyle(
                      color: PharmacieTheme.primary, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._stockBas.take(5).map((m) {
            final stock = (m['stock'] as num?)?.toInt() ?? 0;
            final seuil = (m['seuil_alerte'] as num?)?.toInt() ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      (m['nom_medicament'] ?? '').toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: PharmacieTheme.textDark,
                      ),
                    ),
                  ),
                  Text(
                    'phar_stock_value'.tr(
                      namedArgs: {
                        'stock': '$stock',
                        'seuil': '$seuil',
                      },
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: stock == 0
                          ? PharmacieTheme.danger
                          : PharmacieTheme.warn,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
