import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/shared/user_profile_helper.dart';

/// 🔴🟡🟢 Service de surveillance en temps réel de l'état des services de l'hôpital
class EtatServicesService {
  final SupabaseClient supabase;
  EtatServicesService(this.supabase);

  /// 💊 Accueil : Patients en attente (consultation non commencée)
  Future<Map<String, dynamic>> getEtatAccueil() async {
    final hid = await UserProfileHelper.getHospitalId();
    try {
      var qAttente = supabase
          .from('Consultation')
          .select('id_consultation')
          .eq('Statut_Consultation', 'en-attente-consultation');
      if (hid != null) qAttente = qAttente.eq('id_hopital', hid);
      final enAttente = await qAttente.count(CountOption.exact);

      final today = DateTime.now();
      final startOfDay = DateTime(
        today.year,
        today.month,
        today.day,
      ).toIso8601String();
      final endOfDay = DateTime(
        today.year,
        today.month,
        today.day,
        23,
        59,
        59,
      ).toIso8601String();

      var qAdmis = supabase
          .from('Patient')
          .select('id_patient')
          .gte('date_enregistrement', startOfDay)
          .lte('date_enregistrement', endOfDay);
      if (hid != null) qAdmis = qAdmis.eq('id_hopital', hid);
      final admisAujourdHui = await qAdmis.count(CountOption.exact);

      return {
        'patientsEnAttente': enAttente.count,
        'admisAujourdHui': admisAujourdHui.count,
      };
    } catch (e) {
      return {'patientsEnAttente': 0, 'admisAujourdHui': 0};
    }
  }

  /// 🩺 Médecin : consultations en cours vs terminées aujourd'hui
  Future<Map<String, dynamic>> getEtatMedecin() async {
    final hid = await UserProfileHelper.getHospitalId();
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(
        today.year,
        today.month,
        today.day,
      ).toIso8601String();
      final endOfDay = DateTime(
        today.year,
        today.month,
        today.day,
        23,
        59,
        59,
      ).toIso8601String();

      var qTerminees = supabase
          .from('Consultation')
          .select('id_consultation')
          .eq('Statut_Consultation', 'terminer')
          .gte('date_derniere_mise_ajour', startOfDay)
          .lte('date_derniere_mise_ajour', endOfDay);
      if (hid != null) qTerminees = qTerminees.eq('id_hopital', hid);
      final terminees = await qTerminees.count(CountOption.exact);

      var qEnCours = supabase
          .from('Consultation')
          .select('id_consultation')
          .or(
            'Statut_Consultation.eq.En cours,Statut_Consultation.eq.en-attente-examen,Statut_Consultation.eq.en-attente-resultat,Statut_Consultation.eq.resultat-disponible',
          );
      if (hid != null) qEnCours = qEnCours.eq('id_hopital', hid);
      final enCours = await qEnCours.count(CountOption.exact);

      return {'termineesAujourdhui': terminees.count, 'enCours': enCours.count};
    } catch (e) {
      return {'termineesAujourdhui': 0, 'enCours': 0};
    }
  }

  /// 🧪 Laboratoire : examens à faire vs terminés aujourd'hui
  Future<Map<String, dynamic>> getEtatLaboratoire() async {
    final hid = await UserProfileHelper.getHospitalId();
    try {
      // Patients (distinct) avec au moins un examen en attente
      var qAFaire = supabase
          .from('examen_a_effectuer')
          .select('id_consultation')
          .eq('statut_examen', 'en attente');
      if (hid != null) qAFaire = qAFaire.eq('id_hopital', hid);
      final aFaireRaw = await qAFaire;
      final patientsEnAttente = (aFaireRaw as List)
          .map((e) => e['id_consultation'])
          .toSet()
          .length;

      final today = DateTime.now();
      final startOfDay = DateTime(
        today.year,
        today.month,
        today.day,
      ).toIso8601String();
      final endOfDay = DateTime(
        today.year,
        today.month,
        today.day,
        23,
        59,
        59,
      ).toIso8601String();

      // Patients (distinct) dont les examens ont été terminés aujourd'hui
      var qTermines = supabase
          .from('examen_a_effectuer')
          .select('id_consultation')
          .eq('statut_examen', 'Terminé')
          .gte('date_enregistrement', startOfDay)
          .lte('date_enregistrement', endOfDay);
      if (hid != null) qTermines = qTermines.eq('id_hopital', hid);
      final terminesRaw = await qTermines;
      final patientsTermines = (terminesRaw as List)
          .map((e) => e['id_consultation'])
          .toSet()
          .length;

      return {
        'examensEnAttente': patientsEnAttente,
        'examensTerminesAujourdHui': patientsTermines,
      };
    } catch (e) {
      return {'examensEnAttente': 0, 'examensTerminesAujourdHui': 0};
    }
  }

  /// 💰 Caisse : paiements en attente et encaissé aujourd'hui
  Future<Map<String, dynamic>> getEtatCaisse() async {
    final hid = await UserProfileHelper.getHospitalId();
    try {
      var qAttente = supabase
          .from('paiement')
          .select('id_paiement')
          .eq('statut_paiement', 'en_attente');
      if (hid != null) qAttente = qAttente.eq('id_hopital', hid);
      final enAttente = await qAttente.count(CountOption.exact);

      final today = DateTime.now();
      final startOfDay = DateTime(
        today.year,
        today.month,
        today.day,
      ).toIso8601String();
      final endOfDay = DateTime(
        today.year,
        today.month,
        today.day,
        23,
        59,
        59,
      ).toIso8601String();

      var qPayes = supabase
          .from('paiement')
          .select('prix_a_paye')
          .eq('statut_paiement', 'payer')
          .gte('date_paiement', startOfDay)
          .lte('date_paiement', endOfDay);
      if (hid != null) qPayes = qPayes.eq('id_hopital', hid);
      final payesAujourdHui = await qPayes;

      double encaisseAujourdHui = 0;
      for (var p in payesAujourdHui) {
        encaisseAujourdHui += (p['prix_a_paye'] as num).toDouble();
      }

      return {
        'paiementsEnAttente': enAttente.count,
        'encaisseAujourdHui': encaisseAujourdHui,
        'nbTransactionsAujourdHui': payesAujourdHui.length,
      };
    } catch (e) {
      return {
        'paiementsEnAttente': 0,
        'encaisseAujourdHui': 0.0,
        'nbTransactionsAujourdHui': 0,
      };
    }
  }

  /// 👥 Résumé du personnel par spécialité
  Future<Map<String, int>> getRepartitionPersonnel() async {
    final hid = await UserProfileHelper.getHospitalId();
    try {
      var query = supabase.from('utilisateur').select('Specialite');
      if (hid != null) query = query.eq('id_hopital', hid);
      final response = await query;

      final Map<String, int> repartition = {};
      for (var p in response) {
        final specialite = p['Specialite']?.toString() ?? 'Autre';
        repartition[specialite] = (repartition[specialite] ?? 0) + 1;
      }
      return repartition;
    } catch (e) {
      return {};
    }
  }

  /// Charge tout d'un coup pour la page d'accueil
  Future<Map<String, dynamic>> getAllServiceStats() async {
    final results = await Future.wait([
      getEtatAccueil(),
      getEtatMedecin(),
      getEtatLaboratoire(),
      getEtatCaisse(),
      getRepartitionPersonnel(),
    ]);

    return {
      'accueil': results[0],
      'medecin': results[1],
      'laboratoire': results[2],
      'caisse': results[3],
      'personnel': results[4],
    };
  }
}
