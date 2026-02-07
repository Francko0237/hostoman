import 'package:supabase_flutter/supabase_flutter.dart';

class ConsultationService {
  final SupabaseClient supabase;

  ConsultationService(this.supabase);

  /// 📋 Récupère les patients en attente de examen (qui ont payé)
  Future<List<Map<String, dynamic>>> getPatientsEnAttente() async {
    final response = await supabase
        .from('Consultation')
        .select('id_consultation, type_service, id_patient, date_enregistrement,Statut_Consultation, Patient(*)')
        .or('payer.eq.non,payer.eq.oui')
        .eq('type_service', 'Consultation')
        .or('Statut_Consultation.eq.en-attente-examen,Statut_Consultation.eq.examen-effectue')
        .order('date_enregistrement', ascending: true);

// structure standard pour ret  ourné les données de la BD récupérer
    return (response as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
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