import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'examen__faire_service.dart';

// Couleurs (à réutiliser ou importer)
const Color labPrimaryColor = Color(0xFF212031);
const Color labSuccessColor = Color(0xFF4CAF50);
const Color labErrorColor = Color(0xFFD32F2F);

class ExamenDetailScreen extends StatefulWidget {
  final int idConsultation;
  final String nomPatient;
  final String sexe;
  final String age;
  final String telephone;

  const ExamenDetailScreen({
    super.key,
    required this.idConsultation,
    required this.nomPatient,
    required this.sexe,
    required this.age,
    required this.telephone,
  });

  @override
  State<ExamenDetailScreen> createState() => _ExamenDetailScreenState();
}

class _ExamenDetailScreenState extends State<ExamenDetailScreen> {
  final LaboExamensService laboService = LaboExamensService(
    Supabase.instance.client,
  );

  List<Map<String, dynamic>> examens = [];
  Set<int> selectedExamensIds = {};

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    chargerExamens();
  }

  Future<void> chargerExamens() async {
    setState(() => isLoading = true);
    try {
      final data = await laboService.getExamensParConsultation(
        widget.idConsultation,
      );
      setState(() {
        examens = data;
        isLoading = false;
        selectedExamensIds.clear();
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'lex_server_error'.tr();
      });
    }
  }

  void toggleSelectAll(bool? selected) {
    setState(() {
      if (selected == true) {
        selectedExamensIds = examens
            .map<int>((e) => e['id_examen'] as int)
            .toSet();
      } else {
        selectedExamensIds.clear();
      }
    });
  }

  void toggleExamen(int id, bool? selected) {
    setState(() {
      if (selected == true) {
        selectedExamensIds.add(id);
      } else {
        selectedExamensIds.remove(id);
      }
    });
  }

  /// 🔄 Vérifie le statut et redirige si nécessaire
  Future<void> _verifierEtRediriger() async {
    try {
      print(
        '🔍 Vérification du statut pour consultation ${widget.idConsultation}...',
      );

      // Vérifie le statut actuel AVANT la mise à jour
      final statutAvant = await laboService.verifierStatutExamens(
        widget.idConsultation,
      );
      print('📊 Statut AVANT mise à jour: $statutAvant');

      // Met à jour le statut de la consultation
      await laboService.mettreAJourStatutConsultation(widget.idConsultation);

      // Vérifie le nouveau statut APRÈS la mise à jour
      final statutApres = await laboService.verifierStatutExamens(
        widget.idConsultation,
      );
      print('📊 Statut APRÈS mise à jour: $statutApres');

      if (mounted) {
        if (statutApres == 'tous-traites') {
          print('✅ Tous traités → Retour à la liste avec pop()');
          _showSuccessSnackBar('lexd_all_done'.tr());
          await Future.delayed(const Duration(milliseconds: 800));

          // Utilise pop() pour revenir en arrière (la liste se rechargera automatiquement)
          if (mounted) {
            context.pop();
          }
        } else {
          print('🔄 Il reste des examens → Recharge la liste');
          await chargerExamens();
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification : $e');
      _showErrorSnackBar('lexd_err_verify'.tr(namedArgs: {'msg': '$e'}));
    }
  }

  Future<void> _enregistrerExamens() async {
    if (selectedExamensIds.isEmpty) {
      _showErrorSnackBar('lexd_err_none_save'.tr());
      return;
    }

    setState(() => isLoading = true);
    try {
      final selectedList = selectedExamensIds.toList();
      await laboService.enregistrerExamensEnCours(selectedList);

      final n = selectedList.length;
      _showSuccessSnackBar(
        (n > 1 ? 'lexd_success_save_many' : 'lexd_success_save_one').tr(
          namedArgs: {'count': '$n'},
        ),
      );

      // Vérifie si tous les examens sont terminés et redirige si nécessaire
      await _verifierEtRediriger();
    } catch (e) {
      _showErrorSnackBar('lexd_err_save'.tr(namedArgs: {'msg': '$e'}));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _annulerExamens() async {
    if (selectedExamensIds.isEmpty) {
      _showErrorSnackBar('lexd_err_none_cancel'.tr());
      return;
    }

    final n = selectedExamensIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('lexd_confirm_title'.tr()),
        content: Text(
          (n > 1 ? 'lexd_confirm_msg_many' : 'lexd_confirm_msg_one').tr(
            namedArgs: {'count': '$n'},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('lexd_confirm_no'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'lexd_confirm_yes'.tr(),
              style: const TextStyle(color: labErrorColor),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => isLoading = true);
      try {
        final selectedList = selectedExamensIds.toList();
        await laboService.annulerExamens(selectedList);

        final m = selectedList.length;
        _showSuccessSnackBar(
          (m > 1 ? 'lexd_success_cancel_many' : 'lexd_success_cancel_one').tr(
            namedArgs: {'count': '$m'},
          ),
        );

        // Vérifie si tous les examens sont annulés et redirige si nécessaire
        await _verifierEtRediriger();
      } catch (e) {
        _showErrorSnackBar('lexd_err_cancel'.tr(namedArgs: {'msg': '$e'}));
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $message'), backgroundColor: labErrorColor),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ $message'), backgroundColor: labSuccessColor),
      );
    }
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final bool isAllSelected =
        examens.isNotEmpty && selectedExamensIds.length == examens.length;

    return Scaffold(
      backgroundColor: labPrimaryColor,
      appBar: AppBar(
        backgroundColor: labPrimaryColor,
        centerTitle: !isDesktop,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'lexd_title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 1000 : double.infinity,
            ),
            child: Column(
              children: [
                // Bandeau Patient
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF33333D),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  widget.nomPatient.isNotEmpty
                                      ? widget.nomPatient[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                widget.nomPatient,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: widget.sexe == 'Homme'
                                    ? Colors.blue.shade600
                                    : Colors.pink.shade600,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.sexe,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(
                          color: Colors.grey,
                          height: 1,
                          thickness: 0.5,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoItem(
                              icon: Icons.assignment_ind_outlined,
                              label: 'lexd_field_consult_id'.tr(),
                              value: widget.idConsultation.toString(),
                            ),
                            const SizedBox(width: 8),
                            _buildInfoItem(
                              icon: Icons.calendar_today_outlined,
                              label: 'lexd_field_age'.tr(),
                              value: 'lexd_age_value'.tr(
                                namedArgs: {'age': widget.age},
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildInfoItem(
                              icon: Icons.phone_outlined,
                              label: 'lexd_field_phone'.tr(),
                              value: widget.telephone,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Tout Sélectionner
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 8.0,
                    bottom: 8.0,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isAllSelected,
                        onChanged: toggleSelectAll,
                        activeColor: labSuccessColor,
                        checkColor: Colors.white,
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return labSuccessColor;
                          }
                          return Colors.grey.shade700;
                        }),
                      ),
                      Text(
                        'lexd_select_all'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Liste des examens
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 60,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                child: Text(
                                  errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: chargerExamens,
                                icon: const Icon(Icons.refresh),
                                label: Text('lex_retry'.tr()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: labPrimaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : examens.isEmpty
                      ? Center(
                          child: Text(
                            'lexd_empty'.tr(),
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: examens.length,
                          itemBuilder: (context, index) {
                            final examen = examens[index];
                            final idExamen = examen['id_examen'] as int;
                            final isSelected = selectedExamensIds.contains(
                              idExamen,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Material(
                                color: const Color(0xFF33333D),
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () =>
                                      toggleExamen(idExamen, !isSelected),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15.0,
                                      horizontal: 8.0,
                                    ),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: isSelected,
                                          onChanged: (val) =>
                                              toggleExamen(idExamen, val),
                                          activeColor: labSuccessColor,
                                          checkColor: Colors.white,
                                          fillColor:
                                              WidgetStateProperty.resolveWith((
                                                states,
                                              ) {
                                                if (states.contains(
                                                  WidgetState.selected,
                                                )) {
                                                  return labSuccessColor;
                                                }
                                                return Colors.grey.shade700;
                                              }),
                                        ),
                                        Expanded(
                                          child: Text(
                                            examen['nom_examen'].toString(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          examen['statut_examen'].toString(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Boutons Annuler et Enregistrer
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _annulerExamens,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: labErrorColor,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'lexd_btn_cancel'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _enregistrerExamens,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: labSuccessColor,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'lexd_btn_save'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
