import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/shared/user_profile_helper.dart';

// ── Couleurs du module Accueil ──────────────────────────────────────────────
const Color accPrimary = Color(0xFF1565C0);
const Color accBackground = Color(0xFFF0F4F8);

// ── Données de navigation ────────────────────────────────────────────────────
class _AccNavItem {
  final IconData icon;
  final String labelKey;
  final String route;
  const _AccNavItem(this.icon, this.labelKey, this.route);
}

const _items = <_AccNavItem>[
  _AccNavItem(Icons.dashboard, 'acc_nav_dashboard', '/Dashboard_Accueil'),
  _AccNavItem(Icons.person_add, 'acc_new_patient', '/Dashboard_Accueil/nouveau-patient'),
  _AccNavItem(Icons.people, 'acc_nav_patients_list', '/Dashboard_Accueil/liste-patient'),
  _AccNavItem(Icons.bar_chart, 'acc_statistics', '/Dashboard_Accueil/statistique'),
];

const _bottomItems = <_AccNavItem>[
  _AccNavItem(Icons.person_outline, 'acc_nav_profil', '/Dashboard_Accueil/profil'),
  _AccNavItem(Icons.settings_outlined, 'acc_settings_menu', '/Dashboard_Accueil/parametre'),
];

// ── Layout PC partagé ────────────────────────────────────────────────────────
class AccueilPcLayout extends StatelessWidget {
  final String activeRoute;
  final String breadcrumbKey;
  final Widget body;

  const AccueilPcLayout({
    super.key,
    required this.activeRoute,
    required this.breadcrumbKey,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: accBackground,
      body: Row(
        children: [
          _Sidebar(activeRoute: activeRoute),
          Expanded(
            child: Column(
              children: [
                _TopBar(breadcrumbKey: breadcrumbKey),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar ──────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final String activeRoute;
  const _Sidebar({required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
        ),
        boxShadow: [
          BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(4, 0)),
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
                    width: 40, height: 40, fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'acc_module_label'.tr(),
                  style: const TextStyle(
                    color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w800, letterSpacing: 0.5,
                  ),
                ),
                ConnectedUserText(
                  fallback: 'auth_hospital_name'.tr(),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 2,
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
                for (final item in _items)
                  _NavTile(item: item, active: activeRoute == item.route),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.15)),
                for (final item in _bottomItems)
                  _NavTile(item: item, active: activeRoute == item.route),
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
                'acc_logout_menu'.tr(),
                style: const TextStyle(
                  color: Color(0xFFEF5350), fontSize: 13, fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _AccNavItem item;
  final bool active;
  const _NavTile({required this.item, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: active ? Colors.white.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: active ? Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1) : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(item.icon,
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.65), size: 20),
        title: Text(
          item.labelKey.tr(),
          style: TextStyle(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.75),
            fontSize: 13.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: active ? null : () => context.go(item.route),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String breadcrumbKey;
  const _TopBar({required this.breadcrumbKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          const Icon(Icons.home_outlined, size: 16, color: Color(0xFF9E9E9E)),
          const SizedBox(width: 6),
          const Text('/', style: TextStyle(color: Color(0xFF9E9E9E))),
          const SizedBox(width: 6),
          Text(
            breadcrumbKey.tr(),
            style: const TextStyle(color: accPrimary, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: accPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: accPrimary),
                const SizedBox(width: 6),
                ConnectedUserText(
                  fallback: 'auth_hospital_name'.tr(),
                  style: const TextStyle(
                    color: accPrimary, fontSize: 12, fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
