import 'package:supabase_flutter/supabase_flutter.dart';

class HistoriqueLaboService {
  final SupabaseClient supabase;

  HistoriqueLaboService(this.supabase);

  /// 📋 Récupère la liste des patients uniques ayant des examens terminés
  /// Retourne un patient une seule fois, avec le total de ses sessions.
  Future<List<Map<String, dynamic>>> getPatientsUniques() async {
    final response = await supabase
        .from('Consultation')
        .select('''
          id_consultation,
          id_patient,
          date_enregistrement,
          Patient(id_patient, nom_complet, sexe, age, telephone),
          examen_a_effectuer!inner(statut_examen)
        ''')
        .eq('examen_a_effectuer.statut_examen', 'Terminé')
        .order('date_enregistrement', ascending: false);

    // Grouper par id_patient : garder uniquement la consultation la plus récente
    // et compter le nombre de sessions distinctes
    final Map<dynamic, Map<String, dynamic>> patientMap = {};
    for (var item in response as List<dynamic>) {
      final map = item as Map<String, dynamic>;
      final idPatient = map['id_patient'];
      if (!patientMap.containsKey(idPatient)) {
        patientMap[idPatient] = {
          ...map,
          'nombre_sessions': 1,
        };
      } else {
        patientMap[idPatient]!['nombre_sessions'] =
            (patientMap[idPatient]!['nombre_sessions'] as int) + 1;
      }
    }

    return patientMap.values.toList();
  }

  /// 📅 Récupère les sessions (consultations avec examens terminés) d'un patient
  /// groupées par date (jour), pour afficher les "dates" de passage.
  Future<List<Map<String, dynamic>>> getSessionsParPatient(
    String idPatient,
  ) async {
    final response = await supabase
        .from('Consultation')
        .select('''
          id_consultation,
          date_enregistrement,
          examen_a_effectuer!inner(statut_examen)
        ''')
        .eq('id_patient', idPatient)
        .eq('examen_a_effectuer.statut_examen', 'Terminé')
        .order('date_enregistrement', ascending: false);

    // Dédoublonner par id_consultation
    final Map<int, Map<String, dynamic>> uniqueConsultations = {};
    for (var item in response as List<dynamic>) {
      final map = item as Map<String, dynamic>;
      final id = map['id_consultation'] as int;
      uniqueConsultations[id] = map;
    }

    // Grouper par date (jour uniquement)
    final Map<String, Map<String, dynamic>> groupedByDate = {};
    for (var consultation in uniqueConsultations.values) {
      final rawDate = consultation['date_enregistrement'] as String;
      final dt = DateTime.parse(rawDate);
      // Clé = YYYY-MM-DD pour grouper par jour
      final dayKey =
          '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

      if (!groupedByDate.containsKey(dayKey)) {
        groupedByDate[dayKey] = {
          'day_key': dayKey,
          'date': rawDate,
          'consultations': <Map<String, dynamic>>[consultation],
        };
      } else {
        (groupedByDate[dayKey]!['consultations'] as List<Map<String, dynamic>>)
            .add(consultation);
      }
    }

    // Trier les groupes du plus récent au plus ancien
    final sorted = groupedByDate.values.toList()
      ..sort((a, b) => b['day_key'].compareTo(a['day_key']));

    return sorted;
  }
}
