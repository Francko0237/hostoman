import 'package:supabase_flutter/supabase_flutter.dart';

class PaiementService {
  final SupabaseClient supabase;
  PaiementService(this.supabase);

  /// 🔍 Récupère les patients dont le paiement de la consultation et des examens qui n'ont pas encore effectué
  Future<List<Map<String, dynamic>>> getPatientsNonPayes() async {
    try {
      final response = await supabase
          .from('Consultation')
          .select('''
            id_consultation, 
            type_service, 
            id_patient, 
            Patient(*),
            paiement!inner(*)
          ''')
          .eq('paiement.statut_paiement', 'non payer');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Erreur getPatientsNonPayes: $e");
      return [];
    }
  }

  /// ✅ Valide le paiement en mettant  'payer':'oui'
  Future<void> validerPaiement(String idConsultation) async {
    try {
      await supabase
          .from('paiement')
          .update({'statut_paiement': 'payer'})
          .eq('id_consultation', idConsultation);

      // Optionnel : Mettre aussi à jour la colonne 'payer' dans Consultation pour la synchro
      await supabase
          .from('Consultation')
          .update({'payer': 'oui'})
          .eq('id_consultation', idConsultation);

      print("Paiement validé avec succès");
    } catch (e) {
      print("Erreur lors de la validation : $e");
    }
  }

  ///  Anuller le paiement en mettant  'payer':'annuler'
  Future<void> AnnulerPaiement(String idConsultation) async {
    try {
      await supabase
          .from('paiement')
          .update({'statut_paiement': 'annuler'})
          .eq('id_consultation', idConsultation);

      print("Paiement annulé");
    } catch (e) {
      print("Erreur lors de l'annulation : $e");
    }
  }
}
