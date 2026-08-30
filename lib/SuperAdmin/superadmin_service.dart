import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class SuperAdminService {
  final SupabaseClient supabase;

  SuperAdminService(this.supabase);

  /// Génère un ID personnalisé aléatoire (ex: HDM-58392)
  static String genererIdAgent(String codeHopital) {
    final prefix = codeHopital.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final randomDigits = (10000 + Random().nextInt(90000)).toString();
    return '$prefix-$randomDigits';
  }

  /// 🏥 Récupère tous les hôpitaux avec leurs directeurs
  Future<List<Map<String, dynamic>>> getHospitaux() async {
    try {
      final response = await supabase
          .from('hopital')
          .select('*')
          .order('date_creation', ascending: false);

      final list = List<Map<String, dynamic>>.from(response);
      for (var h in list) {
        final directeurs = await supabase
            .from('utilisateur')
            .select('*')
            .eq('id_hopital', h['id_hopital'])
            .eq('Specialite', 'Directeur');
        h['directeurs'] = directeurs;
      }
      return list;
    } catch (err) {
      print('Erreur getHospitaux: $err');
      return [];
    }
  }

  /// ➕ Créer un nouvel hôpital et enregistrer la fiche de son Directeur
  Future<String?> enregistrerHopitalEtDirecteur({
    required String nomHopital,
    required String codeHopital,
    String? adresse,
    String? telephone,
    String? email,
    required String nomDirecteur,
    required String prenomDirecteur,
    required String telDirecteur,
    required String sexeDirecteur,
    required String ageDirecteur,
  }) async {
    try {
      final prefixCode = codeHopital.trim().toUpperCase();

      // 1. Insérer l'hôpital avec son code/abréviation
      Map<String, dynamic> insertHopital = {
        'nom_hopital': nomHopital,
        'adresse': adresse,
        'telephone': telephone,
        'email': email,
        'date_creation': DateTime.now().toIso8601String(),
        'actif': true,
      };

      // Tenter d'insérer le code_hopital (si la colonne existe ou pas encore)
      try {
        insertHopital['code_hopital'] = prefixCode;
      } catch (_) {}

      final hopitalRes = await supabase
          .from('hopital')
          .insert(insertHopital)
          .select()
          .single();

      final newHopitalId = hopitalRes['id_hopital'];

      // Générer l'ID personnalisé du Directeur (ex: HDM-58392)
      final directorId = genererIdAgent(prefixCode);

      // 2. Insérer la fiche du Directeur liée à cet hôpital
      await supabase.from('utilisateur').insert({
        'id_utilisateur': directorId, // L'ID personnalisé est la clef TEXT
        'Nom': nomDirecteur,
        'Prenom': prenomDirecteur,
        'telephone': int.tryParse(telDirecteur) ?? 0,
        'Specialite': 'Directeur',
        'sexe': sexeDirecteur,
        'age': int.tryParse(ageDirecteur) ?? 40,
        'username': directorId,
        'compte_actif': false,
        'id_hopital': newHopitalId,
        'date_enregistrement': DateTime.now().toIso8601String(),
      });

      return null; // Succès
    } on PostgrestException catch (e) {
      return 'Erreur Supabase: ${e.message}';
    } catch (e) {
      return 'Erreur inattendue: $e';
    }
  }

  /// 🔄 Activer / Désactiver un hôpital ET tous ses comptes utilisateurs associés
  Future<String?> toggleHopitalActif(String idHopital, bool actif) async {
    try {
      // 1. Mettre à jour le statut de l'hôpital
      await supabase
          .from('hopital')
          .update({'actif': actif})
          .eq('id_hopital', idHopital);

      // 2. Mettre à jour simultanément compte_actif pour tout le personnel de cet hôpital
      await supabase
          .from('utilisateur')
          .update({'compte_actif': actif})
          .eq('id_hopital', idHopital)
          .neq('Specialite', 'superadmin');

      return null;
    } catch (e) {
      print('Erreur toggleHopitalActif: $e');
      return 'Erreur: $e';
    }
  }

  /// ❌ Supprimer un hôpital et TOUTES ses données associées (Action critique irréversible)
  /// Nécessite la ré-authentification du mot de passe du Super-Admin
  Future<String?> supprimerHopital({
    required String idHopital,
    required String motDePasseAdmin,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null || user.email == null) {
        return 'Session expirée. Veuillez vous reconnecter.';
      }

      // 1. Ré-authentification de sécurité avec le mot de passe actuel
      try {
        final authCheck = await supabase.auth.signInWithPassword(
          email: user.email!,
          password: motDePasseAdmin,
        );
        if (authCheck.user == null) {
          return 'Mot de passe incorrect. Suppression annulée.';
        }
      } catch (_) {
        return 'Mot de passe incorrect. Ré-authentification échouée.';
      }

      // 2. Suppression de l'hôpital (la contrainte SQL ON DELETE CASCADE supprimera les dépendances)
      await supabase.from('hopital').delete().eq('id_hopital', idHopital);

      return null; // Succès
    } on PostgrestException catch (e) {
      return 'Erreur de suppression SQL: ${e.message}';
    } catch (e) {
      return 'Erreur inattendue: $e';
    }
  }
}
