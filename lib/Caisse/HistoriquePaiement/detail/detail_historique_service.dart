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
            paiement!inner(*)
          ''')
          .eq('id_consultation', idConsultation)
          .single();

      return response;
    } catch (e) {
      print("Erreur getPatientPaymentDetails: $e");
      return null;
    }
  }
}
