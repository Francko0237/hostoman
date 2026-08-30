import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

/// Service de statistiques pour un hôpital spécifique (vue Super Admin)
class HopitalStatsService {
  final SupabaseClient supabase;
  HopitalStatsService(this.supabase);

  /// Compte total de patients enregistrés dans cet hôpital
  Future<int> countPatients(String idHopital) async {
    try {
      final result = await supabase
          .from('Patient')
          .select('id_patient')
          .eq('id_hopital', idHopital)
          .count(CountOption.exact);
      return result.count;
    } catch (_) {
      return 0;
    }
  }

  /// Compte total du personnel dans cet hôpital
  Future<int> countPersonnel(String idHopital) async {
    try {
      final result = await supabase
          .from('utilisateur')
          .select('id_utilisateur')
          .eq('id_hopital', idHopital)
          .count(CountOption.exact);
      return result.count;
    } catch (_) {
      return 0;
    }
  }

  /// Compte total des consultations dans cet hôpital
  Future<int> countConsultations(String idHopital) async {
    try {
      final result = await supabase
          .from('Consultation')
          .select('id_consultation')
          .eq('id_hopital', idHopital)
          .count(CountOption.exact);
      return result.count;
    } catch (_) {
      return 0;
    }
  }

  /// Consultations des 7 derniers jours (pour graphique courbe)
  Future<List<Map<String, dynamic>>> getConsultationsParJour(
    String idHopital,
  ) async {
    try {
      final now = DateTime.now();
      final List<Map<String, dynamic>> result = [];

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final start = DateTime(date.year, date.month, date.day);
        final end = start.add(const Duration(days: 1));

        final resp = await supabase
            .from('Consultation')
            .select('id_consultation')
            .eq('id_hopital', idHopital)
            .gte('date_enregistrement', start.toIso8601String())
            .lt('date_enregistrement', end.toIso8601String())
            .count(CountOption.exact);

        result.add({
          'label': DateFormat('E', 'fr_FR').format(date),
          'date': DateFormat('dd/MM').format(date),
          'count': resp.count,
        });
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  /// Répartition du personnel par rôle/spécialité
  Future<Map<String, int>> getPersonnelParRole(String idHopital) async {
    try {
      final resp = await supabase
          .from('utilisateur')
          .select('Specialite')
          .eq('id_hopital', idHopital);

      final Map<String, int> map = {};
      for (final r in resp) {
        final spec = r['Specialite']?.toString() ?? 'Autre';
        map[spec] = (map[spec] ?? 0) + 1;
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  /// Patients enregistrés par jour sur les 7 derniers jours
  Future<List<Map<String, dynamic>>> getPatientsParJour(
    String idHopital,
  ) async {
    try {
      final now = DateTime.now();
      final List<Map<String, dynamic>> result = [];

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final start = DateTime(date.year, date.month, date.day);
        final end = start.add(const Duration(days: 1));

        final resp = await supabase
            .from('Patient')
            .select('id_patient')
            .eq('id_hopital', idHopital)
            .gte('date_enregistrement', start.toIso8601String())
            .lt('date_enregistrement', end.toIso8601String())
            .count(CountOption.exact);

        result.add({
          'label': DateFormat('E', 'fr_FR').format(date),
          'date': DateFormat('dd/MM').format(date),
          'count': resp.count,
        });
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  /// Récupère la liste détaillée de tout le personnel de cet hôpital
  Future<List<Map<String, dynamic>>> getPersonnelListe(String idHopital) async {
    try {
      final resp = await supabase
          .from('utilisateur')
          .select('*')
          .eq('id_hopital', idHopital)
          .order('Nom', ascending: true);
      return List<Map<String, dynamic>>.from(resp);
    } catch (_) {
      return [];
    }
  }

  /// Met à jour les informations d'un membre du personnel
  Future<String?> updatePersonnel(String idUtilisateur, Map<String, dynamic> data) async {
    try {
      await supabase
          .from('utilisateur')
          .update(data)
          .eq('id_utilisateur', idUtilisateur);
      return null; // Succès
    } on PostgrestException catch (e) {
      return 'Erreur modification: ${e.message}';
    } catch (e) {
      return 'Erreur inattendue: $e';
    }
  }

  /// Bascule le statut actif d'un membre du personnel
  Future<String?> togglePersonnelActif(String idUtilisateur, bool actif) async {
    try {
      await supabase
          .from('utilisateur')
          .update({'compte_actif': actif})
          .eq('id_utilisateur', idUtilisateur);
      return null;
    } catch (e) {
      return 'Erreur: $e';
    }
  }

  /// Récupère la liste des demandes de réinitialisation de mot de passe en attente
  Future<List<Map<String, dynamic>>> getDemandesResetPassword(String idHopital) async {
    try {
      final resp = await supabase
          .from('utilisateur')
          .select('*')
          .eq('id_hopital', idHopital)
          .eq('reset_password_statut', 'en_attente');
      return List<Map<String, dynamic>>.from(resp);
    } catch (_) {
      return [];
    }
  }

  /// Répond à une demande de réinitialisation de mot de passe (valide ou rejete)
  Future<String?> traiterDemandeResetPassword(String idUtilisateur, String nouveauStatut) async {
    try {
      await supabase
          .from('utilisateur')
          .update({'reset_password_statut': nouveauStatut})
          .eq('id_utilisateur', idUtilisateur);
      return null;
    } catch (e) {
      return 'Erreur: $e';
    }
  }

  /// Charge toutes les stats d'un coup
  Future<Map<String, dynamic>> getAllStats(String idHopital) async {
    final results = await Future.wait([
      countPatients(idHopital),
      countPersonnel(idHopital),
      countConsultations(idHopital),
      getConsultationsParJour(idHopital),
      getPersonnelParRole(idHopital),
      getPatientsParJour(idHopital),
      getPersonnelListe(idHopital),
      getDemandesResetPassword(idHopital),
    ]);

    return {
      'totalPatients': results[0] as int,
      'totalPersonnel': results[1] as int,
      'totalConsultations': results[2] as int,
      'consultationsParJour': results[3] as List<Map<String, dynamic>>,
      'personnelParRole': results[4] as Map<String, int>,
      'patientsParJour': results[5] as List<Map<String, dynamic>>,
      'personnelListe': results[6] as List<Map<String, dynamic>>,
      'demandesReset': results[7] as List<Map<String, dynamic>>,
    };
  }
}
