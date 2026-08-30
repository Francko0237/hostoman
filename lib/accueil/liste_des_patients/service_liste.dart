import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/model_unifier.dart';
import 'package:hostoman/shared/user_profile_helper.dart';

class PatientService {
  final SupabaseClient supabase;
  PatientService(this.supabase);

  /// 🔄 Méthode paginée : récupère les patients par page pour cet hôpital
  Future<List<Patient>> fetchPatientsPaginated({required int page, int pageSize = 10}) async {
    final start = page * pageSize;
    final end = start + pageSize - 1;
    final hid = await UserProfileHelper.getHospitalId();

    var query = supabase.from('Patient').select();
    if (hid != null) {
      query = query.eq('id_hopital', hid);
    }

    final response = await query
        .order('date_enregistrement', ascending: false)
        .range(start, end);
    return (response as List).map((e) => Patient.fromMap(e)).toList();
  }

  // Pour rechercher les patients par nom dans la BD pour cet hôpital
  Future<List<Patient>> searchPatientsByName(String queryStr) async {
    final hid = await UserProfileHelper.getHospitalId();

    var query = supabase
        .from('Patient')
        .select()
        .ilike('nom_complet', '%$queryStr%');
    if (hid != null) {
      query = query.eq('id_hopital', hid);
    }

    final response = await query.order('date_enregistrement', ascending: false);

    return (response as List).map((e) => Patient.fromMap(e)).toList();
  }

  //Supression des patients dans la BD

  Future<void> supprimerPatient(String idPatient) async {
  await supabase
      .from('Patient')
      .delete()
      .eq('id_patient', idPatient);
  }


}

