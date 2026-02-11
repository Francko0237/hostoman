import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardLaboService {
  final SupabaseClient supabase;

  DashboardLaboService(this.supabase);

  /// Récupère les statistiques du dashboard pour aujourd'hui
  Future<Map<String, int>> getStatistiquesJour() async {
    try {
      final aujourdhui = DateTime.now();
      final debutJour = DateTime(
        aujourdhui.year,
        aujourdhui.month,
        aujourdhui.day,
        0,
        0,
        0,
      );
      final finJour = DateTime(
        aujourdhui.year,
        aujourdhui.month,
        aujourdhui.day,
        23,
        59,
        59,
      );

      print(
        '🔍 Dashboard - Période: ${debutJour.toIso8601String()} → ${finJour.toIso8601String()}',
      );

      // Compter les patients distincts dans "examen_a_effectuer" (Examen à faire)
      final examensAFaire = await supabase
          .from('Consultation')
          .select('''
            *,
            Patient(*),
            paiement!inner(*),
            examen_a_effectuer!inner(id_examen)
          ''')
          .eq('Statut_Consultation', 'en-attente-examen')
          .eq('paiement.statut_paiement', 'payer') // Filtre sur la table jointe
          // On ne veut que les consultations qui ont au moins un examen "en attente"
          .neq('examen_a_effectuer.statut_examen', 'En cours')
          .neq('examen_a_effectuer.statut_examen', 'Terminé')
          .neq('examen_a_effectuer.statut_examen', 'Annulé')
          .gte('date_enregistrement', debutJour.toIso8601String())
          .lte('date_enregistrement', finJour.toIso8601String())
          .order('date_enregistrement', ascending: true);

      final patientsExamensAFaire = (examensAFaire as List)
          .map((e) => e['id_patient'])
          .toSet()
          .length;

      // Compter les patients distincts dans "resultat_examen" (Résultats)
      final resultatsExamen = await supabase
          .from('Consultation')
          .select('''
            *,
            Patient(*),
            examen_a_effectuer!inner(id_examen)
        ''')
          .eq('Statut_Consultation', 'en-attente-resultat')
          // On s'assure qu'il reste au moins un examen "En cours" (donc sans résultat)
          .eq('examen_a_effectuer.statut_examen', 'En cours')
          .gte('date_enregistrement', debutJour.toIso8601String())
          .lte('date_enregistrement', finJour.toIso8601String())
          .order('date_enregistrement', ascending: true);

      final patientsResultats = (resultatsExamen as List)
          .map((e) => e['id_patient'])
          .toSet()
          .length;

      print('📊 Patients examens à faire: $patientsExamensAFaire');
      print('📊 Patients résultats: $patientsResultats');

      return {
        'en_attente_examen': patientsExamensAFaire,
        'en_attente_resultat': patientsResultats,
      };
    } catch (e) {
      print('❌ Erreur getStatistiquesJour: $e');
      return {'en_attente_examen': 0, 'en_attente_resultat': 0};
    }
  }

  /// Récupère la liste des patients en attente de résultats aujourd'hui
  Future<List<Map<String, dynamic>>> getPatientsEnAttenteResultat() async {
    try {
      final aujourdhui = DateTime.now();
      final debutJour = DateTime(
        aujourdhui.year,
        aujourdhui.month,
        aujourdhui.day,
        0,
        0,
        0,
      );
      final finJour = DateTime(
        aujourdhui.year,
        aujourdhui.month,
        aujourdhui.day,
        23,
        59,
        59,
      );

      // Récupérer les consultations avec examens "En cours" (en attente de résultat)
      final data = await supabase
          .from('Consultation')
          .select('''
            id_consultation,
            id_patient,
            date_enregistrement,
            Patient!inner(
              id_patient,
              nom_complet,
              sexe,
              date_de_naissance,
              numero_de_telephone,
              adresse,
              groupe_sanguin
            ),
            examen_a_effectuer!inner(
              id_examen,
              nom_examen,
              statut_examen
            )
          ''')
          .eq('examen_a_effectuer.statut_examen', 'En cours')
          .gte('date_enregistrement', debutJour.toIso8601String())
          .lte('date_enregistrement', finJour.toIso8601String());

      print(
        '📋 Patients en attente résultat: ${(data as List).length} consultations',
      );

      // Grouper par patient pour éviter les doublons
      final Map<int, Map<String, dynamic>> patientsMap = {};

      for (var item in data) {
        final idPatient = item['id_patient'] as int;

        if (!patientsMap.containsKey(idPatient)) {
          // Compter les examens en cours pour ce patient
          final examens = item['examen_a_effectuer'] as List;
          final examensEnCours = examens
              .where((e) => e['statut_examen'] == 'En cours')
              .toList();

          // Créer la liste des noms d'examens
          final nomsExamens = examensEnCours
              .map((e) => e['nom_examen'] as String)
              .take(3)
              .join(', ');

          final plusExamens = examensEnCours.length > 3 ? '...' : '';

          patientsMap[idPatient] = {
            'Patient': item['Patient'],
            'id_patient': idPatient,
            'id_consultation': item['id_consultation'],
            'date_enregistrement': item['date_enregistrement'],
            'examens_details': '$nomsExamens$plusExamens',
            'nombre_examens': examensEnCours.length,
          };
        }
      }

      return patientsMap.values.toList();
    } catch (e) {
      print('❌ Erreur getPatientsEnAttenteResultat: $e');
      return [];
    }
  }
}
