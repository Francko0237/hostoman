import 'package:supabase_flutter/supabase_flutter.dart';
import '../../medecin/Consultation/champs_config/champ_config_model.dart';

class AccueilChampsConfigService {
  final SupabaseClient supabase;
  static const String _table = 'accueil_champs_config';

  AccueilChampsConfigService(this.supabase);

  /// Récupère la config des champs pour un agent d'accueil.
  /// Insère les champs par défaut si aucune config n'existe.
  Future<List<ChampConfig>> getChampsConfig(String idPersonnel) async {
    try {
      final response = await supabase
          .from(_table)
          .select()
          .eq('id_personnel', idPersonnel)
          .eq('visible', true)
          .order('ordre', ascending: true);

      final list = (response as List<dynamic>)
          .map((e) => ChampConfig.fromMap(e as Map<String, dynamic>))
          .toList();

      if (list.isEmpty) {
        final defaults = _getDefaultConfigs(idPersonnel);
        final inserted = await supabase
            .from(_table)
            .insert(defaults.map((e) => e.toMap()).toList())
            .select();
        return (inserted as List<dynamic>)
            .map((e) => ChampConfig.fromMap(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.ordre.compareTo(b.ordre));
      }

      return list;
    } catch (e) {
      print('Erreur getChampsConfig (accueil): $e');
      return [];
    }
  }

  Future<void> saveChampsConfig(List<ChampConfig> configs) async {
    for (final config in configs) {
      if (config.id != null) {
        await supabase
            .from(_table)
            .update(config.toMap())
            .eq('id', config.id!);
      } else {
        await supabase.from(_table).insert(config.toMap());
      }
    }
  }

  Future<void> deleteChampConfig(String id) async {
    await supabase.from(_table).delete().eq('id', id);
  }

  List<ChampConfig> _getDefaultConfigs(String idPersonnel) {
    return [
      ChampConfig(idPersonnel: idPersonnel, cle: 'nom_complet',       label: 'Nom complet',         type: 'alphanumerique', obligatoire: true,  hauteurLignes: 1, ordre: 1,  visible: true, isDefault: true, categorie: 'personnel'),
      ChampConfig(idPersonnel: idPersonnel, cle: 'age',                label: 'Âge',                 type: 'numerique',      obligatoire: true,  hauteurLignes: 1, ordre: 2,  visible: true, isDefault: true, categorie: 'personnel'),
      ChampConfig(idPersonnel: idPersonnel, cle: 'telephone',          label: 'Téléphone',           type: 'numerique',      obligatoire: true,  hauteurLignes: 1, ordre: 3,  visible: true, isDefault: true, categorie: 'personnel'),
      ChampConfig(idPersonnel: idPersonnel, cle: 'adresse',            label: 'Adresse',             type: 'alphanumerique', obligatoire: false, hauteurLignes: 1, ordre: 4,  visible: true, isDefault: true, categorie: 'personnel'),
      ChampConfig(idPersonnel: idPersonnel, cle: 'profession',         label: 'Profession',          type: 'alphanumerique', obligatoire: false, hauteurLignes: 1, ordre: 5,  visible: true, isDefault: true, categorie: 'personnel'),
      ChampConfig(idPersonnel: idPersonnel, cle: 'temperature',        label: 'Température (°C)',    type: 'numerique',      obligatoire: false, hauteurLignes: 1, ordre: 6,  visible: true, isDefault: true, categorie: 'medical'),
      ChampConfig(idPersonnel: idPersonnel, cle: 'poids',              label: 'Poids (kg)',          type: 'numerique',      obligatoire: false, hauteurLignes: 1, ordre: 7,  visible: true, isDefault: true, categorie: 'medical'),
      ChampConfig(idPersonnel: idPersonnel, cle: 'tension_systolique', label: 'Tension Systolique',  type: 'numerique',      obligatoire: false, hauteurLignes: 1, ordre: 8,  visible: true, isDefault: true, categorie: 'medical'),
      ChampConfig(idPersonnel: idPersonnel, cle: 'tension_diastolique',label: 'Tension Diastolique', type: 'numerique',      obligatoire: false, hauteurLignes: 1, ordre: 9,  visible: true, isDefault: true, categorie: 'medical'),
      ChampConfig(idPersonnel: idPersonnel, cle: 'test_vih',           label: 'Test VIH',            type: 'alphanumerique', obligatoire: false, hauteurLignes: 1, ordre: 10, visible: true, isDefault: true, categorie: 'medical'),
      ChampConfig(idPersonnel: idPersonnel, cle: 'vaccination',        label: 'Vaccination',         type: 'alphanumerique', obligatoire: false, hauteurLignes: 1, ordre: 11, visible: true, isDefault: true, categorie: 'medical'),
      ChampConfig(idPersonnel: idPersonnel, cle: 'motif_consultation', label: 'Motif de consultation', type: 'alphanumerique', obligatoire: true, hauteurLignes: 3, ordre: 12, visible: true, isDefault: true, categorie: 'medical'),
    ];
  }
}
