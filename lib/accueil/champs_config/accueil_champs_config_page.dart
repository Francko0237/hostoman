import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../medecin/Consultation/champs_config/champ_config_model.dart';
import 'accueil_champs_config_service.dart';

// Palette bleue (accueil)
const Color _primary = Color(0xFF1565C0);
const Color _accent  = Color(0xFF2196F3);
const Color _bgPage  = Color(0xFFF4F7FB);
const Color _textDark = Color(0xFF1A1A2E);
const Color _textMuted = Color(0xFF64748B);

class AccueilChampsConfigPage extends StatefulWidget {
  const AccueilChampsConfigPage({super.key});

  @override
  State<AccueilChampsConfigPage> createState() => _AccueilChampsConfigPageState();
}

class _AccueilChampsConfigPageState extends State<AccueilChampsConfigPage> {
  late final AccueilChampsConfigService _service;
  bool _isLoading = true;
  List<ChampConfig> _configs = [];
  String? _idPersonnel;

  @override
  void initState() {
    super.initState();
    _service = AccueilChampsConfigService(Supabase.instance.client);
    _idPersonnel = Supabase.instance.client.auth.currentUser?.id;
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    if (_idPersonnel == null) return;
    setState(() => _isLoading = true);
    try {
      final data = await _service.getChampsConfig(_idPersonnel!);
      if (mounted) setState(() { _configs = data; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('champ_config_load_error'.tr(namedArgs: {'msg': '$e'})),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _saveOrder() async {
    for (int i = 0; i < _configs.length; i++) {
      _configs[i] = _configs[i].copyWith(ordre: i + 1);
    }
    try {
      await _service.saveChampsConfig(_configs);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('champ_config_order_save_error'.tr(namedArgs: {'msg': '$e'})),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _showAddEditDialog({ChampConfig? config}) {
    final isEdit = config != null;
    final labelCtrl = TextEditingController(text: config?.label);
    String selectedType = config?.type ?? 'alphanumerique';
    bool isObligatoire = config?.obligatoire ?? false;
    double hauteur = (config?.hauteurLignes ?? 1).toDouble();
    String selectedCategorie = config?.categorie ?? 'personnel';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isEdit ? 'champ_config_edit_title'.tr() : 'champ_config_add_title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, color: _textDark),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: labelCtrl,
                  decoration: InputDecoration(
                    labelText: 'champ_config_label_input'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('champ_config_type_label'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(children: [
                  Expanded(child: RadioListTile<String>(
                    title: Text('champ_config_type_alpha'.tr(), style: const TextStyle(fontSize: 13)),
                    value: 'alphanumerique',
                    groupValue: selectedType,
                    onChanged: (v) => setS(() => selectedType = v!),
                  )),
                  Expanded(child: RadioListTile<String>(
                    title: Text('champ_config_type_numeric'.tr(), style: const TextStyle(fontSize: 13)),
                    value: 'numerique',
                    groupValue: selectedType,
                    onChanged: (v) => setS(() => selectedType = v!),
                  )),
                ]),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: Text('champ_config_required_label'.tr(),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  value: isObligatoire,
                  activeColor: _primary,
                  onChanged: (v) => setS(() => isObligatoire = v),
                ),
                const SizedBox(height: 8),
                Text('champ_config_height_label'.tr(namedArgs: {'n': hauteur.toInt().toString()})),
                Slider(
                  value: hauteur, min: 1, max: 10, divisions: 9,
                  activeColor: _primary,
                  inactiveColor: Colors.grey.shade300,
                  onChanged: (v) => setS(() => hauteur = v),
                ),
                const SizedBox(height: 12),
                Text('champ_config_category_label'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategorie,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      items: [
                        DropdownMenuItem(
                          value: 'personnel',
                          child: Text('champ_config_category_personal'.tr()),
                        ),
                        DropdownMenuItem(
                          value: 'medical',
                          child: Text('champ_config_category_medical'.tr()),
                        ),
                      ],
                      onChanged: (v) => setS(() => selectedCategorie = v!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('champ_config_cancel'.tr(), style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final label = labelCtrl.text.trim();
                if (label.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('champ_config_label_empty_error'.tr())));
                  return;
                }
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  if (isEdit) {
                    await _service.saveChampsConfig([config.copyWith(
                      label: label, type: selectedType,
                      obligatoire: isObligatoire, hauteurLignes: hauteur.toInt(),
                      categorie: selectedCategorie,
                    )]);
                  } else {
                    final clean = label.toLowerCase()
                        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
                        .replaceAll(RegExp(r'_+'), '_');
                    await _service.saveChampsConfig([ChampConfig(
                      idPersonnel: _idPersonnel!,
                      cle: '${clean}_${DateTime.now().millisecondsSinceEpoch}',
                      label: label, type: selectedType,
                      obligatoire: isObligatoire, hauteurLignes: hauteur.toInt(),
                      ordre: _configs.length + 1, visible: true, isDefault: false,
                      categorie: selectedCategorie,
                    )]);
                  }
                  _loadConfig();
                } catch (e) {
                  setState(() => _isLoading = false);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('champ_config_save_error'.tr(namedArgs: {'msg': '$e'})),
                    backgroundColor: Colors.red,
                  ));
                }
              },
              child: Text('champ_config_save'.tr(), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteConfig(ChampConfig config) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('champ_config_delete_title'.tr()),
        content: Text('champ_config_delete_confirm'.tr(namedArgs: {'label': config.label})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text('champ_config_cancel'.tr(), style: const TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text('champ_config_delete'.tr(), style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      if (config.id != null) await _service.deleteChampConfig(config.id!);
      _loadConfig();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('champ_config_delete_error'.tr(namedArgs: {'msg': '$e'})),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('acc_champ_config_page_title'.tr(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            onPressed: () => _showAddEditDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _configs.isEmpty
              ? Center(child: Text('champ_config_empty'.tr()))
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _configs.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _configs.removeAt(oldIndex);
                      _configs.insert(newIndex, item);
                    });
                    _saveOrder();
                  },
                  itemBuilder: (context, index) {
                    final config = _configs[index];
                    final typeLabel = config.type == 'numerique'
                        ? 'champ_config_type_numeric_full'.tr()
                        : 'champ_config_type_alpha_full'.tr();
                    return Card(
                      key: ValueKey(config.id ?? config.cle),
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 1,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                        title: Row(children: [
                          Expanded(child: Text(config.label,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: _textDark))),
                          if (config.obligatoire)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.red.shade200, width: 0.5),
                              ),
                              child: Text('champ_config_obligatoire_badge'.tr(),
                                  style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ]),
                        subtitle: Text(
                          '${config.categorie == 'medical' ? 'champ_config_category_medical'.tr() : 'champ_config_category_personal'.tr()}\n'
                          '${'champ_config_card_subtitle'.tr(namedArgs: {
                            'type': typeLabel, 'n': config.hauteurLignes.toString(),
                          })}',
                          style: const TextStyle(color: _textMuted, fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: _accent, size: 20),
                              onPressed: () => _showAddEditDialog(config: config),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                              onPressed: () => _deleteConfig(config),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
