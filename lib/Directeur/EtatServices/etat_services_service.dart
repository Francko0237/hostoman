import 'package:supabase_flutter/supabase_flutter.dart';

/// 🔴🟡🟢 Service de surveillance en temps réel de l'état des services de l'hôpital
class EtatServicesService {
  final SupabaseClient supabase;
  EtatServicesService(this.supabase);

  /// 💊 Accueil : Patients en attente (consultation non commencée)
  Future<Map<String, dynamic>> getEtatAccueil() async {
    try {
      final enAttente = await supabase
          .from('Consultation')
          .select('id_consultation')
          .eq('Statut_Consultation', 'en-attente-consultation')
          .count(CountOption.exact);

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

      final admisAujourdHui = await supabase
          .from('Patient')
          .select('id_patient')
          .gte('date_enregistrement', startOfDay)
          .lte('date_enregistrement', endOfDay)
          .count(CountOption.exact);

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

      final terminees = await supabase
          .from('Consultation')
          .select('id_consultation')
          .eq('Statut_Consultation', 'terminer')
          .gte('date_derniere_mise_ajour', startOfDay)
          .lte('date_derniere_mise_ajour', endOfDay)
          .count(CountOption.exact);

      final enCours = await supabase
          .from('Consultation')
          .select('id_consultation')
          .or(
            'Statut_Consultation.eq.En cours,Statut_Consultation.eq.en-attente-examen,Statut_Consultation.eq.en-attente-resultat,Statut_Consultation.eq.resultat-disponible',
          )
          .count(CountOption.exact);

      return {'termineesAujourdhui': terminees.count, 'enCours': enCours.count};
    } catch (e) {
      return {'termineesAujourdhui': 0, 'enCours': 0};
    }
  }

  /// 🧪 Laboratoire : examens à faire vs terminés aujourd'hui
  Future<Map<String, dynamic>> getEtatLaboratoire() async {
    try {
      // Patients (distinct) avec au moins un examen en attente
      final aFaireRaw = await supabase
          .from('examen_a_effectuer')
          .select('id_consultation')
          .eq('statut_examen', 'en attente');
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
      final terminesRaw = await supabase
          .from('examen_a_effectuer')
          .select('id_consultation')
          .eq('statut_examen', 'Terminé')
          .gte('date_enregistrement', startOfDay)
          .lte('date_enregistrement', endOfDay);
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
    try {
      final enAttente = await supabase
          .from('paiement')
          .select('id_paiement')
          .eq('statut_paiement', 'en_attente')
          .count(CountOption.exact);

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

      final payesAujourdHui = await supabase
          .from('paiement')
          .select('prix_a_paye')
          .eq('statut_paiement', 'payer')
          .gte('date_paiement', startOfDay)
          .lte('date_paiement', endOfDay);

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
    try {
      final response = await supabase
          .from('Personnel_hopital')
          .select('Specialite');

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
