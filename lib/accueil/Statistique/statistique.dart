import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'service.dart';
import 'package:hostoman/model_unifier.dart';
import 'package:hostoman/shared/pdf_generator.dart';
import 'package:go_router/go_router.dart';

// Internal group ID -> localization key
const Map<String, String> _kGroupLabels = {
  'Consultation de 0 à 5 ans': 'accstat_group_0_5',
  'Consultation plus de 5 ans': 'accstat_group_5_plus',
  'Rendez-vous': 'accstat_group_rdv',
  'CPN': 'accstat_group_cpn',
};

String _groupLabel(String groupId) {
  final key = _kGroupLabels[groupId];
  return key != null ? key.tr() : groupId;
}

// ─── Palette professionnelle ───────────────────────────────────────────────
const Color _primary    = Color(0xFF1565C0);
const Color _accent     = Color(0xFF1E88E5);
const Color _tealGroup  = Color(0xFF00897B);
const Color _indigoGroup  = Color(0xFF3949AB);
const Color _blueGreyGroup = Color(0xFF546E7A);
const Color _deepBlueGroup = Color(0xFF1565C0);
const Color _bgStart    = Color(0xFF0D47A1);
const Color _bgEnd      = Color(0xFF1976D2);

// Filtre rapide
enum _QuickFilter { day, week, month, custom }

class RapportPatientPage extends StatefulWidget {
  const RapportPatientPage({super.key});

  @override
  State<RapportPatientPage> createState() => _RapportPatientPageState();
}

class _RapportPatientPageState extends State<RapportPatientPage>
    with SingleTickerProviderStateMixin {
  final service = RapportPatientService(Supabase.instance.client);

  DateTime? _start;
  DateTime? _end;
  bool _loading = false;
  Map<String, List<Patient>> _grouped = {};
  _QuickFilter _activeFilter = _QuickFilter.day;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final List<String> allGroups = [
    'Consultation de 0 à 5 ans',
    'Consultation plus de 5 ans',
    'Rendez-vous',
    'CPN',
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _applyFilter(_QuickFilter.day));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─── Filtre rapide ─────────────────────────────────────────────────────
  void _applyFilter(_QuickFilter filter) {
    if (filter == _QuickFilter.custom) {
      _showCustomDateDialog();
      return;
    }
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (filter) {
      case _QuickFilter.day:
        start = DateTime(now.year, now.month, now.day);
        break;
      case _QuickFilter.week:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(monday.year, monday.month, monday.day);
        break;
      case _QuickFilter.month:
        start = DateTime(now.year, now.month, 1);
        break;
      default:
        return;
    }
    setState(() {
      _activeFilter = filter;
      _start = start;
      _end = end;
    });
    _generate();
  }

  // ─── Dialogue de dates personnalisées ──────────────────────────────────
  Future<void> _showCustomDateDialog() async {
    DateTime? tempStart = _activeFilter == _QuickFilter.custom ? _start : null;
    DateTime? tempEnd   = _activeFilter == _QuickFilter.custom ? _end   : null;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDlg) {
          Future<void> pickDate(bool isStart) async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: isStart
                  ? (tempStart ?? DateTime.now())
                  : (tempEnd ?? DateTime.now()),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: _primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              setDlg(() {
                if (isStart) tempStart = picked;
                else tempEnd = picked;
              });
            }
          }

          Widget dateChip(String label, DateTime? date, bool isStart) {
            final has = date != null;
            return Expanded(
              child: InkWell(
                onTap: () => pickDate(isStart),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: has
                        ? _primary.withOpacity(0.07)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: has ? _primary : Colors.grey.shade300,
                      width: has ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 14,
                            color:
                                has ? _primary : Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(label,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500)),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        has
                            ? DateFormat('dd/MM/yyyy').format(date)
                            : 'accstat_pick_date'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: has
                              ? Colors.black87
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final dateError = tempStart != null &&
              tempEnd != null &&
              tempEnd!.isBefore(tempStart!);

          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.tune_rounded,
                    color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'accstat_custom_period'.tr(),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
              ),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Row(children: [
                  dateChip(
                      'accstat_date_start'.tr(), tempStart, true),
                  const SizedBox(width: 10),
                  dateChip('accstat_date_end'.tr(), tempEnd, false),
                ]),
                if (dateError)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'accstat_date_error'.tr(),
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.end,
            actionsPadding:
                const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600),
                child: Text('accstat_cancel'.tr()),
              ),
              ElevatedButton(
                onPressed: (tempStart == null ||
                        tempEnd == null ||
                        dateError)
                    ? null
                    : () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text('accstat_apply'.tr()),
              ),
            ],
          );
        });
      },
    );

    if (confirmed == true && tempStart != null && tempEnd != null) {
      setState(() {
        _activeFilter = _QuickFilter.custom;
        _start = tempStart;
        _end = DateTime(
            tempEnd!.year, tempEnd!.month, tempEnd!.day, 23, 59, 59);
      });
      _generate();
    }
  }

  // ─── Génération ────────────────────────────────────────────────────────
  Future<void> _generate() async {
    if (_start == null || _end == null) return;
    setState(() {
      _loading = true;
      _grouped = {};
    });
    _fadeCtrl.reset();

    final result = await service.fetchGroupedPatients(_start!, _end!);
    setState(() {
      _grouped = result;
      _loading = false;
    });
    _fadeCtrl.forward();

    if (result.values.every((list) => list.isEmpty)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.info_outline, color: Colors.white),
          const SizedBox(width: 12),
          Text('accstat_none_found'.tr()),
        ]),
        backgroundColor: _primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────
  int _getTotalConsultations() =>
      (_grouped['Consultation de 0 à 5 ans'] ?? []).length +
      (_grouped['Consultation plus de 5 ans'] ?? []).length;

  int _getTotalCases() {
    int t = 0;
    for (var g in allGroups) t += (_grouped[g] ?? []).length;
    return t;
  }

  IconData _getGroupIcon(String group) {
    if (group.contains('0 à 5')) return Icons.child_care_rounded;
    if (group.contains('plus de 5')) return Icons.person_rounded;
    if (group.contains('Rendez-vous')) return Icons.event_rounded;
    if (group.contains('CPN')) return Icons.pregnant_woman_rounded;
    return Icons.medical_services_rounded;
  }

  Color _getGroupColor(String group) {
    if (group.contains('0 à 5')) return _tealGroup;
    if (group.contains('plus de 5')) return _deepBlueGroup;
    if (group.contains('Rendez-vous')) return _blueGreyGroup;
    if (group.contains('CPN')) return _indigoGroup;
    return _accent;
  }

  // ─── Widgets ───────────────────────────────────────────────────────────

  Widget _buildQuickFilters() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        _filterBtn(_QuickFilter.day, Icons.today_rounded, 'accstat_filter_day'.tr()),
        _filterBtn(_QuickFilter.week, Icons.date_range_rounded, 'accstat_filter_week'.tr()),
        _filterBtn(_QuickFilter.month, Icons.calendar_month_rounded, 'accstat_filter_month'.tr()),
        _filterBtn(_QuickFilter.custom, Icons.tune_rounded, 'accstat_filter_custom'.tr()),
      ]),
    );
  }

  Widget _filterBtn(_QuickFilter f, IconData icon, String label) {
    final active = _activeFilter == f;
    return Expanded(
      child: GestureDetector(
        onTap: () => _applyFilter(f),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2))]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18,
                  color: active ? _primary : Colors.white70),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? _primary : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivePeriodBadge() {
    if (_start == null || _end == null) return const SizedBox.shrink();
    final fmt = DateFormat('dd/MM/yyyy');
    String label;
    switch (_activeFilter) {
      case _QuickFilter.day:
        label = fmt.format(_start!);
        break;
      case _QuickFilter.week:
        label = '${fmt.format(_start!)} → ${fmt.format(_end!)}';
        break;
      case _QuickFilter.month:
        label = DateFormat('MMMM yyyy').format(_start!);
        break;
      case _QuickFilter.custom:
        label = '${fmt.format(_start!)} → ${fmt.format(_end!)}';
        break;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 13, color: Colors.white70),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade800)),
                  const SizedBox(height: 3),
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientTile(Patient p) {
    final sexe = p.sexe.trim();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: () => context.pushNamed(
          'detail_patient',
          pathParameters: {'id': p.id_patient.toString()},
        ),
        leading: CircleAvatar(
          backgroundColor: _primary.withOpacity(0.1),
          child: Text(
            p.nom_complet.isNotEmpty
                ? p.nom_complet[0].toUpperCase()
                : '?',
            style: const TextStyle(
                color: _primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(p.nom_complet,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Row(children: [
          sexe == 'Homme'
              ? const Icon(Icons.man_rounded,
                  size: 16, color: _primary)
              : const Icon(Icons.woman_rounded,
                  size: 16, color: Color(0xFFAD1457)),
          const SizedBox(width: 4),
          Text(p.sexe,
              style: TextStyle(
                  color: Colors.grey.shade700, fontSize: 13)),
        ]),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            DateFormat('dd/MM/yyyy').format(p.date_enregistrement),
            style: const TextStyle(
                fontSize: 12,
                color: _primary,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildGroup(String title, List<Patient> patients) {
    final color = _getGroupColor(title);
    final icon = _getGroupIcon(title);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      elevation: 2,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.07),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: color,
            onSurface: Colors.grey.shade800,
          ),
          expansionTileTheme: ExpansionTileThemeData(
            iconColor: color,
            collapsedIconColor: Colors.grey.shade500,
            textColor: Colors.grey.shade800,
            collapsedTextColor: Colors.grey.shade800,
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.grey.shade800)),
          subtitle: Text(
            (patients.length > 1
                    ? 'accstat_patient_many'
                    : 'accstat_patient_one')
                .tr(namedArgs: {'count': '${patients.length}'}),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${patients.length}',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ),
          children: patients.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      Icon(Icons.inbox_outlined,
                          size: 44, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      Text('accstat_empty_group'.tr(),
                          style:
                              TextStyle(color: Colors.grey.shade400)),
                    ]),
                  ),
                ]
              : [
                  const SizedBox(height: 6),
                  ...patients.map(_buildPatientTile),
                  const SizedBox(height: 12),
                ],
        ),
      ),
    );
  }

  List<Widget> _buildAllGroups() {
    return allGroups
        .map((g) =>
            _buildGroup(_groupLabel(g), _grouped[g] ?? []))
        .toList();
  }

  Future<void> _printPatientList() async {
    final List<PatientPdfData> allPatients = [];
    for (var group in allGroups) {
      for (var p in (_grouped[group] ?? [])) {
        allPatients.add(PatientPdfData(
          nom: p.nom_complet,
          sexe: p.sexe,
          age: 'list_age_years'.tr(namedArgs: {'age': '${p.age}'}),
          telephone: p.telephone.toString(),
          dateEnregistrement:
              DateFormat('dd/MM/yyyy').format(p.date_enregistrement),
          categorie: _groupLabel(group),
        ));
      }
    }
    final periodeLabel = (_start != null && _end != null)
        ? 'accstat_period_label'.tr(namedArgs: {
            'start': DateFormat('dd/MM/yyyy').format(_start!),
            'end': DateFormat('dd/MM/yyyy').format(_end!),
          })
        : 'accstat_period_all'.tr();

    await PatientListPdfGenerator.previewAndPrint(
      context: context,
      serviceName: 'accstat_service_name'.tr(),
      periodeLabel: periodeLabel,
      patients: allPatients,
      showCategorie: true,
      categorieLabel: 'accstat_cat_label'.tr(),
    );
  }

  // ─── Build principal ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgStart,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.analytics_outlined, color: _primary),
            const SizedBox(width: 10),
            Text(
              'accstat_title'.tr(),
              style: const TextStyle(
                  color: _primary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_grouped.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.print_rounded, color: _accent),
              tooltip: 'accstat_print'.tr(),
              onPressed: _printPatientList,
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgStart, _bgEnd],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 700;
            final maxW = isDesktop ? 960.0 : double.infinity;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: Column(
                  children: [
                    _buildQuickFilters(),
                    _buildActivePeriodBadge(),

                    Expanded(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5))
                          : _grouped.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                            Icons.bar_chart_rounded,
                                            size: 60,
                                            color: Colors.white60),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'accstat_select_period'.tr(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : FadeTransition(
                                  opacity: _fadeAnim,
                                  child: ClipRRect(
                                    borderRadius:
                                        const BorderRadius.only(
                                      topLeft: Radius.circular(28),
                                      topRight: Radius.circular(28),
                                    ),
                                    child: Container(
                                      color: Colors.grey.shade50,
                                      child: ListView(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                vertical: 20),
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 16),
                                            child: Row(children: [
                                              _buildStatCard(
                                                'accstat_consultations'
                                                    .tr(),
                                                '${_getTotalConsultations()}',
                                                Icons
                                                    .medical_services_rounded,
                                                _primary,
                                              ),
                                              const SizedBox(width: 12),
                                              _buildStatCard(
                                                'accstat_total_cases'
                                                    .tr(),
                                                '${_getTotalCases()}',
                                                Icons.people_rounded,
                                                _tealGroup,
                                              ),
                                            ]),
                                          ),
                                          const SizedBox(height: 22),

                                          Padding(
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 20),
                                            child: Row(children: [
                                              Container(
                                                width: 4,
                                                height: 20,
                                                decoration:
                                                    BoxDecoration(
                                                  color: _accent,
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(2),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'accstat_details_by_cat'
                                                    .tr(),
                                                style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: Colors
                                                        .grey.shade800),
                                              ),
                                            ]),
                                          ),
                                          const SizedBox(height: 10),

                                          ..._buildAllGroups(),
                                          const SizedBox(height: 90),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _grouped.isNotEmpty
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_rounded, color: _primary),
                  const SizedBox(width: 12),
                  Text(
                    'accstat_total_label'.tr(),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_getTotalCases()}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _accent),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
