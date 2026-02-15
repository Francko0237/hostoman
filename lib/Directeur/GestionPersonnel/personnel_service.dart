import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/model_unifier.dart';

class PersonnelService {
  final SupabaseClient supabase;

  PersonnelService(this.supabase);

  /// 📋 Récupère tout le personnel
  Future<List<Map<String, dynamic>>> getAllPersonnel() async {
    try {
      final response = await supabase
          .from('Personnel_hopital')
          .select()
          .order('Nom', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur getPersonnel: $e');
      return [];
    }
  }

  /// ➕ Ajoute un nouveau membre du personnel
  /// Note: Cette méthode crée l'utilisateur Auth ET l'entrée dans la base de données
  Future<String?> addPersonnel(
    Map<String, dynamic> data,
    String password,
  ) async {
    try {
      // 1. Créer l'utilisateur Auth
      final authResponse = await supabase.auth.signUp(
        email: data['email'],
        password: password,
      );

      if (authResponse.user == null) {
        return 'Erreur lors de la création du compte utilisateur.';
      }

      final userId = authResponse.user!.id;

      // 2. Ajouter l'entrée dans la table Personnel_hopital
      // Note: Le trigger Supabase peut gérer cela automatiquement si configuré,
      // sinon on fait l'insertion manuelle ici.
      await supabase.from('Personnel_hopital').insert({
        'id_personnel': userId,
        'Nom': data['Nom'],
        'Prenom': data['Prenom'],
        'telephone': data['telephone'],
        'adresse': data['adresse'],
        'email': data['email'],
        'Specialite':
            data['Specialite'], // Rôle: Médecin Généraliste, Caissier, etc.
        'sexe': data['sexe'],
        'age': data['age'],
      });

      return null; // Succès
    } on AuthException catch (e) {
      if (e.message.contains("Error sending confirmation email")) {
        return "Erreur lors de l'envoi de l'email de confirmation. Veuillez vérifier la configuration SMTP de votre projet Supabase ou désactiver la confirmation par email."; // Message convivial
      }
      return 'Erreur Auth: ${e.message}';
    } catch (e) {
      print('Erreur addPersonnel: $e');
      return 'Erreur: $e';
    }
  }

  /// ✏️ Modifie un membre du personnel
  Future<String?> updatePersonnel(String id, Map<String, dynamic> data) async {
    try {
      await supabase
          .from('Personnel_hopital')
          .update(data)
          .eq('id_personnel', id);
      return null;
    } catch (e) {
      return 'Erreur modification: $e';
    }
  }

  /// ❌ Supprime un membre du personnel
  /// Attention: Cela devrait idéalement aussi supprimer le compte Auth (nécessite Admin API ou Edge Function)
  /// Pour l'instant, on se contente de supprimer de la table DB (ou soft delete si préféré)
  Future<String?> deletePersonnel(String id) async {
    try {
      await supabase.from('Personnel_hopital').delete().eq('id_personnel', id);
      return null;
    } catch (e) {
      return 'Erreur suppression: $e';
    }
  }
}
