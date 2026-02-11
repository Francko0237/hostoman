import 'package:supabase_flutter/supabase_flutter.dart';

class MedecinServices {
  final SupabaseClient supabase;
  MedecinServices(this.supabase);

  /// 🔍 Récupère les infos du patient et ses constantes
  Future<List<Map<String, dynamic>>> infosPatient(int idConsultation) async {
    final response = await supabase
        .from('Consultation')
        .select('id_consultation, Patient(*), Parametres_vitaux(*)')
        .eq('id_consultation', idConsultation);

    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// 📋 Récupère la liste des examens disponibles depuis la base de données
  Future<List<Map<String, dynamic>>> getListeExamens() async {
    final response = await supabase
        .from('listeexamen')
        .select('id_examlist, nom_examen, prix_examen')
        .order('nom_examen', ascending: true);

    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// 🩺 Sauvegarde les données de la consultation (Adapté à ton UI)
  Future<void> saveConsultationData({
    required int idConsultation,
    required String antecedents,
    required String signesSymptomes,
    required String diagnosticInitial,
    required String statutConsultation, // Reçu de l'UI
    required List<Map<String, dynamic>> examensPrescrits,
    required String diagnosticFinal,
    required String traitementPrescrit,
    required String programmationRdv,
    DateTime? rdvDate,
  }) async {
    final now = DateTime.now().toIso8601String();

    // Logique de statut : Si examens cochés, on force 'en-attente-examen'
    String statutFinal = (examensPrescrits.isNotEmpty)
        ? 'en-attente-examen'
        : 'terminer';

    // 1. Mise à jour de la table 'Consultation'
    await supabase
        .from('Consultation')
        .update({
          'antecedents': antecedents,
          'signes_symptomes': signesSymptomes,
          'diagnostic_initial': diagnosticInitial,
          'diagnostic_final': diagnosticFinal,
          'traitement_prescrit': traitementPrescrit,
          'programmation_rdv': programmationRdv,
          'Statut_Consultation': statutFinal,
          'date_rdv_prevu': rdvDate?.toIso8601String(),
          'date_derniere_mise_ajour': now,
        })
        .eq('id_consultation', idConsultation);

    // 2. Traitement des examens et de la facturation
    if (examensPrescrits.isNotEmpty) {
      // Insertion des examens à effectuer
      final List<Map<String, dynamic>> dataToInsert = examensPrescrits.map((
        examen,
      ) {
        return {
          'id_consultation': idConsultation,
          'nom_examen': examen['nom'],
          'prix_examen': examen['prix'],
          'statut_examen': 'en attente',
          'date_enregistrement': now,
        };
      }).toList();

      await supabase.from('examen_a_effectuer').insert(dataToInsert);

      // 3. GÉNÉRATION AUTOMATIQUE DE LA FACTURE
      double totalPrix = 0;
      for (var ex in examensPrescrits) {
        // Conversion sécurisée : gère String ou num
        final prix = ex['prix'];
        if (prix is String) {
          totalPrix += double.parse(prix);
        } else if (prix is num) {
          totalPrix += prix.toDouble();
        }
      }

      await supabase.from('paiement').insert({
        'id_consultation': idConsultation,
        'prix_a_paye': totalPrix,
        'statut_paiement': 'en_attente',
        'motif': 'Examens',
        'date_paiement': now,
      });
    }
  }
}
