import 'package:supabase_flutter/supabase_flutter.dart';

class StatistiqueLaboService {
  final SupabaseClient supabase;

  StatistiqueLaboService(this.supabase);

  /// Récupère les statistiques des examens par statut
  Future<Map<String, int>> getStatistiques(DateTime debut, DateTime fin) async {
    try {
      // Créer des timestamps pour le début et la fin de la journée
      final debutTimestamp = DateTime(
        debut.year,
        debut.month,
        debut.day,
        0,
        0,
        0,
      );
      final finTimestamp = DateTime(fin.year, fin.month, fin.day, 23, 59, 59);

      print(
        '🔍 Période: ${debutTimestamp.toIso8601String()} → ${finTimestamp.toIso8601String()}',
      );

      // Compter les examens terminés directement
      final terminesData = await supabase
          .from('examen_a_effectuer')
          .select('id_examen')
          .eq('statut_examen', 'Terminé')
          .gte('date_enregistrement', debutTimestamp.toIso8601String())
          .lte('date_enregistrement', finTimestamp.toIso8601String());

      print('✅ Terminés brut: ${terminesData.length} résultats');
      print('📊 Données terminés: $terminesData');

      // Compter les examens annulés directement
      final annulesData = await supabase
          .from('examen_a_effectuer')
          .select('id_examen')
          .eq('statut_examen', 'Annulé')
          .gte('date_enregistrement', debutTimestamp.toIso8601String())
          .lte('date_enregistrement', finTimestamp.toIso8601String());

      print('❌ Annulés brut: ${annulesData.length} résultats');
      print('📊 Données annulés: $annulesData');

      return {
        'termines': (terminesData as List).length,
        'annules': (annulesData as List).length,
      };
    } catch (e) {
      print('❌ Erreur getStatistiques: $e');
      return {'termines': 0, 'annules': 0};
    }
  }

  /// Récupère la liste des patients avec leurs examens (Terminé ou Annulé)
  Future<List<Map<String, dynamic>>> getPatientsAvecExamens(
    DateTime debut,
    DateTime fin, {
    String? statutFiltre, // 'Terminé', 'Annulé', ou null pour tous
  }) async {
    try {
      // Formater les dates au format YYYY-MM-DD
      final debutStr =
          '${debut.year}-${debut.month.toString().padLeft(2, '0')}-${debut.day.toString().padLeft(2, '0')}';
      final finStr =
          '${fin.year}-${fin.month.toString().padLeft(2, '0')}-${fin.day.toString().padLeft(2, '0')}';

      // Requête pour récupérer les consultations avec examens terminés ou annulés
      var query = supabase
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
              statut_examen
            )
          ''')
          .gte('date_enregistrement', debutStr)
          .lte('date_enregistrement', finStr);

      final response = await query;

      // Grouper par consultation et compter les examens
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

        // Ajouter les examens
        final examens = item['examen_a_effectuer'];
        if (examens is List) {
          for (var examen in examens) {
            if (examen is Map<String, dynamic>) {
              // Filtrer par statut si spécifié
              if (statutFiltre == null ||
                  examen['statut_examen'] == statutFiltre) {
                consultationsMap[idConsultation]!['examens'].add(examen);
              }
            }
          }
        }
      }

      // Convertir en liste et calculer le nombre d'examens
      final result = consultationsMap.values
          .map((consultation) {
            final examens = consultation['examens'] as List;
            consultation['nombre_examens'] = examens.length;
            return consultation;
          })
          .where((c) => c['nombre_examens'] > 0)
          .toList();

      // Trier par date décroissante
      result.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['date_enregistrement'] ?? '') ?? DateTime(2000);
        final dateB =
            DateTime.tryParse(b['date_enregistrement'] ?? '') ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

      return result;
    } catch (e) {
      print('❌ Erreur getPatientsAvecExamens: $e');
      return [];
    }
  }
}
