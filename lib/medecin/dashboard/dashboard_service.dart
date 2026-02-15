import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  final SupabaseClient supabase;

  DashboardService(this.supabase);

  /// 📊 Récupère les statistiques du jour
  Future<Map<String, int>> getDailyStats() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).toIso8601String();
      final todayEnd = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
      ).toIso8601String();

      // 1. Consultations (En attente de consultation pour aujourd'hui)
      final consultationsResponse = await supabase
          .from('Consultation')
          .select('id_consultation, paiement!inner(*)')
          .eq('type_service', 'Consultation')
          .eq('paiement.statut_paiement', 'payer')
          .eq('Statut_Consultation', 'en-attente-consultation')
          .gte('date_enregistrement', todayStart)
          .lte('date_enregistrement', todayEnd)
          .count(CountOption.exact);

      final consultationsCount = consultationsResponse.count;

      // 2. En Attente (En examen ou résultats pour aujourd'hui)
      // Note: On regarde ceux qui son en cours de traitement aujourd'hui
      final enAttenteResponse = await supabase
          .from('Consultation')
          .select('id_consultation')
          .or(
            'Statut_Consultation.eq.en-attente-examen,Statut_Consultation.eq.en-attente-resultat,Statut_Consultation.eq.resultat-disponible',
          )
          .gte('date_enregistrement', todayStart)
          .lte('date_enregistrement', todayEnd)
          .count(CountOption.exact);

      final enAttenteCount = enAttenteResponse.count;

      // 3. Terminer (Consultations terminées aujourd'hui)
      final terminerResponse = await supabase
          .from('Consultation')
          .select('id_consultation')
          .eq('Statut_Consultation', 'terminer')
          .gte('date_enregistrement', todayStart)
          .lte('date_enregistrement', todayEnd)
          .count(CountOption.exact);

      final terminerCount = terminerResponse.count;

      return {
        'consultations': consultationsCount,
        'en_attente': enAttenteCount,
        'terminer': terminerCount,
      };
    } catch (e) {
      print('Erreur lors du chargement des stats: $e');
      return {'consultations': 0, 'en_attente': 0, 'terminer': 0};
    }
  }
}
