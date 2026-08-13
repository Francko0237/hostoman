import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/shared/user_profile_helper.dart';

/// Couleurs et styles partagés du module Pharmacie.
class PharmacieTheme {
  static const Color primary = Color(0xFF2E7D5B); // vert sapin
  static const Color primaryDark = Color(0xFF1F5A40);
  static const Color accent = Color(0xFF4ECDC4); // menthe
  static const Color background = Color(0xFFF4F7F5);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF1A2E1F);
  static const Color textMuted = Color(0xFF5C7468);
  static const Color border = Color(0xFFE3E9E5);
  static const Color warn = Color(0xFFE67E22);
  static const Color danger = Color(0xFFE53935);
  static const Color success = Color(0xFF2E7D5B);

  /// Élément de navigation pour la sidebar/drawer pharmacie.
  static const List<PharmacieNavItem> navItems = [
    PharmacieNavItem(
      icon: Icons.dashboard_outlined,
      labelKey: 'phar_nav_dashboard',
      route: '/Dashboard_Pharmacie',
    ),
    PharmacieNavItem(
      icon: Icons.point_of_sale_outlined,
      labelKey: 'phar_nav_vente_libre',
      route: '/Dashboard_Pharmacie/VenteLibre',
    ),
    PharmacieNavItem(
      icon: Icons.inventory_2_outlined,
      labelKey: 'phar_nav_catalogue',
      route: '/Dashboard_Pharmacie/Catalogue',
    ),
    PharmacieNavItem(
      icon: Icons.history,
      labelKey: 'phar_nav_historique',
      route: '/Dashboard_Pharmacie/Historique',
    ),
    PharmacieNavItem(
      icon: Icons.bar_chart,
      labelKey: 'phar_nav_stats',
      route: '/Dashboard_Pharmacie/Statistiques',
    ),
    PharmacieNavItem(
      icon: Icons.person_outline,
      labelKey: 'phar_nav_profil',
      route: '/Dashboard_Pharmacie/Profil',
    ),
    PharmacieNavItem(
      icon: Icons.settings_outlined,
      labelKey: 'phar_nav_parametres',
      route: '/Dashboard_Pharmacie/Parametres',
    ),
  ];
}

class PharmacieNavItem {
  final IconData icon;
  final String labelKey;
  final String route;
  const PharmacieNavItem({
    required this.icon,
    required this.labelKey,
    required this.route,
  });
}

/// Sidebar verticale pour la version PC.
/// [activeRoute] = la route active (passée par chaque page).
class PharmacieSidebar extends StatelessWidget {
  final String activeRoute;
  const PharmacieSidebar({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [PharmacieTheme.primaryDark, PharmacieTheme.primary],
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
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.medication_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'phar_module_name'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                ConnectedUserText(
                  fallback: 'auth_hospital_name'.tr(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 2,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: PharmacieTheme.navItems.map((item) {
                final isActive = item.route == activeRoute;
                return _navTile(context, item, isActive);
              }).toList(),
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
                'phar_menu_logout'.tr(),
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

  Widget _navTile(BuildContext context, PharmacieNavItem item, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: isActive
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: isActive ? null : () => context.go(item.route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isActive ? Colors.white : Colors.white70,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.labelKey.tr(),
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: PharmacieTheme.accent,
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
}

/// AppBar mobile pour les pages pharmacie.
class PharmacieAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;

  /// Quand renseigné, affiche une flèche ← qui navigue vers cette route.
  final String? backRoute;
  const PharmacieAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = false,
    this.backRoute,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: PharmacieTheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: backRoute == null ? showBack : false,
      leading: backRoute != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(backRoute!),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: actions,
    );
  }
}

/// Drawer mobile (réutilise les mêmes nav items)
class PharmacieDrawer extends StatelessWidget {
  final String activeRoute;
  const PharmacieDrawer({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: PharmacieTheme.primaryDark,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.medication_rounded,
                          color: Colors.white,
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
                          'phar_module_name'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        ConnectedUserText(
                          fallback: 'auth_hospital_name'.tr(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                children: PharmacieTheme.navItems.map((item) {
                  final isActive = item.route == activeRoute;
                  return ListTile(
                    leading: Icon(
                      item.icon,
                      color: isActive ? Colors.white : Colors.white70,
                    ),
                    title: Text(
                      item.labelKey.tr(),
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white70,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    selected: isActive,
                    selectedTileColor: Colors.white.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (!isActive) context.go(item.route);
                    },
                  );
                }).toList(),
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white70),
              title: Text(
                'phar_menu_logout'.tr(),
                style: const TextStyle(color: Colors.white70),
              ),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/Authen_Personnel');
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Layout PC standard : sidebar + topbar + body.
/// Évite de répéter ce squelette dans chaque page.
class PharmaciePcLayout extends StatelessWidget {
  final String activeRoute;
  final String breadcrumbKey;
  final Widget body;
  const PharmaciePcLayout({
    super.key,
    required this.activeRoute,
    required this.breadcrumbKey,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PharmacieTheme.background,
      body: Row(
        children: [
          PharmacieSidebar(activeRoute: activeRoute),
          Expanded(
            child: Column(
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
                      const Text(
                        '/',
                        style: TextStyle(color: Color(0xFF9E9E9E)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        breadcrumbKey.tr(),
                        style: const TextStyle(
                          color: PharmacieTheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: PharmacieTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_hospital,
                              size: 14,
                              color: PharmacieTheme.primary,
                            ),
                            const SizedBox(width: 6),
                             ConnectedUserText(
                               fallback: 'auth_hospital_name'.tr(),
                               style: const TextStyle(
                                 color: PharmacieTheme.primary,
                                 fontSize: 12,
                                 fontWeight: FontWeight.w600,
                               ),
                             ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte KPI réutilisable
class PharmacieKpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  const PharmacieKpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PharmacieTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.trending_up,
                    size: 16,
                    color: color.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: PharmacieTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge de statut compact (Disponible/Indisponible/En attente/Payé/Délivré...)
class PharmacieStatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const PharmacieStatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper pour les couleurs/labels de statut prescription.
class StatutHelper {
  static Color colorOf(String statut) {
    switch (statut) {
      case 'en_attente_paiement':
        return PharmacieTheme.warn;
      case 'paye':
        return Colors.blue;
      case 'partiellement_delivre':
        return Colors.deepPurple;
      case 'delivre':
        return PharmacieTheme.success;
      case 'annule':
        return PharmacieTheme.danger;
      default:
        return PharmacieTheme.textMuted;
    }
  }

  static String labelOf(String statut) {
    switch (statut) {
      case 'en_attente_paiement':
        return 'phar_status_attente_paiement'.tr();
      case 'paye':
        return 'phar_status_paye'.tr();
      case 'partiellement_delivre':
        return 'phar_status_partiel'.tr();
      case 'delivre':
        return 'phar_status_delivre'.tr();
      case 'annule':
        return 'phar_status_annule'.tr();
      default:
        return statut;
    }
  }

  static IconData iconOf(String statut) {
    switch (statut) {
      case 'en_attente_paiement':
        return Icons.schedule;
      case 'paye':
        return Icons.payments_outlined;
      case 'partiellement_delivre':
        return Icons.inventory_2_outlined;
      case 'delivre':
        return Icons.check_circle_outline;
      case 'annule':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }
}
