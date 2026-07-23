import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'Nbr_patient_service.dart';
import 'package:hostoman/shared/responsive_wrapper.dart';
import 'package:hostoman/shared/user_profile_helper.dart';

const Color npPrimaryColor = Color(0xFF1565C0);
const Color npAccentColor = Color(0xFF2196F3);
const Color npSuccessColor = Color(0xFF4CAF50);
const Color npPurpleColor = Color(0xFF7B1FA2);
const Color npPageBackgroundStart = Color(0xFF0D47A1);
const Color npPageBackgroundEnd = Color(0xFF1976D2);
const Color npCardColor = Colors.white; // Nouvelle couleur pour la clarté

class DashboardAccueil extends StatefulWidget {
  const DashboardAccueil({super.key});

  @override
  State<DashboardAccueil> createState() => _DashboardAccueilState();
}

class _DashboardAccueilState extends State<DashboardAccueil> {
  final patientService = PatientDuJourService(Supabase.instance.client);
  int patientsDuJour = 0;
  bool loadingStats = true;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _loadStats(); //appel de la fonction une fois au demarage
    //Pour rafraichir le nombres de patients chaque 5 secondes de a base de données
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    // Simuler un léger délai pour voir l'état de chargement
    await Future.delayed(const Duration(milliseconds: 500));
    final total = await patientService.countPatientsDuJour();
    setState(() {
      patientsDuJour = total;
      loadingStats = false;
    });
  }

  //Pour liberer la mémoire
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _handleTap(BuildContext context, String action) {
    print('Action sélectionnée : $action');
    context.push(action);
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
    final isTablet = size.width > 600;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: npPageBackgroundStart,
      appBar: AppBar(
        backgroundColor: npCardColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: npPrimaryColor.withOpacity(0.1),
              border: Border.all(
                color: npPrimaryColor.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.local_hospital, color: npPrimaryColor, size: 24),
              ),
            ),
          ),
        ),
        title: ConnectedUserText(
          fallback: 'auth_hospital_name'.tr(),
          style: TextStyle(
            color: npPrimaryColor,
            fontSize: isDesktop ? 20 : 20,
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
              color: npCardColor,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) async {
                if (value == 'profile') {
                  context.push('/Dashboard_Accueil/profil');
                } else if (value == 'parametre') {
                  context.push('/Dashboard_Accueil/parametre');
                } else if (value == 'deconnexion') {
                  print('déconnexion sélectionnée');

                  try {
                    await Supabase.instance.client.auth.signOut();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('acc_logout_success'.tr()),
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
                        content: Text('acc_logout_error'.tr()),
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
                  label: 'acc_profile_menu'.tr(),
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
                  label: 'acc_logout_menu'.tr(),
                  color: Colors.red[700]!,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [npPageBackgroundStart, npPageBackgroundEnd],
          ),
        ),
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
                          // En-tête "Actions Rapides"
                          _buildSectionHeader('acc_dashboard_title'.tr()),
                          SizedBox(height: isDesktop ? 70 : 80),

                          // Grille des actions
                          isDesktop
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: _buildActionButton(
                                        context,
                                        icon: Icons.person_add_outlined,
                                        label: 'acc_new_patient'.tr(),
                                        action:
                                            '/Dashboard_Accueil/nouveau-patient',
                                        color: npSuccessColor,
                                        onTap: _handleTap,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: _buildActionButton(
                                        context,
                                        icon: Icons.history_outlined,
                                        label: 'acc_patients_list'.tr(),
                                        action:
                                            '/Dashboard_Accueil/liste-patient',
                                        color: npAccentColor,
                                        onTap: _handleTap,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: _buildActionButton(
                                        context,
                                        icon: Icons.bar_chart_outlined,
                                        label: 'acc_statistics'.tr(),
                                        action:
                                            '/Dashboard_Accueil/statistique',
                                        color: npPurpleColor,
                                        onTap: _handleTap,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildActionButton(
                                            context,
                                            icon: Icons.person_add_outlined,
                                            label: 'acc_new_patient'.tr(),
                                            action:
                                                '/Dashboard_Accueil/nouveau-patient',
                                            color: npSuccessColor,
                                            onTap: _handleTap,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildActionButton(
                                            context,
                                            icon: Icons.history_outlined,
                                            label: 'acc_patients_list'.tr(),
                                            action:
                                                '/Dashboard_Accueil/liste-patient',
                                            color: npAccentColor,
                                            onTap: _handleTap,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // La carte "Statistiques" seule sur mobile/tablette prend toute la largeur
                                    _buildActionButton(
                                      context,
                                      icon: Icons.bar_chart_outlined,
                                      label: 'acc_statistics'.tr(),
                                      action: '/Dashboard_Accueil/statistique',
                                      color: npPurpleColor,
                                      onTap: _handleTap,
                                    ),
                                  ],
                                ),

                          SizedBox(height: isDesktop ? 48 : 32),

                          // Carte des statistiques du jour (Nouvelle disposition horizontale)
                          _buildTodayStatsCard(isDesktop, isTablet),

                          const SizedBox(height: 24),
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
                  color: Colors.black.withOpacity(0.03),
                ),
                child: Text(
                  'acc_footer_copyright'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
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

  // ========== LAYOUT PC ==========
  Widget _buildPcLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Row(
        children: [
          // ── SIDEBAR ──
          _buildPcSidebar(context),
          // ── CONTENU ──
          Expanded(child: _buildPcContent(context)),
        ],
      ),
    );
  }

  Widget _buildPcSidebar(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
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
          // Logo + Titre
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
                  'acc_module_label'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
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
          // Navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _pcNavItem(
                  context,
                  Icons.dashboard,
                  'acc_nav_dashboard'.tr(),
                  null,
                  active: true,
                ),
                _pcNavItem(
                  context,
                  Icons.person_add,
                  'acc_new_patient'.tr(),
                  '/Dashboard_Accueil/nouveau-patient',
                ),
                _pcNavItem(
                  context,
                  Icons.people,
                  'acc_nav_patients_list'.tr(),
                  '/Dashboard_Accueil/liste-patient',
                ),
                _pcNavItem(
                  context,
                  Icons.bar_chart,
                  'acc_statistics'.tr(),
                  '/Dashboard_Accueil/statistique',
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.15)),
                _pcNavItem(
                  context,
                  Icons.person_outline,
                  'acc_nav_profil'.tr(),
                  '/Dashboard_Accueil/profil',
                ),
                _pcNavItem(
                  context,
                  Icons.settings_outlined,
                  'acc_settings_menu'.tr(),
                  '/Dashboard_Accueil/parametre',
                ),
              ],
            ),
          ),
          // Déconnexion
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/Authen_Personnel');
              },
              icon: const Icon(Icons.logout, color: Color(0xFFEF5350), size: 18),
              label: Text(
                'acc_logout_menu'.tr(),
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

  Widget _pcNavItem(
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
            ? Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1)
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

  Widget _buildPcContent(BuildContext context) {
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
                'acc_dashboard_title'.tr(),
                style: const TextStyle(
                  color: npPrimaryColor,
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
                  color: npPrimaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: npPrimaryColor),
                    const SizedBox(width: 6),
                    ConnectedUserText(
                      fallback: 'auth_hospital_name'.tr(),
                      style: const TextStyle(
                        color: npPrimaryColor,
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
        // Corps
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre section
                Text(
                  'acc_dashboard_topbar'.tr(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'acc_dashboard_welcome'.tr(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 28),

                // Carte patients du jour (grande)
                _buildPcStatsCard(),
                const SizedBox(height: 28),

                // Grille actions
                Text(
                  'acc_actions_rapides'.tr(),
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
                      child: _buildPcActionCard(
                        context,
                        icon: Icons.person_add_outlined,
                        label: 'acc_new_patient'.tr(),
                        subtitle: 'acc_new_patient_sub'.tr(),
                        color: npSuccessColor,
                        route: '/Dashboard_Accueil/nouveau-patient',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPcActionCard(
                        context,
                        icon: Icons.people_outline,
                        label: 'acc_patients_list'.tr(),
                        subtitle: 'acc_patients_list_sub'.tr(),
                        color: npAccentColor,
                        route: '/Dashboard_Accueil/liste-patient',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPcActionCard(
                        context,
                        icon: Icons.bar_chart_outlined,
                        label: 'acc_statistics'.tr(),
                        subtitle: 'acc_statistics_sub'.tr(),
                        color: npPurpleColor,
                        route: '/Dashboard_Accueil/statistique',
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

  Widget _buildPcStatsCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [npPrimaryColor, npAccentColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: npPrimaryColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_alt, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loadingStats ? '...' : '$patientsDuJour',
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'acc_today_patients_short'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.today, color: Colors.white70, size: 20),
                const SizedBox(height: 4),
                Text(
                  _todayDate(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _todayDate() {
    final now = DateTime.now();
    // Format localisé selon la langue active (FR ou EN)
    final locale = context.locale.toString();
    return DateFormat('d MMM yyyy', locale).format(now);
  }

  Widget _buildPcActionCard(
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
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'acc_open_action'.tr(),
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
      ),
    );
  }

  // ===== FIN LAYOUT PC =====

  // Fonctions de construction existantes (PopupMenu, Header, ActionButton) ...
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

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: npCardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: npPrimaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home, color: npPrimaryColor, size: 30),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: npPrimaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String action,
    required Color color,
    required Function(BuildContext, String) onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: npCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
        ),
      ),
    );
  }

  // NOUVELLE VERSION : Correction du débordement avec Expanded
  Widget _buildTodayStatsCard(bool isDesktop, bool isTablet) {
    // Si les données sont en cours de chargement
    if (loadingStats) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: npCardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: npPrimaryColor),
            const SizedBox(width: 16),
            Text(
              'acc_stats_loading'.tr(),
              style: const TextStyle(
                color: npPrimaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Carte Statistique en mode Ligne
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 28,
        vertical: isDesktop ? 32 : 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [npPrimaryColor, npAccentColor],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: npPrimaryColor.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bloc 1 : Icône et Labels (DOIT ÊTRE FLEXIBLE)
          Expanded(
            // <--- AJOUT CRUCIAL ICI
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône et fond blanc pour le contraste
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: npCardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.people_alt_outlined,
                    size: 36,
                    color: npPrimaryColor,
                  ),
                ),
                const SizedBox(width: 24),
                // Nous n'avons pas besoin d'Expanded ici car Column gère bien la verticalité
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bloc 2 : Le Nombre (Utilise la taille minimale requise)
                    Text(
                      '         $patientsDuJour',
                      style: TextStyle(
                        fontSize: isDesktop ? 45 : 35,
                        fontWeight: FontWeight.w900,
                        color: npCardColor,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'acc_today_patients_caps'.tr(),
                      style: TextStyle(
                        fontSize: isDesktop ? 20 : 18,
                        fontWeight: FontWeight.w600,
                        color: npCardColor.withOpacity(0.95),
                        letterSpacing: 1,
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
}
