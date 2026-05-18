import 'package:supabase_flutter/supabase_flutter.dart';

class HistoriqueConsultationService {
  final SupabaseClient supabase;

  HistoriqueConsultationService(this.supabase);

  /// 📋 Récupère toutes les consultations terminées
  Future<List<Map<String, dynamic>>> getConsultationsTerminees() async {
    final response = await supabase
        .from('Consultation')
        .select('''
          *,
          Patient(*)
        ''')
        .eq('Statut_Consultation', 'terminer')
        .order('date_derniere_mise_ajour', ascending: false);

    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// 🔍 Récupère les détails d'une consultation terminée
  Future<Map<String, dynamic>?> getConsultationDetail(
    int idConsultation,
  ) async {
    final response = await supabase
        .from('Consultation')
        .select('''
          *,
          Patient(*),
          Parametres_vitaux(*)
        ''')
        .eq('id_consultation', idConsultation)
        .eq('Statut_Consultation', 'terminer')
        .single();

    return response as Map<String, dynamic>?;
  }

  /// 🔬 Récupère les examens d'une consultation
  Future<List<Map<String, dynamic>>> getExamensConsultation(
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
}
