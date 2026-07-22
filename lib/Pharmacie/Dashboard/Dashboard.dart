import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/shared/responsive_wrapper.dart';
import 'package:hostoman/model_unifier.dart';
import '../shared/pharmacie_theme.dart';
import 'dashboard_service.dart';
import '../Ordonnances/ordonnances_service.dart';
import 'profil_service.dart';
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
  final _profilService = PharmacienService(Supabase.instance.client);

  Map<String, dynamic> _kpis = {};
  List<Map<String, dynamic>> _stockBas = [];
  bool _loading = true;
  String? _error;
  String _pharmacienName = '';
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
    await _ordoService.annulerPerimees();
    await _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _kpiService.getKpis(),
        _medService.getStockBas(),
        _profilService.fetchPharmacienConnecte(),
      ]);
      final kpis = results[0] as Map<String, dynamic>;
      final stockBas = results[1] as List<Map<String, dynamic>>;
      final pharmacien = results[2] as Medecin?;
      if (mounted) {
        setState(() {
          _kpis = kpis;
          _stockBas = stockBas;
          if (pharmacien != null) {
            _pharmacienName = '${pharmacien.prenom ?? ''} ${pharmacien.nom}'
                .trim();
          }
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
    return ResponsiveLayout(mobile: _buildMobile(), pc: _buildPc());
  }

  // ========== MOBILE — design selon maquette ==========
  Widget _buildMobile() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.medication_rounded,
              color: PharmacieTheme.primary,
              size: 24,
            ),
          ),
        ),
        title: Text(
          _pharmacienName.isNotEmpty
              ? 'phar_dash_greeting'.tr(namedArgs: {'name': _pharmacienName})
              : 'phar_dash_loading_name'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: PharmacieTheme.textDark,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: PharmacieTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(
                Icons.person_rounded,
                color: PharmacieTheme.primary,
              ),
              color: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) async {
                if (value == 'profile') {
                  context.go('/Dashboard_Pharmacie/Profil');
                } else if (value == 'parametres') {
                  context.go('/Dashboard_Pharmacie/Parametres');
                } else if (value == 'deconnexion') {
                  try {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) context.go('/Authen_Personnel');
                  } catch (_) {}
                }
              },
              itemBuilder: (ctx) => [
                _popupItem(
                  value: 'profile',
                  icon: Icons.person_outline_rounded,
                  label: 'phar_nav_profil'.tr(),
                  color: PharmacieTheme.primary,
                ),
                _popupItem(
                  value: 'parametres',
                  icon: Icons.settings_outlined,
                  label: 'phar_nav_parametres'.tr(),
                  color: PharmacieTheme.primary,
                ),
                _popupItem(
                  value: 'deconnexion',
                  icon: Icons.logout_rounded,
                  label: 'phar_menu_logout'.tr(),
                  color: PharmacieTheme.danger,
                ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: PharmacieTheme.primary),
            )
          : _error != null
          ? _errorView()
          : _buildMobileBody(),
    );
  }

  PopupMenuItem<String> _popupItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBody() {
    final ventesTotal = (_kpis['ventes_jour_total'] ?? 0).toDouble();
    final stockBasCount = _kpis['stock_bas'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Bannière ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
              color: PharmacieTheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                'phar_dashboard_title'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── KPIs ──
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  icon: Icons.attach_money_rounded,
                  iconColor: PharmacieTheme.primary,
                  value: '${ventesTotal.toStringAsFixed(0)} XAF',
                  label: 'phar_kpi_vente_jour_simple'.tr(),
                  valueColor: PharmacieTheme.textDark,
                  onTap: () => context.go('/Dashboard_Pharmacie/Historique'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _kpiCard(
                  icon: Icons.warning_rounded,
                  iconColor: PharmacieTheme.danger,
                  value: '$stockBasCount',
                  label: 'phar_kpi_stock_bas'.tr(),
                  valueColor: PharmacieTheme.danger,
                  onTap: () => context.go('/Dashboard_Pharmacie/Catalogue'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Actions (2 colonnes) ──
          Row(
            children: [
              Expanded(
                child: _actionCard(
                  icon: Icons.point_of_sale_rounded,
                  label: 'phar_action_nouvelle_vente'.tr(),
                  onTap: () => context.go('/Dashboard_Pharmacie/VenteLibre'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionCard(
                  icon: Icons.history_rounded,
                  label: 'phar_action_historique_ventes'.tr(),
                  onTap: () => context.go('/Dashboard_Pharmacie/Historique'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Action pleine largeur ──
          _actionCard(
            icon: Icons.calendar_month_rounded,
            label: 'phar_nav_stats'.tr(),
            onTap: () => context.go('/Dashboard_Pharmacie/Statistiques'),
            fullWidth: true,
          ),

          const SizedBox(height: 32),

          // ── Footer ──
          Center(
            child: Text(
              'fiche_footer'.tr(),
              style: const TextStyle(
                fontSize: 12,
                color: PharmacieTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required Color valueColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PharmacieTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: PharmacieTheme.textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return Material(
      color: const Color(0xFFEEEEEE),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: fullWidth ? 110 : 130,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: PharmacieTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: PharmacieTheme.primary, size: 34),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: PharmacieTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== PC — sidebar + grille complète ==========
  Widget _buildPc() {
    return PharmaciePcLayout(
      activeRoute: '/Dashboard_Pharmacie',
      breadcrumbKey: 'phar_breadcrumb_dashboard',
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: PharmacieTheme.primary),
            )
          : _error != null
          ? _errorView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: _buildPcBody(),
            ),
    );
  }

  Widget _buildPcBody() {
    final attente = _kpis['en_attente_paiement'] ?? 0;
    final aDelivrer = _kpis['a_delivrer'] ?? 0;
    final ventesTotal = (_kpis['ventes_jour_total'] ?? 0).toDouble();
    final ventesCount = _kpis['ventes_jour_count'] ?? 0;
    final stockBasCount = _kpis['stock_bas'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          style: const TextStyle(fontSize: 14, color: PharmacieTheme.textMuted),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: PharmacieKpiCard(
                  icon: Icons.schedule,
                  label: 'phar_kpi_attente_paiement'.tr(),
                  value: '$attente',
                  color: PharmacieTheme.warn,
                  onTap: () => context.go('/Dashboard_Pharmacie/Ordonnances'),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: PharmacieKpiCard(
                  icon: Icons.local_shipping_outlined,
                  label: 'phar_kpi_a_delivrer'.tr(),
                  value: '$aDelivrer',
                  color: Colors.blue,
                  onTap: () => context.go('/Dashboard_Pharmacie/Ordonnances'),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: PharmacieKpiCard(
                  icon: Icons.payments_outlined,
                  label: 'phar_kpi_ventes_jour'.tr(
                    namedArgs: {'count': '$ventesCount'},
                  ),
                  value: '${ventesTotal.toStringAsFixed(0)} F',
                  color: PharmacieTheme.success,
                  onTap: () => context.go('/Dashboard_Pharmacie/Historique'),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: PharmacieKpiCard(
                  icon: Icons.warning_amber_rounded,
                  label: 'phar_kpi_stock_bas'.tr(),
                  value: '$stockBasCount',
                  color: PharmacieTheme.danger,
                  onTap: () => context.go('/Dashboard_Pharmacie/Catalogue'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'phar_quick_actions'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: PharmacieTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        _pcQuickAction(
          icon: Icons.point_of_sale_outlined,
          title: 'phar_qa_vente_libre_title'.tr(),
          subtitle: 'phar_qa_vente_libre_sub'.tr(),
          color: PharmacieTheme.accent,
          onTap: () => context.go('/Dashboard_Pharmacie/VenteLibre'),
        ),
        const SizedBox(height: 10),
        _pcQuickAction(
          icon: Icons.inventory_2_outlined,
          title: 'phar_qa_catalogue_title'.tr(),
          subtitle: 'phar_qa_catalogue_sub'.tr(),
          color: PharmacieTheme.primary,
          onTap: () => context.go('/Dashboard_Pharmacie/Catalogue'),
        ),
        const SizedBox(height: 24),
        if (_stockBas.isNotEmpty) _buildStockBasSection(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _pcQuickAction({
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
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
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
        border: Border.all(color: PharmacieTheme.danger.withValues(alpha: 0.3)),
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
                onPressed: () => context.go('/Dashboard_Pharmacie/Catalogue'),
                child: Text(
                  'phar_view_all'.tr(),
                  style: const TextStyle(
                    color: PharmacieTheme.primary,
                    fontSize: 12,
                  ),
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
                      namedArgs: {'stock': '$stock', 'seuil': '$seuil'},
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

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: PharmacieTheme.danger,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PharmacieTheme.danger,
                fontSize: 16,
              ),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
