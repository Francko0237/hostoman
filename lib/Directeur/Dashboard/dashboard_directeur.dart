import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/Directeur/EtatServices/etat_services_ui.dart';
import 'package:hostoman/Directeur/GestionPersonnel/gestion_personnel_page.dart';
import 'package:hostoman/Directeur/Statistiques/stats_view.dart';
import 'package:hostoman/Directeur/Dashboard/home_directeur.dart';
import 'package:hostoman/Directeur/Dashboard/home_directeur_service.dart';
import 'package:hostoman/shared/responsive_wrapper.dart';
import 'package:hostoman/Directeur/Dashboard/parametre_directeur.dart';
import 'package:hostoman/Directeur/Dashboard/notifications_bell.dart';
import 'package:easy_localization/easy_localization.dart';

// Palette du module Directeur
const Color dirPrimaryColor = Color(0xFF1A237E);
const Color dirPrimaryDark = Color(0xFF0D1333);
const Color dirAccentColor = Color(0xFFFFD700);
const Color dirBackgroundColor = Color(0xFFF5F6FA);

class DirecteurDashboardPage extends StatefulWidget {
  const DirecteurDashboardPage({super.key});

  @override
  State<DirecteurDashboardPage> createState() => _DirecteurDashboardPageState();
}

class _DirecteurDashboardPageState extends State<DirecteurDashboardPage> {
  int _selectedIndex = 0;
  Map<String, dynamic> _adminProfile = {};
  // Clé pour piloter le Scaffold mobile (fermer le drawer après navigation).
  final GlobalKey<ScaffoldState> _mobileScaffoldKey =
      GlobalKey<ScaffoldState>();

  List<_NavItem> get _navItems => [
    _NavItem(
      icon: Icons.dashboard_rounded,
      activeIcon: Icons.dashboard,
      label: 'nav_home'.tr(),
    ),
    _NavItem(
      icon: Icons.monitor_heart_outlined,
      activeIcon: Icons.monitor_heart,
      label: 'nav_services'.tr(),
    ),
    _NavItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
      label: 'nav_stats'.tr(),
    ),
    _NavItem(
      icon: Icons.people_alt_outlined,
      activeIcon: Icons.people_alt,
      label: 'nav_staff'.tr(),
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'nav_settings'.tr(),
    ),
  ];

  // Getter (pas `late final`) pour que les pages soient recreees a chaque
  // build. La cle liee a la locale force la reconstruction de chaque
  // sous-arbre quand la langue change, meme pour les pages inactives de
  // l'IndexedStack.
  List<Widget> get _pages {
    final localeKey = context.locale.toString();
    return [
      HomeDirecteurPage(key: ValueKey('home_$localeKey'), onNavigate: _onNav),
      EtatServicesPage(key: ValueKey('services_$localeKey')),
      stats_view(key: ValueKey('stats_$localeKey')),
      GestionPersonnelPage(key: ValueKey('staff_$localeKey')),
      ParametreDirecteurPage(key: ValueKey('settings_$localeKey')),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await HomeDirecteurService(
      Supabase.instance.client,
    ).getAdminProfile();
    if (mounted) setState(() => _adminProfile = p);
  }

  void _onNav(int index) {
    setState(() => _selectedIndex = index);
    // Fermer le drawer mobile si ouvert (via la GlobalKey du Scaffold mobile,
    // car Scaffold.maybeOf(context) ne marche pas depuis le State qui est
    // au-dessus du Scaffold dans l'arbre).
    final scaffoldState = _mobileScaffoldKey.currentState;
    if (scaffoldState != null && scaffoldState.isDrawerOpen) {
      scaffoldState.closeDrawer();
    }
  }

  /// Mappe un nom d'onglet textuel (utilisé par les notifications)
  /// vers l'index de la BottomNavigation/Sidebar.
  void _onNavByName(String tabName) {
    final index = switch (tabName) {
      'overview' || 'home' => 0,
      'services' => 1,
      'finance' || 'stats' || 'patients' => 2,
      'staff' => 3,
      'settings' => 4,
      _ => 0,
    };
    _onNav(index);
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/Authen_Personnel');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${'error_prefix'.tr()}: $e')));
      }
    }
  }

  String _initials() {
    final p = (_adminProfile['Prenom'] ?? '').toString();
    final n = (_adminProfile['Nom'] ?? '').toString();
    final i1 = p.isNotEmpty ? p[0] : 'A';
    final i2 = n.isNotEmpty ? n[0] : 'D';
    return (i1 + i2).toUpperCase();
  }

  String _fullName() {
    final p = (_adminProfile['Prenom'] ?? '').toString();
    final n = (_adminProfile['Nom'] ?? '').toString();
    final f = '$p $n'.trim();
    if (f.isEmpty) return 'administrator'.tr();
    final spec = (_adminProfile['Specialite'] ?? '').toString().toLowerCase();
    if (spec.contains('médecin') || spec.contains('medecin')) {
      return 'Dr. $f';
    }
    return f;
  }

  Future<bool> _onBackPressed() async {
    // Si on n'est pas sur l'onglet Accueil, retourner à l'Accueil au lieu de quitter
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
      return false;
    }
    // Sur l'Accueil : demander confirmation avant de quitter
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('dialog_quit_title'.tr()),
        content: Text('dialog_quit_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('dialog_cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: dirPrimaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('dialog_quit'.tr()),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final allow = await _onBackPressed();
        if (allow && mounted) {
          // Retour vers l'authentification (vide la pile route)
          context.go('/Authen_Personnel');
        }
      },
      child: ResponsiveLayout(
        mobile: _buildMobile(),
        pc: _buildDesktop(),
        breakpoint: 900,
      ),
    );
  }

  // ============================== MOBILE ==============================
  Widget _buildMobile() {
    return Scaffold(
      key: _mobileScaffoldKey,
      backgroundColor: dirBackgroundColor,
      drawer: _buildMobileDrawer(),
      appBar: AppBar(
        backgroundColor: dirPrimaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Icon(
              _navItems[_selectedIndex].activeIcon,
              color: dirAccentColor,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              _navItems[_selectedIndex].label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        actions: [
          NotificationsBell(
            iconColor: Colors.white,
            onNavigateToTab: _onNavByName,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: dirPrimaryDark,
      child: SafeArea(
        child: Column(
          children: [
            _buildBrandHeader(compact: false),
            const SizedBox(height: 8),
            _buildProfileCard(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _navItems.length,
                itemBuilder: (ctx, i) => _sideNavItem(i),
              ),
            ),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  // ============================== DESKTOP ==============================
  Widget _buildDesktop() {
    return Scaffold(
      backgroundColor: dirBackgroundColor,
      body: Row(
        children: [
          _buildDesktopSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: IndexedStack(index: _selectedIndex, children: _pages),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [dirPrimaryDark, dirPrimaryColor],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 24,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildBrandHeader(compact: false),
          const SizedBox(height: 4),
          _buildProfileCard(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _navItems.length,
              itemBuilder: (ctx, i) => _sideNavItem(i),
            ),
          ),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildBrandHeader({required bool compact}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, compact ? 24 : 32, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: dirAccentColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.local_hospital_rounded,
                      color: dirPrimaryColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'sidebar_hospital'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'sidebar_location'.tr(),
                      style: const TextStyle(
                        color: dirAccentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  dirAccentColor.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [dirAccentColor, Color(0xFFFFA000)],
                ),
              ),
              child: Center(
                child: Text(
                  _initials(),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fullName(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    (_adminProfile['Specialite'] ?? 'director'.tr()).toString(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sideNavItem(int index) {
    final isActive = _selectedIndex == index;
    final item = _navItems[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive
            ? dirAccentColor.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isActive
            ? Border.all(color: dirAccentColor.withValues(alpha: 0.35))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _onNav(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive ? dirAccentColor : Colors.white60,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontSize: 13.5,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: dirAccentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    const danger = Color(0xFFDC2626);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: ElevatedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: Text(
          'sidebar_logout'.tr(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: danger,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.home_outlined, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Text(
            'breadcrumb_home'.tr(),
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Colors.grey[400],
            ),
          ),
          Icon(
            _navItems[_selectedIndex].activeIcon,
            size: 16,
            color: dirPrimaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            _navItems[_selectedIndex].label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: dirPrimaryColor,
            ),
          ),
          const Spacer(),
          NotificationsBell(
            iconColor: dirPrimaryColor,
            onNavigateToTab: _onNavByName,
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
