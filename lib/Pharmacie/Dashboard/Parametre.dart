import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:hostoman/shared/responsive_wrapper.dart';
import '../shared/pharmacie_theme.dart';

class ParametrePharmacie extends StatelessWidget {
  const ParametrePharmacie({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _mobile(context),
      pc: _pc(context),
    );
  }

  Widget _mobile(BuildContext context) {
    return Scaffold(
      backgroundColor: PharmacieTheme.background,
      drawer: const PharmacieDrawer(
          activeRoute: '/Dashboard_Pharmacie/Parametres'),
      appBar: PharmacieAppBar(title: 'phar_param_title'.tr()),
      body: _body(context),
    );
  }

  Widget _pc(BuildContext context) {
    return PharmaciePcLayout(
      activeRoute: '/Dashboard_Pharmacie/Parametres',
      breadcrumbKey: 'phar_breadcrumb_parametres',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _body(context),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'phar_param_section_catalogue'.tr(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: PharmacieTheme.textDark,
            ),
          ),
          const SizedBox(height: 10),
          _settingTile(
            context,
            icon: Icons.inventory_2_outlined,
            title: 'phar_param_catalogue_title'.tr(),
            subtitle: 'phar_param_catalogue_sub'.tr(),
            onTap: () => context.go('/Dashboard_Pharmacie/Catalogue'),
            color: PharmacieTheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'phar_param_section_app'.tr(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: PharmacieTheme.textDark,
            ),
          ),
          const SizedBox(height: 10),
          _settingTile(
            context,
            icon: Icons.language,
            title: 'phar_param_lang_title'.tr(),
            subtitle: context.locale.languageCode == 'fr'
                ? 'Français'
                : 'English',
            color: PharmacieTheme.accent,
            onTap: () => _showLangPicker(context),
          ),
          const SizedBox(height: 10),
          _settingTile(
            context,
            icon: Icons.person_outline,
            title: 'phar_param_profil'.tr(),
            subtitle: 'phar_param_profil_sub'.tr(),
            color: Colors.blueGrey,
            onTap: () => context.go('/Dashboard_Pharmacie/Profil'),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'fiche_footer'.tr(),
              style: const TextStyle(
                color: PharmacieTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLangPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Text('🇫🇷', style: TextStyle(fontSize: 24)),
              title: const Text('Français'),
              onTap: () async {
                await context.setLocale(const Locale('fr', 'FR'));
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              onTap: () async {
                await context.setLocale(const Locale('en', 'US'));
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PharmacieTheme.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: PharmacieTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: PharmacieTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
