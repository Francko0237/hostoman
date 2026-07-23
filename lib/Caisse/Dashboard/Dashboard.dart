import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'Nbr&Caisse.dart';
import 'package:hostoman/shared/responsive_wrapper.dart';
import 'package:hostoman/shared/user_profile_helper.dart';

// Couleurs
const Color npPrimaryColor = Color(0xFF4CAF50);
const Color npAccentColor = Color(0xFF378127);
const Color npSuccessColor = Color(0xFF4CAF50);
const Color npOrangeColor = Color(0xFFFF9800);
const Color fondColor = Color(0xFFF5F3F3);

class DashboardCaisse extends StatefulWidget {
  const DashboardCaisse({super.key});

  @override
  State<DashboardCaisse> createState() => _DashboardCaisseState();
}

class _DashboardCaisseState extends State<DashboardCaisse> {
  final DashboardStatsService statsService = DashboardStatsService(
    Supabase.instance.client,
  );

  int personnesRecues = 0;
  int totalEncaisse = 0;
  int paiementsEnAttente = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _chargerStats(); // Appel de la fonction une fois au démarrage

    // Pour rafraîchir le nombre de patients chaque 5 secondes depuis la base de données
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _chargerStats();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Annuler le timer quand on quitte la page
    super.dispose();
  }

  Future<void> _chargerStats() async {
    final stats = await statsService.getStatsJour();
    if (mounted) {
      setState(() {
        personnesRecues = stats['personnes_recues'] as int;
        totalEncaisse = stats['total_encaisse'] as int;
        paiementsEnAttente = stats['en_attente'] as int? ?? 0;
      });
    }
  }

  void _handleTap(BuildContext context, String action) {
    context.push('/Dashboard_Caisse/$action');
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
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: fondColor,
      appBar: AppBar(
        backgroundColor: Color(0xFF274621),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: npPrimaryColor.withOpacity(0.2),
              border: Border.all(
                color: npPrimaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/images/logo.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        title: ConnectedUserText(
          fallback: 'auth_hospital_name'.tr(),
          style: TextStyle(
            color: Color(0xFF26AE6C),
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
              color: npPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: PopupMenuButton(
              icon: Icon(Icons.person, color: npPrimaryColor),
              color: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) async {
                if (value == 'profile') {
                  context.push('/Dashboard_Caisse/profilcaisse');
                } else if (value == 'parametre') {
                  context.push('/Dashboard_Caisse/parametrecaisse');
                } else if (value == 'deconnexion') {
                  print('déconnexion sélectionnée');
                  try {
                    await Supabase.instance.client.auth.signOut();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('cdash_logout_success'.tr()),
                        backgroundColor: npSuccessColor,
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
                        content: Text('cdash_logout_error'.tr()),
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
                  label: 'cdash_menu_profile'.tr(),
                  color: npPrimaryColor,
                ),

                _buildPopupMenuItem(
                  value: 'parametre',
                  icon: Icons.settings_outlined,
                  label: 'acc_settings_menu'.tr(),
                  color: npPrimaryColor,
                ),

                _buildPopupMenuItem(
                  value: 'deconnexion',
                  icon: Icons.logout_outlined,
                  label: 'cdash_menu_logout'.tr(),
                  color: Colors.red[700]!,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        color: Color(0xFFF5F3F3),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 900 : double.infinity,
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 48 : (isTablet ? 32 : 20),
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Titre Dashboard Caisse
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [npPrimaryColor, npAccentColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: npPrimaryColor.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'cdash_title'.tr(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isDesktop ? 50 : 30),

                          // Statistiques (Personne Reçue + Total Encaissé)
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  title: 'cdash_stat_received_day'.tr(),
                                  value: personnesRecues.toString(),
                                  color: npOrangeColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  title: 'cdash_stat_total_day'.tr(),
                                  value: 'cdash_amount_fcfa'.tr(
                                    namedArgs: {
                                      'value': statsService.formatMontant(
                                        totalEncaisse,
                                      ),
                                    },
                                  ),
                                  color: npSuccessColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isDesktop ? 32 : 40),

                          // Actions principales (2x2 grid)
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionCard(
                                  context: context,
                                  icon: Icons.access_time,
                                  label: 'cdash_action_pending'.tr(),
                                  action: 'paiementlist',
                                  color: npSuccessColor,
                                  onTap: _handleTap,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildActionCard(
                                  context: context,
                                  icon: Icons.history,
                                  label: 'cdash_action_history'.tr(),
                                  action: 'HistoriquePaiement',
                                  color: npAccentColor,
                                  onTap: _handleTap,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Statistiques (pleine largeur)
                          _buildActionCard(
                            context: context,
                            icon: Icons.analytics,
                            label: 'cdash_action_stats'.tr(),
                            action: 'Statistiques',
                            color: const Color(0xFF2196F3),
                            onTap: _handleTap,
                          ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.02),
                ),
                child: Text(
                  'cdash_footer'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.95),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } // end _buildMobileLayout

  // ===== LAYOUT PC =====
  Widget _buildPcLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5F1),
      body: Row(
        children: [
          _buildCaissePcSidebar(context),
          Expanded(child: _buildCaissePcContent(context)),
        ],
      ),
    );
  }

  Widget _buildCaissePcSidebar(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
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
                  'cdash_title_short'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                ConnectedUserText(
                  fallback: 'auth_hospital_name'.tr(),
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
                _caissePcNavItem(
                  context,
                  Icons.dashboard,
                  'cdash_nav_dashboard'.tr(),
                  null,
                  active: true,
                ),
                _caissePcNavItem(
                  context,
                  Icons.access_time,
                  'cdash_action_pending'.tr(),
                  '/Dashboard_Caisse/paiementlist',
                ),
                _caissePcNavItem(
                  context,
                  Icons.history,
                  'cdash_action_history_short'.tr(),
                  '/Dashboard_Caisse/HistoriquePaiement',
                ),
                _caissePcNavItem(
                  context,
                  Icons.analytics,
                  'cdash_action_stats'.tr(),
                  '/Dashboard_Caisse/Statistiques',
                ),
                Divider(color: Colors.white.withValues(alpha: 0.15)),
                _caissePcNavItem(
                  context,
                  Icons.person_outline,
                  'cdash_nav_profile'.tr(),
                  '/Dashboard_Caisse/profilcaisse',
                ),
                _caissePcNavItem(
                  context,
                  Icons.settings_outlined,
                  'acc_settings_menu'.tr(),
                  '/Dashboard_Caisse/parametrecaisse',
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
              icon: const Icon(Icons.logout, color: Color(0xFFEF5350), size: 18),
              label: Text(
                'cdash_menu_logout'.tr(),
                style: const TextStyle(
                  color: Color(0xFFEF5350),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
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

  Widget _caissePcNavItem(
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

  Widget _buildCaissePcContent(BuildContext context) {
    const green = Color(0xFF2E7D32);
    const lightGreen = Color(0xFF4CAF50);
    return Column(
      children: [
        // TopBar
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
                'cdash_breadcrumb'.tr(),
                style: const TextStyle(
                  color: green,
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
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: green),
                    const SizedBox(width: 6),
                    ConnectedUserText(
                      fallback: 'auth_hospital_name'.tr(),
                      style: const TextStyle(
                        color: green,
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
                  'cdash_section_dashboard'.tr(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'cdash_section_subtitle'.tr(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 28),
                // KPIs
                Row(
                  children: [
                    Expanded(
                      child: _kpiCard(
                        'cdash_stat_received_short'.tr(),
                        '$personnesRecues',
                        Icons.people_outline,
                        const Color(0xFFFF9800),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _kpiCard(
                        'cdash_stat_total_short'.tr(),
                        'cdash_amount_fcfa'.tr(
                          namedArgs: {
                            'value': statsService.formatMontant(totalEncaisse),
                          },
                        ),
                        Icons.payments_outlined,
                        lightGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'cdash_quick_actions'.tr(),
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
                      child: _caissePcActionCard(
                        context,
                        icon: Icons.access_time,
                        label: 'cdash_action_pending'.tr(),
                        subtitle: 'cdash_action_pending_sub'.tr(),
                        color: lightGreen,
                        route: '/Dashboard_Caisse/paiementlist',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _caissePcActionCard(
                        context,
                        icon: Icons.history,
                        label: 'cdash_action_history_short'.tr(),
                        subtitle: 'cdash_action_history_sub'.tr(),
                        color: green,
                        route: '/Dashboard_Caisse/HistoriquePaiement',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _caissePcActionCard(
                        context,
                        icon: Icons.analytics_outlined,
                        label: 'cdash_action_stats'.tr(),
                        subtitle: 'cdash_action_stats_sub'.tr(),
                        color: const Color(0xFF2196F3),
                        route: '/Dashboard_Caisse/Statistiques',
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

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _caissePcActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required String route,
  }) {
    final bool isPending = route.endsWith('paiementlist') && paiementsEnAttente > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(route),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        'cdash_open'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 14, color: color),
                    ],
                  ),
                ],
              ),
            ),
            if (isPending)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    '$paiementsEnAttente',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
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
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
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
    final bool isPending = action == 'paiementlist' && paiementsEnAttente > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
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
                    const SizedBox(height: 16),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPending)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD32F2F),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '$paiementsEnAttente',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
