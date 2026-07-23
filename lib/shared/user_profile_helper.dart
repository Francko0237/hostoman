import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileHelper {
  static String? _cachedFormattedName;
  static Map<String, dynamic>? _cachedUserData;

  static void clearCache() {
    _cachedFormattedName = null;
    _cachedUserData = null;
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        clearCache();
        return null;
      }

      if (_cachedUserData != null && _cachedUserData!['id_personnel'] == user.id) {
        return _cachedUserData;
      }

      clearCache();

      final data = await client
          .from('Personnel_hopital')
          .select('Nom, Prenom, Specialite, sexe, id_personnel')
          .eq('id_personnel', user.id)
          .single();

      _cachedUserData = data;
      return _cachedUserData;
    } catch (e) {
      print('Erreur lors de la récupération des données utilisateur : $e');
      return null;
    }
  }

  static Future<String> getFormattedName() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        clearCache();
        return '';
      }

      if (_cachedFormattedName != null && _cachedUserData != null && _cachedUserData!['id_personnel'] == user.id) {
        return _cachedFormattedName!;
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
        final isFemale = rawSexe == 'F' || 
                         rawSexe == 'Femme' || 
                         rawSexe == 'Féminin' || 
                         rawSexe.toLowerCase() == 'femme' ||
                         rawSexe.toLowerCase() == 'féminin';
        title = isFemale ? 'Mme' : 'M.';
      }

      String fullName = '';
      if (nom.isNotEmpty) {
        fullName += nom;
      }
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
        final text = (snapshot.hasData && snapshot.data!.isNotEmpty)
            ? snapshot.data!
            : fallback;
        return Text(
          text,
          style: style,
          overflow: overflow,
          maxLines: maxLines,
        );
      },
    );
  }
}
