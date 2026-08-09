import 'package:supabase_flutter/supabase_flutter.dart';
import 'champ_config_model.dart';

class ChampsConfigService {
  final SupabaseClient supabase;

  ChampsConfigService(this.supabase);

  /// 🔍 Récupère la configuration des champs pour un médecin.
  /// Si aucune config n'existe en base, insère les 5 champs par défaut.
  Future<List<ChampConfig>> getChampsConfig(String idPersonnel) async {
    try {
      final response = await supabase
          .from('medecin_champs_config')
          .select()
          .eq('id_personnel', idPersonnel)
          .eq('visible', true)
          .order('ordre', ascending: true);

      final list = (response as List<dynamic>)
          .map((e) => ChampConfig.fromMap(e as Map<String, dynamic>))
          .toList();

      if (list.isEmpty) {
        // Initialisation automatique en BD
        final defaults = _getDefaultConfigs(idPersonnel);
        final inserted = await supabase
            .from('medecin_champs_config')
            .insert(defaults.map((e) => e.toMap()).toList())
            .select();
        
        return (inserted as List<dynamic>)
            .map((e) => ChampConfig.fromMap(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.ordre.compareTo(b.ordre));
      }

      return list;
    } catch (e) {
      print('Erreur getChampsConfig: $e');
      return [];
    }
  }

  /// 💾 Sauvegarde ou met à jour la configuration complète (y compris la réorganisation)
  Future<void> saveChampsConfig(List<ChampConfig> configs) async {
    try {
      for (final config in configs) {
        if (config.id != null) {
          // Update
          await supabase
              .from('medecin_champs_config')
              .update(config.toMap())
              .eq('id', config.id!);
        } else {
          // Insert new
          await supabase
              .from('medecin_champs_config')
              .insert(config.toMap());
        }
      }
    } catch (e) {
      print('Erreur saveChampsConfig: $e');
      rethrow;
    }
  }

  /// ❌ Supprime un champ de la configuration
  Future<void> deleteChampConfig(String id) async {
    try {
      await supabase
          .from('medecin_champs_config')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Erreur deleteChampConfig: $e');
      rethrow;
    }
  }

  List<ChampConfig> _getDefaultConfigs(String idPersonnel) {
    return [
      ChampConfig(
        idPersonnel: idPersonnel,
        cle: 'antecedents',
        label: 'Antécédents',
        type: 'alphanumerique',
        obligatoire: true,
        hauteurLignes: 3,
        ordre: 1,
        visible: true,
        isDefault: true,
      ),
      ChampConfig(
        idPersonnel: idPersonnel,
        cle: 'signes_symptomes',
        label: 'Signes & Symptômes',
        type: 'alphanumerique',
        obligatoire: true,
        hauteurLignes: 3,
        ordre: 2,
        visible: true,
        isDefault: true,
      ),
      ChampConfig(
        idPersonnel: idPersonnel,
        cle: 'diagnostic_initial',
        label: 'Diagnostic Initial',
        type: 'alphanumerique',
        obligatoire: true,
        hauteurLignes: 3,
        ordre: 3,
        visible: true,
        isDefault: true,
      ),
      ChampConfig(
        idPersonnel: idPersonnel,
        cle: 'diagnostic_final',
        label: 'Diagnostic Final',
        type: 'alphanumerique',
        obligatoire: true,
        hauteurLignes: 3,
        ordre: 4,
        visible: true,
        isDefault: true,
      ),
      ChampConfig(
        idPersonnel: idPersonnel,
        cle: 'traitement_prescrit',
        label: 'Traitement Prescrit',
        type: 'alphanumerique',
        obligatoire: true,
        hauteurLignes: 3,
        ordre: 5,
        visible: true,
        isDefault: true,
      ),
    ];
  }
}
