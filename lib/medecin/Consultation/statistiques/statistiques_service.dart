import 'package:supabase_flutter/supabase_flutter.dart';

class StatistiquesService {
  final SupabaseClient supabase;

  StatistiquesService(this.supabase);

  /// 📊 Compte les consultations terminées dans une période
  Future<int> getConsultationsTerminees(DateTime debut, DateTime fin) async {
    final response = await supabase
        .from('Consultation')
        .select('id_consultation')
        .eq('Statut_Consultation', 'terminer')
        .gte('date_derniere_mise_ajour', debut.toIso8601String())
        .lte('date_derniere_mise_ajour', fin.toIso8601String());

    return (response as List).length;
  }

  /// ❌ Compte les consultations annulées dans une période
  Future<int> getConsultationsAnnulees(DateTime debut, DateTime fin) async {
    final response = await supabase
        .from('Consultation')
        .select('id_consultation')
        .eq('Statut_Consultation', 'annuler')
        .gte('date_derniere_mise_ajour', debut.toIso8601String())
        .lte('date_derniere_mise_ajour', fin.toIso8601String());

    return (response as List).length;
  }

  /// 📅 Compte les rendez-vous terminés (consultations avec RDV programmé qui sont terminées)
  Future<int> getRendezVousTermines(DateTime debut, DateTime fin) async {
    final response = await supabase
        .from('Consultation')
        .select('id_consultation')
        .eq('Statut_Consultation', 'terminer')
        .eq('programmation_rdv', 'programmer')
        .gte('date_derniere_mise_ajour', debut.toIso8601String())
        .lte('date_derniere_mise_ajour', fin.toIso8601String());

    return (response as List).length;
  }

  /// 📋 Récupère la liste des patients pour un statut donné (ou tous si statut est nul ou 'tous')
  Future<List<Map<String, dynamic>>> getPatientsParStatut(
    String? statut,
    DateTime debut,
    DateTime fin,
  ) async {
    var query = supabase
        .from('Consultation')
        .select('''
          id_consultation,
          date_derniere_mise_ajour,
          Patient(
            id_patient,
            nom_complet,
            sexe,
            age
          )
        ''')
        .gte('date_derniere_mise_ajour', debut.toIso8601String())
        .lte('date_derniere_mise_ajour', fin.toIso8601String());

    if (statut != null && statut != 'tous') {
      query = query.eq('Statut_Consultation', statut);
    }

    final response = await query.order('date_derniere_mise_ajour', ascending: false);

    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// 📅 Récupère la liste des patients avec RDV terminés
  Future<List<Map<String, dynamic>>> getPatientsRdvTermines(
    DateTime debut,
    DateTime fin,
  ) async {
    final response = await supabase
        .from('Consultation')
        .select('''
          id_consultation,
          date_derniere_mise_ajour,
          date_rdv_prevu,
          Patient(
            id_patient,
            nom_complet,
            sexe,
            age
          )
        ''')
        .eq('Statut_Consultation', 'terminer')
        .eq('programmation_rdv', 'programmer')
        .gte('date_derniere_mise_ajour', debut.toIso8601String())
        .lte('date_derniere_mise_ajour', fin.toIso8601String())
        .order('date_derniere_mise_ajour', ascending: false);

    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }
}
