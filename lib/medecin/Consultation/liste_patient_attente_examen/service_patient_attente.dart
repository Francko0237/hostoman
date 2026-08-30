import 'package:supabase_flutter/supabase_flutter.dart';

class ConsultationService {
  final SupabaseClient supabase;

  ConsultationService(this.supabase);

  /// 📋 Récupère les patients en attente de examen (qui ont payé)
  /// Filtre uniquement les patients assignés au médecin connecté
  Future<List<Map<String, dynamic>>> getPatientsEnAttente() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await supabase
        .from('Consultation')
        .select('''
          *,
          Patient(*),
          paiement(*),
          examen_a_effectuer!inner(*)
        ''')
        .or(
          'Statut_Consultation.eq.en-attente-examen,Statut_Consultation.eq.en-attente-resultat,Statut_Consultation.eq.resultat-disponible,Statut_Consultation.eq.Annuler',
        )
        .eq('id_utilisateur', userId)
        .order('date_enregistrement', ascending: true);

    // 🔄 Dédoublonnage robuste par id_consultation
    final Map<int, Map<String, dynamic>> uniqueConsultations = {};

    for (var item in response as List<dynamic>) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = int.tryParse(map['id_consultation'].toString()) ?? 0;

      // Extraction sécurisée de l'examen/des examens (Supabase peut renvoyer un Map ou une List)
      final dynamic rawExam = map['examen_a_effectuer'];
      final List<dynamic> currentExams = (rawExam is List)
          ? rawExam
          : (rawExam is Map ? [rawExam] : []);

      if (uniqueConsultations.containsKey(id)) {
        // Ajouter les nouveaux examens à la liste existante sans créer de couches supplémentaires
        final List<dynamic> list =
            uniqueConsultations[id]!['examen_a_effectuer'] as List<dynamic>;
        list.addAll(currentExams);
      } else {
        // Initialiser avec une copie de la liste pour éviter les effets de bord
        map['examen_a_effectuer'] = [...currentExams];

        // Filtrage métier : Si c'est en attente d'examen, on vérifie le paiement
        final statut = map['Statut_Consultation'];
        if (statut == 'en-attente-examen') {
          final paiements = map['paiement'] as List<dynamic>?;
          final aPaye =
              paiements != null &&
              paiements.any((p) => p['statut_paiement'] == 'payer');
          if (!aPaye) continue;
        }

        uniqueConsultations[id] = map;
      }
    }

    return uniqueConsultations.values.toList();
  }

  /// ✅ Commencer une consultation (Statut = 'En cours')
  Future<void> commencerConsultation(String idConsultation) async {
    await supabase
        .from('Consultation')
        .update({'Statut_Consultation': 'En cours'})
        .eq('id_consultation', idConsultation);
  }

  /// 🔄 Reporter une consultation (Statut = 'Reporter')
  Future<void> reporterConsultation(String idConsultation) async {
    await supabase
        .from('Consultation')
        .update({'Statut_Consultation': 'Reporter'})
        .eq('id_consultation', idConsultation);
  }

  /// ❌ Annuler une consultation (Statut = 'Annuler')
  Future<void> annulerConsultation(String idConsultation) async {
    await supabase
        .from('Consultation')
        .update({'Statut_Consultation': 'Annuler'})
        .eq('id_consultation', idConsultation);
  }
}
