import 'package:supabase_flutter/supabase_flutter.dart';

class PatientDuJourService {
  final SupabaseClient client;

  PatientDuJourService(this.client);

  Future<int> countPatientsDuJour() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await client
          .from('Parametres_vitaux')
          .select('id_parametres_vitaux')
          .eq('id_utilisateur', user.id)
          .gte('date_enregistrement', startOfDay.toIso8601String())
          .lt('date_enregistrement', endOfDay.toIso8601String());

      return response.length;
    } catch (e) {
      print('❌ Erreur lors du comptage des patients du jour : $e');
      return 0;
    }
  }
}
