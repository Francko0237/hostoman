import 'package:supabase_flutter/supabase_flutter.dart';

class ResultatsService {
  final SupabaseClient supabase;

  ResultatsService(this.supabase);

  /// 📋 Récupère les patients en attente de résultat
  /// Basé sur la Consultation (Statut_Consultation = 'en-attente-resultat')
  Future<List<Map<String, dynamic>>> getPatientsEnAttenteResultat() async {
    final response = await supabase
        .from('Consultation')
        .select('''
            *,
            Patient(*),
            examen_a_effectuer!inner(id_examen)
        ''')
        .eq('Statut_Consultation', 'en-attente-resultat')
        // On s'assure qu'il reste au moins un examen "En cours" (donc sans résultat)
        .eq('examen_a_effectuer.statut_examen', 'En cours')
        .order('date_enregistrement', ascending: true);

    // Dédoublonnage manuel car !inner peut ramener plusieurs lignes si plusieurs examens
    final uniqueList = <int, Map<String, dynamic>>{};
    for (var item in response as List<dynamic>) {
      final map = item as Map<String, dynamic>;
      uniqueList[map['id_consultation']] = map;
    }

    return uniqueList.values.toList();
  }

  /// 🔬 Récupère la liste des examens en attente de résultat (En cours)
  Future<List<Map<String, dynamic>>> getExamensEnAttenteResultat(
    int idConsultation,
  ) async {
    final response = await supabase
        .from('examen_a_effectuer')
        .select('*')
        .eq('id_consultation', idConsultation)
        .eq(
          'statut_examen',
          'En cours',
        ) // Seuls ceux qui n'ont pas encore de résultat
        .order('id_examen', ascending: true);

    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// 💾 Enregistre le résultat d'un examen et le marque comme Terminé
  Future<void> enregistrerResultatExamen(
    int idExamen,
    String resultat,
    int idConsultation,
  ) async {
    // 1. Mise à jour de l'examen
    await supabase
        .from('examen_a_effectuer')
        .update({
          'resultat_examen': resultat,
          'statut_examen': 'Terminé', // Disparaît de la liste "En cours"
        })
        .eq('id_examen', idExamen);

    // 2. Vérification si tous les examens sont terminés
    await verifierEtFinaliserConsultation(idConsultation);
  }

  /// ✅ Vérifie si tous les résultats d'une consultation sont saisis et met à jour le statut global
  Future<void> verifierEtFinaliserConsultation(int idConsultation) async {
    // Compte combien d'examens sont encore "En cours" pour cette consultation
    final response = await supabase
        .from('examen_a_effectuer')
        .select('id_examen')
        .eq('id_consultation', idConsultation)
        .eq('statut_examen', 'En cours');

    final examensRestants = response as List<dynamic>;

    if (examensRestants.isEmpty) {
      // Tous les examens sont traités (Terminé ou Annulé), on passe la consultation à "resultat-disponible"
      await supabase
          .from('Consultation')
          .update({
            'Statut_Consultation': 'resultat-disponible',
            'date_derniere_mise_ajour': DateTime.now().toIso8601String(),
          })
          .eq('id_consultation', idConsultation);
    }
  }
}
