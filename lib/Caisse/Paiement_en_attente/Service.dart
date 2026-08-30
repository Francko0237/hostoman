import 'package:supabase_flutter/supabase_flutter.dart';

class PaiementService {
  final SupabaseClient supabase;
  PaiementService(this.supabase);

  /// 🔍 Récupère CHAQUE paiement en attente comme une ligne indépendante,
  /// avec les informations de la consultation et du patient.
  Future<List<Map<String, dynamic>>> getPaiementsEnAttente() async {
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
              id_patient,
              date_derniere_mise_ajour,
              date_enregistrement,
              Patient(*),
              examen_a_effectuer(nom_examen, prix_examen, statut_examen)
            )
          ''')
          .eq('statut_paiement', 'en_attente')
          .order('date_paiement', ascending: false);

      final list = List<Map<String, dynamic>>.from(response);

      // Post-fetch pour les paiements de médicaments directs (sans Consultation)
      for (var item in list) {
        if (item['Consultation'] == null && item['id_prescription'] != null) {
          final prescr = await supabase
              .from('prescription')
              .select('id_patient, Patient(*)')
              .eq('id_prescription', item['id_prescription'])
              .maybeSingle();
          if (prescr != null) {
            item['Consultation'] = {
              'id_consultation': null,
              'type_service': 'Pharmacie',
              'id_patient': prescr['id_patient'],
              'Patient': prescr['Patient'],
              'examen_a_effectuer': [],
            };
          }
        }
      }

      return list;
    } catch (e) {
      print("Erreur getPaiementsEnAttente: $e");
      return [];
    }
  }

  /// ⚠️ Kept for backwards compatibility — now targets a single paiement by ID
  Future<List<Map<String, dynamic>>> getPatientsNonPayes() async {
    return getPaiementsEnAttente();
  }

  /// ✅ Valide un paiement précis par son id_paiement
  Future<void> validerPaiementById(int idPaiement) async {
    try {
      await supabase
          .from('paiement')
          .update({'statut_paiement': 'payer'})
          .eq('id_paiement', idPaiement);
    } catch (e) {
      print("Erreur lors de la validation : $e");
      rethrow;
    }
  }

  /// ❌ Annule un paiement précis par son id_paiement
  Future<void> annulerPaiementById(int idPaiement) async {
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

  /// ✅ Valide le paiement en mettant 'payer' (tous les paiements de la consultation)
  Future<void> validerPaiement(String idConsultation) async {
    try {
      await supabase
          .from('paiement')
          .update({'statut_paiement': 'payer'})
          .eq('id_consultation', idConsultation);
    } catch (e) {
      print("Erreur lors de la validation : $e");
    }
  }

  /// ❌ Annuler le paiement (tous les paiements de la consultation)
  Future<void> AnnulerPaiement(String idConsultation) async {
    try {
      await supabase
          .from('paiement')
          .update({'statut_paiement': 'annuler'})
          .eq('id_consultation', idConsultation);
    } catch (e) {
      print("Erreur lors de l'annulation : $e");
    }
  }
}
