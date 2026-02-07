import 'package:supabase_flutter/supabase_flutter.dart';

class ResultatsService {
  final SupabaseClient supabase;

  ResultatsService(this.supabase);

  /// 📋 Récupère les patients en attente de résultat
  /// Basé sur la Consultation (Statut_Consultation = 'en-attente-resultat')
  Future<List<Map<String, dynamic>>> getPatientsEnAttenteResultat() async {
    final response = await supabase
        .from('Consultation')
        .select('id_consultation, id_patient, date_enregistrement, Statut_Consultation, Patient(*)')
        .eq('Statut_Consultation', 'en-attente-resultat')
        .eq('paye_examen', true)
        .order('date_enregistrement', ascending: true);

    return (response as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
  }

  /// 🔬 Récupère la liste des examens terminés pour une consultation donnée
  /// Basé sur examen_a_effectuer avec statut 'En cours'
  Future<List<Map<String, dynamic>>> getExamensTerminesParConsultation(int idConsultation) async {
    final response = await supabase
        .from('examen_a_effectuer')
        .select('id_examen, nom_examen, statut_examen, prix_examen')
        .eq('id_consultation', idConsultation)
        .eq('statut_examen', 'En cours') // Les examens terminés sont marqués "En cours"
        .order('id_examen', ascending: true);

    return (response as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
  }

  /// 📄 Récupère les détails d'un examen spécifique
  Future<Map<String, dynamic>?> getExamenDetails(int idExamen) async {
    final response = await supabase
        .from('examen_a_effectuer')
        .select('*')
        .eq('id_examen', idExamen)
        .single();

    return response;
  }

  /// 💾 Enregistre le résultat d'un examen
  /// (Pour l'instant, on peut juste marquer comme "Résultat saisi" ou ajouter une note)
  Future<void> enregistrerResultatExamen(int idExamen, String resultat) async {
    await supabase
        .from('examen_a_effectuer')
        .update({
      'resultat_examen': resultat,
      'statut_examen': 'Terminé',
    })
        .eq('id_examen', idExamen);
  }

  /// ✅ Vérifie si tous les résultats d'une consultation sont saisis
  Future<bool> tousLesResultatsSaisis(int idConsultation) async {
    final response = await supabase
        .from('examen_a_effectuer')
        .select('statut_examen')
        .eq('id_consultation', idConsultation)
        .eq('statut_examen', 'En cours'); // Ceux qui n'ont pas encore de résultat

    final examensEnCours = (response as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();

    // Si la liste est vide, tous les résultats sont saisis
    return examensEnCours.isEmpty;
  }

  /// ✅ Finalise la consultation (tous les résultats saisis)
  Future<void> finaliserConsultation(int idConsultation) async {
    await supabase
        .from('Consultation')
        .update({'Statut_Consultation': 'examen-effectue'})
        .eq('id_consultation', idConsultation);
  }
}