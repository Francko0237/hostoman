import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'notifications_service.dart';

/// Cloche de notifications du directeur.
/// - Affiche un badge avec le nombre de notifications actives
/// - Au clic : ouvre un dropdown stylé avec la liste des alertes
/// - Permet de naviguer vers l'onglet concerné via [onNavigateToTab]
class NotificationsBell extends StatefulWidget {
  final Color iconColor;

  /// Callback : reçoit le nom de l'onglet ('overview','finance','patients','staff','services').
  /// À adapter en index pour le _selectedIndex du dashboard.
  final void Function(String tabName)? onNavigateToTab;

  const NotificationsBell({
    super.key,
    this.iconColor = Colors.white,
    this.onNavigateToTab,
  });

  @override
  State<NotificationsBell> createState() => _NotificationsBellState();
}

class _NotificationsBellState extends State<NotificationsBell> {
  late final NotificationsService _service;
  List<DirectorNotification> _notifs = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _service = NotificationsService(Supabase.instance.client);
    // Différer le chargement de 2 s pour ne pas bloquer le rendu initial
    // du dashboard (priorité au paint avant les requêtes réseau).
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final list = await _service.getDirectorNotifications();
    if (mounted) {
      setState(() {
        _notifs = list;
        _loading = false;
      });
    }
  }

  void _showDropdown() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (ctx) => _NotificationsDialog(
        notifs: _notifs,
        loading: _loading,
        onRefresh: () async {
          await _load();
        },
        onNavigate: (tab) {
          Navigator.pop(ctx);
          widget.onNavigateToTab?.call(tab);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final criticalCount = _notifs
        .where(
          (n) =>
              n.severity == NotificationSeverity.critical ||
              n.severity == NotificationSeverity.warning,
        )
        .length;
    final totalCount = _notifs.length;

    return Tooltip(
      message: 'notif_tooltip'.tr(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: _showDropdown,
            icon: Icon(
              criticalCount > 0
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_outlined,
              color: widget.iconColor,
            ),
          ),
          if (totalCount > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: criticalCount > 0
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF0284C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  totalCount > 9 ? '9+' : '$totalCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationsDialog extends StatelessWidget {
  final List<DirectorNotification> notifs;
  final bool loading;
  final Future<void> Function() onRefresh;
  final void Function(String tab) onNavigate;

  const _NotificationsDialog({
    required this.notifs,
    required this.loading,
    required this.onRefresh,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;
    return Dialog(
      alignment: isDesktop ? Alignment.topRight : Alignment.center,
      insetPadding: isDesktop
          ? const EdgeInsets.only(top: 70, right: 20)
          : const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===== HEADER =====
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF1A237E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'notif_title'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          notifs.isEmpty
                              ? 'notif_empty_subtitle'.tr()
                              : 'notif_count_subtitle'.tr(
                                  args: ['${notifs.length}'],
                                ),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: 'refresh'.tr(),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            // ===== BODY =====
            Flexible(
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    )
                  : notifs.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(8),
                      itemCount: notifs.length,
                      separatorBuilder: (_, ignored) =>
                          const SizedBox(height: 6),
                      itemBuilder: (_, i) =>
                          _NotifTile(notif: notifs[i], onNavigate: onNavigate),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF16A34A),
              size: 40,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'notif_empty_title'.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'notif_empty_message'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final DirectorNotification notif;
  final void Function(String tab) onNavigate;

  const _NotifTile({required this.notif, required this.onNavigate});

  Color get _color {
    switch (notif.severity) {
      case NotificationSeverity.critical:
        return const Color(0xFFDC2626);
      case NotificationSeverity.warning:
        return const Color(0xFFD97706);
      case NotificationSeverity.info:
        return const Color(0xFF0284C7);
      case NotificationSeverity.success:
        return const Color(0xFF16A34A);
    }
  }

  IconData get _icon {
    switch (notif.severity) {
      case NotificationSeverity.critical:
        return Icons.error_rounded;
      case NotificationSeverity.warning:
        return Icons.warning_amber_rounded;
      case NotificationSeverity.info:
        return Icons.info_rounded;
      case NotificationSeverity.success:
        return Icons.check_circle_rounded;
    }
  }

  String _format(String key, Map<String, String> args) {
    final fmt = NumberFormat('#,###', 'fr_FR');
    final namedArgs = <String, String>{};
    args.forEach((k, v) {
      // formater les nombres avec séparateur si numérique
      final n = num.tryParse(v);
      namedArgs[k] = (n != null && n >= 1000) ? fmt.format(n) : v;
    });
    return key.tr(namedArgs: namedArgs);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: notif.actionTab == null
            ? null
            : () => onNavigate(notif.actionTab!),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.06),
            border: Border(left: BorderSide(color: _color, width: 3)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_icon, color: _color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _format(notif.titleKey, notif.titleArgs),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _format(notif.messageKey, notif.messageArgs),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF334155),
                        height: 1.35,
                      ),
                    ),
                    if (notif.actionTab != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'notif_view_details'.tr(),
                            style: TextStyle(
                              fontSize: 11,
                              color: _color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: _color,
                            size: 12,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
