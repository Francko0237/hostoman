import 'package:supabase_flutter/supabase_flutter.dart';

class HistoriqueConsultationService {
  final SupabaseClient supabase;

  HistoriqueConsultationService(this.supabase);

  /// 📋 Récupère toutes les consultations terminées du médecin connecté
  Future<List<Map<String, dynamic>>> getConsultationsTerminees() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await supabase
        .from('Consultation')
        .select('''
          *,
          Patient(*)
        ''')
        .eq('Statut_Consultation', 'terminer')
        .eq('id_personnel', userId)
        .order('date_derniere_mise_ajour', ascending: false);

    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// 🔍 Récupère les détails d'une consultation (tous statuts)
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

  /// 📅 Récupère l'historique des consultations d'un patient (tous statuts).
  /// [excludeIdConsultation] permet d'exclure la consultation en cours.
  Future<List<Map<String, dynamic>>> getHistoriqueParPatient(
    String idPatient, {
    int? excludeIdConsultation,
  }) async {
    final response = await supabase
        .from('Consultation')
        .select('''
          id_consultation,
          date_derniere_mise_ajour,
          Statut_Consultation,
          antecedents,
          signes_symptomes,
          diagnostic_initial,
          diagnostic_final,
          traitement_prescrit,
          champs_supplementaires,
          Parametres_vitaux(motif_de_consultation)
        ''')
        .eq('id_patient', idPatient)
        .order('date_derniere_mise_ajour', ascending: false);

    var results = (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    if (excludeIdConsultation != null) {
      results = results
          .where((c) => c['id_consultation'] != excludeIdConsultation)
          .toList();
    }
    return results;
  }

  /// 💊 Récupère les lignes de prescription (médicaments) d'une consultation
  Future<List<Map<String, dynamic>>> getMedicamentsConsultation(
    int idConsultation,
  ) async {
    final List<dynamic> prescription = await supabase
        .from('prescription')
        .select('id_prescription')
        .eq('id_consultation', idConsultation);

    if (prescription.isEmpty) return [];

    final idPrescription = prescription.first['id_prescription'] as int;

    final response = await supabase
        .from('prescription_ligne')
        .select('*')
        .eq('id_prescription', idPrescription)
        .order('id_ligne', ascending: true);

    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }
}
