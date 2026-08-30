import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'etat_services_service.dart';
import 'package:easy_localization/easy_localization.dart';

// Couleurs (reprises du dashboard directeur)
const Color dirPrimaryColor = Color(0xFF1A237E);
const Color dirAccentColor = Color(0xFFFFD700);

class EtatServicesPage extends StatefulWidget {
  const EtatServicesPage({super.key});

  @override
  State<EtatServicesPage> createState() => _EtatServicesPageState();
}

class _EtatServicesPageState extends State<EtatServicesPage> {
  final EtatServicesService _service = EtatServicesService(
    Supabase.instance.client,
  );

  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  DateTime _lastRefresh = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final data = await _service.getAllServiceStats();
    if (mounted) {
      setState(() {
        _stats = data;
        _isLoading = false;
        _lastRefresh = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: dirPrimaryColor,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: dirPrimaryColor),
              )
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 1100 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _SectionTitle(
                title: 'svc_realtime'.tr(),
                icon: Icons.monitor_heart,
              ),
              const SizedBox(height: 16),
              isDesktop
                  ? _buildServicesGridDesktop()
                  : _buildServicesGridMobile(),
              const SizedBox(height: 28),
              _SectionTitle(title: 'svc_staff'.tr(), icon: Icons.people_alt),
              const SizedBox(height: 16),
              _buildPersonnelDistribution(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final heure = DateFormat("HH:mm").format(_lastRefresh);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [dirPrimaryColor, Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: dirPrimaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'svc_title'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${'svc_last_update'.tr()} : $heure',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGridDesktop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildAccueilCard(),
              const SizedBox(height: 14),
              _buildMedecinCard(),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            children: [
              _buildLaboCard(),
              const SizedBox(height: 14),
              _buildCaisseCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServicesGridMobile() {
    return Column(
      children: [
        _buildAccueilCard(),
        const SizedBox(height: 14),
        _buildMedecinCard(),
        const SizedBox(height: 14),
        _buildLaboCard(),
        const SizedBox(height: 14),
        _buildCaisseCard(),
      ],
    );
  }

  Widget _buildAccueilCard() {
    final data = (_stats['accueil'] as Map<String, dynamic>?) ?? {};
    final attente = data['patientsEnAttente'] ?? 0;
    final admisAujourdHui = data['admisAujourdHui'] ?? 0;
    final status = attente > 10
        ? _ServiceStatus.busy
        : (attente > 4 ? _ServiceStatus.moderate : _ServiceStatus.ok);
    return _ServiceCard(
      title: 'svc_accueil'.tr(),
      icon: Icons.meeting_room_rounded,
      status: status,
      items: [
        _InfoItem(
          label: 'svc_waiting'.tr(),
          value: '$attente',
          highlight: attente > 5,
        ),
        _InfoItem(label: 'svc_admitted_today'.tr(), value: '$admisAujourdHui'),
      ],
    );
  }

  Widget _buildMedecinCard() {
    final data = (_stats['medecin'] as Map<String, dynamic>?) ?? {};
    final enCours = data['enCours'] ?? 0;
    final terminees = data['termineesAujourdhui'] ?? 0;
    final status = enCours > 5
        ? _ServiceStatus.busy
        : (enCours > 2 ? _ServiceStatus.moderate : _ServiceStatus.ok);
    return _ServiceCard(
      title: 'svc_consult'.tr(),
      icon: Icons.medical_services_rounded,
      status: status,
      items: [
        _InfoItem(
          label: 'svc_in_progress'.tr(),
          value: '$enCours',
          highlight: enCours > 3,
        ),
        _InfoItem(label: 'svc_finished_today'.tr(), value: '$terminees'),
      ],
    );
  }

  Widget _buildLaboCard() {
    final data = (_stats['laboratoire'] as Map<String, dynamic>?) ?? {};
    final aFaire = data['examensEnAttente'] ?? 0;
    final termines = data['examensTerminesAujourdHui'] ?? 0;
    final status = aFaire > 10
        ? _ServiceStatus.busy
        : (aFaire > 5 ? _ServiceStatus.moderate : _ServiceStatus.ok);
    return _ServiceCard(
      title: 'svc_lab'.tr(),
      icon: Icons.biotech_rounded,
      status: status,
      items: [
        _InfoItem(
          label: 'svc_exams_waiting'.tr(),
          value: '$aFaire',
          highlight: aFaire > 5,
        ),
        _InfoItem(label: 'svc_exams_done_today'.tr(), value: '$termines'),
      ],
    );
  }

  Widget _buildCaisseCard() {
    final data = (_stats['caisse'] as Map<String, dynamic>?) ?? {};
    final attente = data['paiementsEnAttente'] ?? 0;
    final encaisse = (data['encaisseAujourdHui'] as num?)?.toDouble() ?? 0.0;
    final nbTrans = data['nbTransactionsAujourdHui'] ?? 0;
    final status = attente > 10
        ? _ServiceStatus.busy
        : (attente > 4 ? _ServiceStatus.moderate : _ServiceStatus.ok);
    final formatted = NumberFormat('#,###', 'fr_FR').format(encaisse);
    return _ServiceCard(
      title: 'svc_cashier'.tr(),
      icon: Icons.point_of_sale_rounded,
      status: status,
      items: [
        _InfoItem(
          label: 'svc_payments_waiting'.tr(),
          value: '$attente',
          highlight: attente > 5,
        ),
        _InfoItem(label: 'svc_collected_today'.tr(), value: '$formatted FCFA'),
        _InfoItem(label: 'svc_trans_today'.tr(), value: '$nbTrans'),
      ],
    );
  }

  Widget _buildPersonnelDistribution() {
    final repartition = (_stats['personnel'] as Map<String, int>?) ?? {};
    if (repartition.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            'no_staff'.tr(),
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    final total = repartition.values.fold<int>(0, (a, b) => a + b);
    final colors = [
      dirPrimaryColor,
      const Color(0xFF00897B),
      const Color(0xFFE53935),
      const Color(0xFFF59E0B),
      const Color(0xFF7C3AED),
      const Color(0xFF0284C7),
    ];
    int colorIdx = 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: repartition.entries.map((e) {
          final color = colors[colorIdx % colors.length];
          colorIdx++;
          final percent = total > 0 ? e.value / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(e.key, style: const TextStyle(fontSize: 13)),
                    ),
                    Text(
                      '${e.value} (${(percent * 100).toStringAsFixed(0)}%)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ===== HELPERS =====

enum _ServiceStatus { ok, moderate, busy }

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: dirPrimaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
      ],
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  final bool highlight;
  _InfoItem({required this.label, required this.value, this.highlight = false});
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final _ServiceStatus status;
  final List<_InfoItem> items;
  const _ServiceCard({
    required this.title,
    required this.icon,
    required this.status,
    required this.items,
  });

  Color get _statusColor {
    switch (status) {
      case _ServiceStatus.ok:
        return const Color(0xFF16A34A);
      case _ServiceStatus.moderate:
        return const Color(0xFFF59E0B);
      case _ServiceStatus.busy:
        return const Color(0xFFDC2626);
    }
  }

  String get _statusLabel {
    switch (status) {
      case _ServiceStatus.ok:
        return 'svc_status_ok'.tr();
      case _ServiceStatus.moderate:
        return 'svc_status_moderate'.tr();
      case _ServiceStatus.busy:
        return 'svc_status_busy'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la card
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: dirPrimaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: dirPrimaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              // Badge de statut
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _statusLabel,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          // Info rows
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    item.value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: item.highlight
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF0F172A),
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
}
