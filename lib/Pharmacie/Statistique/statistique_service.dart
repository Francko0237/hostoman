import 'package:supabase_flutter/supabase_flutter.dart';

class StatistiquePharmacieService {
  final SupabaseClient supabase;
  StatistiquePharmacieService(this.supabase);

  /// Renvoie les KPI pour une plage de dates donnée.
  Future<Map<String, dynamic>> getStatsParPlage(
    DateTime dateDebut,
    DateTime dateFin,
  ) async {
    final debutIso = DateTime(
      dateDebut.year,
      dateDebut.month,
      dateDebut.day,
    ).toIso8601String();
    final finIso = DateTime(
      dateFin.year,
      dateFin.month,
      dateFin.day,
      23,
      59,
      59,
    ).toIso8601String();

    // 1. Paiements médicaments payés dans la plage (par date de paiement)
    final paiements = await supabase
        .from('paiement')
        .select('prix_a_paye, date_paiement')
        .eq('motif', 'Medicaments')
        .inFilter('statut_paiement', ['paye', 'payer', 'payé'])
        .gte('date_paiement', debutIso)
        .lte('date_paiement', finIso);

    double totalVente = 0;
    final Map<String, double> parJour = {};
    final nbJours = dateFin.difference(dateDebut).inDays + 1;
    for (var i = 0; i < nbJours; i++) {
      final d = dateDebut.add(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      parJour[key] = 0;
    }
    for (final p in paiements as List<dynamic>) {
      final amt = (p['prix_a_paye'] as num?)?.toDouble() ?? 0;
      totalVente += amt;
      final dStr = (p['date_paiement'] ?? '').toString();
      if (dStr.length >= 10) {
        final key = dStr.substring(0, 10);
        if (parJour.containsKey(key)) {
          parJour[key] = (parJour[key] ?? 0) + amt;
        }
      }
    }

    // 2. Prescriptions créées dans la plage
    final prescriptions = await supabase
        .from('prescription')
        .select('id_prescription')
        .gte('date_prescription', debutIso)
        .lte('date_prescription', finIso);

    final prescIds = (prescriptions as List<dynamic>)
        .map((p) => p['id_prescription'] as int)
        .toList();
    final totalOrdonnances = prescIds.length;

    // 3. Lignes délivrées pour ces prescriptions
    int totalMedVendus = 0;
    final Map<String, Map<String, num>> topMap = {};
    if (prescIds.isNotEmpty) {
      final lignes = await supabase
          .from('prescription_ligne')
          .select('nom_medicament, quantite, prix_unitaire, statut_ligne')
          .inFilter('id_prescription', prescIds)
          .inFilter('statut_ligne', ['delivre', 'substitue']);
      for (final l in lignes as List<dynamic>) {
        final nom = (l['nom_medicament'] ?? '').toString();
        final qte = (l['quantite'] as num?)?.toInt() ?? 0;
        final prix = (l['prix_unitaire'] as num?)?.toDouble() ?? 0;
        totalMedVendus += qte;
        final entry = topMap.putIfAbsent(nom, () => {'qte': 0, 'ca': 0});
        entry['qte'] = (entry['qte'] ?? 0) + qte;
        entry['ca'] = (entry['ca'] ?? 0) + prix * qte;
      }
    }
    final top =
        topMap.entries
            .map(
              (e) => {
                'nom': e.key,
                'quantite': e.value['qte']!.toInt(),
                'ca': (e.value['ca'] ?? 0).toDouble(),
              },
            )
            .toList()
          ..sort(
            (a, b) => (b['quantite'] as int).compareTo(a['quantite'] as int),
          );

    // 4. Stock actuel (indépendant de la plage)
    final medicaments = await supabase
        .from('listemedicament')
        .select('stock, seuil_alerte')
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
      'total_vente': totalVente,
      'par_jour': parJour,
      'top_medicaments': top.take(5).toList(),
      'stock_bas': stockBas,
      'rupture': rupture,
      'total_catalogue': medicaments.length,
      'total_med_vendus': totalMedVendus,
      'total_ordonnances': totalOrdonnances,
    };
  }
}
