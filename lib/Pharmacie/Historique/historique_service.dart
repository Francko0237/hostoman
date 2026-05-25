import 'package:supabase_flutter/supabase_flutter.dart';

class HistoriquePharmacieService {
  final SupabaseClient supabase;
  HistoriquePharmacieService(this.supabase);

  /// Liste les prescriptions terminées (delivre, partiellement_delivre, annule)
  /// avec filtre par période.
  Future<List<Map<String, dynamic>>> lister({
    DateTime? debut,
    DateTime? fin,
    String? typePrescription,
    String? statut,
  }) async {
    var query = supabase
        .from('prescription')
        .select(
            'id_prescription, id_patient, type_prescription, '
            'statut_prescription, total_prix, date_prescription, '
            'date_derniere_mise_ajour, '
            'Patient(nom_complet, sexe, age)')
        .inFilter('statut_prescription',
            ['delivre', 'partiellement_delivre', 'annule', 'paye']);

    if (debut != null) {
      query = query.gte('date_prescription', debut.toIso8601String());
    }
    if (fin != null) {
      query = query.lte('date_prescription', fin.toIso8601String());
    }
    if (typePrescription != null) {
      query = query.eq('type_prescription', typePrescription);
    }
    if (statut != null) {
      query = query.eq('statut_prescription', statut);
    }

    final response =
        await query.order('date_prescription', ascending: false).limit(300);
    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }
}
