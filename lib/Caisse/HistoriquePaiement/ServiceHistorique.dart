import 'package:supabase_flutter/supabase_flutter.dart';

class PaiementService {
  final SupabaseClient supabase;

  PaiementService(this.supabase);

  /// 🔍 Récupère les patients dont le paiement est effectué ou annulé
  Future<List<Map<String, dynamic>>> getPatientsNonPayes() async {
    try {
      final response = await supabase
          .from('Consultation')
          .select('''
          id_consultation, 
          type_service, 
          date_enregistrement,
          id_patient, 
          Patient(*), 
          paiement!inner(*)
        ''')
          .or(
            'statut_paiement.eq.payer,statut_paiement.eq.annuler',
            referencedTable: 'paiement',
          );

      // SI L'ERREUR PERSISTE avec le code ci-dessus, utilise cette syntaxe alternative :
      // .or('paiement.statut_paiement.eq.annuler, paiement.statut_paiement.eq.payer');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Erreur détectée : $e");
      return [];
    }
  }
}
