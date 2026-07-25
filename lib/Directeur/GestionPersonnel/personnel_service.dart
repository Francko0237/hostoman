import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:hostoman/app_config.dart';

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
      return [];
    }
  }

  /// ➕ Ajoute un nouveau membre du personnel (sans créer de compte Auth)
  /// Le compte Auth sera créé à la première connexion de l'utilisateur.
  Future<String?> addPersonnel(Map<String, dynamic> data) async {
    try {
      await supabase.from('Personnel_hopital').insert({
        'Nom': data['Nom'],
        'Prenom': data['Prenom'],
        'telephone': data['telephone'],
        'adresse': data['adresse'],
        'Specialite': data['Specialite'],
        'sexe': data['sexe'],
        'age': data['age'],
        'compte_actif': false,
        'date_enregistrement': DateTime.now().toIso8601String(),
      });
      return null; // ✅ Succès
    } on PostgrestException catch (e) {
      return 'Erreur création fiche: ${e.message}';
    } catch (e) {
      return 'Erreur inattendue: $e';
    }
  }

  /// ✏️ Modifie un membre du personnel
  Future<String?> updatePersonnel(String id, Map<String, dynamic> data) async {
    try {
      final rows = await supabase
          .from('Personnel_hopital')
          .update(data)
          .eq('id_personnel', id)
          .select();

      if (rows.isEmpty) {
        return 'Aucune modification effectuée. Vérifiez vos droits (RLS) '
            'ou rechargez la liste avant de réessayer.';
      }
      return null;
    } on PostgrestException catch (e) {
      return 'Erreur modification: ${e.message}';
    } catch (e) {
      return 'Erreur inattendue: $e';
    }
  }

  /// 🔒 Active ou désactive un compte (compte_actif)
  Future<String?> toggleCompteActif(String id, bool actif) async {
    try {
      await supabase
          .from('Personnel_hopital')
          .update({'compte_actif': actif})
          .eq('id_personnel', id);
      return null;
    } catch (e) {
      return 'Erreur: $e';
    }
  }

  /// ❌ Supprime un membre du personnel ET son compte Auth si existant
  Future<String?> deletePersonnel(String id) async {
    // Récupérer auth_id pour supprimer le compte Auth si activé
    try {
      final fiche = await supabase
          .from('Personnel_hopital')
          .select('auth_id')
          .eq('id_personnel', id)
          .maybeSingle();

      final authId = fiche?['auth_id']?.toString();
      if (authId != null) {
        // Tenter de supprimer le compte Auth via Admin API (best effort)
        try {
          await http
              .delete(
                Uri.parse(AppConfig.adminDeleteUserUrl(authId)),
                headers: AppConfig.adminHeaders,
              )
              .timeout(AppConfig.adminApiTimeout);
        } catch (_) {
          // Pas bloquant — on continue avec la suppression de la fiche
        }
      }
    } catch (_) {}

    try {
      await supabase.from('Personnel_hopital').delete().eq('id_personnel', id);
      return null;
    } catch (e) {
      return 'Erreur suppression: $e';
    }
  }
}
