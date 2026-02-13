import 'package:supabase_flutter/supabase_flutter.dart';

class ConsultationService {
  final SupabaseClient supabase;

  ConsultationService(this.supabase);

  /// 📋 Récupère les patients en attente de examen (qui ont payé)
  Future<List<Map<String, dynamic>>> getPatientsEnAttente() async {
    final response = await supabase
        .from('Consultation')
        .select('''
          *,
          Patient(*),
          paiement(*),
          examen_a_effectuer!inner(*)
        ''')
        .or(
          'Statut_Consultation.eq.en-attente-examen,Statut_Consultation.eq.en-attente-resultat,Statut_Consultation.eq.resultat-disponible,Statut_Consultation.eq.Annuler',
        )
        .order('date_enregistrement', ascending: true);

    // 🔄 Dédoublonnage robuste par id_consultation
    final Map<int, Map<String, dynamic>> uniqueConsultations = {};

    for (var item in response as List<dynamic>) {
      final map = item as Map<String, dynamic>;
      final id = int.tryParse(map['id_consultation'].toString()) ?? 0;

      // Filtrage métier : Si c'est en attente d'examen, on vérifie le paiement
      final statut = map['Statut_Consultation'];
      if (statut == 'en-attente-examen') {
        final paiements = map['paiement'] as List<dynamic>?;
        final aPaye =
            paiements != null &&
            paiements.any((p) => p['statut_paiement'] == 'payer');
        if (!aPaye) continue; // On masque si pas encore payé au labo
      }

      uniqueConsultations[id] = map;
    }

    return uniqueConsultations.values.toList();
  }

  /// ✅ Commencer une consultation (Statut = 'En cours')
  Future<void> commencerConsultation(String idConsultation) async {
    await supabase
        .from('Consultation')
        .update({'Statut_Consultation': 'En cours'})
        .eq('id_consultation', idConsultation);
  }

  /// 🔄 Reporter une consultation (Statut = 'Reporter')
  Future<void> reporterConsultation(String idConsultation) async {
    await supabase
        .from('Consultation')
        .update({'Statut_Consultation': 'Reporter'})
        .eq('id_consultation', idConsultation);
  }

  /// ❌ Annuler une consultation (Statut = 'Annuler')
  Future<void> annulerConsultation(String idConsultation) async {
    await supabase
        .from('Consultation')
        .update({'Statut_Consultation': 'Annuler'})
        .eq('id_consultation', idConsultation);
  }
}
