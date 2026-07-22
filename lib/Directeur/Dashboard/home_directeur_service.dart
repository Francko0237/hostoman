import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

/// Service centralisant les KPI temps réel pour la page d'accueil du Directeur.
/// Toutes les requêtes attaquent directement Supabase.
class HomeDirecteurService {
  final SupabaseClient supabase;
  HomeDirecteurService(this.supabase);

  // ===================== UTILS =====================
  Map<String, String> _dayRange(DateTime d) {
    final start = DateTime(d.year, d.month, d.day).toIso8601String();
    final end = DateTime(d.year, d.month, d.day, 23, 59, 59).toIso8601String();
    return {'start': start, 'end': end};
  }

  // ===================== ADMIN PROFIL =====================
  Future<Map<String, dynamic>> getAdminProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return {};
      final data = await supabase
          .from('Personnel_hopital')
          .select('Nom, Prenom, email, Specialite, sexe')
          .eq('id_personnel', user.id)
          .maybeSingle();
      return data ?? {};
    } catch (_) {
      return {};
    }
  }

  // ===================== KPI DU JOUR =====================
  Future<Map<String, dynamic>> getTodayKpis() async {
    final today = DateTime.now();
    final range = _dayRange(today);

    try {
      // 1) Revenu du jour
      final paiementsJour = await supabase
          .from('paiement')
          .select('prix_a_paye')
          .eq('statut_paiement', 'payer')
          .gte('date_paiement', range['start']!)
          .lte('date_paiement', range['end']!);
      double revenuJour = 0;
      for (var p in paiementsJour) {
        revenuJour += (p['prix_a_paye'] as num).toDouble();
      }

      // 2) Patients admis aujourd'hui
      final patientsJour = await supabase
          .from('Patient')
          .select('id_patient')
          .gte('date_enregistrement', range['start']!)
          .lte('date_enregistrement', range['end']!)
          .count(CountOption.exact);

      // 3) Consultations en cours (tous les statuts actifs)
      final consultationsEnCours = await supabase
          .from('Consultation')
          .select('id_consultation')
          .or(
            'Statut_Consultation.eq.En cours,Statut_Consultation.eq.en-attente-examen,Statut_Consultation.eq.en-attente-resultat,Statut_Consultation.eq.resultat-disponible',
          )
          .count(CountOption.exact);

      // 4) Consultations terminées aujourd'hui
      final consultationsFinies = await supabase
          .from('Consultation')
          .select('id_consultation')
          .eq('Statut_Consultation', 'terminer')
          .gte('date_derniere_mise_ajour', range['start']!)
          .lte('date_derniere_mise_ajour', range['end']!)
          .count(CountOption.exact);

      // 5) Personnel total
      final personnelTotal = await supabase
          .from('Personnel_hopital')
          .select('id_personnel')
          .count(CountOption.exact);

      // 6) Paiements en attente
      final paiementsAttente = await supabase
          .from('paiement')
          .select('id_paiement')
          .eq('statut_paiement', 'en_attente')
          .count(CountOption.exact);

      // 7) Patients en attente au labo (distinct par consultation)
      final examensAttenteRaw = await supabase
          .from('examen_a_effectuer')
          .select('id_consultation')
          .eq('statut_examen', 'en attente');
      final patientsAttenteExam = (examensAttenteRaw as List)
          .map((e) => e['id_consultation'])
          .toSet()
          .length;

      // 8) Patients en attente de consultation
      final patientsAttenteConsult = await supabase
          .from('Consultation')
          .select('id_consultation')
          .eq('Statut_Consultation', 'en-attente-consultation')
          .count(CountOption.exact);

      // ── Pharmacie (non-fatal si table absente) ──────────────────────────
      int stockRupture = 0, stockBas = 0, lotsPerimes = 0;
      try {
        final ruptureRes = await supabase
            .from('listemedicament')
            .select('id_medicament')
            .eq('actif', true)
            .eq('stock', 0)
            .count(CountOption.exact);
        stockRupture = ruptureRes.count;

        final stockBasList = await supabase
            .from('listemedicament')
            .select('stock, seuil_alerte')
            .eq('actif', true)
            .gt('stock', 0);
        stockBas = (stockBasList as List).where((m) {
          final s = (m['stock'] as num?)?.toInt() ?? 0;
          final a = (m['seuil_alerte'] as num?)?.toInt() ?? 0;
          return s <= a;
        }).length;

        final todayStr = DateTime.now().toIso8601String().split('T').first;
        final lotsPerimesRaw = await supabase
            .from('stock_entree')
            .select('id_medicament')
            .not('date_peremption', 'is', null)
            .lt('date_peremption', todayStr);
        lotsPerimes = (lotsPerimesRaw as List)
            .map((e) => e['id_medicament'])
            .toSet()
            .length;
      } catch (_) {}

      return {
        'revenuJour': revenuJour,
        'nbTransactionsJour': paiementsJour.length,
        'patientsJour': patientsJour.count,
        'consultationsEnCours': consultationsEnCours.count,
        'consultationsFinies': consultationsFinies.count,
        'personnelTotal': personnelTotal.count,
        'paiementsAttente': paiementsAttente.count,
        'examensAttente': patientsAttenteExam,
        'patientsAttenteConsult': patientsAttenteConsult.count,
        'stockRupture': stockRupture,
        'stockBas': stockBas,
        'lotsPerimes': lotsPerimes,
      };
    } catch (_) {
      return {
        'revenuJour': 0.0,
        'nbTransactionsJour': 0,
        'patientsJour': 0,
        'consultationsEnCours': 0,
        'consultationsFinies': 0,
        'personnelTotal': 0,
        'paiementsAttente': 0,
        'examensAttente': 0,
        'patientsAttenteConsult': 0,
        'stockRupture': 0,
        'stockBas': 0,
        'lotsPerimes': 0,
      };
    }
  }

  // ===================== ACTIVITÉ 7 DERNIERS JOURS =====================
  Future<List<Map<String, dynamic>>> getWeeklyActivity() async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> activity = [];
    try {
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final range = _dayRange(date);
        final label = DateFormat('E', 'fr_FR').format(date);

        final consult = await supabase
            .from('Consultation')
            .select('id_consultation')
            .gte('date_enregistrement', range['start']!)
            .lte('date_enregistrement', range['end']!)
            .count(CountOption.exact);

        final patients = await supabase
            .from('Patient')
            .select('id_patient')
            .gte('date_enregistrement', range['start']!)
            .lte('date_enregistrement', range['end']!)
            .count(CountOption.exact);

        activity.add({
          'day': label,
          'date': DateFormat('dd/MM').format(date),
          'consultations': consult.count,
          'patients': patients.count,
        });
      }
      return activity;
    } catch (_) {
      return [];
    }
  }

  // ===================== TOP SPÉCIALITÉS PERSONNEL =====================
  Future<List<Map<String, dynamic>>> getStaffBySpecialite() async {
    try {
      final response = await supabase
          .from('Personnel_hopital')
          .select('Specialite');
      final Map<String, int> map = {};
      for (var p in response) {
        final s = p['Specialite']?.toString() ?? 'Autre';
        map[s] = (map[s] ?? 0) + 1;
      }
      final entries = map.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return entries
          .map((e) => {'specialite': e.key, 'count': e.value})
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ===================== TOUT D'UN COUP =====================
  Future<Map<String, dynamic>> getDashboardData() async {
    final results = await Future.wait([
      getAdminProfile(),
      getTodayKpis(),
      getWeeklyActivity(),
      getStaffBySpecialite(),
    ]);
    return {
      'admin': results[0],
      'kpis': results[1],
      'activity': results[2],
      'staff': results[3],
    };
  }
}
