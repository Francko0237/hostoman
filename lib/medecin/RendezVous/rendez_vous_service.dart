import 'package:supabase_flutter/supabase_flutter.dart';

class RendezVousService {
  final SupabaseClient supabase;

  RendezVousService(this.supabase);

  /// 📅 Récupère la liste des rendez-vous programmés
  Future<List<Map<String, dynamic>>> getRendezVous() async {
    try {
      final response = await supabase
          .from('Consultation')
          .select('''
            id_consultation,
            date_rdv_prevu,
            programmation_rdv,
            Patient!inner(
              id_patient,
              nom_complet,
              telephone,
              sexe,
              age,
              profession
            )
          ''')
          .eq('programmation_rdv', 'RDV_programmer')
          .order('date_rdv_prevu', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur lors de la récupération des rendez-vous: $e');
      return [];
    }
  }
}
