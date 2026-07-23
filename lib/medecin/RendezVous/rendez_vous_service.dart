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

  /// ❌ Annule un rendez-vous
  Future<bool> annulerRendezVous(int idConsultation) async {
    try {
      await supabase
          .from('Consultation')
          .update({
            'programmation_rdv': 'pas_programmer',
            'date_rdv_prevu': null,
          })
          .eq('id_consultation', idConsultation);
      return true;
    } catch (e) {
      print('Erreur lors de l\'annulation du rendez-vous: $e');
      return false;
    }
  }

  /// 📅 Reprogramme un rendez-vous
  Future<bool> reprogrammerRendezVous(int idConsultation, DateTime nouvelleDate) async {
    try {
      await supabase
          .from('Consultation')
          .update({
            'date_rdv_prevu': nouvelleDate.toIso8601String(),
            'programmation_rdv': 'RDV_programmer',
          })
          .eq('id_consultation', idConsultation);
      return true;
    } catch (e) {
      print('Erreur lors de la reprogrammation du rendez-vous: $e');
      return false;
    }
  }
}
