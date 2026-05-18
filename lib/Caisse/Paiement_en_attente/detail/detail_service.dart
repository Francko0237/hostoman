import 'package:supabase_flutter/supabase_flutter.dart';

class DetailService {
  final SupabaseClient supabase;
  DetailService(this.supabase);

  /// 🔍 Récupère les détails complets d'un patient et de son paiement
  Future<Map<String, dynamic>?> getPatientPaymentDetails(
    String idConsultation,
  ) async {
    try {
      final response = await supabase
          .from('Consultation')
          .select('''
            id_consultation,
            type_service,
            date_enregistrement,
            Statut_Consultation,
            id_patient,
            Patient(*),
            paiement!inner(*),
            examen_a_effectuer(nom_examen, prix_examen, statut_examen)
          ''')
          .eq('id_consultation', idConsultation)
          .single();

      return response;
    } catch (e) {
      print("Erreur getPatientPaymentDetails: $e");
      return null;
    }
  }

  /// ✅ Valide le paiement
  Future<void> validerPaiement(String idConsultation) async {
    try {
      await supabase
          .from('paiement')
          .update({'statut_paiement': 'payer'})
          .eq('id_consultation', idConsultation);

      print("Paiement validé avec succès");
    } catch (e) {
      print("Erreur lors de la validation : $e");
    }
  }

  /// ❌ Annule le paiement
  Future<void> annulerPaiement(String idConsultation) async {
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
