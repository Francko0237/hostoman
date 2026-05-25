import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/model_unifier.dart';

class PharmacienService {
  final SupabaseClient client;
  PharmacienService(this.client);

  Future<Medecin?> fetchPharmacienConnecte() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('Aucun utilisateur connecté');
      }
      final response = await client
          .from('Personnel_hopital')
          .select()
          .eq('id_personnel', user.id)
          .single();
      return Medecin.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Stats personnelles : ordonnances délivrées, ventes du jour
  Future<Map<String, dynamic>> fetchStatsPharmacien() async {
    try {
      final today = DateTime.now();
      final startOfDay =
          DateTime(today.year, today.month, today.day).toIso8601String();

      final delivrees = await client
          .from('prescription')
          .select('id_prescription')
          .eq('statut_prescription', 'delivre')
          .count(CountOption.exact);

      final ventesJour = await client
          .from('paiement')
          .select('prix_a_paye')
          .eq('motif', 'Medicaments')
          .eq('statut_paiement', 'paye')
          .gte('date_paiement', startOfDay);

      double totalJour = 0;
      for (final p in ventesJour as List<dynamic>) {
        totalJour += (p['prix_a_paye'] as num?)?.toDouble() ?? 0;
      }

      return {
        'delivrees_total': delivrees.count,
        'ventes_jour': totalJour,
      };
    } catch (_) {
      return {'delivrees_total': 0, 'ventes_jour': 0.0};
    }
  }
}
