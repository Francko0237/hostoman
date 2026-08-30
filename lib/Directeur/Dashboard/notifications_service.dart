import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/shared/user_profile_helper.dart';

/// Niveau de sévérité d'une notification
enum NotificationSeverity { critical, warning, info, success }

/// Notification destinée au directeur (cas urgents / méritant l'attention)
class DirectorNotification {
  final String id;
  final NotificationSeverity severity;
  final String titleKey; // clé i18n
  final Map<String, String> titleArgs; // arguments substitués dans le titre
  final String messageKey;
  final Map<String, String> messageArgs;
  final DateTime timestamp;
  final String?
  actionTab; // 'finance', 'overview', 'patients', 'staff', 'services'

  DirectorNotification({
    required this.id,
    required this.severity,
    required this.titleKey,
    this.titleArgs = const {},
    required this.messageKey,
    this.messageArgs = const {},
    required this.timestamp,
    this.actionTab,
  });
}

/// Service qui calcule les notifications pour le directeur en agrégant
/// plusieurs sources (paiements, consultations, affluence...).
class NotificationsService {
  final SupabaseClient supabase;
  NotificationsService(this.supabase);

  /// Calcule les notifications actuelles. Lecture seule, ne mute rien.
  Future<List<DirectorNotification>> getDirectorNotifications() async {
    final notifs = <DirectorNotification>[];
    final now = DateTime.now();
    final hid = await UserProfileHelper.getHospitalId();

    try {
      // ============ 1. Paiements en attente depuis +24h (CRITICAL) ============
      final cutoff24h = now.subtract(const Duration(hours: 24));
      var qPaiement24h = supabase
          .from('paiement')
          .select('prix_a_paye, date_paiement, statut_paiement')
          .neq('statut_paiement', 'payer')
          .lt('date_paiement', cutoff24h.toIso8601String());
      if (hid != null) qPaiement24h = qPaiement24h.eq('id_hopital', hid);
      final paiementsAttente = await qPaiement24h;

      if (paiementsAttente.isNotEmpty) {
        double total = 0;
        for (var p in paiementsAttente) {
          total += (p['prix_a_paye'] as num?)?.toDouble() ?? 0;
        }
        notifs.add(
          DirectorNotification(
            id: 'pending_24h',
            severity: NotificationSeverity.critical,
            titleKey: 'notif_pending_payments_title',
            titleArgs: {'count': '${paiementsAttente.length}'},
            messageKey: 'notif_pending_payments_msg',
            messageArgs: {
              'count': '${paiementsAttente.length}',
              'total': total.round().toString(),
            },
            timestamp: now,
            actionTab: 'finance',
          ),
        );
      }

      // ============ 2. Consultations en cours depuis +6h (WARNING) ============
      final cutoff6h = now.subtract(const Duration(hours: 6));
      var qConsult6h = supabase
          .from('Consultation')
          .select('id_consultation, date_enregistrement, Statut_Consultation')
          .eq('Statut_Consultation', 'en attente')
          .lt('date_enregistrement', cutoff6h.toIso8601String());
      if (hid != null) qConsult6h = qConsult6h.eq('id_hopital', hid);
      final consultsBloquees = await qConsult6h;

      if (consultsBloquees.isNotEmpty) {
        notifs.add(
          DirectorNotification(
            id: 'stuck_consults',
            severity: NotificationSeverity.warning,
            titleKey: 'notif_stuck_consults_title',
            titleArgs: {'count': '${consultsBloquees.length}'},
            messageKey: 'notif_stuck_consults_msg',
            messageArgs: {'count': '${consultsBloquees.length}'},
            timestamp: now,
            actionTab: 'overview',
          ),
        );
      }

      // ============ 3. Pic d'affluence aujourd'hui (INFO) ============
      final today = DateTime(now.year, now.month, now.day);
      final last7Start = today.subtract(const Duration(days: 7));

      var qPatientsRecents = supabase
          .from('Patient')
          .select('date_enregistrement')
          .gte('date_enregistrement', last7Start.toIso8601String())
          .lt('date_enregistrement', today.toIso8601String());
      if (hid != null) qPatientsRecents = qPatientsRecents.eq('id_hopital', hid);
      final patientsRecents = await qPatientsRecents;

      // Compter patients aujourd'hui
      var qPatientsToday = supabase
          .from('Patient')
          .select('id_patient')
          .gte('date_enregistrement', today.toIso8601String());
      if (hid != null) qPatientsToday = qPatientsToday.eq('id_hopital', hid);
      final patientsAujourdhui = await qPatientsToday;
      final nbAujourdhui = (patientsAujourdhui as List).length;

      // Moyenne 7 derniers jours (hors aujourd'hui)
      final avg7 = patientsRecents.length / 7.0;
      if (avg7 > 0 && nbAujourdhui > avg7 * 1.5 && nbAujourdhui >= 5) {
        notifs.add(
          DirectorNotification(
            id: 'attendance_peak',
            severity: NotificationSeverity.info,
            titleKey: 'notif_peak_title',
            messageKey: 'notif_peak_msg',
            messageArgs: {
              'today': '$nbAujourdhui',
              'avg': avg7.toStringAsFixed(0),
            },
            timestamp: now,
            actionTab: 'overview',
          ),
        );
      }

      // ============ 4. Aucun paiement aujourd'hui après 12h (WARNING) ============
      if (now.hour >= 12) {
        var qPaiementToday = supabase
            .from('paiement')
            .select('id_paiement')
            .eq('statut_paiement', 'payer')
            .gte('date_paiement', today.toIso8601String());
        if (hid != null) qPaiementToday = qPaiementToday.eq('id_hopital', hid);
        final paiementsToday = await qPaiementToday;
        if ((paiementsToday as List).isEmpty) {
          notifs.add(
            DirectorNotification(
              id: 'no_payment_today',
              severity: NotificationSeverity.warning,
              titleKey: 'notif_no_payment_title',
              messageKey: 'notif_no_payment_msg',
              timestamp: now,
              actionTab: 'finance',
            ),
          );
        }
      }
      // ============ 5. Stock en rupture — Pharmacie (CRITICAL) ============
      try {
        var qRupture = supabase
            .from('listemedicament')
            .select('id_medicament')
            .eq('actif', true)
            .eq('stock', 0);
        if (hid != null) qRupture = qRupture.eq('id_hopital', hid);
        final ruptureRes = await qRupture.count(CountOption.exact);
        if (ruptureRes.count > 0) {
          notifs.add(
            DirectorNotification(
              id: 'stock_rupture',
              severity: NotificationSeverity.critical,
              titleKey: 'notif_stock_rupture_title',
              titleArgs: {'count': '${ruptureRes.count}'},
              messageKey: 'notif_stock_rupture_msg',
              messageArgs: {'count': '${ruptureRes.count}'},
              timestamp: now,
              actionTab: 'overview',
            ),
          );
        }
      } catch (_) {}

      // ============ 6. Lots périmés — Pharmacie (WARNING) ============
      try {
        final todayStr = now.toIso8601String().split('T').first;
        var qPerimes = supabase
            .from('stock_entree')
            .select('id_medicament')
            .not('date_peremption', 'is', null)
            .lt('date_peremption', todayStr);
        if (hid != null) qPerimes = qPerimes.eq('id_hopital', hid);
        final lotsPerimesRaw = await qPerimes;
        final perimesCount = (lotsPerimesRaw as List)
            .map((e) => e['id_medicament'])
            .toSet()
            .length;
        if (perimesCount > 0) {
          notifs.add(
            DirectorNotification(
              id: 'lots_perimes',
              severity: NotificationSeverity.warning,
              titleKey: 'notif_lots_perimes_title',
              titleArgs: {'count': '$perimesCount'},
              messageKey: 'notif_lots_perimes_msg',
              messageArgs: {'count': '$perimesCount'},
              timestamp: now,
              actionTab: 'overview',
            ),
          );
        }
      } catch (_) {}
      // ============ 7. Demandes de réinitialisation de mot de passe (CRITICAL) ============
      try {
        var qReset = supabase
            .from('utilisateur')
            .select('Nom, Prenom, username')
            .eq('reset_password_statut', 'en_attente');
        if (hid != null) qReset = qReset.eq('id_hopital', hid);
        final demandesReset = await qReset;

        if ((demandesReset as List).isNotEmpty) {
          for (final p in demandesReset) {
            final nom = '${p['Prenom'] ?? ''} ${p['Nom'] ?? ''}'.trim();
            final username = p['username']?.toString() ?? '';
            notifs.add(
              DirectorNotification(
                id: 'reset_pwd_$username',
                severity: NotificationSeverity.critical,
                titleKey: 'notif_reset_pwd_title',
                titleArgs: {'nom': nom},
                messageKey: 'notif_reset_pwd_msg',
                messageArgs: {'username': username},
                timestamp: now,
                actionTab: 'staff',
              ),
            );
          }
        }
      } catch (_) {}
    } catch (e) {
      print('Erreur Notifications: $e');
    }

    // Tri : critical > warning > info, puis timestamp desc
    notifs.sort((a, b) {
      final ord = a.severity.index.compareTo(b.severity.index);
      if (ord != 0) return ord;
      return b.timestamp.compareTo(a.timestamp);
    });

    return notifs;
  }
}
