import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Thème de couleurs partagé pour les pickers examens/médicaments.
class PickerTheme {
  final Color primary;
  final Color light;
  final Color fieldBg;
  final Color fieldBorder;
  final Color blue;

  const PickerTheme({
    required this.primary,
    required this.light,
    required this.fieldBg,
    required this.fieldBorder,
    required this.blue,
  });
}

// ============================================================================
// EXAMENS
// ============================================================================

/// Ouvre le picker des examens (catalogue + saisies libres).
/// Retourne la nouvelle liste si validé, `null` sinon.
Future<List<Map<String, dynamic>>?> showExamensPickerDialog({
  required BuildContext context,
  required List<Map<String, dynamic>> current,
  required PickerTheme theme,
}) async {
  final width = MediaQuery.of(context).size.width;
  final dialogWidth = width < 500 ? width * 0.92 : 460.0;

  final List<Map<String, dynamic>> working = current
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
  String search = '';

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final filtered = search.isEmpty
              ? working
              : working
                    .where(
                      (e) => (e['nom_examen'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(search),
                    )
                    .toList();
          final selectedCount = working
              .where((e) => e['selected'] == true)
              .length;
          final total = working
              .where((e) => e['selected'] == true)
              .fold<double>(
                0,
                (sum, e) =>
                    sum + ((e['prix_examen'] as num?)?.toDouble() ?? 0),
              );

          Future<void> openCustomExamDialog() async {
            final nomCtrl = TextEditingController();
            final prixCtrl = TextEditingController();
            final formKey = GlobalKey<FormState>();

            final added = await showDialog<bool>(
              context: ctx,
              builder: (ctx2) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                title: Text('fiche_exam_custom_title'.tr()),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nomCtrl,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: 'fiche_exam_field_name'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'fiche_field_required'.tr()
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: prixCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'fiche_exam_field_price'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) {
                            final n = double.tryParse(
                              (v ?? '').trim().replaceAll(',', '.'),
                            );
                            if (n == null || n < 0) {
                              return 'fiche_field_required'.tr();
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx2, false),
                    child: Text('att_cancel_no'.tr()),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(ctx2, true);
                      }
                    },
                    child: Text('fiche_exam_custom_add'.tr()),
                  ),
                ],
              ),
            );

            if (added == true) {
              final prix = double.parse(
                prixCtrl.text.trim().replaceAll(',', '.'),
              );
              setLocal(() {
                working.add({
                  'id_examlist': null,
                  'nom_examen': nomCtrl.text.trim(),
                  'prix_examen': prix,
                  'selected': true,
                  'is_custom': true,
                });
              });
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: dialogWidth,
                maxHeight: MediaQuery.of(ctx).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                    decoration: BoxDecoration(
                      color: theme.light,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.science_outlined,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'fiche_exams_modal_title'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          icon: const Icon(Icons.close, color: Colors.white),
                          tooltip: 'fiche_modal_close'.tr(),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setLocal(
                              () => search = v.trim().toLowerCase(),
                            ),
                            decoration: InputDecoration(
                              hintText: 'fiche_exams_search_hint'.tr(),
                              prefixIcon: const Icon(Icons.search),
                              isDense: true,
                              filled: true,
                              fillColor: theme.fieldBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: theme.fieldBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: theme.fieldBorder,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: openCustomExamDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: Text('fiche_exam_custom_btn'.tr()),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.primary,
                            side: BorderSide(color: theme.primary),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: working.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'fiche_exams_empty'.tr(),
                              style: const TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final examen = filtered[i];
                              final isSelected = examen['selected'] == true;
                              final isCustom = examen['is_custom'] == true;
                              return CheckboxListTile(
                                dense: true,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                activeColor: theme.primary,
                                value: isSelected,
                                onChanged: (v) {
                                  setLocal(() {
                                    examen['selected'] = v ?? false;
                                  });
                                },
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        (examen['nom_examen'] ?? '')
                                            .toString(),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (isCustom)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              theme.primary.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'fiche_exam_custom_badge'.tr(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: theme.primary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  'fiche_exam_price'.tr(
                                    namedArgs: {
                                      'price':
                                          '${examen['prix_examen'] ?? 0}',
                                    },
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                secondary: isCustom
                                    ? IconButton(
                                        tooltip:
                                            'fiche_exam_remove_custom'.tr(),
                                        onPressed: () => setLocal(() {
                                          working.remove(examen);
                                        }),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                        ),
                                      )
                                    : null,
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    decoration: BoxDecoration(
                      color: theme.fieldBg,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(18),
                      ),
                      border: Border(
                        top: BorderSide(color: theme.fieldBorder),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'fiche_exams_selected_count'.tr(
                                  namedArgs: {'count': '$selectedCount'},
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              'fiche_exams_total'.tr(
                                namedArgs: {
                                  'total': total.toStringAsFixed(0),
                                },
                              ),
                              style: TextStyle(
                                color: theme.blue,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text('att_cancel_no'.tr()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'fiche_exams_validate'.tr(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  return confirmed == true ? working : null;
}

// ============================================================================
// MÉDICAMENTS
// ============================================================================

/// Ouvre le picker des médicaments (catalogue + saisies libres).
/// Retourne la nouvelle liste si validé, `null` sinon.
Future<List<Map<String, dynamic>>?> showMedicamentsPickerDialog({
  required BuildContext context,
  required List<Map<String, dynamic>> current,
  required PickerTheme theme,
}) async {
  final width = MediaQuery.of(context).size.width;
  final dialogWidth = width < 500 ? width * 0.94 : 520.0;

  final List<Map<String, dynamic>> working = current
      .map((m) => Map<String, dynamic>.from(m))
      .toList();
  String search = '';

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final filtered = search.isEmpty
              ? working
              : working
                    .where(
                      (m) => (m['nom_medicament'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(search),
                    )
                    .toList();
          final selectedItems = working
              .where((m) => m['selected'] == true)
              .toList();
          final selectedCount = selectedItems.length;
          final total = selectedItems.fold<double>(0, (sum, m) {
            final p = (m['prix_unitaire'] as num?)?.toDouble() ?? 0;
            final q = (m['quantite'] as num?)?.toInt() ?? 1;
            return sum + p * q;
          });

          Future<void> openCustomDialog() async {
            final nomCtrl = TextEditingController();
            final qteCtrl = TextEditingController(text: '1');
            final posoCtrl = TextEditingController();
            final formKey = GlobalKey<FormState>();

            final added = await showDialog<bool>(
              context: ctx,
              builder: (ctx2) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                title: Text('fiche_med_custom_title'.tr()),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nomCtrl,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: 'fiche_med_field_name'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'fiche_field_required'.tr()
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: qteCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'fiche_med_field_quantity'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) {
                            final n = int.tryParse((v ?? '').trim());
                            if (n == null || n <= 0) {
                              return 'fiche_field_required'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: posoCtrl,
                          minLines: 2,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'fiche_med_field_posologie'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'fiche_field_required'.tr()
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx2, false),
                    child: Text('att_cancel_no'.tr()),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(ctx2, true);
                      }
                    },
                    child: Text('fiche_med_custom_add'.tr()),
                  ),
                ],
              ),
            );

            if (added == true) {
              setLocal(() {
                working.add({
                  'id_medicament': null,
                  'nom_medicament': nomCtrl.text.trim(),
                  'forme': null,
                  'dosage': null,
                  'prix_unitaire': null,
                  'stock': 0,
                  'disponible': false,
                  'selected': true,
                  'quantite': int.parse(qteCtrl.text.trim()),
                  'posologie': posoCtrl.text.trim(),
                  'is_custom': true,
                });
              });
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: dialogWidth,
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                    decoration: BoxDecoration(
                      color: theme.light,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.medication_outlined,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'fiche_med_modal_title'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          icon: const Icon(Icons.close, color: Colors.white),
                          tooltip: 'fiche_modal_close'.tr(),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setLocal(
                              () => search = v.trim().toLowerCase(),
                            ),
                            decoration: InputDecoration(
                              hintText: 'fiche_med_search_hint'.tr(),
                              prefixIcon: const Icon(Icons.search),
                              isDense: true,
                              filled: true,
                              fillColor: theme.fieldBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: theme.fieldBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: theme.fieldBorder,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: openCustomDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: Text('fiche_med_custom_btn'.tr()),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: working.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'fiche_med_empty'.tr(),
                              style: const TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final m = filtered[i];
                              return _buildMedTile(
                                m: m,
                                theme: theme,
                                onChanged: () => setLocal(() {}),
                                onRemoveCustom: () => setLocal(() {
                                  working.remove(m);
                                }),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    decoration: BoxDecoration(
                      color: theme.fieldBg,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(18),
                      ),
                      border: Border(
                        top: BorderSide(color: theme.fieldBorder),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'fiche_exams_selected_count'.tr(
                                  namedArgs: {'count': '$selectedCount'},
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              'fiche_med_total_estim'.tr(
                                namedArgs: {
                                  'total': total.toStringAsFixed(0),
                                },
                              ),
                              style: TextStyle(
                                color: theme.blue,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text('att_cancel_no'.tr()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final invalid = working.firstWhere(
                                    (m) =>
                                        m['selected'] == true &&
                                        ((m['posologie'] ?? '')
                                                .toString()
                                                .trim()
                                                .isEmpty ||
                                            ((m['quantite'] as num?) ?? 0) <=
                                                0),
                                    orElse: () => {},
                                  );
                                  if (invalid.isNotEmpty) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'fiche_med_validation_error'.tr(),
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.pop(ctx, true);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'fiche_exams_validate'.tr(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  return confirmed == true ? working : null;
}

Widget _buildMedTile({
  required Map<String, dynamic> m,
  required PickerTheme theme,
  required VoidCallback onChanged,
  required VoidCallback onRemoveCustom,
}) {
  final isSelected = m['selected'] == true;
  final isCustom = m['is_custom'] == true;
  final disponible = m['disponible'] == true;
  final prix = (m['prix_unitaire'] as num?)?.toDouble();
  final dosage = (m['dosage'] ?? '').toString();
  final forme = (m['forme'] ?? '').toString();
  final subtitle = [
    if (forme.isNotEmpty) forme,
    if (dosage.isNotEmpty) dosage,
  ].join(' • ');

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: isSelected,
              activeColor: theme.primary,
              onChanged: (v) {
                m['selected'] = v ?? false;
                onChanged();
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (m['nom_medicament'] ?? '').toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _availabilityBadge(
                        disponible: disponible,
                        isCustom: isCustom,
                      ),
                    ],
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  if (prix != null)
                    Text(
                      'fiche_med_price'.tr(
                        namedArgs: {'price': prix.toStringAsFixed(0)},
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (isSelected)
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 4, 8, 8),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    initialValue: (m['quantite'] ?? 1).toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'fiche_med_field_quantity'.tr(),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v.trim());
                      m['quantite'] = (n != null && n > 0) ? n : 1;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: (m['posologie'] ?? '').toString(),
                    decoration: InputDecoration(
                      labelText: 'fiche_med_field_posologie'.tr(),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (v) {
                      m['posologie'] = v;
                    },
                  ),
                ),
                if (isCustom)
                  IconButton(
                    tooltip: 'fiche_med_remove_custom'.tr(),
                    onPressed: onRemoveCustom,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

Widget _availabilityBadge({required bool disponible, required bool isCustom}) {
  if (isCustom) {
    return _badge(
      text: 'fiche_med_badge_custom'.tr(),
      color: Colors.deepPurple,
    );
  }
  return _badge(
    text: disponible
        ? 'fiche_med_badge_available'.tr()
        : 'fiche_med_badge_unavailable'.tr(),
    color: disponible ? Colors.green : Colors.redAccent,
  );
}

Widget _badge({required String text, required Color color}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

// ============================================================================
// BOUTONS / CARTES D'ACCÈS AUX PICKERS
// ============================================================================

/// Carte/bouton qui ouvre le picker examens.
Widget buildExamsPickerCard({
  required BuildContext context,
  required List<Map<String, dynamic>> examens,
  required bool loading,
  required PickerTheme theme,
  required VoidCallback onTap,
}) {
  final selectedCount = examens.where((e) => e['selected'] == true).length;
  final total = examens.where((e) => e['selected'] == true).fold<double>(
    0,
    (sum, e) => sum + ((e['prix_examen'] as num?)?.toDouble() ?? 0),
  );

  return _pickerCard(
    context: context,
    icon: Icons.science_outlined,
    title: 'fiche_exams_pick_button'.tr(),
    sectionTitle: 'fiche_exams_list_title'.tr(),
    subtitle: loading
        ? 'fiche_exams_loading'.tr()
        : (selectedCount == 0
              ? 'fiche_exams_pick_hint'.tr()
              : 'fiche_exams_pick_summary'.tr(
                  namedArgs: {
                    'count': '$selectedCount',
                    'total': total.toStringAsFixed(0),
                  },
                )),
    badgeCount: selectedCount,
    theme: theme,
    onTap: loading ? null : onTap,
  );
}

/// Carte/bouton qui ouvre le picker médicaments.
Widget buildMedicamentsPickerCard({
  required BuildContext context,
  required List<Map<String, dynamic>> medicaments,
  required bool loading,
  required PickerTheme theme,
  required VoidCallback onTap,
}) {
  final selected = medicaments.where((m) => m['selected'] == true).toList();
  final selectedCount = selected.length;
  final total = selected.fold<double>(0, (sum, m) {
    final p = (m['prix_unitaire'] as num?)?.toDouble() ?? 0;
    final q = (m['quantite'] as num?)?.toInt() ?? 1;
    return sum + p * q;
  });

  return _pickerCard(
    context: context,
    icon: Icons.medication_outlined,
    title: 'fiche_med_pick_button'.tr(),
    sectionTitle: 'fiche_med_section_title'.tr(),
    subtitle: loading
        ? 'fiche_med_loading'.tr()
        : (selectedCount == 0
              ? 'fiche_med_pick_hint'.tr()
              : 'fiche_med_pick_summary'.tr(
                  namedArgs: {
                    'count': '$selectedCount',
                    'total': total.toStringAsFixed(0),
                  },
                )),
    badgeCount: selectedCount,
    theme: theme,
    onTap: loading ? null : onTap,
  );
}

Widget _pickerCard({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String sectionTitle,
  required String subtitle,
  required int badgeCount,
  required PickerTheme theme,
  required VoidCallback? onTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Material(
          color: theme.fieldBg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.fieldBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.light.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: theme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (badgeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
