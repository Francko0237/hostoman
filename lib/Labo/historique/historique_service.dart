import 'package:supabase_flutter/supabase_flutter.dart';

class HistoriqueLaboService {
  final SupabaseClient supabase;

  HistoriqueLaboService(this.supabase);

  /// 📋 Récupère les patients avec des examens terminés
  Future<List<Map<String, dynamic>>> getPatientsAvecExamensTermines() async {
    final response = await supabase
        .from('Consultation')
        .select('''
            *,
            Patient(*),
            examen_a_effectuer!inner(*)
        ''')
        .eq('examen_a_effectuer.statut_examen', 'Terminé')
        .order('date_enregistrement', ascending: false);

    // Dédoublonnage manuel car !inner peut ramener plusieurs lignes si plusieurs examens
    final uniqueList = <int, Map<String, dynamic>>{};
    for (var item in response as List<dynamic>) {
      final map = item as Map<String, dynamic>;
      uniqueList[map['id_consultation']] = map;
    }

    return uniqueList.values.toList();
  }
}
