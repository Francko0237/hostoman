import 'package:supabase_flutter/supabase_flutter.dart';

class DetailService {
  final SupabaseClient supabase;
  DetailService(this.supabase);

  /// 🔍 Récupère les détails complets d'un paiement par son id_paiement
  Future<Map<String, dynamic>?> getPatientPaymentDetails(
    int idPaiement,
  ) async {
    try {
      final response = await supabase
          .from('paiement')
          .select('''
            id_paiement,
            id_consultation,
            id_prescription,
            prix_a_paye,
            statut_paiement,
            motif,
            date_paiement,
            Consultation(
              id_consultation,
              type_service,
              date_enregistrement,
              Statut_Consultation,
              id_patient,
              Patient(*),
              examen_a_effectuer(nom_examen, prix_examen, statut_examen)
            )
          ''')
          .eq('id_paiement', idPaiement)
          .single();

      return response;
    } catch (e) {
      print("Erreur getPatientPaymentDetails: $e");
      return null;
    }
  }

  /// ✅ Valide le paiement par son id_paiement
  Future<void> validerPaiement(int idPaiement) async {
    try {
      await supabase
          .from('paiement')
          .update({'statut_paiement': 'payer'})
          .eq('id_paiement', idPaiement);

      print("Paiement validé avec succès");
    } catch (e) {
      print("Erreur lors de la validation : $e");
    }
  }

  /// ❌ Annule le paiement par son id_paiement
  Future<void> annulerPaiement(int idPaiement) async {
    try {
      await supabase
          .from('paiement')
          .update({'statut_paiement': 'annuler'})
          .eq('id_paiement', idPaiement);

      print("Paiement annulé");
    } catch (e) {
      print("Erreur lors de l'annulation : $e");
    }
  }
}
