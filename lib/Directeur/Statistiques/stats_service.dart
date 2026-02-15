import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class StatsService {
  final SupabaseClient supabase;

  StatsService(this.supabase);

  /// 📊 Récupère les stats globales (Total)
  Future<Map<String, dynamic>> getGlobalStats() async {
    try {
      // 1. Revenu Total (Somme des paiements validés)
      final revenuResponse = await supabase
          .from('paiement')
          .select('prix_a_paye')
          .eq(
            'statut_paiement',
            'payer',
          ); // Assurez-vous que c'est 'payer' ou 'payé'

      double revenuTotal = 0;
      for (var p in revenuResponse) {
        revenuTotal += (p['prix_a_paye'] as num).toDouble();
      }

      // 2. Total Patients (Nombre de patients enregistrés)
      final patientsResponse = await supabase
          .from('Patient')
          .select('id_patient')
          .count(CountOption.exact);

      final totalPatients = patientsResponse.count;

      // 3. Total Consultations (Toutes les consultations)
      final consultationsResponse = await supabase
          .from('Consultation')
          .select('id_consultation')
          .count(CountOption.exact);

      final totalConsultations = consultationsResponse.count;

      return {
        'revenu': revenuTotal,
        'patients': totalPatients,
        'consultations': totalConsultations,
      };
    } catch (e) {
      print('Erreur Global Stats: $e');
      return {'revenu': 0.0, 'patients': 0, 'consultations': 0};
    }
  }

  /// � Récupère l'activité des 7 derniers jours pour le graphe
  Future<List<Map<String, dynamic>>> getDailyActivity() async {
    try {
      final now = DateTime.now();
      final List<Map<String, dynamic>> activity = [];

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(
          date.year,
          date.month,
          date.day,
        ).toIso8601String();
        final endOfDay = DateTime(
          date.year,
          date.month,
          date.day,
          23,
          59,
          59,
        ).toIso8601String();
        final dayLabel = DateFormat('EEE', 'fr_FR').format(date);

        final countResponse = await supabase
            .from('Consultation')
            .select('id_consultation')
            .gte('date_enregistrement', startOfDay)
            .lte('date_enregistrement', endOfDay)
            .count(CountOption.exact);

        activity.add({'day': dayLabel, 'count': countResponse.count});
      }
      return activity;
    } catch (e) {
      print('Erreur Daily Activity: $e');
      return [];
    }
  }

  /// �🚻 Récupère la démographie des patients (Sexe et Âge)
  Future<Map<String, dynamic>> getDemographics() async {
    try {
      final response = await supabase.from('Patient').select('sexe, age');

      int male = 0;
      int female = 0;
      Map<String, int> ageRanges = {
        '0-18': 0,
        '19-35': 0,
        '36-60': 0,
        '60+': 0,
      };

      for (var p in response) {
        // Sexe
        if (p['sexe'] == 'M') male++;
        if (p['sexe'] == 'F') female++;

        // Âge
        int age = int.tryParse(p['age'].toString()) ?? 0;
        if (age <= 18)
          ageRanges['0-18'] = ageRanges['0-18']! + 1;
        else if (age <= 35)
          ageRanges['19-35'] = ageRanges['19-35']! + 1;
        else if (age <= 60)
          ageRanges['36-60'] = ageRanges['36-60']! + 1;
        else
          ageRanges['60+'] = ageRanges['60+']! + 1;
      }

      return {
        'gender': {'M': male, 'F': female},
        'ageRanges': ageRanges,
      };
    } catch (e) {
      print('Erreur Demographics: $e');
      return {
        'gender': {'M': 0, 'F': 0},
        'ageRanges': {'0-18': 0, '19-35': 0, '36-60': 0, '60+': 0},
      };
    }
  }

  /// 🏥 Récupère les stats opérationnelles (États des consultations)
  Future<Map<String, int>> getOperationalStats() async {
    try {
      final response = await supabase
          .from('Consultation')
          .select('Statut_Consultation');

      Map<String, int> stats = {'terminer': 0, 'en attente': 0, 'annuler': 0};

      for (var c in response) {
        String status = c['Statut_Consultation'] ?? 'en attente';
        if (status.contains('attente'))
          stats['en attente'] = stats['en attente']! + 1;
        else if (status == 'terminer')
          stats['terminer'] = stats['terminer']! + 1;
        else if (status == 'annuler')
          stats['annuler'] = stats['annuler']! + 1;
      }
      return stats;
    } catch (e) {
      print('Erreur Operational Stats: $e');
      return {'terminer': 0, 'en attente': 0, 'annuler': 0};
    }
  }

  /// 💰 Récupère le revenu détaillé (30 derniers jours)
  Future<List<Map<String, dynamic>>> getRevenueTrend() async {
    try {
      final now = DateTime.now();
      final List<Map<String, dynamic>> trend = [];

      for (int i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(
          date.year,
          date.month,
          date.day,
        ).toIso8601String();
        final endOfDay = DateTime(
          date.year,
          date.month,
          date.day,
          23,
          59,
          59,
        ).toIso8601String();

        final response = await supabase
            .from('paiement')
            .select('prix_a_paye')
            .eq('statut_paiement', 'payer')
            .gte('date_paiement', startOfDay)
            .lte('date_paiement', endOfDay);

        double dailyTotal = 0;
        for (var p in response) {
          dailyTotal += (p['prix_a_paye'] as num).toDouble();
        }

        trend.add({
          'date': DateFormat('dd/MM').format(date),
          'amount': dailyTotal,
        });
      }
      return trend;
    } catch (e) {
      print('Erreur Revenue Trend: $e');
      return [];
    }
  }
}
