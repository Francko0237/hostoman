import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:hostoman/shared/responsive_wrapper.dart';
import '../shared/pharmacie_theme.dart';

const Color _primary = PharmacieTheme.primary;
const Color _primaryDark = PharmacieTheme.primaryDark;
const Color _accent = PharmacieTheme.accent;
const Color _textDark = PharmacieTheme.textDark;
const Color _textMuted = PharmacieTheme.textMuted;
const Color _bg = PharmacieTheme.background;

const List<Locale> _kLocales = [Locale('fr', 'FR'), Locale('en', 'US')];

class ParametrePharmacie extends StatelessWidget {
  const ParametrePharmacie({super.key});

  String _localeLabel(BuildContext context, Locale l) =>
      l.languageCode == 'en' ? 'acc_lang_english'.tr() : 'acc_lang_french'.tr();

  Future<void> _showLanguagePicker(BuildContext context) async {
    final current = context.locale;
    final picked = await showModalBottomSheet<Locale>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'acc_lang_picker_title'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 16),
              ..._kLocales.map((l) {
                final isCurrent = l == current;
                final isEn = l.languageCode == 'en';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isCurrent
                        ? _primary.withValues(alpha: 0.08)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(ctx, l),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isCurrent ? _primary : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCurrent
                                      ? _primary
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                isEn ? '🇬🇧' : '🇫🇷',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _localeLabel(ctx, l),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isCurrent
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isCurrent ? _primary : _textDark,
                                ),
                              ),
                            ),
                            Icon(
                              isCurrent
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked,
                              color: isCurrent
                                  ? _primary
                                  : Colors.grey.shade400,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
    if (picked != null && picked != current) {
      await context.setLocale(picked);
    }
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'auth_hospital_name'.tr(),
      applicationVersion: 'v1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.medication_rounded, color: _primary),
      ),
      applicationLegalese: '© 2025 Yamgai Mokube Franck Daniel',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobile(context),
      pc: _buildPc(context),
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            elevation: 0,
            backgroundColor: _primary,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.canPop(context)
                  ? Navigator.pop(context)
                  : context.go('/Dashboard_Pharmacie'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                'phar_param_title'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_primaryDark, _primary],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      top: -20,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 80,
                      bottom: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate(_bodyItems(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPc(BuildContext context) {
    return PharmaciePcLayout(
      activeRoute: '/Dashboard_Pharmacie/Parametres',
      breadcrumbKey: 'phar_breadcrumb_parametres',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _bodyItems(context),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _bodyItems(BuildContext context) {
    return [
      // ── Préférences ──
      _sectionTitle('acc_settings_preferences'.tr()),
      const SizedBox(height: 10),
      _settingCard(
        icon: Icons.language_rounded,
        iconColor: _accent,
        title: 'acc_settings_language'.tr(),
        subtitle: _localeLabel(context, context.locale),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            context.locale.languageCode.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _primary,
            ),
          ),
        ),
        onTap: () => _showLanguagePicker(context),
      ),
      const SizedBox(height: 28),

      // ── Gestion ──
      _sectionTitle('phar_param_section_catalogue'.tr()),
      const SizedBox(height: 10),
      _settingCard(
        icon: Icons.inventory_2_outlined,
        iconColor: _primary,
        title: 'phar_param_catalogue_title'.tr(),
        subtitle: 'phar_param_catalogue_sub'.tr(),
        onTap: () => context.go('/Dashboard_Pharmacie/Catalogue'),
      ),
      const SizedBox(height: 28),

      // ── Compte ──
      _sectionTitle('phar_param_section_app'.tr()),
      const SizedBox(height: 10),
      _settingCard(
        icon: Icons.info_outline_rounded,
        iconColor: _accent,
        title: 'acc_settings_version'.tr(),
        subtitle: 'v1.0.0',
        onTap: () => _showAbout(context),
      ),
      const SizedBox(height: 40),

      // ── Footer ──
      Center(
        child: Column(
          children: [
            Icon(
              Icons.medication_rounded,
              color: Colors.grey.shade400,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'auth_hospital_name'.tr(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'fiche_footer'.tr(),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: _textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _settingCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: _textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (trailing != null) trailing,
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
