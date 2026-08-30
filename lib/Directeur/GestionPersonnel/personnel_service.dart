import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:hostoman/app_config.dart';

import 'package:hostoman/shared/user_profile_helper.dart';
import 'package:hostoman/SuperAdmin/superadmin_service.dart';

class PersonnelService {
  final SupabaseClient supabase;

  PersonnelService(this.supabase);

  /// 📋 Récupère tout le personnel de cet hôpital
  Future<List<Map<String, dynamic>>> getAllPersonnel() async {
    try {
      final hid = await UserProfileHelper.getHospitalId();
      var query = supabase.from('utilisateur').select();
      if (hid != null) {
        query = query.eq('id_hopital', hid);
      }
      final response = await query.order('Nom', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// ➕ Ajoute un nouveau membre du personnel (rattaché à cet hôpital)
  /// Retourne un Map avec 'error' (null si succès) et 'generatedId' (ex: HDM-48291)
  Future<Map<String, dynamic>> addPersonnel(Map<String, dynamic> data) async {
    try {
      final hid = await UserProfileHelper.getHospitalId();
      String prefix = 'AG'; // Prefixe par défaut

      if (hid != null) {
        // Récupérer le nom ou le code de l'hôpital pour extraire l'abréviation
        final hopitalRes = await supabase
            .from('hopital')
            .select('nom_hopital, code_hopital')
            .eq('id_hopital', hid)
            .maybeSingle();

        if (hopitalRes != null) {
          final codeH = hopitalRes['code_hopital']?.toString();
          if (codeH != null && codeH.trim().isNotEmpty) {
            prefix = codeH.trim().toUpperCase();
          } else {
            // Extraire 3 lettres significatives du nom (ex: Hopital District Manjo -> HDM)
            final nom = hopitalRes['nom_hopital']?.toString() ?? '';
            final words = nom.split(RegExp(r'\s+')).where((w) => w.length >= 2).toList();
            if (words.length >= 3) {
              prefix = '${words[0][0]}${words[1][0]}${words[2][0]}'.toUpperCase();
            } else if (nom.length >= 3) {
              prefix = nom.substring(0, 3).toUpperCase();
            }
          }
        }
      }

      // Générer l'ID unique d'activation (ex: HDM-48201)
      final generatedId = SuperAdminService.genererIdAgent(prefix);

      final Map<String, dynamic> insertData = {
        'id_utilisateur': generatedId, // L'ID personnalisé est la colonne TEXT
        'Nom': data['Nom'],
        'Prenom': data['Prenom'],
        'telephone': int.tryParse(data['telephone']?.toString() ?? '0') ?? 0,
        'adresse': data['adresse'],
        'Specialite': data['Specialite'],
        'sexe': data['sexe'],
        'age': int.tryParse(data['age']?.toString() ?? '30') ?? 30,
        'username': generatedId,
        'compte_actif': false,
        'date_enregistrement': DateTime.now().toIso8601String(),
      };

      final hospitalIdToUse = hid ?? data['id_hopital'];
      if (hospitalIdToUse != null) {
        insertData['id_hopital'] = hospitalIdToUse;
      }

      await supabase.from('utilisateur').insert(insertData);
      return {'error': null, 'generatedId': generatedId}; // ✅ Succès
    } on PostgrestException catch (e) {
      return {'error': 'Erreur création fiche: ${e.message}', 'generatedId': null};
    } catch (e) {
      return {'error': 'Erreur inattendue: $e', 'generatedId': null};
    }
  }

  /// ✏️ Modifie un membre du personnel
  Future<String?> updatePersonnel(String id, Map<String, dynamic> data) async {
    try {
      final rows = await supabase
          .from('utilisateur')
          .update(data)
          .eq('id_utilisateur', id)
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
          .from('utilisateur')
          .update({'compte_actif': actif})
          .eq('id_utilisateur', id);
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
          .from('utilisateur')
          .select('auth_id')
          .eq('id_utilisateur', id)
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
      await supabase.from('utilisateur').delete().eq('id_utilisateur', id);
      return null;
    } catch (e) {
      return 'Erreur suppression: $e';
    }
  }
}
