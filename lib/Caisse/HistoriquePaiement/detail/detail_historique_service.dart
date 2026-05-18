import 'package:supabase_flutter/supabase_flutter.dart';

class DetailHistoriqueService {
  final SupabaseClient supabase;
  DetailHistoriqueService(this.supabase);

  /// 🔍 Récupère les détails complets d'un paiement historique
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

  /// 🔍 Récupère les détails d'un paiement spécifique
  Future<Map<String, dynamic>?> getPaymentDetails(String idPaiement) async {
    try {
      final response = await supabase
          .from('paiement')
          .select('''
            id_paiement,
            motif,
            prix_a_paye,
            statut_paiement,
            date_paiement,
            id_consultation,
            Consultation!inner(
              id_consultation,
              type_service,
              date_enregistrement,
              id_patient,
              Patient(*),
              examen_a_effectuer(nom_examen, prix_examen, statut_examen)
            )
          ''')
          .eq('id_paiement', idPaiement)
          .single();

      return response;
    } catch (e) {
      print("Erreur getPaymentDetails: $e");
      return null;
    }
  }
}
