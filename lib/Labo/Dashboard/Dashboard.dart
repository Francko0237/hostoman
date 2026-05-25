import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_service.dart';
import '../resultats_des_examens/resultat_des_examens.dart';
import 'package:hostoman/shared/responsive_wrapper.dart';

// ============================================================================
// CONSTANTES
// ============================================================================

class LabTheme {
  static const Color primaryColor = Color(0xFF212031);
  static const Color accentColor = Color(0xFF212031);
  static const Color cardBackground = Colors.white;
  static const Color textColor = Color(0xFF212121);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color attentionColor = Colors.red;
}

// ============================================================================
// MODÈLES DE DONNÉES
// ============================================================================

class ExamenEnCours {
  final String patientName;
  final String examDetails;

  ExamenEnCours({required this.patientName, required this.examDetails});
}

// ============================================================================
// WIDGET PRINCIPAL
// ============================================================================

class DashboardLaboratoire extends StatefulWidget {
  const DashboardLaboratoire({super.key});

  @override
  State<DashboardLaboratoire> createState() => _DashboardLaboratoireState();
}

class _DashboardLaboratoireState extends State<DashboardLaboratoire> {
  final dashboardService = DashboardLaboService(Supabase.instance.client);

  // État des données
  int patientsEnAttenteExamen = 0;
  int patientsEnAttenteResultat = 0;
  List<Map<String, dynamic>> patientsEnCours = [];
  bool isLoading = true;
  String? errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    chargerDonnees();
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        chargerDonnees(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> chargerDonnees({bool silent = false}) async {
    if (!silent) setState(() => isLoading = true);
    try {
      final stats = await dashboardService.getStatistiquesJour();
      final patients = await dashboardService.getPatientsEnAttenteResultat();

      if (mounted) {
        setState(() {
          patientsEnAttenteExamen = stats['en_attente_examen'] ?? 0;
          patientsEnAttenteResultat = stats['en_attente_resultat'] ?? 0;
          patientsEnCours = patients;
          isLoading = false;
          errorMessage = null; // Clear error on success
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          if (!silent) {
            errorMessage = 'labd_server_error'.tr();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileScaffold(context),
      pc: _buildPcLayout(context),
    );
  }

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: LabTheme.primaryColor,
      appBar: _CustomAppBar(onMenuSelected: _handleMenuSelection),
      bottomNavigationBar: _CustomBottomNav(currentIndex: 0),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: LabTheme.primaryColor),
            )
          : errorMessage != null
          ? _buildError()
          : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: chargerDonnees,
            icon: const Icon(Icons.refresh),
            label: Text('labd_retry'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: LabTheme.primaryColor,
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

  // ===== LAYOUT PC LABO =====
  Widget _buildPcLayout(BuildContext context) {
    const darkNavy = Color(0xFF1A1A2E);
    const labColor = Color(0xFF212031);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 240,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F0E1A), darkNavy],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x60000000),
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
                          color: Colors.white.withValues(alpha: 0.1),
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
                        'labd_module_name'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'auth_hospital_name'.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(width: 40, height: 2, color: Colors.white24),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _labPcNavItem(
                        context,
                        Icons.dashboard,
                        'labd_nav_dashboard'.tr(),
                        null,
                        active: true,
                      ),
                      _labPcNavItem(
                        context,
                        Icons.science_outlined,
                        'labd_action_exams_todo'.tr(),
                        '/Dashboard_Laboratoire/ExamensAFaire',
                      ),
                      _labPcNavItem(
                        context,
                        Icons.check_circle_outline,
                        'labd_action_results'.tr(),
                        '/Dashboard_Laboratoire/Resultats',
                      ),
                      _labPcNavItem(
                        context,
                        Icons.bar_chart,
                        'labd_action_stats'.tr(),
                        '/Dashboard_Laboratoire/Statistiques',
                      ),
                      _labPcNavItem(
                        context,
                        Icons.history,
                        'labd_action_history'.tr(),
                        '/Dashboard_Laboratoire/Historique',
                      ),
                      Divider(color: Colors.white.withValues(alpha: 0.1)),
                      _labPcNavItem(
                        context,
                        Icons.person_outline,
                        'labd_nav_profile'.tr(),
                        '/Dashboard_Laboratoire/Profil',
                      ),
                      _labPcNavItem(
                        context,
                        Icons.settings_outlined,
                        'labd_nav_settings'.tr(),
                        '/Dashboard_Laboratoire/parametrelaboratoire',
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
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white54,
                      size: 18,
                    ),
                    label: Text(
                      'labd_menu_logout'.tr(),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
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
          ),
          // Content
          Expanded(
            child: Column(
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
                      const Text(
                        '/',
                        style: TextStyle(color: Color(0xFF9E9E9E)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'labd_breadcrumb'.tr(),
                        style: TextStyle(
                          color: labColor,
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
                          color: labColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_hospital,
                              size: 14,
                              color: labColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'auth_hospital_name'.tr(),
                              style: TextStyle(
                                color: labColor,
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
                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'labd_section_title'.tr(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'labd_section_subtitle'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // KPIs
                        Row(
                          children: [
                            Expanded(
                              child: _labKpiCard(
                                'labd_kpi_pending_exam'.tr(),
                                '$patientsEnAttenteExamen',
                                Icons.science_outlined,
                                Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _labKpiCard(
                                'labd_kpi_pending_result'.tr(),
                                '$patientsEnAttenteResultat',
                                Icons.hourglass_empty,
                                labColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'labd_quick_actions'.tr(),
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
                              child: _labPcActionCard(
                                context,
                                icon: Icons.science_outlined,
                                label: 'labd_action_exams_todo'.tr(),
                                subtitle: 'labd_action_exams_todo_sub'.tr(),
                                color: labColor,
                                route: '/Dashboard_Laboratoire/ExamensAFaire',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _labPcActionCard(
                                context,
                                icon: Icons.check_circle_outline,
                                label: 'labd_action_results'.tr(),
                                subtitle: 'labd_action_results_sub'.tr(),
                                color: LabTheme.successColor,
                                route: '/Dashboard_Laboratoire/Resultats',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _labPcActionCard(
                                context,
                                icon: Icons.bar_chart,
                                label: 'labd_action_stats'.tr(),
                                subtitle: 'labd_action_stats_sub'.tr(),
                                color: Colors.blue,
                                route: '/Dashboard_Laboratoire/Statistiques',
                              ),
                            ),
                          ],
                        ),
                        if (patientsEnCours.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          Text(
                            'labd_section_ongoing'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: labColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...patientsEnCours.map((patient) {
                            final patientMap =
                                patient['Patient'] as Map<String, dynamic>;
                            final nom =
                                patientMap['nom_complet'] ??
                                'labd_unknown_patient'.tr();
                            final examens = patient['examens_details'] ?? '';
                            return _ExamenListItem(
                              patientName: nom,
                              examDetails: examens,
                              onFinalize: () => _handleFinalizeExamen(patient),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _labPcNavItem(
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
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: active
            ? Border.all(color: Colors.white.withValues(alpha: 0.2))
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: active ? Colors.white : Colors.white54,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white60,
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

  Widget _labKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(22),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
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
                  fontSize: 28,
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

  Widget _labPcActionCard(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
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
                    'labd_open'.tr(),
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
  // ===== FIN PC LABO =====

  // Construction du corps
  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 25),
          // Container Dashboard arrondi
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'labd_title'.tr(),
                style: TextStyle(
                  color: LabTheme.primaryColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildStatisticsSection(),
          const SizedBox(height: 30),
          _buildActionsSection(),
          const SizedBox(height: 40),
          _buildExamensSection(),
        ],
      ),
    );
  }

  // Section statistiques
  Widget _buildStatisticsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'labd_kpi_pending_exam_mobile'.tr(),
              count: patientsEnAttenteExamen,
              textColor: Colors.orange.shade800,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'labd_kpi_pending_result_mobile'.tr(),
              count: patientsEnAttenteResultat,
              textColor: LabTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // Section actions
  Widget _buildActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              icon: Icons.science_outlined,
              label: 'labd_action_exams_todo'.tr(),
              color: LabTheme.accentColor.withOpacity(0.1),
              iconColor: LabTheme.accentColor,
              onTap: () => context.push('/Dashboard_Laboratoire/ExamensAFaire'),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _ActionCard(
              icon: Icons.check_circle_outline,
              label: 'labd_action_results'.tr(),
              color: LabTheme.successColor.withOpacity(0.1),
              iconColor: LabTheme.successColor,
              onTap: () => context.push('/Dashboard_Laboratoire/Resultats'),
            ),
          ),
        ],
      ),
    );
  }

  // Section examens en cours
  Widget _buildExamensSection() {
    return Container(
      decoration: const BoxDecoration(
        color: LabTheme.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'labd_section_ongoing_mobile'.tr(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: LabTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 15),
          _buildExamensList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Liste des examens
  Widget _buildExamensList() {
    if (patientsEnCours.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text(
            'labd_ongoing_empty'.tr(),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SizedBox(
      height: 400,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: patientsEnCours.length,
        itemBuilder: (context, index) {
          final patient = patientsEnCours[index];
          final patientMap = patient['Patient'] as Map<String, dynamic>;
          final nomComplet =
              patientMap['nom_complet'] ?? 'labd_unknown_patient'.tr();
          final examensDetails = patient['examens_details'] ?? '';

          return _ExamenListItem(
            patientName: nomComplet,
            examDetails: examensDetails,
            onFinalize: () => _handleFinalizeExamen(patient),
          );
        },
      ),
    );
  }

  // Gestion de la sélection du menu
  void _handleMenuSelection(String value) async {
    if (value == 'profile') {
      context.go('/Dashboard_Laboratoire/Profil');
    } else if (value == 'settings') {
      context.push('/Dashboard_Laboratoire/parametrelaboratoire');
    } else if (value == 'deconnexion') {
      await _handleDeconnexion();
    }
  }

  // Gestion de la déconnexion
  Future<void> _handleDeconnexion() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('labd_logout_success'.tr()),
            backgroundColor: LabTheme.successColor,
          ),
        );
        context.go('/Authen_Personnel');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('labd_logout_error'.tr()),
            backgroundColor: LabTheme.attentionColor,
          ),
        );
      }
    }
  }

  // Gestion de la finalisation d'examen
  void _handleFinalizeExamen(Map<String, dynamic> patient) {
    final patientMap = patient['Patient'] as Map<String, dynamic>;
    final nomComplet = patientMap['nom_complet'] ?? 'labd_unknown_patient'.tr();
    final idConsultation = patient['id_consultation'];
    final telephone =
        patientMap['telephone']?.toString() ?? 'pay_value_na'.tr();
    final age = patient['age'] != null
        ? patient['age'].toString()
        : (patientMap['age'] != null ? patientMap['age'].toString() : '0');
    final sexe = patientMap['sexe'] ?? 'pay_value_na'.tr();

    final data = PatientResultatData(
      nomComplet: nomComplet,
      sexe: sexe,
      age: age,
      telephone: telephone,
    );

    context
        .push(
          '/Dashboard_Laboratoire/ResultatDetail/$idConsultation',
          extra: data,
        )
        .then((_) {
          // Recharger les données au retour
          chargerDonnees();
        });
  }
}

// ============================================================================
// COMPOSANTS RÉUTILISABLES
// ============================================================================

// AppBar personnalisée
class _CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Function(String) onMenuSelected;

  const _CustomAppBar({required this.onMenuSelected});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: LabTheme.primaryColor,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.local_hospital, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
      // Titre avec bordure arrondie
      title: Container(
        child: Text(
          'auth_hospital_name'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      centerTitle: false,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
          ),
          child: PopupMenuButton(
            icon: const Icon(Icons.person, color: Colors.white, size: 28),
            color: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            onSelected: onMenuSelected,
            itemBuilder: (context) => [
              _buildPopupMenuItem(
                value: 'profile',
                icon: Icons.person_outline,
                label: 'labd_menu_profile'.tr(),
                color: LabTheme.primaryColor,
              ),
              const PopupMenuDivider(),
              _buildPopupMenuItem(
                value: 'settings',
                icon: Icons.settings_outlined,
                label: 'labd_menu_settings'.tr(),
                color: LabTheme.primaryColor,
              ),
              const PopupMenuDivider(),
              _buildPopupMenuItem(
                value: 'deconnexion',
                icon: Icons.logout_outlined,
                label: 'labd_menu_logout'.tr(),
                color: LabTheme.attentionColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

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
}

// Carte de statistiques
class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color textColor;

  const _StatCard({
    required this.label,
    required this.count,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LabTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: LabTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              color: textColor,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// Carte d'action
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: LabTheme.cardBackground,
          borderRadius: BorderRadius.circular(15),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 36, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: LabTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Item de la liste d'examens
class _ExamenListItem extends StatelessWidget {
  final String patientName;
  final String examDetails;
  final VoidCallback onFinalize;

  const _ExamenListItem({
    required this.patientName,
    required this.examDetails,
    required this.onFinalize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 15),
            _buildPatientInfo(),
            const SizedBox(width: 10),
            _buildFinalizeButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: LabTheme.successColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          patientName.isNotEmpty ? patientName.substring(0, 1) : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPatientInfo() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            patientName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: LabTheme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            examDetails,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFinalizeButton() {
    return ElevatedButton(
      onPressed: onFinalize,
      style: ElevatedButton.styleFrom(
        backgroundColor: LabTheme.successColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      ),
      child: Text(
        'labd_finalize_btn'.tr(),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

// Bottom Navigation Bar
class _CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const _CustomBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: Colors.white,
      selectedItemColor: LabTheme.primaryColor,
      unselectedItemColor: Colors.grey.shade500,
      showUnselectedLabels: true,
      onTap: (index) => _handleNavigation(context, index),
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard),
          label: 'labd_bottom_dashboard'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.bar_chart),
          label: 'labd_bottom_stats'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.history),
          label: 'labd_bottom_history'.tr(),
        ),
      ],
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Already on dashboard, do nothing
        break;
      case 1:
        context.push('/Dashboard_Laboratoire/Statistiques');
        break;
      case 2:
        context.push('/Dashboard_Laboratoire/Historique');
        break;
    }
  }
}
