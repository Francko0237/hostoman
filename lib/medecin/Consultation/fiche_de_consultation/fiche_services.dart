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

  /// 💊 Récupère la liste des médicaments du catalogue (actifs uniquement).
  /// Le champ `disponible` est calculé : actif AND stock > 0.
  Future<List<Map<String, dynamic>>> getListeMedicaments() async {
    final response = await supabase
        .from('listemedicament')
        .select(
          'id_medicament, nom_medicament, forme, dosage, prix_unitaire, stock, actif',
        )
        .eq('actif', true)
        .order('nom_medicament', ascending: true);

    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// 🩺 Sauvegarde les données de la consultation (Adapté à ton UI)
  /// [medicamentsPrescrits] : liste de maps avec
  ///   - id_medicament (int?)        -> NULL si saisie libre
  ///   - nom_medicament (String)
  ///   - posologie (String)
  ///   - quantite (int)
  ///   - prix_unitaire (num?)        -> NULL si saisie libre
  ///   - disponible_initialement (bool)
  Future<void> saveConsultationData({
    required int idConsultation,
    required String antecedents,
    required String signesSymptomes,
    required String diagnosticInitial,
    required String statutConsultation, // Reçu de l'UI
    required List<Map<String, dynamic>> examensPrescrits,
    required String diagnosticFinal,
    required String traitementPrescrit,
    String? programmationRdv,
    DateTime? rdvDate,
    List<Map<String, dynamic>> medicamentsPrescrits = const [],
    String? idPatient,
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
        totalPrix += prix;
      }

      await supabase.from('paiement').insert({
        'id_consultation': idConsultation,
        'prix_a_paye': totalPrix,
        'statut_paiement': 'en_attente',
        'motif': 'Examens',
        'date_paiement': now,
      });
    }

    // 4. Traitement des médicaments prescrits (Pharmacie)
    if (medicamentsPrescrits.isNotEmpty) {
      // Total estimé (les saisies libres sans prix sont ignorées du total)
      double totalMed = 0;
      for (final m in medicamentsPrescrits) {
        final prix = (m['prix_unitaire'] as num?)?.toDouble() ?? 0;
        final qte = (m['quantite'] as num?)?.toInt() ?? 1;
        totalMed += prix * qte;
      }

      // 4.a Création de la prescription
      final prescriptionRes = await supabase
          .from('prescription')
          .insert({
            'id_consultation': idConsultation,
            'id_patient': idPatient,
            'type_prescription': 'consultation',
            'statut_prescription': 'en_attente_paiement',
            'total_prix': totalMed,
            'date_prescription': now,
            'date_derniere_mise_ajour': now,
          })
          .select('id_prescription')
          .single();

      final int idPrescription = prescriptionRes['id_prescription'] as int;

      // 4.b Lignes de prescription
      final List<Map<String, dynamic>> lignes = medicamentsPrescrits.map((m) {
        return {
          'id_prescription': idPrescription,
          'id_medicament': m['id_medicament'], // peut être null
          'nom_medicament': m['nom_medicament'],
          'posologie': m['posologie'],
          'quantite': m['quantite'],
          'prix_unitaire': m['prix_unitaire'], // peut être null si saisie libre
          'disponible_initialement': m['disponible_initialement'] ?? false,
          'statut_ligne': 'en_attente',
        };
      }).toList();

      await supabase.from('prescription_ligne').insert(lignes);

      // 4.c Facture pharmacie
      await supabase.from('paiement').insert({
        'id_consultation': idConsultation,
        'id_prescription': idPrescription,
        'prix_a_paye': totalMed,
        'statut_paiement': 'en_attente',
        'motif': 'Medicaments',
        'date_paiement': now,
      });
    }
  }

  /// 🔬 Récupère les examens avec leurs résultats pour une consultation
  Future<List<Map<String, dynamic>>> getExamensResultats(
    int idConsultation,
  ) async {
    final response = await supabase
        .from('examen_a_effectuer')
        .select('*')
        .eq('id_consultation', idConsultation)
        .order('id_examen', ascending: true);

    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }
}
