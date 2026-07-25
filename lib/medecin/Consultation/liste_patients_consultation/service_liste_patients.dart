import 'package:supabase_flutter/supabase_flutter.dart';

class ConsultationService {
  final SupabaseClient supabase;

  ConsultationService(this.supabase);

  /// 📋 Récupère les patients en attente de consultation (qui ont payé)
  /// Filtre uniquement les patients assignés au médecin connecté
  Future<List<Map<String, dynamic>>> getPatientsEnAttente() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await supabase
        .from('Consultation')
        .select(
          '''id_consultation, type_service, id_patient, date_enregistrement, Patient(*),paiement!inner(*)''',
        )
        .eq('type_service', 'Consultation')
        .eq('paiement.statut_paiement', 'payer')
        .eq('Statut_Consultation', 'en-attente-consultation')
        .eq('id_personnel', userId)
        .order('date_enregistrement', ascending: true);
    // structure standard pour ret  ourné les données de la BD récupérer
    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
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
