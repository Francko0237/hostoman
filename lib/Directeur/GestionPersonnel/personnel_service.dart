import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// ⚠️ IMPORTANTE ⚠️
/// Ne mettez PAS la clé "anon" ici. L'Admin API nécessite obligatoirement la clé "service_role".
/// Copiez-la depuis `supabase status` (cherchez "service_role key"). Si vous êtes bloqué,
/// le fallback avec signUp est utilisé, mais il gérera mieux les insertions locale.
const String _serviceRoleKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJzZXJ2aWNlX3JvbGUiLAogICAgImlzcyI6ICJzdXBhYmFzZS1kZW1vIiwKICAgICJpYXQiOiAxNjQxNzY5MjAwLAogICAgImV4cCI6IDE3OTk1MzU2MDAKfQ.DaYlNEoUrrEn2Ig7tqibS-PHK5vgusbcbo7X36XVt4Q';

class PersonnelService {
  final SupabaseClient supabase;

  // URL du projet Supabase (cloud). Doit correspondre à celle de main.dart.
  String get _supabaseUrl => 'https://mzgyccyaywncafocmdnd.supabase.co';

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

  /// ➕ Ajoute un nouveau membre du personnel
  Future<String?> addPersonnel(
    Map<String, dynamic> data,
    String password,
  ) async {
    // Essai 1 : Admin API (Création instantanée, pas de confirmation d'email)
    try {
      final createResponse = await http
          .post(
            Uri.parse('$_supabaseUrl/auth/v1/admin/users'),
            headers: {
              'apikey': _serviceRoleKey,
              'Authorization': 'Bearer $_serviceRoleKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': data['email'],
              'password': password,
              'email_confirm': true,
              'user_metadata': {'Specialite': data['Specialite']},
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (createResponse.statusCode == 200 ||
          createResponse.statusCode == 201) {
        final body = jsonDecode(createResponse.body) as Map<String, dynamic>;
        final userId = body['id']?.toString();
        if (userId != null) {
          // Insérer dans la table
          await supabase.from('Personnel_hopital').insert({
            'id_personnel': userId,
            'Nom': data['Nom'],
            'Prenom': data['Prenom'],
            'telephone': data['telephone'],
            'adresse': data['adresse'],
            'email': data['email'],
            'Specialite': data['Specialite'],
            'sexe': data['sexe'],
            'age': data['age'],
            'date_enregistrement': DateTime.now().toIso8601String(),
          });
          return null; // ✅ Succès via Admin API
        }
      } else {
        print('Admin API erreur: ${createResponse.body}');
        // Si la réponse est "Unauthorized", la clé service_role est fausse. Fallback.
      }
    } catch (e) {
      print('Admin API crash (timeout/hors ligne): $e');
    }

    // Essai 2 (fallback) : signUp classique
    try {
      print('Tentative de création via signUp...');
      final authResponse = await supabase.auth.signUp(
        email: data['email'],
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        return 'Impossible de créer le compte. Vérifiez les informations.';
      }

      await supabase.from('Personnel_hopital').insert({
        'id_personnel': user.id,
        'Nom': data['Nom'],
        'Prenom': data['Prenom'],
        'telephone': data['telephone'],
        'adresse': data['adresse'],
        'email': data['email'],
        'Specialite': data['Specialite'],
        'sexe': data['sexe'],
        'age': data['age'],
      });

      return null; // ✅ Succès via signUp complet
    } on AuthException catch (e) {
      // Cas où Auth a créé le compte mais plante sur le SMTP local
      if (e.message.contains('confirmation email') ||
          e.message.contains('SMTP') ||
          e.message.contains('sending')) {
        // Impossible de récupérer l'ID nouvellement créé via le client
        // parce qu'on n'a pas accès à la table user sans connexion Admin et on n'est pas connecté en tant que lui
        return 'Le compte a été créé dans Auth mais le profil n\'a pas pu être inséré car l\'API Admin est bloquée. Remettez votre clé "service_role" originelle dans le fichier personnel_service.';
      }
      return 'Erreur Auth: ${e.message}';
    } catch (e) {
      return 'Erreur inattendue: $e';
    }
  }

  /// ✏️ Modifie un membre du personnel (sans toucher à l'Auth)
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

  /// ❌ Supprime un membre du personnel ET son compte Auth via Admin API
  Future<String?> deletePersonnel(String id) async {
    try {
      await http
          .delete(
            Uri.parse('$_supabaseUrl/auth/v1/admin/users/$id'),
            headers: {
              'apikey': _serviceRoleKey,
              'Authorization': 'Bearer $_serviceRoleKey',
            },
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}

    try {
      await supabase.from('Personnel_hopital').delete().eq('id_personnel', id);
      return null;
    } catch (e) {
      return 'Erreur suppression: $e';
    }
  }
}
