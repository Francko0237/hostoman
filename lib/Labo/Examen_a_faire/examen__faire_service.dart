import 'package:supabase_flutter/supabase_flutter.dart';

class LaboExamensService {
  final SupabaseClient supabase;
  LaboExamensService(this.supabase);

  /// 📋 Liste des patients en attente (Filtrée par le champ 'payer' de ta DB)
  /// Et qui ont au moins un examen non traité (ni "En cours", ni "Terminé", ni "Annulé")
  Future<List<Map<String, dynamic>>> getPatientsEnAttenteExamen() async {
    final response = await supabase
        .from('Consultation')
        .select('''
            *,
            Patient(*),
            paiement!inner(*),
            examen_a_effectuer!inner(id_examen)
          ''')
        .eq('Statut_Consultation', 'en-attente-examen')
        .eq('paiement.statut_paiement', 'payer')
        .eq(
          'paiement.motif',
          'Examens',
        ) // Filtre sur le motif spécifique aux examens
        // On ne veut que les consultations qui ont au moins un examen "en attente"
        .neq('examen_a_effectuer.statut_examen', 'En cours')
        .neq('examen_a_effectuer.statut_examen', 'Terminé')
        .neq('examen_a_effectuer.statut_examen', 'Annulé')
        .order('date_enregistrement', ascending: true);

    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// 🔬 Récupère les examens d'une consultation (seulement ceux en attente)
  Future<List<Map<String, dynamic>>> getExamensParConsultation(
    int idConsultation,
  ) async {
    final response = await supabase
        .from('examen_a_effectuer')
        .select('*')
        .eq('id_consultation', idConsultation)
        .neq('statut_examen', 'En cours') // On masque ceux en cours
        .neq('statut_examen', 'Terminé') // On masque ceux terminés
        .neq('statut_examen', 'Annulé') // On masque ceux annulés
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

  /// 🔍 Vérifie si tous les examens sont finis ou en cours pour libérer le patient
  Future<String> verifierStatutExamens(int idConsultation) async {
    final response = await supabase
        .from('examen_a_effectuer')
        .select('statut_examen')
        .eq('id_consultation', idConsultation);

    final examens = response as List<dynamic>;
    if (examens.isEmpty) return 'vide';

    // Compte les examens qui sont "traités" (Terminé, Annulé ou En cours)
    int nbTraites = examens
        .where(
          (e) =>
              e['statut_examen'] == 'Terminé' ||
              e['statut_examen'] == 'Annulé' ||
              e['statut_examen'] == 'En cours',
        )
        .length;

    // Si tous les examens sont traités (donc plus aucun "en attente"), on renvoie un statut spécial
    if (nbTraites == examens.length) return 'tous-traites';
    return 'partiel';
  }

  /// ✅ Met à jour la consultation quand le labo a pris en charge toutes les analyses
  Future<void> mettreAJourStatutConsultation(int idConsultation) async {
    // 1. On vérifie l'état réel de TOUS les examens de cette consultation
    final statut = await verifierStatutExamens(idConsultation);

    print('🔍 Résultat de la vérification : $statut');

    if (statut == 'tous-traites') {
      // 2. Si tout est traité (En cours ou Terminé), on met à jour la table Consultation
      // On passe à 'en-attente-resultat' comme demandé
      await supabase
          .from('Consultation')
          .update({
            'Statut_Consultation': 'en-attente-resultat',
            'date_derniere_mise_ajour': DateTime.now().toIso8601String(),
          })
          .eq('id_consultation', idConsultation);

      print('✅ Statut Consultation mis à jour : en-attente-resultat');
    } else {
      print(
        '⏸️ Il reste encore des examens en attente, on ne change pas le statut global.',
      );
    }
  }
}
