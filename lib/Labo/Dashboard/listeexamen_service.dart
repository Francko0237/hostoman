import 'package:supabase_flutter/supabase_flutter.dart';

/// Service CRUD pour la table `listeexamen` (catalogue des examens du labo)
class ListeExamenService {
  final SupabaseClient supabase;
  ListeExamenService(this.supabase);

  /// 📋 Récupère tous les examens du catalogue
  Future<List<Map<String, dynamic>>> getAll() async {
    final response = await supabase
        .from('listeexamen')
        .select('id_examlist, nom_examen, prix_examen, date_enregistrement')
        .order('nom_examen', ascending: true);

    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// ➕ Ajoute un nouvel examen au catalogue
  Future<void> create({required String nom, required double prix}) async {
    await supabase.from('listeexamen').insert({
      'nom_examen': nom,
      'prix_examen': prix,
    });
  }

  /// ✏️ Met à jour un examen existant
  Future<void> update({
    required int idExamlist,
    required String nom,
    required double prix,
  }) async {
    await supabase
        .from('listeexamen')
        .update({'nom_examen': nom, 'prix_examen': prix})
        .eq('id_examlist', idExamlist);
  }

  /// 🗑️ Supprime un examen du catalogue
  Future<void> delete(int idExamlist) async {
    await supabase.from('listeexamen').delete().eq('id_examlist', idExamlist);
  }
}
