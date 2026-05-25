import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'listeexamen_service.dart';

// Couleurs (cohérentes avec Parametre.dart)
const Color _primaryColor = Color(0xFF212031);
const Color _accentColor = Color(0xFF4285F4);
const Color _background = Color(0xFFF5F3F3);
const Color _textDark = Color(0xFF1A1A2E);
const Color _textMuted = Color(0xFF64748B);

class GestionExamensPage extends StatefulWidget {
  const GestionExamensPage({super.key});

  @override
  State<GestionExamensPage> createState() => _GestionExamensPageState();
}

class _GestionExamensPageState extends State<GestionExamensPage> {
  late final ListeExamenService _service;
  late Future<List<Map<String, dynamic>>> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _service = ListeExamenService(Supabase.instance.client);
    _future = _service.getAll();
  }

  void _reload() {
    setState(() {
      _future = _service.getAll();
    });
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ExamenFormSheet(
        service: _service,
        existing: existing,
      ),
    );
    if (result == true) _reload();
  }

  Future<void> _confirmDelete(Map<String, dynamic> exam) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('labex_delete_title'.tr()),
        content: Text(
          'labex_delete_msg'.tr(
            namedArgs: {'nom': (exam['nom_examen'] ?? '').toString()},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('att_cancel_no'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('att_cancel_yes'.tr()),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.delete(exam['id_examlist'] as int);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('labex_deleted'.tr())),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('labex_error'.tr(namedArgs: {'msg': '$e'}))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'labex_title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'labex_add'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () => _openForm(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'labex_search_hint'.tr(),
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _accentColor),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _reload(),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _primaryColor),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'labex_error'
                              .tr(namedArgs: {'msg': '${snapshot.error}'}),
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  final all = snapshot.data ?? [];
                  final items = _search.isEmpty
                      ? all
                      : all
                          .where((e) => (e['nom_examen'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains(_search))
                          .toList();

                  if (items.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        Icon(Icons.science_outlined,
                            size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'labex_empty'.tr(),
                            style: const TextStyle(
                              color: _textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final e = items[i];
                      final nom = (e['nom_examen'] ?? '').toString();
                      final prix = (e['prix_examen'] as num?)?.toDouble() ?? 0;
                      return _ExamenTile(
                        nom: nom,
                        prix: prix,
                        onEdit: () => _openForm(existing: e),
                        onDelete: () => _confirmDelete(e),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamenTile extends StatelessWidget {
  final String nom;
  final double prix;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExamenTile({
    required this.nom,
    required this.prix,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.biotech_rounded, color: _primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'labex_price_fmt'.tr(
                        namedArgs: {'prix': prix.toStringAsFixed(0)},
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'labex_edit'.tr(),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, color: _accentColor),
              ),
              IconButton(
                tooltip: 'labex_delete'.tr(),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamenFormSheet extends StatefulWidget {
  final ListeExamenService service;
  final Map<String, dynamic>? existing;

  const _ExamenFormSheet({required this.service, this.existing});

  @override
  State<_ExamenFormSheet> createState() => _ExamenFormSheetState();
}

class _ExamenFormSheetState extends State<_ExamenFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomCtrl;
  late final TextEditingController _prixCtrl;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(
      text: widget.existing?['nom_examen']?.toString() ?? '',
    );
    final p = (widget.existing?['prix_examen'] as num?)?.toDouble();
    _prixCtrl = TextEditingController(
      text: p == null ? '' : p.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prixCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final nom = _nomCtrl.text.trim();
      final prix = double.parse(_prixCtrl.text.trim().replaceAll(',', '.'));
      if (_isEdit) {
        await widget.service.update(
          idExamlist: widget.existing!['id_examlist'] as int,
          nom: nom,
          prix: prix,
        );
      } else {
        await widget.service.create(nom: nom, prix: prix);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'labex_updated'.tr() : 'labex_created'.tr()),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('labex_error'.tr(namedArgs: {'msg': '$e'}))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _isEdit ? 'labex_edit_title'.tr() : 'labex_add_title'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _nomCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'labex_field_name'.tr(),
                prefixIcon: const Icon(Icons.biotech_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'labex_field_name_required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _prixCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: 'labex_field_price'.tr(),
                prefixIcon: const Icon(Icons.payments_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'labex_field_price_required'.tr();
                }
                final parsed =
                    double.tryParse(v.trim().replaceAll(',', '.'));
                if (parsed == null || parsed < 0) {
                  return 'labex_field_price_invalid'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  _isEdit ? 'labex_save'.tr() : 'labex_create'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
