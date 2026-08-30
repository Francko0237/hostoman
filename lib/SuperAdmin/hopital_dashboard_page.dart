import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hostoman/SuperAdmin/hopital_stats_service.dart';

/// 🏥 Tableau de bord d'un hôpital — Vue Super Admin (design sobre)
class HopitalDashboardPage extends StatefulWidget {
  final Map<String, dynamic> hopital;

  const HopitalDashboardPage({super.key, required this.hopital});

  @override
  State<HopitalDashboardPage> createState() => _HopitalDashboardPageState();
}

class _HopitalDashboardPageState extends State<HopitalDashboardPage> {
  late final HopitalStatsService _service;

  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  // ── Palette alignée sur le reste de l'app ──
  static const Color _bg      = Color(0xFFF5F6FA);
  static const Color _surface = Colors.white;
  static const Color _primary = Color(0xFF1A237E);
  static const Color _text    = Color(0xFF0F172A);
  static const Color _subtext = Color(0xFF64748B);
  static const Color _border  = Color(0xFFE2E8F0);
  static const Color _success = Color(0xFF16A34A);
  static const Color _danger  = Color(0xFFDC2626);

  // Couleurs discrètes pour les graphiques
  static const List<Color> _chartColors = [
    Color(0xFF1A237E),
    Color(0xFF3949AB),
    Color(0xFF5C6BC0),
    Color(0xFF7986CB),
    Color(0xFF9FA8DA),
    Color(0xFFBBCFF8),
  ];

  @override
  void initState() {
    super.initState();
    _service = HopitalStatsService(Supabase.instance.client);
    _chargerStats();
  }

  Future<void> _chargerStats() async {
    setState(() => _isLoading = true);
    final s = await _service.getAllStats(widget.hopital['id_hopital']);
    if (mounted) {
      setState(() {
        _stats = s;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final estActif   = widget.hopital['actif'] ?? true;
    final nomHopital = widget.hopital['nom_hopital'] ?? 'Hôpital';
    final adresse    = widget.hopital['adresse'] ?? '';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nomHopital,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            if (adresse.isNotEmpty)
              Text(adresse,
                  style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          _statusChip(estActif),
          const SizedBox(width: 4),
          _buildNotificationBell(),
          IconButton(
            tooltip: 'Rafraîchir',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _chargerStats,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── KPI Cards ──
                _buildKpiRow(),
                const SizedBox(height: 24),
                // ── Graphique Consultations ──
                _buildSection(
                  title: 'Consultations — 7 derniers jours',
                  icon: Icons.timeline_outlined,
                  child: _buildConsultationsChart(),
                ),
                const SizedBox(height: 20),
                // ── Graphique Patients ──
                _buildSection(
                  title: 'Nouveaux patients — 7 derniers jours',
                  icon: Icons.person_add_outlined,
                  child: _buildPatientsBarChart(),
                ),
                const SizedBox(height: 20),
                // ── Répartition Personnel ──
                _buildSection(
                  title: 'Répartition du personnel',
                  icon: Icons.pie_chart_outline,
                  child: _buildPersonnelRepartition(),
                ),
                const SizedBox(height: 20),
                // ── Liste & Gestion du Personnel ──
                _buildSection(
                  title: 'sa_staff_management'.tr(),
                  icon: Icons.badge_outlined,
                  child: _buildPersonnelListeWidget(),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _statusChip(bool estActif) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (estActif ? _success : _danger).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: (estActif ? _success : _danger).withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: estActif ? _success : _danger),
        ),
        const SizedBox(width: 5),
        Text(
          estActif ? 'Actif' : 'Suspendu',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: estActif ? _success : _danger),
        ),
      ]),
    );
  }

  // ── KPI ──
  Widget _buildKpiRow() {
    final totalPatients      = _stats['totalPatients'] as int? ?? 0;
    final totalPersonnel     = _stats['totalPersonnel'] as int? ?? 0;
    final totalConsultations = _stats['totalConsultations'] as int? ?? 0;

    final kpis = [
      {'label': 'Patients', 'value': totalPatients, 'icon': Icons.people_outline},
      {'label': 'Personnel', 'value': totalPersonnel, 'icon': Icons.badge_outlined},
      {'label': 'Consultations', 'value': totalConsultations, 'icon': Icons.medical_services_outlined},
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 480;
      if (isWide) {
        return Row(children: kpis.asMap().entries.map((e) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: e.key < kpis.length - 1 ? 12 : 0),
              child: _kpiCard(e.value),
            ),
          );
        }).toList());
      }
      return Column(
        children: kpis.map((k) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _kpiCard(k),
        )).toList(),
      );
    });
  }

  Widget _kpiCard(Map<String, dynamic> data) {
    return Card(
      elevation: 0,
      color: _surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data['icon'] as IconData, color: _primary, size: 22),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '${data['value']}',
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: _text, height: 1),
            ),
            const SizedBox(height: 2),
            Text(data['label'] as String,
                style: const TextStyle(fontSize: 12, color: _subtext)),
          ]),
        ]),
      ),
    );
  }

  // ── Section card wrapper ──
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: _surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: _primary, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: _text)),
            ]),
            const SizedBox(height: 4),
            const Divider(color: _border),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  // ── Graphique courbe Consultations ──
  Widget _buildConsultationsChart() {
    final data = (_stats['consultationsParJour'] as List?)
            ?.cast<Map<String, dynamic>>() ?? [];
    if (data.isEmpty) return _emptyChart();

    final maxY = data.fold<int>(0, (m, e) => (e['count'] as int) > m ? e['count'] as int : m);
    final yMax = (maxY < 5 ? 5 : maxY + 2).toDouble();

    final spots = data.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), (e.value['count'] as int).toDouble()))
        .toList();

    return SizedBox(
      height: 180,
      child: LineChart(LineChartData(
        minY: 0,
        maxY: yMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: _border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: _subtext),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(data[i]['label'] as String,
                      style: const TextStyle(fontSize: 10, color: _subtext)),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.4,
            color: _primary,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3.5,
                color: _primary,
                strokeColor: Colors.white,
                strokeWidth: 2,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: _primary.withValues(alpha: 0.07),
            ),
          ),
        ],
      )),
    );
  }

  // ── Graphique barres Patients ──
  Widget _buildPatientsBarChart() {
    final data = (_stats['patientsParJour'] as List?)
            ?.cast<Map<String, dynamic>>() ?? [];
    if (data.isEmpty) return _emptyChart();

    final maxY = data.fold<int>(0, (m, e) => (e['count'] as int) > m ? e['count'] as int : m);
    final yMax = (maxY < 5 ? 5 : maxY + 2).toDouble();

    return SizedBox(
      height: 180,
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: yMax,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => _primary,
            getTooltipItem: (_, __, rod, ___) => BarTooltipItem(
              '${rod.toY.toInt()} patient${rod.toY > 1 ? 's' : ''}',
              const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: _subtext),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(data[i]['label'] as String,
                      style: const TextStyle(fontSize: 10, color: _subtext)),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: _border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          final count = (entry.value['count'] as int).toDouble();
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: count,
                color: _primary.withValues(alpha: 0.75),
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      )),
    );
  }

  // ── Répartition Personnel (barres horizontales) ──
  Widget _buildPersonnelRepartition() {
    final roles = (_stats['personnelParRole'] as Map?)?.cast<String, int>() ?? {};
    if (roles.isEmpty) return _emptyChart(message: 'Aucun personnel enregistré');

    final total = roles.values.fold(0, (a, b) => a + b);
    final entries = roles.entries.toList();

    return Column(
      children: entries.asMap().entries.map((e) {
        final idx   = e.key;
        final role  = e.value.key;
        final count = e.value.value;
        final pct   = total > 0 ? count / total : 0.0;
        final color = _chartColors[idx % _chartColors.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(role,
                        style: const TextStyle(fontSize: 13, color: _text)),
                  ]),
                  Text(
                    '$count  (${(pct * 100).toStringAsFixed(0)}%)',
                    style: const TextStyle(
                        fontSize: 12, color: _subtext, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: _border,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyChart({String message = 'Aucune donnée disponible'}) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, color: _subtext.withValues(alpha: 0.4), size: 32),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: _subtext, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── Liste & Gestion des membres du personnel de cet hôpital ──
  Widget _buildPersonnelListeWidget() {
    final List<Map<String, dynamic>> personnelListe =
        (_stats['personnelListe'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (personnelListe.isEmpty) {
      return _emptyChart(message: 'Aucun membre du personnel trouvé dans cet hôpital');
    }

    return Column(
      children: personnelListe.map((p) {
        final nom = '${p['Prenom'] ?? ''} ${p['Nom'] ?? ''}'.trim();
        final role = p['Specialite'] ?? 'Personnel';
        final tel = p['telephone']?.toString() ?? 'N/A';
        final idAgent = p['id_utilisateur']?.toString() ?? p['username']?.toString() ?? '';
        final bool estActif = p['compte_actif'] ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: _bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: _border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: _primary.withValues(alpha: 0.1),
              child: Text(
                nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                style: const TextStyle(color: _primary, fontWeight: FontWeight.bold),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    nom,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _text),
                  ),
                ),
                if (idAgent.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _border),
                    ),
                    child: Text(
                      'ID: $idAgent',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _primary),
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      role,
                      style: const TextStyle(fontSize: 11, color: _primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.phone_outlined, size: 12, color: _subtext),
                  const SizedBox(width: 3),
                  Text(tel, style: const TextStyle(fontSize: 12, color: _subtext)),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: estActif ? _success : _danger,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    estActif ? 'Actif' : 'Inactif',
                    style: TextStyle(
                      fontSize: 11,
                      color: estActif ? _success : _danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit_note, color: _primary),
              tooltip: 'Modifier les informations',
              onPressed: () => _ouvrirModalModificationPersonnel(p),
            ),
            onTap: () => _ouvrirModalModificationPersonnel(p),
          ),
        );
      }).toList(),
    );
  }

  // ── Modal de consultation & modification d'un membre du personnel ──
  void _ouvrirModalModificationPersonnel(Map<String, dynamic> p) {
    final formKey = GlobalKey<FormState>();
    final nomCtrl = TextEditingController(text: p['Nom'] ?? '');
    final prenomCtrl = TextEditingController(text: p['Prenom'] ?? '');
    final telCtrl = TextEditingController(text: p['telephone']?.toString() ?? '');
    final adresseCtrl = TextEditingController(text: p['adresse'] ?? '');
    final ageCtrl = TextEditingController(text: p['age']?.toString() ?? '30');
    String roleSaisi = p['Specialite'] ?? 'Médecin Généraliste';
    String sexeSaisi = p['sexe'] ?? 'M';
    bool compteActif = p['compte_actif'] ?? false;

    final roles = [
      'Directeur',
      'Médecin Généraliste',
      'Major Accueil',
      'Caissier',
      'Laborantin',
      'Pharmacien',
      'Infirmier',
    ];

    if (!roles.contains(roleSaisi)) {
      roles.add(roleSaisi);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: _surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_outline, color: _primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('sa_agent_fiche_title'.tr(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _text)),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9 < 520
                    ? MediaQuery.of(context).size.width * 0.9
                    : 520,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 14),
                      if ((p['id_utilisateur'] != null && p['id_utilisateur'].toString().isNotEmpty) || (p['username'] != null && p['username'].toString().isNotEmpty))
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: _primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.badge, color: _primary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '${'sa_agent_id'.tr()} ',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _subtext),
                              ),
                              SelectableText(
                                '${p['id_utilisateur'] ?? p['username']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _primary,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: nomCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nom *',
                                prefixIcon: Icon(Icons.person_outline, color: _primary),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: prenomCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Prénom',
                                prefixIcon: Icon(Icons.person_outline, color: _primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: telCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Téléphone *',
                                prefixIcon: Icon(Icons.phone_android_outlined, color: _primary),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: roles.contains(roleSaisi) ? roleSaisi : roles.first,
                              decoration: const InputDecoration(
                                labelText: 'Rôle / Spécialité',
                                prefixIcon: Icon(Icons.badge_outlined, color: _primary),
                              ),
                              items: roles
                                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) roleSaisi = val;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: (sexeSaisi == 'F' || sexeSaisi == 'Femme') ? 'F' : 'M',
                              decoration: const InputDecoration(
                                labelText: 'Sexe',
                                prefixIcon: Icon(Icons.wc_outlined, color: _primary),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'M', child: Text('Masculin')),
                                DropdownMenuItem(value: 'F', child: Text('Féminin')),
                              ],
                              onChanged: (val) {
                                if (val != null) sexeSaisi = val;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: ageCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Âge',
                                prefixIcon: Icon(Icons.cake_outlined, color: _primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: adresseCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Adresse / Quarier',
                          prefixIcon: Icon(Icons.place_outlined, color: _primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        value: compteActif,
                        activeThumbColor: _success,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'sa_account_access_active'.tr(),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          compteActif ? 'L\'agent peut se connecter' : 'L\'accès est suspendu',
                          style: TextStyle(fontSize: 12, color: compteActif ? _success : _danger),
                        ),
                        onChanged: (val) => setDialogState(() => compteActif = val),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Annuler', style: TextStyle(color: _subtext)),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSubmitting = true);

                        final err = await _service.updatePersonnel(
                          p['id_utilisateur'],
                          {
                            'Nom': nomCtrl.text.trim(),
                            'Prenom': prenomCtrl.text.trim(),
                            'telephone': int.tryParse(telCtrl.text) ?? 0,
                            'Specialite': roleSaisi,
                            'sexe': sexeSaisi,
                            'age': int.tryParse(ageCtrl.text) ?? 30,
                            'adresse': adresseCtrl.text.trim(),
                            'compte_actif': compteActif,
                          },
                        );

                        if (mounted) {
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(err ?? 'Fiche agent mise à jour avec succès.'),
                            backgroundColor: err != null ? _danger : _success,
                          ));
                          if (err == null) _chargerStats();
                        }
                      },
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check, size: 18),
                label: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        });
      },
    );
  }

  /// 🔔 Bouton cloche avec badge des demandes de réinitialisation en attente
  Widget _buildNotificationBell() {
    final List<Map<String, dynamic>> demandes =
        (_stats['demandesReset'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final count = demandes.length;

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'Demandes de réinitialisation ($count)',
          icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
          onPressed: () => _ouvrirModalDemandesResetPassword(demandes),
        ),
        if (count > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  /// 🔓 Modale de gestion des demandes de réinitialisation de mot de passe
  void _ouvrirModalDemandesResetPassword(List<Map<String, dynamic>> demandes) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: _surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock_reset, color: Colors.orange, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Mots de passe oubliés',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _text),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9 < 520
                    ? MediaQuery.of(context).size.width * 0.9
                    : 520,
                child: demandes.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline, color: _success, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'Aucune demande en attente',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _subtext),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: demandes.map((d) {
                          final nom = '${d['Prenom'] ?? ''} ${d['Nom'] ?? ''}'.trim();
                          final role = d['Specialite'] ?? 'Agent';
                          final idAgent = d['id_utilisateur'] ?? d['username'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _bg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nom,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: _text,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'ID: $idAgent · $role',
                                        style: const TextStyle(fontSize: 12, color: _subtext),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Rejeter',
                                  icon: const Icon(Icons.close, color: _danger),
                                  onPressed: () async {
                                    await _service.traiterDemandeResetPassword(
                                      d['id_utilisateur'],
                                      'rejete',
                                    );
                                    if (mounted) {
                                      Navigator.pop(dialogCtx);
                                      _chargerStats();
                                    }
                                  },
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _success,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Valider', style: TextStyle(fontSize: 12)),
                                  onPressed: () async {
                                    await _service.traiterDemandeResetPassword(
                                      d['id_utilisateur'],
                                      'valide',
                                    );
                                    if (mounted) {
                                      Navigator.pop(dialogCtx);
                                      _chargerStats();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Demande de $nom validée. L\'agent peut réinitialiser son mot de passe.'),
                                          backgroundColor: _success,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Fermer', style: TextStyle(color: _subtext)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
