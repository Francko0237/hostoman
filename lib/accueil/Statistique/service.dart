import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/model_unifier.dart';
import 'package:hostoman/shared/user_profile_helper.dart';

class RapportPatientService {
  final SupabaseClient supabase;
  RapportPatientService(this.supabase);

  // --- Fonction : récupérer et regrouper les patients par catégorie ---
  Future<Map<String, List<Patient>>> fetchGroupedPatients(
    DateTime start,
    DateTime end,
  ) async {
    // On ajoute 1 jour à la fin pour inclure toute la journée sélectionnée
    final endPlusOne = end.add(const Duration(days: 1));
    final hid = await UserProfileHelper.getHospitalId();

    var query = supabase
        .from('Consultation')
        .select('''
        id_consultation, type_service, date_enregistrement,
        Patient!inner(id_patient, nom_complet, age,sexe, telephone, date_enregistrement)
      ''')
        .gte('date_enregistrement', start.toIso8601String())
        .lt(
          'date_enregistrement',
          endPlusOne.toIso8601String(),
        );

    if (hid != null) {
      query = query.eq('id_hopital', hid);
    }

    final data = await query;

    print(data); // debug

    // 2) Préparation des seaux (catégories)
    final Map<String, Map<String, Patient>> groupes = {
      'Consultation de 0 à 5 ans': {},
      'Consultation plus de 5 ans': {},
      'Rendez-vous': {},
      'CPN': {},
    };

    // 3) Parcours des lignes retournées
    for (final ligne in data) {
      // Sécuriser l'accès au patient pour éviter les erreurs "null"
      final patientMap = ligne['Patient'] as Map<String, dynamic>? ?? {};
      if (patientMap.isEmpty) continue; // si pas de patient, on ignore

      final patient = Patient.fromMap(patientMap);

      // Type du service (consultation, rendez-vous, CPN...)
      final typeService = (ligne['type_service'] ?? '')
          .toString()
          .toLowerCase();

      // Déterminer dans quel groupe classer ce patient
      String? groupe;

      if (typeService.contains('cpn') || typeService.contains('prénatale')) {
        groupe = 'CPN';
      } else if (typeService.contains('rendez')) {
        groupe = 'Rendez-vous';
      } else if (typeService.contains('consultation')) {
        if (patient.age <= 5) {
          groupe = 'Consultation de 0 à 5 ans';
        } else {
          groupe = 'Consultation plus de 5 ans';
        }
      }

      // Si on a trouvé une catégorie valide → on stocke le patient
      if (groupe != null) {
        // On utilise `id_patient` comme clé pour éviter les doublons
        groupes[groupe]![patient.id_patient!] = patient;
      }
    }

    // 4) Trier les patients par date d'inscription (récent d’abord)
    return groupes.map((nomGroupe, mapPatients) {
      final patients = mapPatients.values.toList()
        ..sort(
          (a, b) => b.date_enregistrement.compareTo(a.date_enregistrement),
        );
      return MapEntry(nomGroupe, patients);
    });
  }
}
