import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/model_unifier.dart';

class MedecinService {
  final SupabaseClient client;

  MedecinService(this.client);

  Future<Medecin?> fetchMedecinConnecte() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Aucun utilisateur connecté');

      // Chercher par auth_id (nouveaux comptes) ou id_personnel (anciens comptes)
      Map<String, dynamic>? response = await client
          .from('utilisateur')
          .select()
          .eq('auth_id', user.id)
          .maybeSingle();

      response ??= await client
          .from('utilisateur')
          .select()
          .eq('id_utilisateur', user.id)
          .maybeSingle();

      if (response == null) return null;
      return Medecin.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  Future<int> countPatientsEnregistres() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      final response = await client
          .from('Parametres_vitaux')
          .select('id_parametres_vitaux')
          .eq('id_utilisateur', user.id);

      return response.length;
    } catch (e) {
      print('❌ Erreur lors du comptage des patients : $e');
      return 0;
    }
  }
}
