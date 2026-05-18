import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_directeur_service.dart';
import 'package:easy_localization/easy_localization.dart';

// Palette du module Directeur (coh\u00e9rence avec l'app)
const Color _primary = Color(0xFF1A237E);
const Color _accent = Color(0xFFFFD700);
const Color _bg = Color(0xFFF5F6FA);
const Color _success = Color(0xFF16A34A);
const Color _warning = Color(0xFFF59E0B);
const Color _danger = Color(0xFFDC2626);
const Color _info = Color(0xFF0284C7);

/// Page d'accueil (vue d'ensemble) du module Directeur.
/// Affiche les KPI temps r\u00e9el + activit\u00e9 7 jours + alertes + r\u00e9partition personnel.
/// Permet aussi la navigation rapide vers les autres onglets via [onNavigate].
class HomeDirecteurPage extends StatefulWidget {
  final void Function(int index)? onNavigate;
  const HomeDirecteurPage({super.key, this.onNavigate});

  @override
  State<HomeDirecteurPage> createState() => _HomeDirecteurPageState();
}

class _HomeDirecteurPageState extends State<HomeDirecteurPage> {
  final HomeDirecteurService _service = HomeDirecteurService(
    Supabase.instance.client,
  );

  bool _isLoading = true;
  Map<String, dynamic> _admin = {};
  Map<String, dynamic> _kpis = {};
  List<Map<String, dynamic>> _activity = [];
  List<Map<String, dynamic>> _staff = [];
  DateTime _lastRefresh = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final data = await _service.getDashboardData();
    if (!mounted) return;
    setState(() {
      _admin = (data['admin'] as Map<String, dynamic>?) ?? {};
      _kpis = (data['kpis'] as Map<String, dynamic>?) ?? {};
      _activity =
          (data['activity'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _staff = (data['staff'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _lastRefresh = DateTime.now();
      _isLoading = false;
    });
  }

  // ============================== BUILD ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        color: _primary,
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final isDesktop = w >= 1100;
        final isTablet = w >= 700 && w < 1100;
        final padding = isDesktop ? 28.0 : (isTablet ? 20.0 : 14.0);

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(padding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDesktop, isTablet),
                  SizedBox(height: isDesktop ? 24 : 18),
                  _buildKpiGrid(isDesktop, isTablet),
                  SizedBox(height: isDesktop ? 24 : 18),
                  if (isDesktop)
                    _buildDesktopTwoColumns()
                  else
                    _buildStackedColumns(),
                  SizedBox(height: isDesktop ? 24 : 18),
                  _buildQuickActions(isDesktop, isTablet),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================== HEADER ==============================
  Widget _buildHeader(bool isDesktop, bool isTablet) {
    final prenom = (_admin['Prenom'] ?? '').toString();
    final nom = (_admin['Nom'] ?? '').toString();
    final fullName = ('$prenom $nom').trim();
    final greetingName = fullName.isNotEmpty ? 'Dr. $fullName' : '';
    final greeting = _greeting();
    final loc = context.locale.languageCode == 'en' ? 'en_US' : 'fr_FR';
    final dateStr = DateFormat("EEEE d MMMM yyyy", loc).format(_lastRefresh);
    final timeStr = DateFormat('HH:mm').format(_lastRefresh);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 20,
        vertical: isDesktop ? 32 : 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, Color(0xFF283593), Color(0xFF3949AB)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    greetingName.isNotEmpty
                        ? '$greeting, $greetingName \u{1F44B}'
                        : '$greeting \u{1F44B}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isDesktop ? 28 : (isTablet ? 24 : 20),
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'header_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: isDesktop ? 14.5 : 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _pill(Icons.calendar_today_rounded, dateStr),
                      _pill(Icons.access_time_rounded, '${'updated_at'.tr()} : $timeStr'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildRefreshButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return ElevatedButton.icon(
      onPressed: _load,
      icon: const Icon(Icons.refresh_rounded, size: 18),
      label: Text('refresh'.tr()),
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.black87,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'greeting_morning'.tr();
    if (h < 18) return 'greeting_afternoon'.tr();
    return 'greeting_evening'.tr();
  }

  // ============================== KPI GRID ==============================
  Widget _buildKpiGrid(bool isDesktop, bool isTablet) {
    final revenu = (_kpis['revenuJour'] as num?)?.toDouble() ?? 0;
    final nbTrans = _kpis['nbTransactionsJour'] ?? 0;
    final patients = _kpis['patientsJour'] ?? 0;
    final consultEnCours = _kpis['consultationsEnCours'] ?? 0;
    final consultFinies = _kpis['consultationsFinies'] ?? 0;
    final personnelTotal = _kpis['personnelTotal'] ?? 0;
    final connectes = Supabase.instance.client.auth.currentUser != null ? 1 : 0;
    final fmt = NumberFormat('#,###', 'fr_FR');

    final kpis = [
      _KpiData(
        title: 'kpi_revenue'.tr(),
        value: '${fmt.format(revenu)} FCFA',
        subtitle: '$nbTrans ${'kpi_transactions'.tr()}',
        icon: Icons.payments_rounded,
        color: _success,
      ),
      _KpiData(
        title: 'kpi_patients'.tr(),
        value: '$patients',
        subtitle: 'kpi_today'.tr(),
        icon: Icons.person_add_alt_1_rounded,
        color: _info,
      ),
      _KpiData(
        title: 'kpi_consultations'.tr(),
        value: '$consultFinies',
        subtitle: '$consultEnCours ${'kpi_in_progress'.tr()}',
        icon: Icons.medical_services_rounded,
        color: _primary,
      ),
      _KpiData(
        title: 'kpi_connected'.tr(),
        value: '$connectes',
        subtitle: '$personnelTotal ${'kpi_members_total'.tr()}',
        icon: Icons.groups_2_rounded,
        color: const Color(0xFF7C3AED),
      ),
    ];

    final cols = isDesktop ? 4 : (isTablet ? 2 : 2);
    final spacing = isDesktop ? 16.0 : 12.0;
    final aspect = isDesktop ? 2.1 : (isTablet ? 1.9 : 1.35);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kpis.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: aspect,
      ),
      itemBuilder: (ctx, i) => _KpiCard(data: kpis[i]),
    );
  }

  // ============================== LAYOUTS ==============================
  Widget _buildDesktopTwoColumns() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _buildActivityChartCard()),
          const SizedBox(width: 18),
          Expanded(flex: 2, child: _buildAlertsCard()),
        ],
      ),
    );
  }

  Widget _buildStackedColumns() {
    return Column(
      children: [
        _buildActivityChartCard(),
        const SizedBox(height: 14),
        _buildAlertsCard(),
        const SizedBox(height: 14),
        _buildStaffCard(),
      ],
    );
  }

  // ============================== CHART ==============================
  Widget _buildActivityChartCard() {
    return _Card(
      title: 'weekly_activity'.tr(),
      icon: Icons.show_chart_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _legendDot(_primary, 'chart_consult'.tr()),
              const SizedBox(width: 16),
              _legendDot(_info, 'chart_patients'.tr()),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 220,
            child: _activity.isEmpty
                ? Center(
                    child: Text(
                      'no_data'.tr(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : _buildLineChart(),
          ),
          if (_activity.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildStaffMini(),
          ],
        ],
      ),
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    final maxConsult = _activity
        .map((e) => (e['consultations'] as int))
        .fold<int>(0, (a, b) => a > b ? a : b);
    final maxPat = _activity
        .map((e) => (e['patients'] as int))
        .fold<int>(0, (a, b) => a > b ? a : b);
    final maxY =
        ([maxConsult, maxPat, 5].reduce((a, b) => a > b ? a : b)).toDouble() *
        1.3;

    List<FlSpot> spotsFor(String key) => List.generate(
      _activity.length,
      (i) => FlSpot(i.toDouble(), (_activity[i][key] as int).toDouble()),
    );

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY / 4).clamp(1, double.infinity),
          getDrawingHorizontalLine: (_) => FlLine(
            color: const Color(0xFFE2E8F0),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (maxY / 4).clamp(1, double.infinity),
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= _activity.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    (_activity[idx]['day'] ?? '').toString(),
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => _primary,
            getTooltipItems: (touches) {
              return touches.map((t) {
                final idx = t.x.toInt();
                final label = idx >= 0 && idx < _activity.length
                    ? _activity[idx]['date']
                    : '';
                final isFirst = t.barIndex == 0;
                return LineTooltipItem(
                  '$label\n${isFirst ? 'chart_consult'.tr() : 'chart_patients'.tr()} : ${t.y.toInt()}',
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spotsFor('consultations'),
            isCurved: true,
            color: _primary,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                radius: 3.5,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: _primary,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _primary.withValues(alpha: 0.25),
                  _primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          LineChartBarData(
            spots: spotsFor('patients'),
            isCurved: true,
            color: _info,
            barWidth: 2.5,
            dashArray: [6, 4],
            dotData: FlDotData(
              show: true,
              getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                radius: 3,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: _info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================== ALERTES ==============================
  Widget _buildAlertsCard() {
    final paiementsAttente = _kpis['paiementsAttente'] ?? 0;
    final examensAttente = _kpis['examensAttente'] ?? 0;
    final patientsAttente = _kpis['patientsAttenteConsult'] ?? 0;
    final consultEnCours = _kpis['consultationsEnCours'] ?? 0;

    final items = <_AlertData>[
      _AlertData(
        icon: Icons.hourglass_top_rounded,
        label: 'kpi_waiting_consult'.tr(),
        count: patientsAttente,
        threshold: 5,
      ),
      _AlertData(
        icon: Icons.medical_services_outlined,
        label: '${'kpi_consultations'.tr()} ${'kpi_in_progress'.tr()}',
        count: consultEnCours,
        threshold: 3,
      ),
      _AlertData(
        icon: Icons.biotech_rounded,
        label: 'kpi_lab_pending'.tr(),
        count: examensAttente,
        threshold: 5,
      ),
      _AlertData(
        icon: Icons.payments_outlined,
        label: 'kpi_pending_payments'.tr(),
        count: paiementsAttente,
        threshold: 5,
      ),
    ];

    return _Card(
      title: 'alerts_title'.tr(),
      icon: Icons.notifications_active_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final a in items) _AlertRow(data: a),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => widget.onNavigate?.call(1),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: _primary),
                  const SizedBox(width: 6),
                  Text(
                    'see_service_detail'.tr(),
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================== STAFF ==============================
  Widget _buildStaffCard() {
    return _Card(
      title: 'staff_distribution'.tr(),
      icon: Icons.groups_3_rounded,
      child: _staff.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'no_staff'.tr(),
                style: const TextStyle(color: Colors.grey),
              ),
            )
          : _buildStaffMini(),
    );
  }

  Widget _buildStaffMini() {
    if (_staff.isEmpty) return const SizedBox();
    final total = _staff.fold<int>(0, (a, e) => a + (e['count'] as int));
    final palette = [
      _primary,
      _info,
      _success,
      _warning,
      const Color(0xFF7C3AED),
      _danger,
      const Color(0xFF00897B),
    ];

    return Column(
      children: List.generate(_staff.length, (i) {
        final e = _staff[i];
        final c = palette[i % palette.length];
        final pct = total > 0 ? (e['count'] as int) / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e['specialite'].toString(),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${e['count']}  \u00b7  ${(pct * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: c.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(c),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ============================== QUICK ACTIONS ==============================
  Widget _buildQuickActions(bool isDesktop, bool isTablet) {
    final actions = [
      _QuickAction(
        icon: Icons.monitor_heart_rounded,
        label: 'action_services'.tr(),
        color: _primary,
        onTap: () => widget.onNavigate?.call(1),
      ),
      _QuickAction(
        icon: Icons.bar_chart_rounded,
        label: 'action_stats'.tr(),
        color: _info,
        onTap: () => widget.onNavigate?.call(2),
      ),
      _QuickAction(
        icon: Icons.people_alt_rounded,
        label: 'action_staff'.tr(),
        color: const Color(0xFF7C3AED),
        onTap: () => widget.onNavigate?.call(3),
      ),
      _QuickAction(
        icon: Icons.refresh_rounded,
        label: 'refresh'.tr(),
        color: _success,
        onTap: _load,
      ),
    ];
    final cols = isDesktop ? 4 : (isTablet ? 4 : 2);
    return _Card(
      title: 'quick_actions'.tr(),
      icon: Icons.bolt_rounded,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isDesktop ? 2.6 : 2.4,
        ),
        itemBuilder: (ctx, i) => _QuickActionTile(action: actions[i]),
      ),
    );
  }
}

// ============================== WIDGETS ==============================

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Card({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _KpiData {
  final String title, value, subtitle;
  final IconData icon;
  final Color color;
  _KpiData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.color, size: 18),
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
                  data.value,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.subtitle,
                style: TextStyle(
                  color: data.color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertData {
  final IconData icon;
  final String label;
  final int count;
  final int threshold;
  _AlertData({
    required this.icon,
    required this.label,
    required this.count,
    required this.threshold,
  });
}

class _AlertRow extends StatelessWidget {
  final _AlertData data;
  const _AlertRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final isHigh = data.count >= data.threshold;
    final c = isHigh ? _danger : (data.count > 0 ? _warning : _success);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, color: c, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              data.label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${data.count}',
              style: TextStyle(
                color: c,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [action.color.withValues(alpha: 0.05), Colors.white],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(action.icon, color: action.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: action.color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
