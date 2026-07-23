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
      // Récupérer tous les paiements validés aujourd'hui (Consultations + Examens)
      final response = await supabase
          .from('paiement')
          .select('prix_a_paye, date_paiement, Consultation(id_patient)')
          .eq('statut_paiement', 'payer')
          .gte('date_paiement', debutJour.toIso8601String())
          .lte('date_paiement', finJour.toIso8601String());

      final List<dynamic> data = response as List<dynamic>;

      // Calculer le total encaissé
      double totalEncaisse = 0;
      final Set<String> patientsUniques = {};

      for (var p in data) {
        totalEncaisse += (p['prix_a_paye'] as num).toDouble();

        // Récupérer l'ID du patient via la consultation
        final consultation = p['Consultation'];
        if (consultation != null && consultation['id_patient'] != null) {
          patientsUniques.add(consultation['id_patient'].toString());
        }
      }

      // Récupérer le nombre total de paiements en attente (toutes dates confondues)
      final pendingResponse = await supabase
          .from('paiement')
          .select('id_paiement')
          .eq('statut_paiement', 'en_attente');
      final pendingCount = (pendingResponse as List).length;

      return {
        'personnes_recues':
            data.length, // Compte total des paiements (transactions)
        'total_encaisse': totalEncaisse.toInt(),
        'en_attente': pendingCount,
        'date_recuperation': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Erreur lors de la récupération des stats du jour: $e');
      return {
        'personnes_recues': 0,
        'total_encaisse': 0,
        'en_attente': 0,
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
          .from('paiement')
          .select('prix_a_paye, date_paiement, Consultation(id_patient)')
          .eq('statut_paiement', 'payer')
          .gte('date_paiement', dateDebut.toIso8601String())
          .lte('date_paiement', dateFin.toIso8601String());

      final List<dynamic> data = response as List<dynamic>;

      double totalEncaisse = 0;
      final Set<String> patientsUniques = {};

      for (var p in data) {
        totalEncaisse += (p['prix_a_paye'] as num).toDouble();
        final consultation = p['Consultation'];
        if (consultation != null && consultation['id_patient'] != null) {
          patientsUniques.add(consultation['id_patient'].toString());
        }
      }

      return {
        'personnes_recues':
            data.length, // Compte total des paiements (transactions)
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
