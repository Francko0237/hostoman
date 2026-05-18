import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hostoman/Directeur/Dashboard/dashboard_directeur.dart'
    show dirPrimaryColor;

class ParametreDirecteurPage extends StatefulWidget {
  const ParametreDirecteurPage({super.key});

  @override
  State<ParametreDirecteurPage> createState() => _ParametreDirecteurPageState();
}

class _ParametreDirecteurPageState extends State<ParametreDirecteurPage> {
  static const _locales = <Locale>[Locale('fr', 'FR'), Locale('en', 'US')];

  String _localeLabel(Locale l) {
    switch (l.languageCode) {
      case 'fr':
        return 'Fran\u00e7ais';
      case 'en':
        return 'English';
      default:
        return l.languageCode;
    }
  }

  void _showLanguagePicker() {
    final currentLocale = context.locale;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'settings_pick_language'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ..._locales.map((locale) {
                  final selected = locale == currentLocale;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: selected
                          ? dirPrimaryColor
                          : Colors.grey.shade200,
                      child: Text(
                        locale.languageCode.toUpperCase(),
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    title: Text(
                      _localeLabel(locale),
                      style: TextStyle(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected ? dirPrimaryColor : Colors.black87,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check_circle, color: dirPrimaryColor)
                        : null,
                    onTap: () {
                      context.setLocale(locale);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================== BUILD ==============================
  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle('settings_preferences'.tr()),
          const SizedBox(height: 8),
          _settingCard(
            icon: Icons.language_rounded,
            title: 'settings_language'.tr(),
            subtitle: _localeLabel(currentLocale),
            onTap: _showLanguagePicker,
          ),
          const SizedBox(height: 28),
          _sectionTitle('settings_system'.tr()),
          const SizedBox(height: 8),
          _settingCard(
            icon: Icons.info_outline_rounded,
            title: 'settings_version'.tr(),
            subtitle: 'v1.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'H\u00f4p. District de Manjo',
                applicationVersion: '1.0.0',
                applicationLegalese:
                    '\u00a9 2026 H\u00f4pital de District de Manjo',
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================== WIDGETS ==============================
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _settingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: dirPrimaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: dirPrimaryColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }
}
