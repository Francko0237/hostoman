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
          'Patient(id_patient, nom_complet, age, sexe)',
        )
        .inFilter('statut_prescription', statuts);

    if (typePrescription != null) {
      query = query.eq('type_prescription', typePrescription);
    }

    final response = await query
        .order('date_prescription', ascending: false)
        .limit(200);
    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// Liste les prescriptions de type 'consultation' avec statut
  /// 'en_attente_paiement', en joignant Patient ET Consultation (motif).
  Future<List<Map<String, dynamic>>> listerConsultationsEnAttente() async {
    final response = await supabase
        .from('prescription')
        .select(
          'id_prescription, id_consultation, id_patient, '
          'statut_prescription, total_prix, date_prescription, '
          'Patient(id_patient, nom_complet, age, sexe), '
          'Consultation(id_consultation, Parametres_vitaux(motif_de_consultation))',
        )
        .eq('type_prescription', 'consultation')
        .eq('statut_prescription', 'en_attente_paiement')
        .order('date_prescription', ascending: false)
        .limit(200);
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
          'Consultation(id_consultation, Parametres_vitaux(motif_de_consultation))',
        )
        .eq('id_prescription', idPrescription)
        .single();

    final lignes = await supabase
        .from('prescription_ligne')
        .select(
          'id_ligne, id_medicament, id_medicament_substitut, nom_medicament, '
          'posologie, quantite, prix_unitaire, disponible_initialement, '
          'statut_ligne',
        )
        .eq('id_prescription', idPrescription)
        .order('id_ligne', ascending: true);

    // Prend le paiement le plus récent (évite le crash si plusieurs lignes)
    final paiements = await supabase
        .from('paiement')
        .select(
          'id_paiement, prix_a_paye, statut_paiement, date_paiement, motif',
        )
        .eq('id_prescription', idPrescription)
        .order('id_paiement', ascending: false)
        .limit(1);

    final paiement =
        (paiements as List).isNotEmpty
            ? paiements.first
            : null;

    return {
      'prescription': prescription,
      'lignes': lignes as List<dynamic>,
      'paiement': paiement,
    };
  }

  /// Confirme le paiement de l'ordonnance (statut `paye`).
  Future<void> confirmerPaiement(int idPrescription) async {
    final now = DateTime.now().toIso8601String();

    // Vérifie si une ligne paiement existe déjà pour cette prescription
    final existing = await supabase
        .from('paiement')
        .select('id_paiement, prix_a_paye')
        .eq('id_prescription', idPrescription)
        .order('id_paiement', ascending: false)
        .limit(1);

    if ((existing as List).isNotEmpty) {
      // Met à jour la ligne existante — cast sécurisé (Supabase renvoie num)
      final idPaiement = (existing.first['id_paiement'] as num).toInt();
      await supabase
          .from('paiement')
          .update({'statut_paiement': 'paye', 'date_paiement': now})
          .eq('id_paiement', idPaiement);
    } else {
      // Crée la ligne paiement si elle n'existe pas (cas rare)
      final prescription = await supabase
          .from('prescription')
          .select('total_prix, id_consultation')
          .eq('id_prescription', idPrescription)
          .single();

      await supabase.from('paiement').insert({
        'id_prescription': idPrescription,
        'id_consultation': prescription['id_consultation'],
        'prix_a_paye': (prescription['total_prix'] as num?)?.toDouble() ?? 0.0,
        'statut_paiement': 'paye',
        'motif': 'Medicaments',
        'date_paiement': now,
      });
    }

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
    await supabase.rpc(
      'delivrer_ligne_prescription',
      params: {
        'p_id_ligne': idLigne,
        'p_id_medicament_substitut': idMedicamentSubstitut,
      },
    );
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

  /// Annule une prescription (statut `annule`).
  Future<void> annulerPrescription(int idPrescription) async {
    final now = DateTime.now().toIso8601String();

    // Annuler le paiement associé s'il existe
    await supabase
        .from('paiement')
        .update({'statut_paiement': 'annule'})
        .eq('id_prescription', idPrescription);

    // Annuler la prescription
    await supabase
        .from('prescription')
        .update({
          'statut_prescription': 'annule',
          'date_derniere_mise_ajour': now,
        })
        .eq('id_prescription', idPrescription);
  }
}
