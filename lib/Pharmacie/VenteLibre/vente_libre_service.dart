import 'package:supabase_flutter/supabase_flutter.dart';
import '../Ordonnances/ordonnances_service.dart';

/// Service pour la vente libre (prescription type='vente_libre').
/// Crée immédiatement une prescription `paye`, décrémente le stock
/// ligne par ligne et insère le paiement.
class VenteLibreService {
  final SupabaseClient supabase;
  VenteLibreService(this.supabase);

  /// [lignes] : liste de maps
  ///   - id_medicament (int, requis)
  ///   - nom_medicament (String)
  ///   - prix_unitaire (num)
  ///   - quantite (int)
  ///   - posologie (String)
  Future<int> creerVente({
    required List<Map<String, dynamic>> lignes,
    String? nomClient,
  }) async {
    final now = DateTime.now().toIso8601String();
    if (lignes.isEmpty) {
      throw Exception('Aucune ligne fournie');
    }

    double total = 0;
    for (final l in lignes) {
      final p = (l['prix_unitaire'] as num?)?.toDouble() ?? 0;
      final q = (l['quantite'] as num?)?.toInt() ?? 1;
      total += p * q;
    }

    // 1. Création de la prescription type=vente_libre, déjà payée
    final prescriptionRes = await supabase
        .from('prescription')
        .insert({
          'id_consultation': null,
          'id_patient': null,
          'type_prescription': 'vente_libre',
          'statut_prescription': 'paye',
          'total_prix': total,
          'date_prescription': now,
          'date_derniere_mise_ajour': now,
        })
        .select('id_prescription')
        .single();

    final idPrescription = prescriptionRes['id_prescription'] as int;

    // 2. Insertion des lignes (statut 'en_attente', délivrance juste après)
    final List<Map<String, dynamic>> dataLignes = lignes.map((l) {
      return {
        'id_prescription': idPrescription,
        'id_medicament': l['id_medicament'],
        'nom_medicament': l['nom_medicament'],
        'posologie': (l['posologie'] ?? '').toString().isEmpty
            ? '-'
            : l['posologie'],
        'quantite': l['quantite'],
        'prix_unitaire': l['prix_unitaire'],
        'disponible_initialement': true,
        'statut_ligne': 'en_attente',
      };
    }).toList();

    final inserted = await supabase
        .from('prescription_ligne')
        .insert(dataLignes)
        .select('id_ligne');

    // 3. Paiement
    await supabase.from('paiement').insert({
      'id_consultation': null,
      'id_prescription': idPrescription,
      'prix_a_paye': total,
      'statut_paiement': 'paye',
      'motif': 'Medicaments',
      'date_paiement': now,
    });

    // 4. Vérification et décrémentation du stock pour chaque ligne livrée
    //    On réutilise la même logique robuste que delivrerLigne (100 % Dart).
    final svc = OrdonnancesService(supabase);
    for (final row in inserted as List<dynamic>) {
      final idLigne = row['id_ligne'] as int;
      try {
        await svc.delivrerLigne(idLigne: idLigne);
      } catch (e) {
        // Rollback partiel : marquer la ligne en rupture si stock insuffisant
        await supabase
            .from('prescription_ligne')
            .update({'statut_ligne': 'rupture'})
            .eq('id_ligne', idLigne);
        rethrow;
      }
    }

    return idPrescription;
  }
}
