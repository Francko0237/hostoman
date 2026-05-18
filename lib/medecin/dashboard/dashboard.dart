import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_service.dart';
import 'package:hostoman/shared/responsive_wrapper.dart';

// Couleurs
const Color medPrimaryColor = Color(0xFF5A47C9);
const Color medAccentColor = Color(0xFF5A47C9);
const Color fondColor = Color(0xFFF3F2F8);
const Color attentionColor = Colors.red;
const Color successColor = Colors.green;
const Color warningColor = Colors.amber;

class DashboardMedecin extends StatefulWidget {
  const DashboardMedecin({super.key});

  @override
  State<DashboardMedecin> createState() => _DashboardMedecinState();
}

class _DashboardMedecinState extends State<DashboardMedecin> {
  int consultationsJour = 12;
  int enAttente = 12;
  int terminer = 12;
  Timer? _timer;

  late final DashboardService _dashboardService;

  @override
  void initState() {
    super.initState();
    _dashboardService = DashboardService(Supabase.instance.client);
    _chargerStats();

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _chargerStats();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _chargerStats() async {
    final stats = await _dashboardService.getDailyStats();
    if (mounted) {
      setState(() {
        consultationsJour = stats['consultations'] ?? 0;
        enAttente = stats['en_attente'] ?? 0;
        terminer = stats['terminer'] ?? 0;
      });
    }
  }

  void _handleTap(BuildContext context, String action) {
    context.push('/Dashboard_Medecin/$action');
    print('Action sélectionnée : $action');
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(context),
      pc: _buildPcLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: medPrimaryColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: medPrimaryColor.withOpacity(0.2),
              border: Border.all(
                color: medPrimaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.local_hospital,
                  color: medPrimaryColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'auth_hospital_name'.tr(),
          style: TextStyle(
            color: Colors.white,
            fontSize: isDesktop ? 20 : 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: !isDesktop,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: PopupMenuButton(
              icon: Icon(Icons.person, color: Colors.white),
              color: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) async {
                if (value == 'profile') {
                  context.push('/Dashboard_Medecin/Profil');
                } else if (value == 'parametre') {
                  context.push('/Dashboard_Medecin/parametremedecin');
                } else if (value == 'deconnexion') {
                  print('déconnexion sélectionnée');
                  try {
                    await Supabase.instance.client.auth.signOut();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('mdash_logout_success'.tr()),
                        backgroundColor: successColor,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    if (context.mounted) {
                      context.go('/Authen_Personnel');
                    }
                  } catch (e) {
                    print('❌ Erreur de déconnexion : $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('mdash_logout_error'.tr()),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                _buildPopupMenuItem(
                  value: 'profile',
                  icon: Icons.person_outline,
                  label: 'mdash_menu_profile'.tr(),
                  color: medPrimaryColor,
                ),

                _buildPopupMenuItem(
                  value: 'parametre',
                  icon: Icons.settings_outlined,
                  label: 'acc_settings_menu'.tr(),
                  color: medPrimaryColor,
                ),

                _buildPopupMenuItem(
                  value: 'deconnexion',
                  icon: Icons.logout_outlined,
                  label: 'mdash_menu_logout'.tr(),
                  color: Colors.red[700]!,
                ),
              ],
            ),
          ),
        ],
      ),

      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Header Background Pour le le design violet du haut
          Container(
            height: 210,
            decoration: const BoxDecoration(
              color: medPrimaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // AppBar
                  const SizedBox(height: 50),

                  // Stats Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            count: consultationsJour,
                            label: 'mdash_stat_consultations_short'.tr(),
                            color: successColor,
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            count: enAttente,
                            label: 'mdash_stat_pending_short'.tr(),
                            color: attentionColor,
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            count: terminer,
                            label: 'mdash_stat_done_short'.tr(),
                            color: warningColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 42),

                  // Titre Dashboard
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: medPrimaryColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'mdash_title'.tr(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Cards Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 13.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                context: context,
                                icon: Icons.person_add,
                                label: 'mdash_action_consultations'.tr(),
                                action: 'ConsultationList',
                                color: Colors.blue,
                                onTap: _handleTap,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildActionCard(
                                context: context,
                                icon: Icons.history,
                                label: 'mdash_action_history'.tr(),
                                action: 'HistoriqueConsultations',
                                color: Colors.green,
                                onTap: _handleTap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                context: context,
                                icon: Icons.timer,
                                label: 'mdash_action_pending'.tr(),
                                action: 'EnattenteExam',
                                color: Colors.redAccent,
                                onTap: _handleTap,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildActionCard(
                                context: context,
                                icon: Icons.calendar_month,
                                label: 'mdash_action_stats'.tr(),
                                action: 'Statistiques',
                                color: Colors.teal,
                                onTap: _handleTap,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Gestion Rendez-vous
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildMainActionButton(),
                  ),

                  const SizedBox(height: 58),

                  // Footer
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'mdash_footer'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  } // end _buildMobileLayout

  // ===== LAYOUT PC =====
  Widget _buildPcLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FC),
      body: Row(
        children: [
          _buildMedPcSidebar(context),
          Expanded(child: _buildMedPcContent(context)),
        ],
      ),
    );
  }

  Widget _buildMedPcSidebar(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF311B92), Color(0xFF5A47C9)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 16,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'mdash_title_short'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'auth_hospital_name'.tr(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _medPcNavItem(
                  context,
                  Icons.dashboard,
                  'mdash_nav_dashboard'.tr(),
                  null,
                  active: true,
                ),
                _medPcNavItem(
                  context,
                  Icons.person_add,
                  'mdash_action_consultations'.tr(),
                  '/Dashboard_Medecin/ConsultationList',
                ),
                _medPcNavItem(
                  context,
                  Icons.history,
                  'mdash_action_history'.tr(),
                  '/Dashboard_Medecin/HistoriqueConsultations',
                ),
                _medPcNavItem(
                  context,
                  Icons.timer,
                  'mdash_action_pending_full'.tr(),
                  '/Dashboard_Medecin/EnattenteExam',
                ),
                _medPcNavItem(
                  context,
                  Icons.calendar_today,
                  'mdash_action_rdv'.tr(),
                  '/Dashboard_Medecin/rendez-vous',
                ),
                _medPcNavItem(
                  context,
                  Icons.bar_chart,
                  'mdash_action_stats'.tr(),
                  '/Dashboard_Medecin/Statistiques',
                ),
                Divider(color: Colors.white.withValues(alpha: 0.15)),
                _medPcNavItem(
                  context,
                  Icons.person_outline,
                  'mdash_nav_profile'.tr(),
                  '/Dashboard_Medecin/Profil',
                ),
                _medPcNavItem(
                  context,
                  Icons.settings_outlined,
                  'acc_settings_menu'.tr(),
                  '/Dashboard_Medecin/parametremedecin',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/Authen_Personnel');
              },
              icon: const Icon(Icons.logout, color: Colors.white70, size: 18),
              label: Text(
                'mdash_menu_logout'.tr(),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _medPcNavItem(
    BuildContext context,
    IconData icon,
    String label,
    String? route, {
    bool active = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: active
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: active
            ? Border.all(color: Colors.white.withValues(alpha: 0.3))
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.65),
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.75),
            fontSize: 13.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: route != null ? () => context.push(route) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }

  Widget _buildMedPcContent(BuildContext context) {
    const purple = Color(0xFF5A47C9);
    return Column(
      children: [
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.home_outlined,
                size: 16,
                color: Color(0xFF9E9E9E),
              ),
              const SizedBox(width: 6),
              const Text('/', style: TextStyle(color: Color(0xFF9E9E9E))),
              const SizedBox(width: 6),
              Text(
                'mdash_breadcrumb'.tr(),
                style: const TextStyle(
                  color: purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_hospital, size: 14, color: purple),
                    const SizedBox(width: 6),
                    Text(
                      'auth_hospital_name'.tr(),
                      style: const TextStyle(
                        color: purple,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'mdash_section_dashboard'.tr(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'mdash_section_subtitle'.tr(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                // Stats KPI
                Row(
                  children: [
                    Expanded(
                      child: _medKpiCard(
                        'mdash_stat_consultations_short'.tr(),
                        '$consultationsJour',
                        Icons.assignment,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _medKpiCard(
                        'mdash_action_pending_full'.tr(),
                        '$enAttente',
                        Icons.timer,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _medKpiCard(
                        'mdash_stat_done_full'.tr(),
                        '$terminer',
                        Icons.check_circle,
                        Colors.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'mdash_quick_actions'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _medPcActionCard(
                        context,
                        icon: Icons.person_add,
                        label: 'mdash_action_consultations'.tr(),
                        subtitle: 'mdash_action_consultations_sub'.tr(),
                        color: Colors.blue,
                        route: '/Dashboard_Medecin/ConsultationList',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _medPcActionCard(
                        context,
                        icon: Icons.history,
                        label: 'mdash_action_history'.tr(),
                        subtitle: 'mdash_action_history_sub'.tr(),
                        color: Colors.green,
                        route: '/Dashboard_Medecin/HistoriqueConsultations',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _medPcActionCard(
                        context,
                        icon: Icons.calendar_today,
                        label: 'mdash_action_rdv'.tr(),
                        subtitle: 'mdash_action_rdv_sub'.tr(),
                        color: purple,
                        route: '/Dashboard_Medecin/rendez-vous',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _medPcActionCard(
                        context,
                        icon: Icons.bar_chart,
                        label: 'mdash_action_stats'.tr(),
                        subtitle: 'mdash_action_stats_sub'.tr(),
                        color: Colors.teal,
                        route: '/Dashboard_Medecin/Statistiques',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _medKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _medPcActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required String route,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(route),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'mdash_open'.tr(),
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 12, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ===== FIN PC =====

  // pour les bouton du haut ou on se deconnect et on a les parametre et profil

  PopupMenuEntry<String> _buildPopupMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required int count,
    required String label,
    required Color color,
  }) {
    final bool isPending = label == 'mdash_stat_pending_short'.tr();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xfffffffff).withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Color(0xfffffffff).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String action,
    required Color color,
    required Function(BuildContext, String) onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEAEFF4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onTap(context, action),
          splashColor: color.withOpacity(0.2),
          highlightColor: color.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.3), width: 2),
                  ),
                  child: Icon(icon, size: 36, color: color),
                ),
                const SizedBox(height: 40),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainActionButton() {
    return ElevatedButton(
      onPressed: () {
        context.push('/Dashboard_Medecin/rendez-vous');
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: medPrimaryColor,
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 30),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'mdash_main_btn_title'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'mdash_main_btn_subtitle'.tr(),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
