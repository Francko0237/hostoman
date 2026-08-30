import 'package:supabase_flutter/supabase_flutter.dart';

class DetailService {
  final SupabaseClient supabase;
  DetailService(this.supabase);

  /// 🔍 Récupère les détails complets d'un paiement par son id_paiement
  /// Inclut les examens si motif = 'Examens', les lignes prescription si motif = 'Medicaments'
  Future<Map<String, dynamic>?> getPatientPaymentDetails(
    int idPaiement,
  ) async {
    try {
      final response = await supabase
          .from('paiement')
          .select('''
            id_paiement,
            id_consultation,
            id_prescription,
            prix_a_paye,
            statut_paiement,
            motif,
            date_paiement,
             Consultation(
              id_consultation,
              type_service,
              date_enregistrement,
              Statut_Consultation,
              id_patient,
              Patient(*),
              examen_a_effectuer(id_examen, nom_examen, prix_examen, statut_examen)
            )
          ''')
          .eq('id_paiement', idPaiement)
          .single();

      final data = Map<String, dynamic>.from(response);

      // Si pas de consultation mais que nous avons un id_prescription, on peut récupérer le patient via prescription -> Patient
      final idPrescription = data['id_prescription'];
      if (data['Consultation'] == null && idPrescription != null) {
        final prescr = await supabase
            .from('prescription')
            .select('id_patient, Patient(*)')
            .eq('id_prescription', idPrescription)
            .maybeSingle();
        if (prescr != null) {
          data['Consultation'] = {
            'id_patient': prescr['id_patient'],
            'Patient': prescr['Patient'],
            'type_service': 'Pharmacie',
            'examen_a_effectuer': [],
          };
        }
      }

      // Si le paiement est lié à une prescription, charger les lignes
      if (idPrescription != null) {
        final lignes = await supabase
            .from('prescription_ligne')
            .select(
              'id_ligne, nom_medicament, quantite, prix_unitaire, statut_ligne',
            )
            .eq('id_prescription', idPrescription)
            .order('id_ligne', ascending: true);
        data['prescription_lignes'] = (lignes as List<dynamic>);
      }

      return data;
    } catch (e) {
      print("Erreur getPatientPaymentDetails: $e");
      return null;
    }
  }

  /// ✅ Valide le paiement et met à jour la prescription associée si nécessaire
  Future<void> validerPaiement(int idPaiement) async {
    try {
      // Récupérer l'id_prescription pour mettre à jour son statut
      final paiementData = await supabase
          .from('paiement')
          .select('id_prescription')
          .eq('id_paiement', idPaiement)
          .maybeSingle();

      await supabase
          .from('paiement')
          .update({'statut_paiement': 'payer'})
          .eq('id_paiement', idPaiement);

      // Mettre à jour la prescription en 'paye' pour que la pharmacie voie l'ordonnance
      final idPrescription = paiementData?['id_prescription'];
      if (idPrescription != null) {
        await supabase
            .from('prescription')
            .update({
              'statut_prescription': 'paye',
              'date_derniere_mise_ajour': DateTime.now().toIso8601String(),
            })
            .eq('id_prescription', idPrescription);
      }
    } catch (e) {
      print("Erreur lors de la validation : $e");
      rethrow;
    }
  }

  /// ❌ Annule le paiement par son id_paiement
  Future<void> annulerPaiement(int idPaiement) async {
    try {
      await supabase
          .from('paiement')
          .update({'statut_paiement': 'annuler'})
          .eq('id_paiement', idPaiement);
    } catch (e) {
      print("Erreur lors de l'annulation : $e");
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────
  // Gestion EXAMENS (toggle Annulé ↔ en attente)
  // ──────────────────────────────────────────────────────────

  /// ❌ Annule un examen et réduit le montant du paiement
  Future<void> annulerExamen({
    required int idExamen,
    required int idPaiement,
    required double prixExamen,
  }) async {
    // 1. Passer l'examen en "Annulé"
    await supabase
        .from('examen_a_effectuer')
        .update({'statut_examen': 'Annulé'})
        .eq('id_examen', idExamen);

    // 2. Décrémenter le prix du paiement
    final paiement = await supabase
        .from('paiement')
        .select('prix_a_paye')
        .eq('id_paiement', idPaiement)
        .single();

    final double actuel = (paiement['prix_a_paye'] as num).toDouble();
    final double nouveau = (actuel - prixExamen).clamp(0, double.infinity);

    await supabase
        .from('paiement')
        .update({'prix_a_paye': nouveau})
        .eq('id_paiement', idPaiement);
  }

  /// 🔄 Restaure un examen annulé et augmente le montant du paiement
  Future<void> restaurerExamen({
    required int idExamen,
    required int idPaiement,
    required double prixExamen,
  }) async {
    // 1. Repasser l'examen en "en attente"
    await supabase
        .from('examen_a_effectuer')
        .update({'statut_examen': 'en attente'})
        .eq('id_examen', idExamen);

    // 2. Incrémenter le prix du paiement
    final paiement = await supabase
        .from('paiement')
        .select('prix_a_paye')
        .eq('id_paiement', idPaiement)
        .single();

    final double actuel = (paiement['prix_a_paye'] as num).toDouble();
    final double nouveau = actuel + prixExamen;

    await supabase
        .from('paiement')
        .update({'prix_a_paye': nouveau})
        .eq('id_paiement', idPaiement);
  }

  // ──────────────────────────────────────────────────────────
  // Gestion MÉDICAMENTS (toggle annule ↔ en_attente)
  // ──────────────────────────────────────────────────────────

  /// ❌ Annule une ligne de prescription et réduit le montant du paiement
  Future<void> annulerLignePrescription({
    required int idLigne,
    required int idPaiement,
    required int idPrescription,
    required double montantLigne,
  }) async {
    // 1. Passer la ligne en 'annule'
    await supabase
        .from('prescription_ligne')
        .update({'statut_ligne': 'annule'})
        .eq('id_ligne', idLigne);

    // 2. Recalculer total_prix de la prescription (hors lignes annulées)
    await _recalculerTotalPrescription(idPrescription);

    // 3. Décrémenter le prix du paiement
    final paiement = await supabase
        .from('paiement')
        .select('prix_a_paye')
        .eq('id_paiement', idPaiement)
        .single();

    final double actuel = (paiement['prix_a_paye'] as num).toDouble();
    final double nouveau = (actuel - montantLigne).clamp(0, double.infinity);

    await supabase
        .from('paiement')
        .update({'prix_a_paye': nouveau})
        .eq('id_paiement', idPaiement);
  }

  /// 🔄 Restaure une ligne de prescription annulée et augmente le montant du paiement
  Future<void> restaurerLignePrescription({
    required int idLigne,
    required int idPaiement,
    required int idPrescription,
    required double montantLigne,
  }) async {
    // 1. Repasser la ligne en 'en_attente'
    await supabase
        .from('prescription_ligne')
        .update({'statut_ligne': 'en_attente'})
        .eq('id_ligne', idLigne);

    // 2. Recalculer total_prix de la prescription (hors lignes annulées)
    await _recalculerTotalPrescription(idPrescription);

    // 3. Incrémenter le prix du paiement
    final paiement = await supabase
        .from('paiement')
        .select('prix_a_paye')
        .eq('id_paiement', idPaiement)
        .single();

    final double actuel = (paiement['prix_a_paye'] as num).toDouble();
    final double nouveau = actuel + montantLigne;

    await supabase
        .from('paiement')
        .update({'prix_a_paye': nouveau})
        .eq('id_paiement', idPaiement);
  }

  /// 🔢 Recalcule le total_prix de la prescription en excluant les lignes annulées
  Future<void> _recalculerTotalPrescription(int idPrescription) async {
    final lignes = await supabase
        .from('prescription_ligne')
        .select('quantite, prix_unitaire, statut_ligne')
        .eq('id_prescription', idPrescription);

    double total = 0;
    for (final l in lignes as List<dynamic>) {
      if (l['statut_ligne'] == 'annule') continue;
      final p = (l['prix_unitaire'] as num?)?.toDouble() ?? 0;
      final q = (l['quantite'] as num?)?.toInt() ?? 1;
      total += p * q;
    }

    await supabase
        .from('prescription')
        .update({'total_prix': total})
        .eq('id_prescription', idPrescription);
  }
}
