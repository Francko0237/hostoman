import 'package:supabase_flutter/supabase_flutter.dart';

/// Service pour la table `stock_entree` (réceptions fournisseurs + traçabilité lots)
class StockEntreeService {
  final SupabaseClient supabase;
  StockEntreeService(this.supabase);

  static const _select = '''
    id_entree, id_medicament, quantite, numero_lot,
    date_peremption, fournisseur, prix_achat, notes, date_entree,
    listemedicament(nom_medicament, forme, dosage)
  ''';

  // ── Créer une entrée et incrémenter le stock ──────────────────────────────
  Future<void> creerEntree({
    required int idMedicament,
    required int quantite,
    String? numeroLot,
    DateTime? datePeremption,
    String? fournisseur,
    double? prixAchat,
    String? notes,
  }) async {
    // 1. Enregistrer l'entrée de stock (toujours)
    await supabase.from('stock_entree').insert({
      'id_medicament': idMedicament,
      'quantite': quantite,
      if (numeroLot != null && numeroLot.isNotEmpty) 'numero_lot': numeroLot,
      if (datePeremption != null)
        'date_peremption':
            '${datePeremption.year.toString().padLeft(4, '0')}-${datePeremption.month.toString().padLeft(2, '0')}-${datePeremption.day.toString().padLeft(2, '0')}',
      if (fournisseur != null && fournisseur.isNotEmpty)
        'fournisseur': fournisseur,
      if (prixAchat != null) 'prix_achat': prixAchat,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'date_entree': DateTime.now().toIso8601String(),
    });

    // 2. Incrémenter le stock (non-fatal si RLS ou erreur réseau)
    try {
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
    } catch (_) {
      // L'entrée est enregistrée, l'update du stock sera à faire manuellement
    }
  }

  // ── Liste toutes les entrées (optionnel : filtrées par médicament) ─────────
  Future<List<Map<String, dynamic>>> getEntrees({int? idMedicament}) async {
    var query = supabase.from('stock_entree').select(_select);
    if (idMedicament != null) {
      query = query.eq('id_medicament', idMedicament);
    }
    final response = await query.order('date_entree', ascending: false);
    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  // ── Lots expirant dans les N prochains jours ──────────────────────────────
  Future<List<Map<String, dynamic>>> getLotsExpirantBientot({
    int joursAvant = 90,
  }) async {
    final limite = DateTime.now().add(Duration(days: joursAvant));
    final limiteStr =
        '${limite.year.toString().padLeft(4, '0')}-${limite.month.toString().padLeft(2, '0')}-${limite.day.toString().padLeft(2, '0')}';
    final response = await supabase
        .from('stock_entree')
        .select(_select)
        .not('date_peremption', 'is', null)
        .lte('date_peremption', limiteStr)
        .order('date_peremption', ascending: true);
    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  // ── Lots déjà expirés ─────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getLotsExpires() async {
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    final response = await supabase
        .from('stock_entree')
        .select(_select)
        .not('date_peremption', 'is', null)
        .lt('date_peremption', todayStr)
        .order('date_peremption', ascending: false);
    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  // ── Compteurs résumé ──────────────────────────────────────────────────────
  Future<Map<String, int>> getResume() async {
    final now = DateTime.now();
    final todayStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final in90Str = () {
      final d = now.add(const Duration(days: 90));
      return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }();

    final totalR = await supabase
        .from('stock_entree')
        .select('id_entree')
        .count(CountOption.exact);

    final expiresR = await supabase
        .from('stock_entree')
        .select('id_entree')
        .not('date_peremption', 'is', null)
        .lt('date_peremption', todayStr)
        .count(CountOption.exact);

    final bientotR = await supabase
        .from('stock_entree')
        .select('id_entree')
        .not('date_peremption', 'is', null)
        .gte('date_peremption', todayStr)
        .lte('date_peremption', in90Str)
        .count(CountOption.exact);

    return {
      'total': totalR.count,
      'expires': expiresR.count,
      'bientot': bientotR.count,
    };
  }
}
