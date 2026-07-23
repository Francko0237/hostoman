import 'package:supabase_flutter/supabase_flutter.dart';

class StatistiqueLaboService {
  final SupabaseClient supabase;

  StatistiqueLaboService(this.supabase);

  /// Récupère les statistiques des examens par statut (tous statuts)
  Future<Map<String, int>> getStatistiques(DateTime debut, DateTime fin) async {
    try {
      final debutTimestamp = DateTime(debut.year, debut.month, debut.day, 0, 0, 0);
      final finTimestamp = DateTime(fin.year, fin.month, fin.day, 23, 59, 59);

      final allData = await supabase
          .from('examen_a_effectuer')
          .select('id_consultation, statut_examen')
          .gte('date_enregistrement', debutTimestamp.toIso8601String())
          .lte('date_enregistrement', finTimestamp.toIso8601String());

      int nbTermines = 0;
      int nbAnnules = 0;

      for (var row in allData as List) {
        final statut = row['statut_examen']?.toString() ?? '';
        if (statut == 'Terminé') {
          nbTermines++;
        } else if (statut == 'Annulé' || statut.toLowerCase().contains('annul')) {
          nbAnnules++;
        }
      }

      return {
        'termines': nbTermines,
        'annules': nbAnnules,
      };
    } catch (e) {
      print('❌ Erreur getStatistiques: $e');
      return {'termines': 0, 'annules': 0, 'en_cours': 0};
    }
  }

  /// Récupère la liste des patients avec leurs examens (Terminé ou Annulé)
  Future<List<Map<String, dynamic>>> getPatientsAvecExamens(
    DateTime debut,
    DateTime fin, {
    String? statutFiltre, // 'Terminé', 'Annulé', ou null pour tous
  }) async {
    try {
      final debutTimestamp = DateTime(debut.year, debut.month, debut.day, 0, 0, 0);
      final finTimestamp = DateTime(fin.year, fin.month, fin.day, 23, 59, 59);

      final response = await supabase
          .from('Consultation')
          .select('''
            id_consultation,
            id_patient,
            date_enregistrement,
            Patient!inner(
              id_patient,
              nom_complet,
              sexe,
              age,
              telephone
            ),
            examen_a_effectuer!inner(
              id_examen,
              nom_examen,
              statut_examen,
              date_enregistrement
            )
          ''')
          .gte(
            'examen_a_effectuer.date_enregistrement',
            debutTimestamp.toIso8601String(),
          )
          .lte(
            'examen_a_effectuer.date_enregistrement',
            finTimestamp.toIso8601String(),
          );

      // Grouper par consultation
      final Map<int, Map<String, dynamic>> consultationsMap = {};

      for (var item in response) {
        final idConsultation = item['id_consultation'] as int;

        if (!consultationsMap.containsKey(idConsultation)) {
          consultationsMap[idConsultation] = {
            'id_consultation': idConsultation,
            'id_patient': item['id_patient'],
            'date_enregistrement': item['date_enregistrement'],
            'Patient': item['Patient'],
            'examens': <Map<String, dynamic>>[],
          };
        }

        final examens = item['examen_a_effectuer'];
        if (examens is List) {
          for (var examen in examens) {
            if (examen is Map<String, dynamic>) {
              final dateExamenStr = examen['date_enregistrement'];
              if (dateExamenStr == null) continue;
              final dateExamen = DateTime.tryParse(dateExamenStr);
              if (dateExamen == null) continue;
              if (dateExamen.isBefore(debutTimestamp) ||
                  dateExamen.isAfter(finTimestamp)) continue;

              final statut = examen['statut_examen'];
              bool matchStatut = false;
              if (statutFiltre != null) {
                matchStatut = (statut == statutFiltre);
              } else {
                matchStatut = (statut == 'Terminé' || statut == 'Annulé');
              }

              if (matchStatut) {
                consultationsMap[idConsultation]!['examens'].add(examen);
              }
            }
          }
        }
      }

      final result = consultationsMap.values.map((consultation) {
        final examens = consultation['examens'] as List;
        consultation['nombre_examens'] = examens.length;
        return consultation;
      }).where((c) => c['nombre_examens'] > 0).toList();

      result.sort((a, b) {
        final dateA = DateTime.tryParse(a['date_enregistrement'] ?? '') ?? DateTime(2000);
        final dateB = DateTime.tryParse(b['date_enregistrement'] ?? '') ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

      return result;
    } catch (e) {
      print('❌ Erreur getPatientsAvecExamens: $e');
      return [];
    }
  }
}
