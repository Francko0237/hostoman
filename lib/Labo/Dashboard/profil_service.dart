import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/model_unifier.dart';

class LaborantinService {
  final SupabaseClient client;

  LaborantinService(this.client);

  Future<Medecin?> fetchLaborantinConnecte() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      final response = await client
          .from('Personnel_hopital')
          .select()
          .eq('id_personnel', user.id)
          .single();

      print('📋 Laborantin: $response');
      return Medecin.fromMap(response);
    } catch (e) {
      print('❌ Erreur lors de la récupération du laborantin : $e');
      return null;
    }
  }

  /// Compte le nombre total d'examens effectués par le laborantin

  /// Compte le nombre total d'examens en cours (toutes dates confondues)
  Future<int> countExamensEnCoursTotal() async {
    try {
      final response = await client
          .from('examen_a_effectuer')
          .select('id_examen')
          .eq('statut_examen', 'Terminé');

      return response.length;
    } catch (e) {
      print('❌ Erreur lors du comptage des examens en cours : $e');
      return 0;
    }
  }
}
