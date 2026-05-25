import 'package:supabase_flutter/supabase_flutter.dart';

/// Service pour les KPI du dashboard pharmacie.
class PharmacieDashboardService {
  final SupabaseClient supabase;
  PharmacieDashboardService(this.supabase);

  /// Renvoie les compteurs principaux affichés sur le dashboard.
  Future<Map<String, dynamic>> getKpis() async {
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();

    // 1. Ordonnances en attente de paiement
    final attente = await supabase
        .from('prescription')
        .select('id_prescription')
        .eq('statut_prescription', 'en_attente_paiement')
        .count(CountOption.exact);

    // 2. Ordonnances payées à délivrer (paye + partiellement_delivre)
    final aDelivrer = await supabase
        .from('prescription')
        .select('id_prescription')
        .inFilter(
            'statut_prescription', ['paye', 'partiellement_delivre']).count(
                CountOption.exact);

    // 3. Ventes du jour (paiements payés aujourd'hui motif='Medicaments')
    final paiementsJour = await supabase
        .from('paiement')
        .select('prix_a_paye, statut_paiement, motif, date_paiement')
        .eq('motif', 'Medicaments')
        .eq('statut_paiement', 'paye')
        .gte('date_paiement', startOfDay);

    double totalJour = 0;
    int countJour = 0;
    for (final p in paiementsJour as List<dynamic>) {
      totalJour += (p['prix_a_paye'] as num?)?.toDouble() ?? 0;
      countJour++;
    }

    // 4. Stock bas
    final medicaments = await supabase
        .from('listemedicament')
        .select('id_medicament, stock, seuil_alerte')
        .eq('actif', true);

    int stockBas = 0;
    for (final m in medicaments as List<dynamic>) {
      final s = (m['stock'] as num?)?.toInt() ?? 0;
      final a = (m['seuil_alerte'] as num?)?.toInt() ?? 0;
      if (s <= a) stockBas++;
    }

    return {
      'en_attente_paiement': attente.count,
      'a_delivrer': aDelivrer.count,
      'ventes_jour_total': totalJour,
      'ventes_jour_count': countJour,
      'stock_bas': stockBas,
    };
  }
}
