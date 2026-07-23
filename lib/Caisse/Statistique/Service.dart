import 'package:supabase_flutter/supabase_flutter.dart';

class StatsService {
  final SupabaseClient supabase;
  StatsService(this.supabase);

  /// 📊 Récupère les statistiques par période (Logique centrale)
  Future<Map<String, dynamic>> getStatsByPeriod({
    required DateTime dateDebut,
    required DateTime dateFin,
    String statutPaiement = 'tous', // Par défaut 'tous' pour récupérer tout
  }) async {
    // Récupération des consultations avec jointures Patient et Paiement
    var query = supabase
        .from('Consultation')
        .select('*, Patient(*), paiement!inner(*)');

    if (statutPaiement != 'tous') {
      query = query.eq('paiement.statut_paiement', statutPaiement);
    }

    final response = await query
        .gte('date_enregistrement', dateDebut.toIso8601String())
        .lte('date_enregistrement', dateFin.toIso8601String())
        .order('date_enregistrement', ascending: false);

    final consultations = List<Map<String, dynamic>>.from(response);

    double sommeTotale = 0;
    int hommes = 0;
    int femmes = 0;

    for (var con in consultations) {
      // Calcul du revenu réel via la table paiement liée
      final listPaiements = con['paiement'] as List;
      if (listPaiements.isNotEmpty) {
        final statut = listPaiements[0]['statut_paiement']?.toString().toLowerCase();
        // Le revenu ne prend en compte que les paiements validés/payés
        if (statut == 'payer') {
          sommeTotale += (listPaiements[0]['prix_a_paye'] as num).toDouble();
        }
      }

      // Calcul Démographie (Sexe)
      final sexe = con['Patient']['sexe']?.toString().toLowerCase() ?? '';
      if (sexe == 'masculin' || sexe == 'm' || sexe == 'homme') {
        hommes++;
      } else if (sexe == 'feminin' || sexe == 'f' || sexe == 'femme') {
        femmes++;
      }
    }

    return {
      'nombre_patients': consultations.length,
      'somme_generee': sommeTotale.toInt(),
      'hommes': hommes,
      'femmes': femmes,
      'consultations': consultations,
    };
  }

  Future<Map<String, dynamic>> getStatsToday({
    String statutPaiement = 'tous',
  }) async {
    final now = DateTime.now();
    return await getStatsByPeriod(
      dateDebut: DateTime(now.year, now.month, now.day, 0, 0, 0),
      dateFin: DateTime(now.year, now.month, now.day, 23, 59, 59),
      statutPaiement: statutPaiement,
    );
  }

  Future<Map<String, dynamic>> getStatsThisWeek({
    String statutPaiement = 'tous',
  }) async {
    final now = DateTime.now();
    final debut = now.subtract(Duration(days: now.weekday - 1));
    return await getStatsByPeriod(
      dateDebut: DateTime(debut.year, debut.month, debut.day, 0, 0, 0),
      dateFin: DateTime(now.year, now.month, now.day, 23, 59, 59),
      statutPaiement: statutPaiement,
    );
  }

  Future<Map<String, dynamic>> getStatsThisMonth({
    String statutPaiement = 'tous',
  }) async {
    final now = DateTime.now();
    return await getStatsByPeriod(
      dateDebut: DateTime(now.year, now.month, 1, 0, 0, 0),
      dateFin: DateTime(now.year, now.month, now.day, 23, 59, 59),
      statutPaiement: statutPaiement,
    );
  }
}
