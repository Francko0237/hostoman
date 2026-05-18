import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'stats_service.dart';
import 'stats_pdf_generator.dart';

// Palette du module Directeur
const Color dirPrimaryColor = Color(0xFF1A237E);
const Color dirAccentColor = Color(0xFFFFD700);

class stats_view extends StatefulWidget {
  const stats_view({super.key});

  @override
  State<stats_view> createState() => _stats_viewState();
}

class _stats_viewState extends State<stats_view>
    with SingleTickerProviderStateMixin {
  final StatsService _service = StatsService(Supabase.instance.client);
  late TabController _tabController;

  Map<String, dynamic> globalStats = {
    'revenu': 0.0,
    'patients': 0,
    'consultations': 0,
  };
  List<Map<String, dynamic>> dailyActivity = [];
  Map<String, dynamic> demographics = {
    'gender': {'M': 0, 'F': 0},
    'ageRanges': {'0-18': 0, '19-35': 0, '36-60': 0, '60+': 0},
  };
  Map<String, int> operationalStats = {
    'terminer': 0,
    'en attente': 0,
    'annuler': 0,
  };
  List<Map<String, dynamic>> revenueTrend = [];
  bool isLoading = true;
  bool _overviewLoading = false;

  // Période pour la Vue Générale (7 derniers jours par défaut)
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  // KPIs filtrés par période (Vue Générale)
  double _periodRevenu = 0;
  int _periodPatients = 0;
  int _periodConsultations = 0;

  // Finance: période et données séparées
  late DateTime _finStart;
  late DateTime _finEnd;
  bool _financeLoading = false;
  Map<String, dynamic> _financeData = {
    'totalRevenu': 0.0,
    'nbPaiements': 0,
    'moyennePaiement': 0.0,
    'maxPaiement': 0.0,
    'minPaiement': 0.0,
    'revenuMoyenJour': 0.0,
    'nbEnAttente': 0,
    'montantEnAttente': 0.0,
    'meilleurJour': {'date': '-', 'montant': 0.0},
    'dailyTrend': <Map<String, dynamic>>[],
  };

  Locale? _lastLocale;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Lazy-load les onglets quand l'utilisateur les ouvre la 1re fois
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      switch (_tabController.index) {
        case 1:
          _ensureFinanceLoaded();
          break;
        case 2:
          _ensurePatientsLoaded();
          break;
      }
    });
    final today = DateTime.now();
    _rangeEnd = DateTime(today.year, today.month, today.day);
    _rangeStart = _rangeEnd.subtract(const Duration(days: 6));
    // Finance: 7 derniers jours par défaut aussi
    _finEnd = _rangeEnd;
    _finStart = _rangeStart;
    // Ne pas appeler _loadData ici: il lit context.locale (InheritedWidget)
    // ce qui n'est pas safe dans initState. On le fait dans didChangeDependencies.
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = context.locale;
    if (_lastLocale == null) {
      // Premier appel: chargement initial
      _lastLocale = current;
      _loadData();
    } else if (_lastLocale != current) {
      // La langue a changé -> recharger l'onglet actif et invalider les autres
      _lastLocale = current;
      _financeLoaded = false;
      _patientsLoaded = false;
      _loadData();
      // Si l'utilisateur est actuellement sur Finance ou Patients,
      // recharger immédiatement.
      if (_tabController.index == 1) {
        _ensureFinanceLoaded();
      } else if (_tabController.index == 2) {
        _ensurePatientsLoaded();
      }
    }
  }

  String _localeTag(BuildContext context) {
    final l = context.locale;
    final cc = l.countryCode != null && l.countryCode!.isNotEmpty
        ? '_${l.countryCode}'
        : '';
    return '${l.languageCode}$cc';
  }

  // Drapeaux de chargement par onglet (lazy load).
  // Au démarrage on ne charge QUE l'onglet Vue Générale ; les autres sont
  // chargés à la demande lors du premier tap sur le tab.
  bool _financeLoaded = false;
  bool _patientsLoaded = false;

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    final tag = _localeTag(context);

    // Charger en parallèle uniquement ce qui est nécessaire pour l'onglet
    // initial (Vue Générale).
    final results = await Future.wait([
      _service.getOverviewForRange(
        start: _rangeStart,
        end: _rangeEnd,
        localeTag: tag,
      ),
      _service.getGlobalStats(),
    ]);
    final overview = results[0];
    final stats = results[1];

    if (!mounted) return;
    setState(() {
      globalStats = stats;
      _periodRevenu = (overview['revenu'] as num).toDouble();
      _periodPatients = overview['patients'] as int;
      _periodConsultations = overview['consultations'] as int;
      dailyActivity = List<Map<String, dynamic>>.from(
        overview['dailyActivity'] as List,
      );
      operationalStats = Map<String, int>.from(
        overview['operationalStats'] as Map,
      );
      isLoading = false;
    });
  }

  /// Chargé uniquement la 1re fois que l'utilisateur ouvre l'onglet Finance.
  Future<void> _ensureFinanceLoaded() async {
    if (_financeLoaded || !mounted) return;
    _financeLoaded = true;
    await _reloadFinance();
  }

  /// Chargé uniquement la 1re fois que l'utilisateur ouvre l'onglet Patients.
  Future<void> _ensurePatientsLoaded() async {
    if (_patientsLoaded || !mounted) return;
    _patientsLoaded = true;
    final results = await Future.wait([
      _service.getDemographics(),
      _service.getRevenueTrend(),
    ]);
    if (!mounted) return;
    setState(() {
      demographics = results[0] as Map<String, dynamic>;
      revenueTrend = (results[1] as List).cast<Map<String, dynamic>>();
    });
  }

  Future<void> _reloadFinance() async {
    if (!mounted) return;
    setState(() => _financeLoading = true);
    final tag = _localeTag(context);
    final finance = await _service.getFinanceForRange(
      start: _finStart,
      end: _finEnd,
      localeTag: tag,
    );
    if (mounted) {
      setState(() {
        _financeData = finance;
        _financeLoading = false;
      });
    }
  }

  Future<void> _pickFinanceRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(start: _finStart, end: _finEnd),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF16A34A),
            onPrimary: Colors.white,
            onSurface: Color(0xFF0F172A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _finStart = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        );
        _finEnd = DateTime(picked.end.year, picked.end.month, picked.end.day);
      });
      await _reloadFinance();
    }
  }

  void _resetFinanceTo7Days() {
    final today = DateTime.now();
    setState(() {
      _finEnd = DateTime(today.year, today.month, today.day);
      _finStart = _finEnd.subtract(const Duration(days: 6));
    });
    _reloadFinance();
  }

  // ===== EXPORT PDF =====
  Future<void> _showExportDialog() async {
    final tabIndex = _tabController.index;
    final defaultType = tabIndex == 0
        ? StatsExportType.overview
        : tabIndex == 1
        ? StatsExportType.finance
        : StatsExportType.patients;

    StatsExportType selected = defaultType;
    final result = await showDialog<StatsExportType>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: dirPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: dirPrimaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'export_dialog_title'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'export_dialog_subtitle'.tr(),
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              _exportRadioTile(
                value: StatsExportType.overview,
                groupValue: selected,
                onChanged: (v) => setDlg(() => selected = v!),
                icon: Icons.dashboard_rounded,
                color: dirPrimaryColor,
                label: 'stats_tab_overview'.tr(),
                subtitle: 'export_overview_desc'.tr(),
              ),
              _exportRadioTile(
                value: StatsExportType.finance,
                groupValue: selected,
                onChanged: (v) => setDlg(() => selected = v!),
                icon: Icons.monetization_on_rounded,
                color: const Color(0xFF16A34A),
                label: 'stats_tab_finance'.tr(),
                subtitle: 'export_finance_desc'.tr(),
              ),
              _exportRadioTile(
                value: StatsExportType.patients,
                groupValue: selected,
                onChanged: (v) => setDlg(() => selected = v!),
                icon: Icons.people_rounded,
                color: const Color(0xFFEC4899),
                label: 'stats_tab_patients'.tr(),
                subtitle: 'export_patients_desc'.tr(),
              ),
              const Divider(height: 24),
              _exportRadioTile(
                value: StatsExportType.full,
                groupValue: selected,
                onChanged: (v) => setDlg(() => selected = v!),
                icon: Icons.summarize_rounded,
                color: const Color(0xFF7C3AED),
                label: 'export_full'.tr(),
                subtitle: 'export_full_desc'.tr(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, selected),
              icon: const Icon(Icons.print_rounded, size: 16),
              label: Text('export_generate'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: dirPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
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
    );

    if (result == null || !mounted) return;
    await _generatePdf(result);
  }

  Widget _exportRadioTile({
    required StatsExportType value,
    required StatsExportType groupValue,
    required ValueChanged<StatsExportType?> onChanged,
    required IconData icon,
    required Color color,
    required String label,
    required String subtitle,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Radio<StatsExportType>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePdf(StatsExportType type) async {
    // Indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: dirPrimaryColor),
      ),
    );

    try {
      // Pour les sections demandées, on utilise la période active de l'onglet
      // ou la période de la Vue Générale par défaut.
      final tag = _localeTag(context);
      Map<String, dynamic>? overview;
      Map<String, dynamic>? finance;
      Map<String, dynamic>? patients;
      DateTime periodStart = _rangeStart;
      DateTime periodEnd = _rangeEnd;

      if (type == StatsExportType.overview || type == StatsExportType.full) {
        overview = await _service.getOverviewForRange(
          start: _rangeStart,
          end: _rangeEnd,
          localeTag: tag,
        );
      }
      if (type == StatsExportType.finance || type == StatsExportType.full) {
        finance = await _service.getFinanceForRange(
          start: _finStart,
          end: _finEnd,
          localeTag: tag,
        );
        // Pour Finance seul, utilise sa propre période
        if (type == StatsExportType.finance) {
          periodStart = _finStart;
          periodEnd = _finEnd;
        }
      }
      if (type == StatsExportType.patients || type == StatsExportType.full) {
        patients = await _service.getDemographics();
      }

      if (!mounted) return;
      Navigator.pop(context); // ferme le loader

      await StatsPdfGenerator.previewAndPrint(
        context: context,
        type: type,
        periodStart: periodStart,
        periodEnd: periodEnd,
        locale: context.locale,
        overviewData: overview,
        financeData: finance,
        patientsData: patients,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'export_error'.tr()}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reloadOverview() async {
    if (!mounted) return;
    setState(() => _overviewLoading = true);
    final tag = _localeTag(context);
    final overview = await _service.getOverviewForRange(
      start: _rangeStart,
      end: _rangeEnd,
      localeTag: tag,
    );
    if (mounted) {
      setState(() {
        _periodRevenu = (overview['revenu'] as num).toDouble();
        _periodPatients = overview['patients'] as int;
        _periodConsultations = overview['consultations'] as int;
        dailyActivity = List<Map<String, dynamic>>.from(
          overview['dailyActivity'] as List,
        );
        operationalStats = Map<String, int>.from(
          overview['operationalStats'] as Map,
        );
        _overviewLoading = false;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(start: _rangeStart, end: _rangeEnd),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: dirPrimaryColor,
            onPrimary: Colors.white,
            onSurface: Color(0xFF0F172A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _rangeStart = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        );
        _rangeEnd = DateTime(picked.end.year, picked.end.month, picked.end.day);
      });
      await _reloadOverview();
    }
  }

  void _resetRangeTo7Days() {
    final today = DateTime.now();
    setState(() {
      _rangeEnd = DateTime(today.year, today.month, today.day);
      _rangeStart = _rangeEnd.subtract(const Duration(days: 6));
    });
    _reloadOverview();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: dirPrimaryColor),
      );
    }

    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        // ===== TAB BAR STYLÉE + BOUTON EXPORT =====
        Container(
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  labelColor: dirPrimaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: dirPrimaryColor,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(
                      text: 'stats_tab_overview'.tr(),
                      icon: const Icon(Icons.dashboard_rounded, size: 18),
                    ),
                    Tab(
                      text: 'stats_tab_finance'.tr(),
                      icon: const Icon(Icons.monetization_on_rounded, size: 18),
                    ),
                    Tab(
                      text: 'stats_tab_patients'.tr(),
                      icon: const Icon(Icons.people_rounded, size: 18),
                    ),
                  ],
                ),
              ),
              // Bouton Export PDF
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Tooltip(
                  message: 'export_print'.tr(),
                  child: ElevatedButton.icon(
                    onPressed: _showExportDialog,
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: Text(
                      'export'.tr(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dirPrimaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(isDesktop),
              _buildFinanceTab(isDesktop),
              _buildPatientsTab(isDesktop),
            ],
          ),
        ),
      ],
    );
  }

  // =========== VUE GÉNÉRALE ===========
  Widget _buildOverviewTab(bool isDesktop) {
    final revenu = _periodRevenu;
    final patients = _periodPatients;
    final consultations = _periodConsultations;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 1100 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bandeau de sélection de période
              _periodHeader(),
              const SizedBox(height: 16),
              if (_overviewLoading)
                const LinearProgressIndicator(
                  color: dirPrimaryColor,
                  backgroundColor: Color(0xFFE2E8F0),
                  minHeight: 2,
                ),
              if (_overviewLoading) const SizedBox(height: 12),
              // Cartes KPI (filtrées par période)
              isDesktop
                  ? Row(
                      children: [
                        Expanded(
                          child: _kpiCard(
                            title: 'stats_total_revenue'.tr(),
                            subtitle: 'stats_kpi_period'.tr(),
                            value:
                                '${NumberFormat('#,###', 'fr_FR').format(revenu)} FCFA',
                            icon: Icons.account_balance_wallet_rounded,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _kpiCard(
                            title: 'stats_total_patients'.tr(),
                            subtitle: 'stats_kpi_period_patients'.tr(),
                            value: '$patients',
                            icon: Icons.person_rounded,
                            color: dirPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _kpiCard(
                            title: 'stats_consultations'.tr(),
                            subtitle: 'stats_kpi_period_consultations'.tr(),
                            value: '$consultations',
                            icon: Icons.assignment_rounded,
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _kpiCard(
                          title: 'stats_total_revenue'.tr(),
                          subtitle: 'stats_kpi_period'.tr(),
                          value:
                              '${NumberFormat('#,###', 'fr_FR').format(revenu)} FCFA',
                          icon: Icons.account_balance_wallet_rounded,
                          color: const Color(0xFF16A34A),
                        ),
                        const SizedBox(height: 12),
                        _kpiCard(
                          title: 'stats_total_patients'.tr(),
                          subtitle: 'stats_kpi_period_patients'.tr(),
                          value: '$patients',
                          icon: Icons.person_rounded,
                          color: dirPrimaryColor,
                        ),
                        const SizedBox(height: 12),
                        _kpiCard(
                          title: 'stats_consultations'.tr(),
                          subtitle: 'stats_kpi_period_consultations'.tr(),
                          value: '$consultations',
                          icon: Icons.assignment_rounded,
                          color: const Color(0xFF0284C7),
                        ),
                      ],
                    ),
              const SizedBox(height: 24),

              // Graphe activité sur la période sélectionnée
              _activityCardSection(),
              const SizedBox(height: 20),

              // Statut des opérations
              _cardSection(
                title: 'stats_operations_status'.tr(),
                icon: Icons.check_circle_rounded,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statPill(
                      'stats_finished'.tr(),
                      operationalStats['terminer'] ?? 0,
                      const Color(0xFF16A34A),
                    ),
                    _statPill(
                      'stats_ongoing'.tr(),
                      operationalStats['en attente'] ?? 0,
                      const Color(0xFFF59E0B),
                    ),
                    _statPill(
                      'stats_cancelled'.tr(),
                      operationalStats['annuler'] ?? 0,
                      const Color(0xFFDC2626),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========== FINANCES ===========
  Widget _buildFinanceTab(bool isDesktop) {
    final totalRevenu = (_financeData['totalRevenu'] as num).toDouble();
    final nbPaiements = _financeData['nbPaiements'] as int;
    final moyennePaiement = (_financeData['moyennePaiement'] as num).toDouble();
    final maxPaiement = (_financeData['maxPaiement'] as num).toDouble();
    final minPaiement = (_financeData['minPaiement'] as num).toDouble();
    final revenuMoyenJour = (_financeData['revenuMoyenJour'] as num).toDouble();
    final nbEnAttente = _financeData['nbEnAttente'] as int;
    final montantEnAttente = (_financeData['montantEnAttente'] as num)
        .toDouble();
    final meilleurJour = _financeData['meilleurJour'] as Map;
    final meilleurDate = meilleurJour['date']?.toString() ?? '-';
    final meilleurMontant = (meilleurJour['montant'] as num).toDouble();

    final f = NumberFormat('#,###', 'fr_FR');
    String fmt(num v) => '${f.format(v.round())} FCFA';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 1100 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sélecteur de période finance
              _financePeriodHeader(),
              const SizedBox(height: 16),
              if (_financeLoading)
                const LinearProgressIndicator(
                  color: Color(0xFF16A34A),
                  backgroundColor: Color(0xFFE2E8F0),
                  minHeight: 2,
                ),
              if (_financeLoading) const SizedBox(height: 12),

              // Carte principale : Revenu total
              _financeHeroCard(totalRevenu, nbPaiements),
              const SizedBox(height: 16),

              // Grille KPI détaillés
              _financeKpiGrid(isDesktop, [
                _FinKpi(
                  label: 'fin_avg_payment'.tr(),
                  value: fmt(moyennePaiement),
                  icon: Icons.show_chart_rounded,
                  color: const Color(0xFF0284C7),
                ),
                _FinKpi(
                  label: 'fin_avg_daily'.tr(),
                  value: fmt(revenuMoyenJour),
                  icon: Icons.calendar_today_rounded,
                  color: const Color(0xFF7C3AED),
                ),
                _FinKpi(
                  label: 'fin_max_payment'.tr(),
                  value: fmt(maxPaiement),
                  icon: Icons.arrow_upward_rounded,
                  color: const Color(0xFF16A34A),
                ),
                _FinKpi(
                  label: 'fin_min_payment'.tr(),
                  value: fmt(minPaiement),
                  icon: Icons.arrow_downward_rounded,
                  color: const Color(0xFFEA580C),
                ),
                _FinKpi(
                  label: 'fin_best_day'.tr(),
                  value: fmt(meilleurMontant),
                  hint: meilleurDate,
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFFD97706),
                ),
                _FinKpi(
                  label: 'fin_pending'.tr(),
                  value: fmt(montantEnAttente),
                  hint: '$nbEnAttente ${'fin_pending_count'.tr()}',
                  icon: Icons.hourglass_top_rounded,
                  color: const Color(0xFFDC2626),
                ),
              ]),

              const SizedBox(height: 20),
              // Graphe revenus
              _financeChartCard(),
            ],
          ),
        ),
      ),
    );
  }

  /// Bandeau date picker spécifique à la Finance (couleur verte)
  Widget _financePeriodHeader() {
    final fmt = DateFormat('dd MMM yyyy', _localeTag(context));
    final daysCount = _finEnd.difference(_finStart).inDays + 1;
    final label = '${fmt.format(_finStart)}  →  ${fmt.format(_finEnd)}';
    const finColor = Color(0xFF16A34A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: finColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: finColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: finColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'stats_period_label'.tr(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: finColor,
                  ),
                ),
                Text(
                  '$daysCount ${'stats_period_days'.tr()}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'stats_period_reset'.tr(),
            onPressed: _financeLoading ? null : _resetFinanceTo7Days,
            icon: const Icon(
              Icons.restart_alt_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _financeLoading ? null : _pickFinanceRange,
            icon: const Icon(Icons.edit_calendar_rounded, size: 16),
            label: Text('stats_period_change'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: finColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Carte principale revenu total (look hero)
  Widget _financeHeroCard(double totalRevenu, int nbPaiements) {
    final f = NumberFormat('#,###', 'fr_FR');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16A34A), Color(0xFF22C55E), Color(0xFF4ADE80)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'fin_total_revenue_period'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${f.format(totalRevenu.round())} FCFA',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$nbPaiements ${'fin_payments'.tr()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Grille responsive des KPI finance détaillés
  Widget _financeKpiGrid(bool isDesktop, List<_FinKpi> kpis) {
    final crossAxisCount = isDesktop ? 3 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isDesktop ? 2.2 : 1.7,
      ),
      itemCount: kpis.length,
      itemBuilder: (_, i) => _financeKpiCard(kpis[i]),
    );
  }

  Widget _financeKpiCard(_FinKpi k) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: k.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(k.icon, color: k.color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  k.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  k.value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              if (k.hint != null) ...[
                const SizedBox(height: 2),
                Text(
                  k.hint!,
                  style: TextStyle(
                    fontSize: 10,
                    color: k.color,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Carte avec le graphe d'évolution du revenu sur la période
  Widget _financeChartCard() {
    final trend = List<Map<String, dynamic>>.from(
      _financeData['dailyTrend'] as List,
    );
    String rangeLabel = '';
    if (trend.isNotEmpty) {
      rangeLabel =
          '${trend.first['date']?.toString() ?? ''} → ${trend.last['date']?.toString() ?? ''}';
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                size: 18,
                color: Color(0xFF16A34A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'fin_revenue_evolution'.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    if (rangeLabel.isNotEmpty)
                      Text(
                        rangeLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: trend.isEmpty
                ? Center(
                    child: Text(
                      'stats_no_data'.tr(),
                      style: const TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  )
                : RepaintBoundary(
                    child: BarChart(_buildRevenueBarChart(trend)),
                  ),
          ),
        ],
      ),
    );
  }

  // =========== PATIENTS ===========
  Widget _buildPatientsTab(bool isDesktop) {
    final gender = demographics['gender'] as Map<String, dynamic>;
    final ageRanges = demographics['ageRanges'] as Map<String, dynamic>;
    final totalM = (gender['M'] as int?) ?? 0;
    final totalF = (gender['F'] as int?) ?? 0;
    final total = totalM + totalF;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 1100 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _cardSection(
                            title: 'stats_gender_dist'.tr(),
                            icon: Icons.wc_rounded,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 180,
                                  child: RepaintBoundary(
                                    child: PieChart(
                                      _buildGenderPieChart(totalM, totalF),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _legend(
                                      '${'stats_men'.tr()} ($totalM)',
                                      const Color(0xFF2563EB),
                                    ),
                                    const SizedBox(width: 20),
                                    _legend(
                                      '${'stats_women'.tr()} ($totalF)',
                                      const Color(0xFFEC4899),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _cardSection(
                            title: 'stats_age_dist'.tr(),
                            icon: Icons.cake_rounded,
                            child: Column(
                              children: _buildAgeRows(ageRanges, total),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _cardSection(
                          title: 'stats_gender_dist'.tr(),
                          icon: Icons.wc_rounded,
                          child: Column(
                            children: [
                              SizedBox(
                                height: 180,
                                child: RepaintBoundary(
                                  child: PieChart(
                                    _buildGenderPieChart(totalM, totalF),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _legend(
                                    '${'stats_men'.tr()} ($totalM)',
                                    const Color(0xFF2563EB),
                                  ),
                                  const SizedBox(width: 20),
                                  _legend(
                                    '${'stats_women'.tr()} ($totalF)',
                                    const Color(0xFFEC4899),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _cardSection(
                          title: 'stats_age_dist'.tr(),
                          icon: Icons.cake_rounded,
                          child: Column(
                            children: _buildAgeRows(ageRanges, total),
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

  // =========== WIDGET FACTORIES ===========

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bandeau d'en-tête avec sélecteur de période manuel
  Widget _periodHeader() {
    final fmt = DateFormat('dd MMM yyyy', _localeTag(context));
    final daysCount = _rangeEnd.difference(_rangeStart).inDays + 1;
    final label = '${fmt.format(_rangeStart)}  →  ${fmt.format(_rangeEnd)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: dirPrimaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dirPrimaryColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            color: dirPrimaryColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'stats_period_label'.tr(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: dirPrimaryColor,
                  ),
                ),
                Text(
                  '$daysCount ${'stats_period_days'.tr()}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'stats_period_reset'.tr(),
            onPressed: _overviewLoading ? null : _resetRangeTo7Days,
            icon: const Icon(
              Icons.restart_alt_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _overviewLoading ? null : _pickDateRange,
            icon: const Icon(Icons.edit_calendar_rounded, size: 16),
            label: Text('stats_period_change'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: dirPrimaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section graphe d'activité sur la période sélectionnée
  Widget _activityCardSection() {
    String rangeLabel = '';
    if (dailyActivity.isNotEmpty) {
      final first = dailyActivity.first['fullDate']?.toString() ?? '';
      final last = dailyActivity.last['fullDate']?.toString() ?? '';
      rangeLabel = '$first → $last';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                size: 18,
                color: dirPrimaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'stats_activity_period'.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: dirPrimaryColor,
                      ),
                    ),
                    if (rangeLabel.isNotEmpty)
                      Text(
                        rangeLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: dailyActivity.isEmpty
                ? Center(
                    child: Text(
                      'stats_no_data'.tr(),
                      style: const TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  )
                : RepaintBoundary(child: LineChart(_buildActivityLineChart())),
          ),
        ],
      ),
    );
  }

  Widget _cardSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: dirPrimaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: dirPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _statPill(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  List<Widget> _buildAgeRows(Map<String, dynamic> ageRanges, int total) {
    final colors = [
      dirPrimaryColor,
      const Color(0xFF0284C7),
      const Color(0xFF16A34A),
      const Color(0xFFF59E0B),
    ];
    int idx = 0;
    return ageRanges.entries.map((e) {
      final color = colors[idx % colors.length];
      idx++;
      final v = (e.value as int?) ?? 0;
      final percent = total > 0 ? v / total : 0.0;
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${e.key} ${'stats_years'.tr()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '$v ${'stats_patients_count'.tr()} (${(percent * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // =========== CHARTS ===========

  LineChartData _buildActivityLineChart() {
    // Etiquettes X adaptatives selon la longueur
    final n = dailyActivity.length;
    final labelStep = n > 21
        ? 4
        : n > 14
        ? 3
        : n > 7
        ? 2
        : 1;

    // Couleur d'accent pour le gradient de la courbe
    const accent = Color(0xFF8B5CF6); // violet doux complementaire
    final gradientColors = [dirPrimaryColor, accent];

    // Calcul du max Y pour des graduations propres
    final maxCount = dailyActivity.isEmpty
        ? 0
        : dailyActivity
              .map((e) => e['count'] as int)
              .reduce((a, b) => a > b ? a : b);
    // Marge superieure de 25% et arrondi a un palier propre
    double computedMax = (maxCount * 1.25).ceilToDouble();
    if (computedMax < 4) computedMax = 4;
    // Intervalle Y propre (4 graduations)
    final yInterval =
        (computedMax / 4).ceilToDouble().clamp(1, double.infinity) as double;
    final maxY = yInterval * 4;

    return LineChartData(
      minY: 0,
      maxY: maxY,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: yInterval,
        getDrawingHorizontalLine: (_) => FlLine(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
          strokeWidth: 1,
          dashArray: const [4, 4],
        ),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        enabled: true,
        handleBuiltInTouches: true,
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: dirPrimaryColor.withValues(alpha: 0.25),
                strokeWidth: 1.5,
                dashArray: const [3, 3],
              ),
              FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 6,
                  color: dirPrimaryColor,
                  strokeWidth: 3,
                  strokeColor: Colors.white,
                ),
              ),
            );
          }).toList();
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF0F172A),
          tooltipBorderRadius: BorderRadius.circular(10),
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          tooltipMargin: 12,
          getTooltipItems: (spots) => spots.map((s) {
            final i = s.x.toInt();
            final fullDate = (i >= 0 && i < dailyActivity.length)
                ? (dailyActivity[i]['fullDate']?.toString() ??
                      dailyActivity[i]['day'].toString())
                : '';
            final count = s.y.toInt();
            return LineTooltipItem(
              '',
              const TextStyle(color: Colors.white),
              children: [
                TextSpan(
                  text: '$fullDate\n',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                    letterSpacing: 0.3,
                  ),
                ),
                TextSpan(
                  text: '$count ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: 'stats_patients_count'.tr(),
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            interval: yInterval,
            getTitlesWidget: (v, _) {
              if (v < 0 || v > maxY) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  v.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 1,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= dailyActivity.length) {
                return const SizedBox.shrink();
              }
              // Toujours afficher la premiere et derniere etiquette
              final isEdge = i == 0 || i == dailyActivity.length - 1;
              if (!isEdge && i % labelStep != 0) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  dailyActivity[i]['day'],
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: dailyActivity
              .asMap()
              .entries
              .map(
                (e) => FlSpot(
                  e.key.toDouble(),
                  (e.value['count'] as int).toDouble(),
                ),
              )
              .toList(),
          isCurved: true,
          curveSmoothness: 0.35,
          preventCurveOverShooting: true,
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          barWidth: 2.5,
          isStrokeCapRound: true,
          isStrokeJoinRound: true,
          shadow: const Shadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
          // Points discrets : visibles uniquement aux extremites et sur les pics
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, _) {
              if (dailyActivity.isEmpty) return false;
              final idx = spot.x.toInt();
              final isFirst = idx == 0;
              final isLast = idx == dailyActivity.length - 1;
              final isMax = spot.y == maxCount.toDouble() && maxCount > 0;
              // Pour <=7 jours, montrer tous les points
              if (n <= 7) return true;
              return isFirst || isLast || isMax;
            },
            getDotPainter: (spot, __, ___, ____) {
              final isMax = spot.y == maxCount.toDouble() && maxCount > 0;
              return FlDotCirclePainter(
                radius: isMax ? 4.5 : 3.5,
                color: Colors.white,
                strokeWidth: 2.5,
                strokeColor: isMax ? accent : dirPrimaryColor,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                dirPrimaryColor.withValues(alpha: 0.18),
                accent.withValues(alpha: 0.08),
                dirPrimaryColor.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  String _formatCompact(num value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  BarChartData _buildRevenueBarChart([List<Map<String, dynamic>>? data]) {
    final trend = data ?? revenueTrend;
    final n = trend.length;
    final labelStep = n > 21
        ? 4
        : n > 14
        ? 3
        : n > 7
        ? 2
        : 1;

    // Calcul maxY propre avec marge
    double maxVal = 0;
    for (final e in trend) {
      final v = (e['amount'] as num).toDouble();
      if (v > maxVal) maxVal = v;
    }
    double maxY = (maxVal * 1.25).ceilToDouble();
    if (maxY < 1000) maxY = 1000;

    // Highlight de la barre max
    final maxIdx = trend.indexWhere((e) => (e['amount'] as num) == maxVal);

    return BarChartData(
      maxY: maxY,
      barGroups: trend.asMap().entries.map((e) {
        final isMax = maxVal > 0 && e.key == maxIdx;
        return BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(
              toY: (e.value['amount'] as num).toDouble(),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: isMax
                    ? const [Color(0xFFD97706), Color(0xFFFBBF24)]
                    : const [Color(0xFF16A34A), Color(0xFF4ADE80)],
              ),
              width: n > 14 ? 10 : 16,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
          ],
        );
      }).toList(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
          strokeWidth: 1,
          dashArray: const [4, 4],
        ),
      ),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF0F172A),
          tooltipBorderRadius: BorderRadius.circular(10),
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          tooltipMargin: 12,
          getTooltipItem: (group, gIdx, rod, rIdx) {
            final i = group.x;
            final date = (i >= 0 && i < trend.length)
                ? (trend[i]['fullDate']?.toString() ??
                      trend[i]['date'].toString())
                : '';
            return BarTooltipItem(
              '',
              const TextStyle(color: Colors.white),
              children: [
                TextSpan(
                  text: '$date\n',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: NumberFormat('#,###', 'fr_FR').format(rod.toY.round()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const TextSpan(
                  text: ' FCFA',
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 48,
            getTitlesWidget: (v, _) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                _formatCompact(v),
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= trend.length) return const SizedBox.shrink();
              final isEdge = i == 0 || i == trend.length - 1;
              if (!isEdge && i % labelStep != 0) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  trend[i]['date'],
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  PieChartData _buildGenderPieChart(int totalM, int totalF) {
    final total = totalM + totalF;
    // Si pas de données, afficher un cercle gris pour rendre le widget visible
    if (total == 0) {
      return PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: 1,
            title: '',
            color: const Color(0xFFE5E7EB),
            radius: 55,
          ),
        ],
      );
    }
    final pctM = totalM / total * 100;
    final pctF = totalF / total * 100;
    return PieChartData(
      sectionsSpace: 3,
      centerSpaceRadius: 40,
      sections: [
        if (totalM > 0)
          PieChartSectionData(
            value: totalM.toDouble(),
            title: '$totalM\n${pctM.toStringAsFixed(0)}%',
            color: const Color(0xFF2563EB),
            radius: 60,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              height: 1.2,
            ),
          ),
        if (totalF > 0)
          PieChartSectionData(
            value: totalF.toDouble(),
            title: '$totalF\n${pctF.toStringAsFixed(0)}%',
            color: const Color(0xFFEC4899),
            radius: 60,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              height: 1.2,
            ),
          ),
      ],
    );
  }
}

/// Modèle léger pour une carte KPI Finance
class _FinKpi {
  final String label;
  final String value;
  final String? hint;
  final IconData icon;
  final Color color;

  const _FinKpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.hint,
  });
}
