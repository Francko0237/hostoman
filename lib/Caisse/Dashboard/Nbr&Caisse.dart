import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardStatsService {
  final SupabaseClient supabase;

  DashboardStatsService(this.supabase);

  /// 📊 Récupère les statistiques du jour (Personnes reçues + Total encaissé)
  Future<Map<String, dynamic>> getStatsJour() async {
    final now = DateTime.now();
    final debutJour = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final finJour = DateTime(now.year, now.month, now.day, 23, 59, 59);

    try {
      // Récupérer toutes les consultations avec paiements validés aujourd'hui
      final response = await supabase
          .from('Consultation')
          .select('id_consultation, date_enregistrement, paiement!inner(*)')
          .eq('paiement.statut_paiement', 'payer')
          .gte('date_enregistrement', debutJour.toIso8601String())
          .lte('date_enregistrement', finJour.toIso8601String());

      final List<dynamic> data = response as List<dynamic>;
      final nombrePatients = data.length;

      // Calculer le total encaissé à partir des montants réels
      double totalEncaisse = 0;
      for (var consultation in data) {
        final List<dynamic> paiements = consultation['paiement'] ?? [];
        if (paiements.isNotEmpty) {
          // Prendre seulement le premier paiement (il n'y a qu'un paiement par consultation)
          totalEncaisse += (paiements[0]['prix_a_paye'] as num).toDouble();
        }
      }

      return {
        'personnes_recues': nombrePatients,
        'total_encaisse': totalEncaisse.toInt(),
        'date_recuperation': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Erreur lors de la récupération des stats du jour: $e');
      return {
        'personnes_recues': 0,
        'total_encaisse': 0,
        'date_recuperation': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 📈 Stream pour actualisation en temps réel toutes les 5 secondes
  Stream<Map<String, dynamic>> getStatsJourStream() async* {
    while (true) {
      yield await getStatsJour();
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  /// 📊 Récupère uniquement le nombre de personnes reçues aujourd'hui
  Future<int> getPersonnesRecuesJour() async {
    final stats = await getStatsJour();
    return stats['personnes_recues'] as int;
  }

  /// 💰 Récupère uniquement le total encaissé aujourd'hui
  Future<int> getTotalEncaisseJour() async {
    final stats = await getStatsJour();
    return stats['total_encaisse'] as int;
  }

  /// 📅 Récupère les stats d'une période personnalisée
  Future<Map<String, dynamic>> getStatsPeriode({
    required DateTime dateDebut,
    required DateTime dateFin,
  }) async {
    try {
      final response = await supabase
          .from('Consultation')
          .select('id_consultation, paiement!inner(*)')
          .eq('paiement.statut_paiement', 'payer')
          .gte('date_enregistrement', dateDebut.toIso8601String())
          .lte('date_enregistrement', dateFin.toIso8601String());

      final List<dynamic> data = response as List<dynamic>;
      final nombrePatients = data.length;

      // Calculer le total encaissé à partir des montants réels
      double totalEncaisse = 0;
      for (var consultation in data) {
        final List<dynamic> paiements = consultation['paiement'] ?? [];
        if (paiements.isNotEmpty) {
          // Prendre seulement le premier paiement (il n'y a qu'un paiement par consultation)
          totalEncaisse += (paiements[0]['prix_a_paye'] as num).toDouble();
        }
      }

      return {
        'personnes_recues': nombrePatients,
        'total_encaisse': totalEncaisse.toInt(),
      };
    } catch (e) {
      print('❌ Erreur lors de la récupération des stats de la période: $e');
      return {'personnes_recues': 0, 'total_encaisse': 0};
    }
  }

  /// 📊 Formatte le montant avec séparateur de milliers
  String formatMontant(int montant) {
    return montant.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]} ',
    );
  }
}
