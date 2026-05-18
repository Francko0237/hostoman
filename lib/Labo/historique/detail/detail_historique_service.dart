import 'package:supabase_flutter/supabase_flutter.dart';

class DetailHistoriqueLaboService {
  final SupabaseClient supabase;

  DetailHistoriqueLaboService(this.supabase);

  /// 🔍 Récupère les détails d'une consultation avec tous les examens terminés
  Future<Map<String, dynamic>?> getDetailsConsultation(
    int idConsultation,
  ) async {
    try {
      final response = await supabase
          .from('Consultation')
          .select('''
            *,
            Patient(*),
            examen_a_effectuer(*)
          ''')
          .eq('id_consultation', idConsultation)
          .single();

      return response;
    } catch (e) {
      print("Erreur getDetailsConsultation: $e");
      return null;
    }
  }
}
