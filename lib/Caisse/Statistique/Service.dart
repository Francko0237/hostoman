import 'package:supabase_flutter/supabase_flutter.dart';

class StatsService {
  final SupabaseClient supabase;
  StatsService(this.supabase);

  /// 📊 Récupère TOUTES les transactions (paiements) par période.
  /// La table `paiement` est la source centrale de toutes les transactions :
  ///  - motif = 'Consultation' → lié à Consultation → Patient
  ///  - motif = 'Examens'      → lié à Consultation → Patient
  ///  - motif = 'Medicaments'  → lié à Consultation → Patient  OU  prescription → Patient (vente libre)
  Future<Map<String, dynamic>> getStatsByPeriod({
    required DateTime dateDebut,
    required DateTime dateFin,
    String statutPaiement = 'tous',
  }) async {
    // Requête directement sur la table paiement avec left joins
    var query = supabase.from('paiement').select('''
      id_paiement,
      motif,
      prix_a_paye,
      statut_paiement,
      date_paiement,
      id_consultation,
      id_prescription,
      Consultation(
        id_consultation,
        type_service,
        date_enregistrement,
        id_patient,
        Patient(nom_complet, sexe, age, telephone)
      ),
      prescription(
        id_prescription,
        id_patient,
        Patient(nom_complet, sexe, age, telephone)
      )
    ''');

    // Filtrage par statut si pas 'tous'
    if (statutPaiement != 'tous') {
      query = query.eq('statut_paiement', statutPaiement);
    }

    final response = await query
        .gte('date_paiement', dateDebut.toIso8601String())
        .lte('date_paiement', dateFin.toIso8601String())
        .order('date_paiement', ascending: false);

    final paiements = List<Map<String, dynamic>>.from(response);

    double sommeTotale = 0;
    int hommes = 0;
    int femmes = 0;
    final Set<String> patientsUniques = {};

    for (var p in paiements) {
      // Calcul revenu uniquement si paiement validé
      final statut = (p['statut_paiement'] ?? '').toString().toLowerCase();
      if (statut == 'payer' || statut == 'paye') {
        sommeTotale += (p['prix_a_paye'] as num? ?? 0).toDouble();
      }

      // Récupération du patient (via Consultation ou prescription)
      final patientMap = getPatientFromPaiement(p);
      if (patientMap != null) {
        final patientId = p['Consultation']?['id_patient']?.toString()
            ?? p['prescription']?['id_patient']?.toString()
            ?? '';

        if (patientId.isNotEmpty && !patientsUniques.contains(patientId)) {
          patientsUniques.add(patientId);
          final sexe = (patientMap['sexe'] ?? '').toString().toLowerCase();
          if (sexe == 'masculin' || sexe == 'm' || sexe == 'homme') {
            hommes++;
          } else if (sexe == 'feminin' || sexe == 'f' || sexe == 'femme') {
            femmes++;
          }
        }
      }
    }

    return {
      'nombre_transactions': paiements.length,
      'nombre_patients': patientsUniques.length,
      'somme_generee': sommeTotale.toInt(),
      'hommes': hommes,
      'femmes': femmes,
      'paiements': paiements,
    };
  }

  /// Extrait le Patient depuis un enregistrement paiement, quel que soit le chemin.
  static Map<String, dynamic>? getPatientFromPaiement(
      Map<String, dynamic> paiement) {
    final consultation = paiement['Consultation'];
    if (consultation is Map && consultation['Patient'] is Map) {
      return Map<String, dynamic>.from(consultation['Patient']);
    }
    final prescription = paiement['prescription'];
    if (prescription is Map && prescription['Patient'] is Map) {
      return Map<String, dynamic>.from(prescription['Patient']);
    }
    return null;
  }

  /// Retourne la date à afficher pour un paiement.
  static DateTime getPaiementDate(Map<String, dynamic> paiement) {
    final dateStr = paiement['date_paiement']
        ?? paiement['Consultation']?['date_enregistrement'];
    if (dateStr != null) {
      try {
        return DateTime.parse(dateStr.toString());
      } catch (_) {}
    }
    return DateTime.now();
  }

  /// Retourne l'id_consultation sous forme de String si disponible.
  static String? getIdConsultation(Map<String, dynamic> paiement) {
    return paiement['Consultation']?['id_consultation']?.toString()
        ?? paiement['id_consultation']?.toString();
  }

  // --- Raccourcis temporels ---

  Future<Map<String, dynamic>> getStatsToday({
    String statutPaiement = 'tous',
  }) async {
    final now = DateTime.now();
    return await getStatsByPeriod(
      dateDebut: DateTime(now.year, now.month, now.day, 0, 0, 0),
      dateFin: DateTime(now.year, now.month, now.day, 23, 59, 59),
      statutPaiement: statutPaiement,
    );
  }

  Future<Map<String, dynamic>> getStatsThisWeek({
    String statutPaiement = 'tous',
  }) async {
    final now = DateTime.now();
    final debut = now.subtract(Duration(days: now.weekday - 1));
    return await getStatsByPeriod(
      dateDebut: DateTime(debut.year, debut.month, debut.day, 0, 0, 0),
      dateFin: DateTime(now.year, now.month, now.day, 23, 59, 59),
      statutPaiement: statutPaiement,
    );
  }

  Future<Map<String, dynamic>> getStatsThisMonth({
    String statutPaiement = 'tous',
  }) async {
    final now = DateTime.now();
    return await getStatsByPeriod(
      dateDebut: DateTime(now.year, now.month, 1, 0, 0, 0),
      dateFin: DateTime(now.year, now.month, now.day, 23, 59, 59),
      statutPaiement: statutPaiement,
    );
  }
}
