import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/model_unifier.dart';

class DetailPatientService {
  final SupabaseClient supabase;
  DetailPatientService(this.supabase);

  /// 🔍 Récupère un patient par son ID
  Future<Patient?> fetchPatientById(String idPatient) async {
    final response = await supabase
        .from('Patient')
        .select('*')
        .eq('id_patient', idPatient)
        .single();

    return Patient.fromMap(response);
      return null;
  }

  /// 📊 Récupère les paramètres vitaux du patient
  Future<List<Parametres_vitaux>> fetchParametresVitaux(
    String idPatient,
  ) async {
    final response = await supabase
        .from('Parametres_vitaux')
        .select('*')
        .eq('id_patient', idPatient)
        .order('date_enregistrement', ascending: false);

    return response.map((e) => Parametres_vitaux.fromMap(e)).toList();
    return [];
  }
}
