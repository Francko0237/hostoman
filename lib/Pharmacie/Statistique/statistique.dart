import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await _service.getStats();
      if (mounted) {
        setState(() {
          _stats = s;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _mobile(),
      pc: _pc(),
    );
  }

  Widget _mobile() {
    return Scaffold(
      backgroundColor: PharmacieTheme.background,
      drawer: const PharmacieDrawer(
          activeRoute: '/Dashboard_Pharmacie/Statistiques'),
      appBar: PharmacieAppBar(
        title: 'phar_stats_title'.tr(),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _body(),
    );
  }

  Widget _pc() {
    return PharmaciePcLayout(
      activeRoute: '/Dashboard_Pharmacie/Statistiques',
      breadcrumbKey: 'phar_breadcrumb_stats',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: _body(isPc: true),
      ),
    );
  }

  Widget _body({bool isPc = false}) {
    if (_loading) {
      return const Center(
        child:
            CircularProgressIndicator(color: PharmacieTheme.primary),
      );
    }

    final totalSemaine = (_stats['total_semaine'] as double?) ?? 0;
    final countSemaine = _stats['count_semaine'] ?? 0;
    final stockBas = _stats['stock_bas'] ?? 0;
    final rupture = _stats['rupture'] ?? 0;
    final totalCat = _stats['total_catalogue'] ?? 0;
    final parJour =
        (_stats['par_jour'] as Map<String, double>?) ?? {};
    final top = (_stats['top_medicaments'] as List<dynamic>?) ?? [];

    final body = Column(
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
        // KPIs
        LayoutBuilder(
          builder: (ctx, c) {
            final isWide = c.maxWidth > 700;
            final cards = [
              PharmacieKpiCard(
                icon: Icons.payments_outlined,
                label: 'phar_stats_kpi_ventes_semaine'.tr(),
                value: '${totalSemaine.toStringAsFixed(0)} F',
                color: PharmacieTheme.success,
              ),
              PharmacieKpiCard(
                icon: Icons.receipt_long_outlined,
                label: 'phar_stats_kpi_count_semaine'.tr(),
                value: '$countSemaine',
                color: PharmacieTheme.primary,
              ),
              PharmacieKpiCard(
                icon: Icons.inventory_2_outlined,
                label: 'phar_stats_kpi_catalogue'.tr(),
                value: '$totalCat',
                color: Colors.blueGrey,
              ),
              PharmacieKpiCard(
                icon: Icons.warning_amber_rounded,
                label: 'phar_stats_kpi_stock_bas'.tr(),
                value: '$stockBas',
                color: PharmacieTheme.warn,
              ),
              PharmacieKpiCard(
                icon: Icons.block,
                label: 'phar_stats_kpi_rupture'.tr(),
                value: '$rupture',
                color: PharmacieTheme.danger,
              ),
            ];
            if (isWide) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: cards
                    .map((c) => SizedBox(width: 200, child: c))
                    .toList(),
              );
            }
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
              children: cards,
            );
          },
        ),
        const SizedBox(height: 24),
        // Graphique simple : ventes par jour
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
          child: _barChart(parJour),
        ),
        const SizedBox(height: 24),
        // Top médicaments
        Text(
          'phar_stats_section_top'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: PharmacieTheme.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PharmacieTheme.border),
          ),
          child: top.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'phar_stats_top_empty'.tr(),
                      style: const TextStyle(
                          color: PharmacieTheme.textMuted),
                    ),
                  ),
                )
              : Column(
                  children: top.asMap().entries.map((e) {
                    final i = e.key;
                    final m = e.value as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: PharmacieTheme.primary
                            .withValues(alpha: 0.12),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: PharmacieTheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      title: Text(
                        (m['nom'] ?? '').toString(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'phar_stats_top_qty'
                            .tr(namedArgs: {'qte': '${m['quantite']}'}),
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Text(
                        'phar_amount_fcfa'.tr(namedArgs: {
                          'amount':
                              (m['ca'] as double).toStringAsFixed(0),
                        }),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: PharmacieTheme.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 30),
      ],
    );

    if (isPc) return body;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: body,
    );
  }

  Widget _barChart(Map<String, double> parJour) {
    final entries = parJour.entries.toList();
    final maxVal = entries.fold<double>(
      0,
      (m, e) => e.value > m ? e.value : m,
    );

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: entries.map((e) {
          final ratio = maxVal == 0 ? 0.0 : e.value / maxVal;
          final parts = e.key.split('-');
          final dayLabel = parts.length == 3 ? parts[2] : '';
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    e.value.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: PharmacieTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    height: 100 * ratio + 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          PharmacieTheme.accent,
                          PharmacieTheme.primary
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: PharmacieTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
