import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

// Couleurs propres au module Directeur
const Color dirPrimaryColor = Color(0xFF1A237E);
const Color dirAccentColor = Color(0xFFFFD700);
const Color dirGradientEnd = Color(0xFF3F51B5);
const Color dirBackground = Color(0xFFF5F6FA);
const Color dirTextDark = Color(0xFF1A1A2E);
const Color dirTextMuted = Color(0xFF64748B);
const Color dirDanger = Color(0xFFDC2626);

const List<Locale> _kLocales = <Locale>[Locale('fr', 'FR'), Locale('en', 'US')];

class ParametreDirecteurPage extends StatefulWidget {
  const ParametreDirecteurPage({super.key});

  @override
  State<ParametreDirecteurPage> createState() => _ParametreDirecteurPageState();
}

class _ParametreDirecteurPageState extends State<ParametreDirecteurPage> {
  String _localeLabel(Locale l) {
    return l.languageCode == 'en'
        ? 'acc_lang_english'.tr()
        : 'acc_lang_french'.tr();
  }

  Future<void> _showLanguagePicker() async {
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
                  color: dirTextDark,
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
                        ? dirPrimaryColor.withValues(alpha: 0.08)
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
                                color: isCurrent
                                    ? dirPrimaryColor
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCurrent
                                      ? dirPrimaryColor
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
                                _localeLabel(l),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isCurrent
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isCurrent
                                      ? dirPrimaryColor
                                      : dirTextDark,
                                ),
                              ),
                            ),
                            Icon(
                              isCurrent
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked,
                              color: isCurrent
                                  ? dirPrimaryColor
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

  void _showAboutSheet() {
    showAboutDialog(
      context: context,
      applicationName: 'auth_hospital_name'.tr(),
      applicationVersion: 'v1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: dirPrimaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.local_hospital, color: dirPrimaryColor),
      ),
      applicationLegalese: '© 2026 Yamgai Mokube Franck Daniel',
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dirBackground,
      body: CustomScrollView(
        slivers: [
          // ===== HEADER GRADIENT =====
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            elevation: 0,
            backgroundColor: dirPrimaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: Navigator.of(context).canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: EdgeInsets.only(
                left: Navigator.of(context).canPop() ? 56 : 20,
                bottom: 16,
              ),
              title: Text(
                'acc_settings_title'.tr(),
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
                    colors: [dirPrimaryColor, dirGradientEnd],
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

          // ===== CONTENU =====
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _sectionTitle('acc_settings_preferences'.tr()),
                const SizedBox(height: 10),
                _settingCard(
                  icon: Icons.language_rounded,
                  iconColor: dirPrimaryColor,
                  title: 'acc_settings_language'.tr(),
                  subtitle: _localeLabel(context.locale),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: dirPrimaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      context.locale.languageCode.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: dirPrimaryColor,
                      ),
                    ),
                  ),
                  onTap: _showLanguagePicker,
                ),
                const SizedBox(height: 28),
                _sectionTitle('acc_settings_system'.tr()),
                const SizedBox(height: 10),
                _settingCard(
                  icon: Icons.info_outline_rounded,
                  iconColor: dirGradientEnd,
                  title: 'acc_settings_version'.tr(),
                  subtitle: 'v1.0.0',
                  onTap: _showAboutSheet,
                ),
                const SizedBox(height: 40),
                
                // Bouton Déconnexion
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _logout,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: dirDanger.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: dirDanger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.logout_rounded, color: dirDanger, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'sidebar_logout'.tr(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: dirDanger,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'déconnexion'.tr(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: dirTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: dirDanger.withValues(alpha: 0.5),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Footer
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_hospital_rounded,
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
                        '© 2026',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: dirTextMuted,
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
                        color: dirTextDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: dirTextMuted,
                      ),
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
