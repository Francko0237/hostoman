import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:hostoman/shared/user_profile_helper.dart';

class StatsService {
  final SupabaseClient supabase;

  StatsService(this.supabase);

  /// Normalise un nom: minuscule, trim, espaces multiples -> simples
  String _normalizeName(dynamic v) {
    return (v ?? '').toString().toLowerCase().trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
  }

  /// Clé d'identité patient: téléphone si dispo, sinon nom normalisé
  String _patientIdentityKey(Map<String, dynamic> p) {
    final tel = (p['telephone'] ?? '').toString().trim();
    if (tel.isNotEmpty && tel != '0' && tel != 'null') return 'tel:$tel';
    return 'nom:${_normalizeName(p['nom_complet'])}';
  }

  /// 📊 Récupère les stats globales (Total)
  Future<Map<String, dynamic>> getGlobalStats() async {
    final hid = await UserProfileHelper.getHospitalId();
    try {
      // 1. Revenu Total (Somme des paiements validés)
      var qPaiement = supabase
          .from('paiement')
          .select('prix_a_paye')
          .eq('statut_paiement', 'payer');
      if (hid != null) qPaiement = qPaiement.eq('id_hopital', hid);
      final revenuResponse = await qPaiement;

      double revenuTotal = 0;
      for (var p in revenuResponse) {
        revenuTotal += (p['prix_a_paye'] as num).toDouble();
      }

      // 2. Total Patients (patients uniques par téléphone + nom normalisé)
      var qPatient = supabase
          .from('Patient')
          .select('id_patient, nom_complet, telephone');
      if (hid != null) qPatient = qPatient.eq('id_hopital', hid);
      final patientsResponse = await qPatient;

      // Map id_patient -> clé d'identité unique
      final identityById = <String, String>{};
      for (var p in patientsResponse) {
        identityById[p['id_patient'].toString()] = _patientIdentityKey(p);
      }
      final totalPatients = identityById.values.toSet().length;

      // 3. Total Consultations (une seule par identité patient + date)
      var qConsult = supabase
          .from('Consultation')
          .select('id_patient, date_enregistrement');
      if (hid != null) qConsult = qConsult.eq('id_hopital', hid);
      final consultationsResponse = await qConsult;

      final uniqueConsults = <String>{};
      for (var c in consultationsResponse) {
        final identity =
            identityById[c['id_patient'].toString()] ?? 'id:${c['id_patient']}';
        final date = (c['date_enregistrement'] ?? '').toString();
        final dateOnly = date.length >= 10 ? date.substring(0, 10) : date;
        uniqueConsults.add('$identity|$dateOnly');
      }
      final totalConsultations = uniqueConsults.length;

      return {
        'revenu': revenuTotal,
        'patients': totalPatients,
        'consultations': totalConsultations,
      };
    } catch (e) {
      print('Erreur Global Stats: $e');
      return {'revenu': 0.0, 'patients': 0, 'consultations': 0};
    }
  }

  /// � Vue d'ensemble pour une plage de dates [start, end] (inclus).
  /// Retourne :
  ///   - revenu: somme des paiements 'payer' dans la plage
  ///   - patients: nb patients uniques (par identité) enregistrés dans la plage
  ///   - consultations: nb consultations dans la plage (uniques par identité+date)
  ///   - dailyActivity: liste {day, fullDate, count} pour le graphe
  ///   - operationalStats: {terminer, en attente, annuler} dans la plage
  Future<Map<String, dynamic>> getOverviewForRange({
    required DateTime start,
    required DateTime end,
    String localeTag = 'fr_FR',
  }) async {
    final hid = await UserProfileHelper.getHospitalId();
    try {
      final startIso = DateTime(
        start.year,
        start.month,
        start.day,
      ).toIso8601String();
      final endIso = DateTime(
        end.year,
        end.month,
        end.day,
        23,
        59,
        59,
      ).toIso8601String();

      // 1. Map id_patient -> identité (téléphone+nom)
      var qPatient = supabase
          .from('Patient')
          .select('id_patient, nom_complet, telephone, date_enregistrement');
      if (hid != null) qPatient = qPatient.eq('id_hopital', hid);
      final allPatients = await qPatient;

      final identityById = <String, String>{};
      for (var p in allPatients) {
        identityById[p['id_patient'].toString()] = _patientIdentityKey(p);
      }

      // 2. Patients uniques enregistrés DANS la plage
      final patientsInRange = allPatients.where((p) {
        final d = (p['date_enregistrement'] ?? '').toString();
        if (d.isEmpty) return false;
        final dt = DateTime.tryParse(d);
        if (dt == null) return false;
        return !dt.isBefore(DateTime(start.year, start.month, start.day)) &&
            !dt.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59));
      }).toList();
      final uniquePatientsInRange = patientsInRange
          .map((p) => _patientIdentityKey(p))
          .toSet()
          .length;

      // 3. Consultations dans la plage
      var qConsult = supabase
          .from('Consultation')
          .select('id_patient, date_enregistrement, Statut_Consultation')
          .gte('date_enregistrement', startIso)
          .lte('date_enregistrement', endIso);
      if (hid != null) qConsult = qConsult.eq('id_hopital', hid);
      final consultationsRaw = await qConsult;

      final uniqueConsults = <String>{};
      int finished = 0, ongoing = 0, cancelled = 0;
      for (var c in consultationsRaw) {
        final identity =
            identityById[c['id_patient'].toString()] ?? 'id:${c['id_patient']}';
        final date = (c['date_enregistrement'] ?? '').toString();
        final dateOnly = date.length >= 10 ? date.substring(0, 10) : date;
        uniqueConsults.add('$identity|$dateOnly');

        final status = (c['Statut_Consultation'] ?? '').toString();
        if (status == 'terminer') {
          finished++;
        } else if (status == 'annuler') {
          cancelled++;
        } else if (status.contains('attente') || status == 'En cours') {
          ongoing++;
        }
      }

      // 4. Revenu sur la période
      var qPaiement = supabase
          .from('paiement')
          .select('prix_a_paye, date_paiement')
          .eq('statut_paiement', 'payer')
          .gte('date_paiement', startIso)
          .lte('date_paiement', endIso);
      if (hid != null) qPaiement = qPaiement.eq('id_hopital', hid);
      final paiementsRaw = await qPaiement;
      double revenuPeriode = 0;
      for (var p in paiementsRaw) {
        revenuPeriode += (p['prix_a_paye'] as num).toDouble();
      }

      // 5. Activité quotidienne (consultations uniques par identité par jour)
      final daysCount = end.difference(start).inDays + 1;
      final dayFmt = daysCount <= 7 ? 'EEE' : 'dd/MM';
      final List<Map<String, dynamic>> dailyActivity = [];

      // Indexer les consultations par jour pour éviter N requêtes
      final consultsByDay = <String, Set<String>>{};
      for (var c in consultationsRaw) {
        final date = (c['date_enregistrement'] ?? '').toString();
        if (date.length < 10) continue;
        final dayKey = date.substring(0, 10); // YYYY-MM-DD
        final identity =
            identityById[c['id_patient'].toString()] ?? 'id:${c['id_patient']}';
        consultsByDay.putIfAbsent(dayKey, () => <String>{}).add(identity);
      }

      for (int i = 0; i < daysCount; i++) {
        final date = DateTime(
          start.year,
          start.month,
          start.day,
        ).add(Duration(days: i));
        final dayKey =
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyActivity.add({
          'day': DateFormat(dayFmt, localeTag).format(date),
          'fullDate': DateFormat('dd/MM', localeTag).format(date),
          'count': (consultsByDay[dayKey]?.length ?? 0),
        });
      }

      return {
        'revenu': revenuPeriode,
        'patients': uniquePatientsInRange,
        'consultations': uniqueConsults.length,
        'dailyActivity': dailyActivity,
        'operationalStats': {
          'terminer': finished,
          'en attente': ongoing,
          'annuler': cancelled,
        },
      };
    } catch (e) {
      print('Erreur Overview Range: $e');
      return {
        'revenu': 0.0,
        'patients': 0,
        'consultations': 0,
        'dailyActivity': <Map<String, dynamic>>[],
        'operationalStats': {'terminer': 0, 'en attente': 0, 'annuler': 0},
      };
    }
  }

  /// � Statistiques financières détaillées pour une plage [start, end].
  /// Retourne :
  ///   - totalRevenu : somme des paiements 'payer'
  ///   - nbPaiements : nombre de paiements 'payer'
  ///   - moyennePaiement : revenu moyen par paiement
  ///   - maxPaiement : paiement le plus élevé
  ///   - minPaiement : paiement le plus faible (>0)
  ///   - revenuMoyenJour : revenu moyen quotidien sur la période
  ///   - nbEnAttente : nb paiements en attente
  ///   - montantEnAttente : montant total en attente
  ///   - meilleurJour : {date, montant} le jour le plus rentable
  ///   - dailyTrend : liste {date, fullDate, amount} pour le graphe
  Future<Map<String, dynamic>> getFinanceForRange({
    required DateTime start,
    required DateTime end,
    String localeTag = 'fr_FR',
  }) async {
    final hid = await UserProfileHelper.getHospitalId();
    try {
      final startIso = DateTime(
        start.year,
        start.month,
        start.day,
      ).toIso8601String();
      final endIso = DateTime(
        end.year,
        end.month,
        end.day,
        23,
        59,
        59,
      ).toIso8601String();

      // Tous les paiements de la période
      var qPaiement = supabase
          .from('paiement')
          .select('prix_a_paye, statut_paiement, date_paiement')
          .gte('date_paiement', startIso)
          .lte('date_paiement', endIso);
      if (hid != null) qPaiement = qPaiement.eq('id_hopital', hid);
      final paiements = await qPaiement;

      double totalRevenu = 0;
      double montantEnAttente = 0;
      int nbPaiements = 0;
      int nbEnAttente = 0;
      double maxPaiement = 0;
      double minPaiement = double.infinity;

      // Agrégation par jour pour le graphe et "meilleur jour"
      final byDay = <String, double>{};

      for (var p in paiements) {
        final montant = (p['prix_a_paye'] as num).toDouble();
        final statut = (p['statut_paiement'] ?? '').toString();
        final date = (p['date_paiement'] ?? '').toString();
        if (statut == 'payer') {
          totalRevenu += montant;
          nbPaiements++;
          if (montant > maxPaiement) maxPaiement = montant;
          if (montant > 0 && montant < minPaiement) minPaiement = montant;
          if (date.length >= 10) {
            final dayKey = date.substring(0, 10);
            byDay[dayKey] = (byDay[dayKey] ?? 0) + montant;
          }
        } else {
          // En attente / non paye
          montantEnAttente += montant;
          nbEnAttente++;
        }
      }
      if (minPaiement == double.infinity) minPaiement = 0;

      final daysCount = end.difference(start).inDays + 1;
      final dayFmt = daysCount <= 7 ? 'EEE dd/MM' : 'dd/MM';

      // Construire le trend journalier complet (jours sans paiement = 0)
      final List<Map<String, dynamic>> dailyTrend = [];
      String? meilleurJourKey;
      double meilleurMontant = 0;
      for (int i = 0; i < daysCount; i++) {
        final d = DateTime(
          start.year,
          start.month,
          start.day,
        ).add(Duration(days: i));
        final dayKey =
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        final amount = byDay[dayKey] ?? 0;
        if (amount > meilleurMontant) {
          meilleurMontant = amount;
          meilleurJourKey = dayKey;
        }
        dailyTrend.add({
          'date': DateFormat(dayFmt, localeTag).format(d),
          'fullDate': DateFormat('dd MMM yyyy', localeTag).format(d),
          'amount': amount,
        });
      }

      final revenuMoyenJour = daysCount > 0 ? totalRevenu / daysCount : 0;
      final moyennePaiement = nbPaiements > 0 ? totalRevenu / nbPaiements : 0;

      String meilleurJourLabel = '-';
      if (meilleurJourKey != null) {
        final parts = meilleurJourKey.split('-');
        final dt = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        meilleurJourLabel = DateFormat('dd MMM yyyy', localeTag).format(dt);
      }

      return {
        'totalRevenu': totalRevenu,
        'nbPaiements': nbPaiements,
        'moyennePaiement': moyennePaiement,
        'maxPaiement': maxPaiement,
        'minPaiement': minPaiement,
        'revenuMoyenJour': revenuMoyenJour,
        'nbEnAttente': nbEnAttente,
        'montantEnAttente': montantEnAttente,
        'meilleurJour': {'date': meilleurJourLabel, 'montant': meilleurMontant},
        'dailyTrend': dailyTrend,
      };
    } catch (e) {
      print('Erreur Finance Range: $e');
      return {
        'totalRevenu': 0.0,
        'nbPaiements': 0,
        'moyennePaiement': 0.0,
        'maxPaiement': 0.0,
        'minPaiement': 0.0,
        'revenuMoyenJour': 0.0,
        'nbEnAttente': 0,
        'montantEnAttente': 0.0,
        'meilleurJour': {'date': '-', 'montant': 0.0},
        'dailyTrend': <Map<String, dynamic>>[],
      };
    }
  }

  /// � Récupère l'activité des N derniers jours pour le graphe
  /// [localeTag] : ex. 'fr_FR' ou 'en_US' pour traduire les noms de jours
  /// [days] : nombre de jours à afficher (défaut 7)
  Future<List<Map<String, dynamic>>> getDailyActivity({
    String localeTag = 'fr_FR',
    int days = 7,
  }) async {
    try {
      final now = DateTime.now();
      final List<Map<String, dynamic>> activity = [];

      // Récupérer la map id_patient -> identité pour dédupliquer correctement
      final patientsResponse = await supabase
          .from('Patient')
          .select('id_patient, nom_complet, telephone');
      final identityById = <String, String>{};
      for (var p in patientsResponse) {
        identityById[p['id_patient'].toString()] = _patientIdentityKey(p);
      }

      // Format adapte: 'EEE' pour <=7 jours, 'dd/MM' pour plus
      final dayFmt = days <= 7 ? 'EEE' : 'dd/MM';

      for (int i = days - 1; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(
          date.year,
          date.month,
          date.day,
        ).toIso8601String();
        final endOfDay = DateTime(
          date.year,
          date.month,
          date.day,
          23,
          59,
          59,
        ).toIso8601String();
        final dayLabel = DateFormat(dayFmt, localeTag).format(date);
        final fullDate = DateFormat('dd/MM', localeTag).format(date);

        // Compter les consultations uniques par identité patient pour ce jour
        final dayConsults = await supabase
            .from('Consultation')
            .select('id_patient')
            .gte('date_enregistrement', startOfDay)
            .lte('date_enregistrement', endOfDay);

        final uniqueForDay = dayConsults
            .map(
              (c) =>
                  identityById[c['id_patient'].toString()] ??
                  c['id_patient'].toString(),
            )
            .toSet()
            .length;

        activity.add({
          'day': dayLabel,
          'fullDate': fullDate,
          'count': uniqueForDay,
        });
      }
      return activity;
    } catch (e) {
      print('Erreur Daily Activity: $e');
      return [];
    }
  }

  /// 🚻 Récupère la démographie des patients uniques (Sexe et Âge)
  Future<Map<String, dynamic>> getDemographics() async {
    final hid = await UserProfileHelper.getHospitalId();
    try {
      var qPatient = supabase
          .from('Patient')
          .select('nom_complet, telephone, sexe, age');
      if (hid != null) qPatient = qPatient.eq('id_hopital', hid);
      final response = await qPatient.limit(10000);

      // Dédupliquer par téléphone + nom normalisé
      final seen = <String>{};
      final uniquePatients = <Map<String, dynamic>>[];
      for (var p in response) {
        final key = _patientIdentityKey(p);
        if (key.isNotEmpty && seen.add(key)) {
          uniquePatients.add(p);
        }
      }

      int male = 0;
      int female = 0;
      Map<String, int> ageRanges = {
        '0-18': 0,
        '19-35': 0,
        '36-60': 0,
        '60+': 0,
      };

      for (var p in uniquePatients) {
        // Sexe (la DB stocke 'Homme'/'Femme', mais on tolère aussi 'M'/'F')
        final sexe = (p['sexe'] ?? '').toString().toLowerCase().trim();
        if (sexe == 'homme' || sexe == 'm' || sexe == 'masculin') {
          male++;
        } else if (sexe == 'femme' ||
            sexe == 'f' ||
            sexe == 'féminin' ||
            sexe == 'feminin') {
          female++;
        }

        // Âge
        int age = int.tryParse(p['age'].toString()) ?? 0;
        if (age <= 18) {
          ageRanges['0-18'] = ageRanges['0-18']! + 1;
        } else if (age <= 35) {
          ageRanges['19-35'] = ageRanges['19-35']! + 1;
        } else if (age <= 60) {
          ageRanges['36-60'] = ageRanges['36-60']! + 1;
        } else {
          ageRanges['60+'] = ageRanges['60+']! + 1;
        }
      }

      return {
        'gender': {'M': male, 'F': female},
        'ageRanges': ageRanges,
      };
    } catch (e) {
      print('Erreur Demographics: $e');
      return {
        'gender': {'M': 0, 'F': 0},
        'ageRanges': {'0-18': 0, '19-35': 0, '36-60': 0, '60+': 0},
      };
    }
  }

  /// 🏥 Récupère les stats opérationnelles (États des consultations)
  Future<Map<String, int>> getOperationalStats() async {
    final hid = await UserProfileHelper.getHospitalId();
    try {
      var qConsult = supabase
          .from('Consultation')
          .select('Statut_Consultation');
      if (hid != null) qConsult = qConsult.eq('id_hopital', hid);
      final response = await qConsult;

      Map<String, int> stats = {'terminer': 0, 'en attente': 0, 'annuler': 0};

      for (var c in response) {
        String status = c['Statut_Consultation'] ?? 'en attente';
        if (status.contains('attente')) {
          stats['en attente'] = stats['en attente']! + 1;
        } else if (status == 'terminer')
          stats['terminer'] = stats['terminer']! + 1;
        else if (status == 'annuler')
          stats['annuler'] = stats['annuler']! + 1;
      }
      return stats;
    } catch (e) {
      print('Erreur Operational Stats: $e');
      return {'terminer': 0, 'en attente': 0, 'annuler': 0};
    }
  }

  /// 💰 Récupère le revenu détaillé (14 derniers jours pour meilleure lisibilité)
  Future<List<Map<String, dynamic>>> getRevenueTrend() async {
    final hid = await UserProfileHelper.getHospitalId();
    try {
      final now = DateTime.now();
      final List<Map<String, dynamic>> trend = [];

      for (int i = 13; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(
          date.year,
          date.month,
          date.day,
        ).toIso8601String();
        final endOfDay = DateTime(
          date.year,
          date.month,
          date.day,
          23,
          59,
          59,
        ).toIso8601String();

        var qPaiement = supabase
            .from('paiement')
            .select('prix_a_paye')
            .eq('statut_paiement', 'payer')
            .gte('date_paiement', startOfDay)
            .lte('date_paiement', endOfDay);
        if (hid != null) qPaiement = qPaiement.eq('id_hopital', hid);
        final response = await qPaiement;

        double dailyTotal = 0;
        for (var p in response) {
          dailyTotal += (p['prix_a_paye'] as num).toDouble();
        }

        trend.add({
          'date': DateFormat('dd/MM').format(date),
          'amount': dailyTotal,
        });
      }
      return trend;
    } catch (e) {
      print('Erreur Revenue Trend: $e');
      return [];
    }
  }
}
