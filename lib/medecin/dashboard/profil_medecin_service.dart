import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/model_unifier.dart';

class ProfilMedecinService {
  final SupabaseClient client;

  ProfilMedecinService(this.client);

  /// 👨‍⚕️ Récupère les infos du médecin connecté
  Future<Medecin?> fetchMedecinConnecte() async {
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

      return Medecin.fromMap(response);
    } catch (e) {
      print('❌ Erreur lors de la récupération du médecin : $e');
      return null;
    }
  }

  /// 📈 Compte le nombre de consultations terminées par ce médecin
  Future<int> countConsultationsTerminees() async {
    try {
      final response = await client
          .from('Consultation')
          .select('id_consultation')
          .eq('Statut_Consultation', 'terminer')
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      print('❌ Erreur lors du comptage des consultations terminées : $e');
      return 0;
    }
  }
}
