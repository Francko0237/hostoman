import 'package:supabase_flutter/supabase_flutter.dart';

/// Service pour la gestion des ordonnances (prescription + lignes + paiement).
class OrdonnancesService {
  final SupabaseClient supabase;
  OrdonnancesService(this.supabase);

  /// Annule les prescriptions `en_attente_paiement` antérieures à aujourd'hui.
  /// Renvoie le nombre de prescriptions annulées.
  Future<int> annulerPerimees() async {
    try {
      final res = await supabase.rpc('annuler_prescriptions_perimees');
      if (res is int) return res;
      if (res is num) return res.toInt();
      return 0;
    } catch (_) {
      // RPC indisponible : on n'interrompt pas le dashboard
      return 0;
    }
  }

  /// Liste les ordonnances par statut.
  /// [statuts] peut contenir : 'en_attente_paiement', 'paye',
  /// 'partiellement_delivre', 'delivre', 'annule'.
  Future<List<Map<String, dynamic>>> listerParStatut(
    List<String> statuts, {
    String? typePrescription, // 'consultation' | 'vente_libre' | null (tous)
  }) async {
    var query = supabase
        .from('prescription')
        .select(
            'id_prescription, id_consultation, id_patient, type_prescription, '
            'statut_prescription, total_prix, date_prescription, '
            'date_derniere_mise_ajour, '
            'Patient(id_patient, nom_complet, age, sexe)')
        .inFilter('statut_prescription', statuts);

    if (typePrescription != null) {
      query = query.eq('type_prescription', typePrescription);
    }

    final response =
        await query.order('date_prescription', ascending: false).limit(200);
    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// Détails d'une ordonnance avec ses lignes.
  Future<Map<String, dynamic>> getDetail(int idPrescription) async {
    final prescription = await supabase
        .from('prescription')
        .select(
            'id_prescription, id_consultation, id_patient, type_prescription, '
            'statut_prescription, total_prix, date_prescription, '
            'date_derniere_mise_ajour, '
            'Patient(id_patient, nom_complet, age, sexe, telephone), '
            'Consultation(id_consultation, motif_de_consultation)')
        .eq('id_prescription', idPrescription)
        .single();

    final lignes = await supabase
        .from('prescription_ligne')
        .select(
            'id_ligne, id_medicament, id_medicament_substitut, nom_medicament, '
            'posologie, quantite, prix_unitaire, disponible_initialement, '
            'statut_ligne')
        .eq('id_prescription', idPrescription)
        .order('id_ligne', ascending: true);

    final paiement = await supabase
        .from('paiement')
        .select('id_paiement, prix_a_paye, statut_paiement, date_paiement, motif')
        .eq('id_prescription', idPrescription)
        .maybeSingle();

    return {
      'prescription': prescription,
      'lignes': lignes as List<dynamic>,
      'paiement': paiement,
    };
  }

  /// Confirme le paiement de l'ordonnance (statut `paye`).
  Future<void> confirmerPaiement(int idPrescription) async {
    final now = DateTime.now().toIso8601String();

    // Met à jour le paiement lié
    await supabase
        .from('paiement')
        .update({
          'statut_paiement': 'paye',
          'date_paiement': now,
        })
        .eq('id_prescription', idPrescription);

    // Met à jour la prescription
    await supabase
        .from('prescription')
        .update({
          'statut_prescription': 'paye',
          'date_derniere_mise_ajour': now,
        })
        .eq('id_prescription', idPrescription);
  }

  /// Délivrance d'une ligne (décrément du stock et changement de statut).
  /// [idMedicamentSubstitut] permet de remplacer le médicament prescrit
  /// par un équivalent du catalogue.
  Future<void> delivrerLigne({
    required int idLigne,
    int? idMedicamentSubstitut,
  }) async {
    await supabase.rpc('delivrer_ligne_prescription', params: {
      'p_id_ligne': idLigne,
      'p_id_medicament_substitut': idMedicamentSubstitut,
    });
  }

  /// Marque une ligne en rupture (non délivrée).
  Future<void> marquerRupture(int idLigne) async {
    await supabase
        .from('prescription_ligne')
        .update({'statut_ligne': 'rupture'})
        .eq('id_ligne', idLigne);
  }

  /// Saisie/modification du prix unitaire d'une ligne (utile pour
  /// les médicaments saisis libre par le médecin).
  Future<void> majPrixLigne(int idLigne, double prix) async {
    await supabase
        .from('prescription_ligne')
        .update({'prix_unitaire': prix})
        .eq('id_ligne', idLigne);

    // Recalcule le total de la prescription
    final ligne = await supabase
        .from('prescription_ligne')
        .select('id_prescription')
        .eq('id_ligne', idLigne)
        .single();

    final idPrescription = ligne['id_prescription'] as int;

    final lignes = await supabase
        .from('prescription_ligne')
        .select('quantite, prix_unitaire')
        .eq('id_prescription', idPrescription);

    double total = 0;
    for (final l in lignes as List<dynamic>) {
      final p = (l['prix_unitaire'] as num?)?.toDouble() ?? 0;
      final q = (l['quantite'] as num?)?.toInt() ?? 1;
      total += p * q;
    }

    await supabase
        .from('prescription')
        .update({'total_prix': total})
        .eq('id_prescription', idPrescription);

    await supabase
        .from('paiement')
        .update({'prix_a_paye': total})
        .eq('id_prescription', idPrescription);
  }
}
