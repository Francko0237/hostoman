import 'package:supabase_flutter/supabase_flutter.dart';

class StatistiquePharmacieService {
  final SupabaseClient supabase;
  StatistiquePharmacieService(this.supabase);

  /// Renvoie les KPI globaux + ventes par jour (7 derniers) +
  /// top 5 médicaments les plus vendus.
  Future<Map<String, dynamic>> getStats() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekAgoIso = DateTime(weekAgo.year, weekAgo.month, weekAgo.day)
        .toIso8601String();

    // Ventes payées sur la semaine
    final paiements = await supabase
        .from('paiement')
        .select('prix_a_paye, date_paiement')
        .eq('motif', 'Medicaments')
        .eq('statut_paiement', 'paye')
        .gte('date_paiement', weekAgoIso);

    double totalSemaine = 0;
    int countSemaine = 0;
    final Map<String, double> parJour = {};
    for (var i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: 6 - i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      parJour[key] = 0;
    }
    for (final p in paiements as List<dynamic>) {
      final amt = (p['prix_a_paye'] as num?)?.toDouble() ?? 0;
      totalSemaine += amt;
      countSemaine++;
      final dStr = (p['date_paiement'] ?? '').toString();
      if (dStr.length >= 10) {
        final key = dStr.substring(0, 10);
        if (parJour.containsKey(key)) {
          parJour[key] = (parJour[key] ?? 0) + amt;
        }
      }
    }

    // Top médicaments (sur les lignes délivrées de la semaine)
    final lignes = await supabase
        .from('prescription_ligne')
        .select(
            'nom_medicament, quantite, prix_unitaire, statut_ligne, '
            'prescription!inner(date_prescription, statut_prescription)')
        .inFilter('statut_ligne', ['delivre', 'substitue']);

    final Map<String, Map<String, num>> topMap = {};
    for (final l in lignes as List<dynamic>) {
      final nom = (l['nom_medicament'] ?? '').toString();
      final qte = (l['quantite'] as num?)?.toInt() ?? 0;
      final prix = (l['prix_unitaire'] as num?)?.toDouble() ?? 0;
      final entry = topMap.putIfAbsent(nom, () => {'qte': 0, 'ca': 0});
      entry['qte'] = (entry['qte'] ?? 0) + qte;
      entry['ca'] = (entry['ca'] ?? 0) + prix * qte;
    }
    final top = topMap.entries
        .map((e) => {
              'nom': e.key,
              'quantite': e.value['qte']!.toInt(),
              'ca': (e.value['ca'] ?? 0).toDouble(),
            })
        .toList()
      ..sort((a, b) => (b['quantite'] as int).compareTo(a['quantite'] as int));

    // Stock bas
    final medicaments = await supabase
        .from('listemedicament')
        .select('id_medicament, nom_medicament, stock, seuil_alerte, actif')
        .eq('actif', true);

    int stockBas = 0;
    int rupture = 0;
    for (final m in medicaments as List<dynamic>) {
      final s = (m['stock'] as num?)?.toInt() ?? 0;
      final a = (m['seuil_alerte'] as num?)?.toInt() ?? 0;
      if (s == 0) {
        rupture++;
      } else if (s <= a) {
        stockBas++;
      }
    }

    return {
      'total_semaine': totalSemaine,
      'count_semaine': countSemaine,
      'par_jour': parJour, // map keyée par yyyy-MM-dd
      'top_medicaments': top.take(5).toList(),
      'stock_bas': stockBas,
      'rupture': rupture,
      'total_catalogue': medicaments.length,
    };
  }
}
