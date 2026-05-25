import 'package:supabase_flutter/supabase_flutter.dart';

/// Service CRUD pour la table `listemedicament` (catalogue des médicaments)
class ListeMedicamentService {
  final SupabaseClient supabase;
  ListeMedicamentService(this.supabase);

  Future<List<Map<String, dynamic>>> getAll({bool actifsSeulement = false}) async {
    var query = supabase.from('listemedicament').select(
        'id_medicament, nom_medicament, forme, dosage, prix_unitaire, stock, seuil_alerte, actif, date_enregistrement');
    if (actifsSeulement) {
      query = query.eq('actif', true);
    }
    final response = await query.order('nom_medicament', ascending: true);
    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getStockBas() async {
    final response = await supabase
        .from('listemedicament')
        .select(
            'id_medicament, nom_medicament, forme, dosage, stock, seuil_alerte')
        .eq('actif', true)
        .order('stock', ascending: true);
    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .where((e) =>
            (e['stock'] as num).toInt() <= (e['seuil_alerte'] as num).toInt())
        .toList();
  }

  Future<void> create({
    required String nom,
    String? forme,
    String? dosage,
    required double prix,
    required int stock,
    int seuilAlerte = 5,
  }) async {
    await supabase.from('listemedicament').insert({
      'nom_medicament': nom,
      'forme': forme,
      'dosage': dosage,
      'prix_unitaire': prix,
      'stock': stock,
      'seuil_alerte': seuilAlerte,
      'actif': true,
    });
  }

  Future<void> update({
    required int idMedicament,
    required String nom,
    String? forme,
    String? dosage,
    required double prix,
    required int stock,
    required int seuilAlerte,
    required bool actif,
  }) async {
    await supabase
        .from('listemedicament')
        .update({
          'nom_medicament': nom,
          'forme': forme,
          'dosage': dosage,
          'prix_unitaire': prix,
          'stock': stock,
          'seuil_alerte': seuilAlerte,
          'actif': actif,
        })
        .eq('id_medicament', idMedicament);
  }

  Future<void> ajouterStock(int idMedicament, int quantite) async {
    final m = await supabase
        .from('listemedicament')
        .select('stock')
        .eq('id_medicament', idMedicament)
        .single();
    final current = (m['stock'] as num).toInt();
    await supabase
        .from('listemedicament')
        .update({'stock': current + quantite})
        .eq('id_medicament', idMedicament);
  }

  Future<void> delete(int idMedicament) async {
    await supabase
        .from('listemedicament')
        .delete()
        .eq('id_medicament', idMedicament);
  }
}
