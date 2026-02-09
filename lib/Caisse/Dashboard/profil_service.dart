import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/model_unifier.dart';

class MedecinService {
  final SupabaseClient client;

  MedecinService(this.client);

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
      print(response);
      return Medecin.fromMap(response);
    } catch (e) {
      print('❌ Erreur lors de la récupération du médecin : $e');
      return null;
    }
  }

  Future<int> countPatientsEnregistres() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      // Compter tous les paiements validés (statut = 'payer')
      final response = await client
          .from('paiement')
          .select('id_paiement')
          .eq('statut_paiement', 'payer');

      final nbrPaiements = response.length;
      print("Le nombre de paiements enregistrés est de $nbrPaiements");
      return nbrPaiements;
    } catch (e) {
      print('❌ Erreur lors du comptage des paiements : $e');
      return 0;
    }
  }
}
