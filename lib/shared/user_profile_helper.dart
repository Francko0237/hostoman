import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileHelper {
  static String? _cachedFormattedName;
  static Map<String, dynamic>? _cachedUserData;

  // ─── Getters rapides pour le cloisonnement multi-hôpitaux ──────────────────

  /// Retourne l'id_hopital de l'utilisateur connecté (depuis le cache).
  /// Retourne l'id_hopital de l'utilisateur connecté en s'assurant d'interroger la DB si le cache est vide.
  static Future<String?> getHospitalId() async {
    if (_cachedUserData == null) {
      await getUserData();
    }
    return currentHospitalId;
  }

  /// Retourne l'id_hopital de l'utilisateur connecté (depuis le cache).
  static String? get currentHospitalId =>
      _cachedUserData?['id_hopital']?.toString();

  /// Retourne le nom de l'hôpital de l'utilisateur connecté (depuis le cache).
  static String get currentHospitalName =>
      _cachedUserData?['nom_hopital']?.toString() ?? '';

  // ─── Cache ─────────────────────────────────────────────────────────────────

  static void clearCache() {
    _cachedFormattedName = null;
    _cachedUserData = null;
  }

  // ─── Chargement du profil ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        clearCache();
        return null;
      }

      // Vérifier le cache
      if (_cachedUserData != null) {
        final cachedAuthId = _cachedUserData!['auth_id']?.toString();
        final cachedUserId = _cachedUserData!['id_utilisateur']?.toString();
        if (cachedAuthId == user.id || cachedUserId == user.id) {
          return _cachedUserData;
        }
      }

      clearCache();

      // Chercher par auth_id (nouveaux comptes) — inclure id_hopital et nom_hopital
      Map<String, dynamic>? data = await client
          .from('utilisateur')
          .select(
            'Nom, Prenom, Specialite, sexe, id_utilisateur, auth_id, id_hopital, hopital(nom_hopital)',
          )
          .eq('auth_id', user.id)
          .maybeSingle();

      // Fallback sur id_utilisateur (anciens comptes)
      data ??= await client
          .from('utilisateur')
          .select(
            'Nom, Prenom, Specialite, sexe, id_utilisateur, auth_id, id_hopital, hopital(nom_hopital)',
          )
          .eq('id_utilisateur', user.id)
          .maybeSingle();

      // Aplatir le nom_hopital depuis la jointure
      if (data != null && data['hopital'] != null) {
        data['nom_hopital'] = data['hopital']['nom_hopital'];
      }

      _cachedUserData = data;
      return _cachedUserData;
    } catch (e) {
      return null;
    }
  }

  // ─── Formatage du nom affiché ──────────────────────────────────────────────

  static Future<String> getFormattedName() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        clearCache();
        return '';
      }

      if (_cachedFormattedName != null && _cachedUserData != null) {
        final cachedAuthId = _cachedUserData!['auth_id']?.toString();
        final cachedUserId = _cachedUserData!['id_utilisateur']?.toString();
        if (cachedAuthId == user.id || cachedUserId == user.id) {
          return _cachedFormattedName!;
        }
      }

      final data = await getUserData();
      if (data == null) return '';

      final nom = data['Nom']?.toString().trim() ?? '';
      final prenom = data['Prenom']?.toString().trim() ?? '';
      final specialite = data['Specialite']?.toString().trim() ?? '';
      final rawSexe = data['sexe']?.toString().trim() ?? '';

      String title;
      final specLower = specialite.toLowerCase();
      if (specLower.contains('médecin') ||
          specLower.contains('medecin') ||
          specLower.contains('docteur') ||
          specLower.contains('dr')) {
        title = 'Dr';
      } else {
        final isFemale =
            rawSexe == 'F' ||
            rawSexe == 'Femme' ||
            rawSexe == 'Féminin' ||
            rawSexe.toLowerCase() == 'femme' ||
            rawSexe.toLowerCase() == 'féminin';
        title = isFemale ? 'Mme' : 'M.';
      }

      String fullName = '';
      if (nom.isNotEmpty) fullName += nom;
      if (prenom.isNotEmpty) {
        if (fullName.isNotEmpty) fullName += ' ';
        fullName += prenom;
      }

      _cachedFormattedName = title.isNotEmpty ? '$title $fullName' : fullName;
      return _cachedFormattedName!;
    } catch (e) {
      print('Erreur lors du formatage du nom utilisateur : $e');
      return '';
    }
  }
}

// ─── Widget utilitaire ────────────────────────────────────────────────────────

class ConnectedUserText extends StatelessWidget {
  final TextStyle? style;
  final String fallback;
  final TextOverflow? overflow;
  final int? maxLines;

  const ConnectedUserText({
    super.key,
    this.style,
    required this.fallback,
    this.overflow,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: UserProfileHelper.getFormattedName(),
      builder: (context, snapshot) {
        final text =
            (snapshot.hasData && snapshot.data!.isNotEmpty)
                ? snapshot.data!
                : fallback;
        return Text(text, style: style, overflow: overflow, maxLines: maxLines);
      },
    );
  }
}
