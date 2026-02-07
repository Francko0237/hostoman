import 'package:supabase_flutter/supabase_flutter.dart';

class LaboExamensService {
  final SupabaseClient supabase;
  LaboExamensService(this.supabase);

  /// 📋 Liste des patients en attente (Filtrée par le champ 'payer' de ta DB)
  Future<List<Map<String, dynamic>>> getPatientsEnAttenteExamen() async {
    final response = await supabase
        .from('Consultation')
        .select('''
            *,
            Patient(*),
            paiement!inner(*)
          ''')
        .eq('Statut_Consultation', 'en-attente-examen')
        .eq('paiement.statut_paiement', 'payer') // Filtre sur la table jointe
        .order('date_enregistrement', ascending: true);

    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// 🔬 Récupère les examens d'une consultation
  Future<List<Map<String, dynamic>>> getExamensParConsultation(
    int idConsultation,
  ) async {
    final response = await supabase
        .from('examen_a_effectuer')
        .select('*')
        .eq('id_consultation', idConsultation)
        .order('id_examen', ascending: true);

    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// 💾 Enregistre le résultat final d'un examen
  Future<void> enregistrerResultatExamen({
    required int idExamen,
    required String resultat,
    required int idConsultation,
  }) async {
    // 1. Mise à jour de l'examen
    await supabase
        .from('examen_a_effectuer')
        .update({'resultat_examen': resultat, 'statut_examen': 'Terminé'})
        .eq('id_examen', idExamen);

    // 2. Vérification automatique du statut global
    await mettreAJourStatutConsultation(idConsultation);
  }

  /// 🛠 Met les examens sélectionnés en mode "En cours"
  Future<void> enregistrerExamensEnCours(List<int> idExamens) async {
    await supabase
        .from('examen_a_effectuer')
        .update({'statut_examen': 'En cours'})
        .inFilter('id_examen', idExamens);
  }

  /// ❌ Annule les examens sélectionnés
  Future<void> annulerExamens(List<int> idExamens) async {
    await supabase
        .from('examen_a_effectuer')
        .update({'statut_examen': 'Annulé'})
        .inFilter('id_examen', idExamens);
  }

  /// 🔍 Vérifie si tous les examens sont finis pour libérer le patient
  Future<String> verifierStatutExamens(int idConsultation) async {
    final response = await supabase
        .from('examen_a_effectuer')
        .select('statut_examen')
        .eq('id_consultation', idConsultation);

    final examens = response as List<dynamic>;
    if (examens.isEmpty) return 'vide';

    int nbTermines = examens
        .where(
          (e) =>
              e['statut_examen'] == 'Terminé' || e['statut_examen'] == 'Annulé',
        )
        .length;

    if (nbTermines == examens.length) return 'tous-termines';
    return 'en-cours';
  }

  /// ✅ Met à jour la consultation quand le labo a fini toutes les analyses
  Future<void> mettreAJourStatutConsultation(int idConsultation) async {
    // 1. On vérifie l'état réel de TOUS les examens de cette consultation
    final statut = await verifierStatutExamens(idConsultation);

    print('🔍 Résultat de la vérification : $statut');

    if (statut == 'tous-termines') {
      // 2. Si tout est fini, on met à jour la table Consultation
      // On touche à Statut_Consultation POUR LE FLUX
      // On touche à statut_examen POUR TON CAS PRÉCIS
      await supabase
          .from('Consultation')
          .update({
            'Statut_Consultation': 'en-attente-resultat',
            'statut_examen':
                'termine', // C'est ici qu'on touche ta colonne spécifique
            'date_derniere_mise_ajour': DateTime.now().toIso8601String(),
          })
          .eq('id_consultation', idConsultation);

      print('✅ Statut Consultation mis à jour avec succès en base de données.');
    } else {
      print(
        '⏸️ Il reste encore des examens actifs, on ne change pas le statut global.',
      );
    }
  }
}
