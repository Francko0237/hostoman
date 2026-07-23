import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:hostoman/model_unifier.dart';
import 'Service.dart';
import '../HistoriquePaiement/detail/detail_historique_ui.dart';
import 'package:hostoman/shared/pdf_generator.dart';

// Couleurs (Tes couleurs d'origine)
const Color npPrimaryColor = Color(0xFF4CAF50);
const Color npAccentColor = Color(0xFF378127);
const Color npSuccessColor = Color(0xFF4CAF50);
const Color npErrorColor = Color(0xFFD32F2F);
const Color npBlueColor = Color(0xFF2196F3);

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final StatsService statsService = StatsService(Supabase.instance.client);

  bool isLoading = true;
  String periodeSelectorionnee = 'today';
  String typePaiement = 'tous'; // Type de paiement : 'tous', 'payer' ou 'annuler'
  Map<String, dynamic>? statsData;
  List<Map<String, dynamic>> consultations = [];
  List<Map<String, dynamic>> filteredConsultations = [];
  String searchQuery = '';

  DateTime? dateDebutPersonnalisee;
  DateTime? dateFinPersonnalisee;

  @override
  void initState() {
    super.initState();
    chargerStats();
  }

  Future<void> chargerStats() async {
    setState(() => isLoading = true);
    try {
      Map<String, dynamic> data;
      switch (periodeSelectorionnee) {
        case 'today':
          data = await statsService.getStatsToday(statutPaiement: typePaiement);
          break;
        case 'week':
          data = await statsService.getStatsThisWeek(
            statutPaiement: typePaiement,
          );
          break;
        case 'month':
          data = await statsService.getStatsThisMonth(
            statutPaiement: typePaiement,
          );
          break;
        case 'custom':
          data = await statsService.getStatsByPeriod(
            dateDebut: dateDebutPersonnalisee!,
            dateFin: dateFinPersonnalisee!,
            statutPaiement: typePaiement,
          );
          break;
        default:
          data = await statsService.getStatsToday(statutPaiement: typePaiement);
      }

      setState(() {
        statsData = data;
        consultations = List<Map<String, dynamic>>.from(data['consultations']);
        filteredConsultations = consultations;
        isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar(e.toString());
    }
  }

  void _applyFilters() {
    setState(() {
      filteredConsultations = consultations.where((item) {
        final patientMap = item['Patient'] as Map<String, dynamic>;
        final nom = (patientMap['nom_complet'] ?? '').toString().toLowerCase();
        return nom.contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF274621),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: npPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'cstat_title'.tr(),
          style: const TextStyle(
            color: Color(0xFF26AE6C),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: npSuccessColor),
            onPressed: chargerStats,
          ),
          if (filteredConsultations.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.print, color: npSuccessColor),
              tooltip: 'cstat_print_tooltip'.tr(),
              onPressed: _printPatientList,
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: npPrimaryColor),
            )
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 900 : double.infinity,
                  ),
                  child: Column(
                    children: [
                      _buildPeriodSelector(),
                      _buildTypePaiementSelector(),
                      _buildStatSection(isDesktop),
                      _buildPatientListSection(isDesktop),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // --- Widgets de construction ---

  Future<void> _printPatientList() async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final monthLocale = context.locale.toString().replaceAll('-', '_');
    String periodeLabel;
    switch (periodeSelectorionnee) {
      case 'today':
        periodeLabel = 'cstat_period_today_value'.tr(
          namedArgs: {'date': dateFormat.format(DateTime.now())},
        );
        break;
      case 'week':
        periodeLabel = 'cstat_period_this_week'.tr();
        break;
      case 'month':
        periodeLabel = 'cstat_period_month_value'.tr(
          namedArgs: {
            'date': DateFormat('MMMM yyyy', monthLocale).format(DateTime.now()),
          },
        );
        break;
      case 'custom':
        periodeLabel =
            dateDebutPersonnalisee != null && dateFinPersonnalisee != null
            ? 'cstat_period_custom_value'.tr(
                namedArgs: {
                  'start': dateFormat.format(dateDebutPersonnalisee!),
                  'end': dateFormat.format(dateFinPersonnalisee!),
                },
              )
            : 'cstat_period_custom_label'.tr();
        break;
      default:
        periodeLabel = 'cstat_period_all'.tr();
    }

    final pdfPatients = filteredConsultations.map((item) {
      final patientMap = item['Patient'] as Map<String, dynamic>;
      final patient = Patient.fromMap(patientMap);
      final date = DateTime.parse(item['date_enregistrement']);
      final listPaiements = item['paiement'] as List;
      final montant = listPaiements.isNotEmpty
          ? listPaiements[0]['prix_a_paye']
          : 0;
      final currentStatut = listPaiements.isNotEmpty
          ? listPaiements[0]['statut_paiement']
          : 'payer';

      return PatientPdfData(
        nom: patient.nom_complet,
        sexe: patient.sexe,
        age: 'pay_field_age_value'.tr(namedArgs: {'age': '${patient.age}'}),
        telephone: patient.telephone.toString(),
        dateEnregistrement: dateFormat.format(date),
        categorie: currentStatut == 'payer'
            ? 'hist_badge_paid'.tr()
            : 'hist_badge_cancelled'.tr(),
        montant: 'cstat_amount_fcfa'.tr(
          namedArgs: {
            'value': _formatNumber(montant is int ? montant : montant.toInt()),
          },
        ),
      );
    }).toList();

    await PatientListPdfGenerator.previewAndPrint(
      context: context,
      serviceName: 'cstat_pdf_service'.tr(),
      periodeLabel: periodeLabel,
      patients: pdfPatients,
      showCategorie: true,
      categorieLabel: 'cstat_pdf_cat_label'.tr(),
      showMontant: true,
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPeriodButton(
                'today',
                'cstat_period_today'.tr(),
                Icons.today,
              ),
              _buildPeriodButton(
                'week',
                'cstat_period_week'.tr(),
                Icons.calendar_view_week,
              ),
              _buildPeriodButton(
                'month',
                'cstat_period_month'.tr(),
                Icons.calendar_month,
              ),
              _buildCustomButton(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'cstat_period_label'.tr(namedArgs: {'value': _getPeriodeLabel()}),
            style: const TextStyle(
              color: npAccentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypePaiementSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => typePaiement = 'tous');
                chargerStats();
              },
              icon: const Icon(Icons.apps, size: 18),
              label: Text('cstat_btn_all'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: typePaiement == 'tous'
                    ? npPrimaryColor
                    : Colors.grey.shade300,
                foregroundColor: typePaiement == 'tous'
                    ? Colors.white
                    : Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => typePaiement = 'payer');
                chargerStats();
              },
              icon: const Icon(Icons.check_circle, size: 18),
              label: Text('cstat_btn_paid'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: typePaiement == 'payer'
                    ? npSuccessColor
                    : Colors.grey.shade300,
                foregroundColor: typePaiement == 'payer'
                    ? Colors.white
                    : Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => typePaiement = 'annuler');
                chargerStats();
              },
              icon: const Icon(Icons.cancel, size: 18),
              label: Text('cstat_btn_cancelled'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: typePaiement == 'annuler'
                    ? npErrorColor
                    : Colors.grey.shade300,
                foregroundColor: typePaiement == 'annuler'
                    ? Colors.white
                    : Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatSection(bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'cstat_card_patients'.tr(),
                  '${statsData?['nombre_patients']}',
                  Icons.people,
                  npBlueColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'cstat_card_revenue'.tr(),
                  'cstat_amount_fcfa'.tr(
                    namedArgs: {
                      'value': _formatNumber(statsData?['somme_generee'] ?? 0),
                    },
                  ),
                  Icons.payments,
                  npSuccessColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSmallInfo(
                  Icons.male,
                  'cstat_men'.tr(
                    namedArgs: {'count': '${statsData?['hommes']}'},
                  ),
                  Colors.blue,
                ),
                _buildSmallInfo(
                  Icons.female,
                  'cstat_women'.tr(
                    namedArgs: {'count': '${statsData?['femmes']}'},
                  ),
                  Colors.pink,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientListSection(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'cstat_patient_list'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: npAccentColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 16),
          if (filteredConsultations.isEmpty)
            _buildEmptyState()
          else
            ...filteredConsultations.map((item) => _buildPatientTile(item)),
        ],
      ),
    );
  }

  Widget _buildPatientTile(Map<String, dynamic> item) {
    final patientMap = item['Patient'] as Map<String, dynamic>;
    final patient = Patient.fromMap(patientMap);
    final date = DateTime.parse(item['date_enregistrement']);
    final listPaiements = item['paiement'] as List;
    final montant = listPaiements.isNotEmpty
        ? listPaiements[0]['prix_a_paye']
        : 0;
    final idConsultation = item['id_consultation'].toString();
    final bool isCancelled = listPaiements.isNotEmpty &&
        listPaiements[0]['statut_paiement'] == 'annuler';
    final Color statusColor = isCancelled ? npErrorColor : npSuccessColor;

    return InkWell(
      onTap: () {
        // Note: Statistique affiche les consultations, pas les paiements individuels
        // On utilise donc l'ancienne méthode avec idConsultation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DetailHistoriqueUI(idConsultation: idConsultation),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: statusColor,
            child: Text(
              patient.nom_complet[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            patient.nom_complet,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(DateFormat('dd/MM/yyyy à HH:mm').format(date)),
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'cstat_amount_fcfa'.tr(
                namedArgs: {'value': _formatNumber(montant.toInt())},
              ),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Fonctions utilitaires ---

  Widget _buildPeriodButton(String value, String label, IconData icon) {
    bool isSelected = periodeSelectorionnee == value;
    return ElevatedButton.icon(
      onPressed: () {
        setState(() => periodeSelectorionnee = value);
        chargerStats();
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? npPrimaryColor : Colors.grey.shade300,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'cstat_search_hint'.tr(),
        prefixIcon: const Icon(Icons.search, color: npAccentColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (v) {
        setState(() => searchQuery = v);
        _applyFilters();
      },
    );
  }

  String _formatNumber(int n) {
    final loc = context.locale.toString().replaceAll('-', '_');
    return NumberFormat('#,###', loc).format(n).replaceAll(',', ' ');
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: npErrorColor));
  }

  Widget _buildStatCard(String t, String v, IconData i, Color c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(i, color: c),
          const SizedBox(height: 8),
          Text(t, style: TextStyle(color: Colors.grey[600])),
          Text(
            v,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfo(IconData i, String t, Color c) {
    return Row(
      children: [
        Icon(i, color: c, size: 18),
        const SizedBox(width: 4),
        Text(t),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        'cstat_footer'.tr(),
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
    );
  }

  Future<void> _showCustomDateDialog() async {
    DateTime? tempStart = dateDebutPersonnalisee;
    DateTime? tempEnd = dateFinPersonnalisee;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDlg) {
          Future<void> pickDate(bool isStart) async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: isStart
                  ? (tempStart ?? DateTime.now())
                  : (tempEnd ?? DateTime.now()),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: npPrimaryColor,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              setDlg(() {
                if (isStart) {
                  tempStart = picked;
                } else {
                  tempEnd = picked;
                }
              });
            }
          }

          Widget dateChip(String label, DateTime? date, bool isStart) {
            final has = date != null;
            return Expanded(
              child: InkWell(
                onTap: () => pickDate(isStart),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: has
                        ? npPrimaryColor.withOpacity(0.07)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: has ? npPrimaryColor : Colors.grey.shade300,
                      width: has ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 14,
                            color: has ? npPrimaryColor : Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(label,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500)),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        has
                            ? DateFormat('dd/MM/yyyy').format(date)
                            : 'accstat_pick_date'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: has ? Colors.black87 : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final dateError = tempStart != null &&
              tempEnd != null &&
              tempEnd!.isBefore(tempStart!);

          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: npPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.tune_rounded,
                    color: npPrimaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'accstat_custom_period'.tr(),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
              ),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Row(children: [
                  dateChip('accstat_date_start'.tr(), tempStart, true),
                  const SizedBox(width: 10),
                  dateChip('accstat_date_end'.tr(), tempEnd, false),
                ]),
                if (dateError)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'accstat_date_error'.tr(),
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.end,
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600),
                child: Text('accstat_cancel'.tr()),
              ),
              ElevatedButton(
                onPressed: (tempStart == null || tempEnd == null || dateError)
                    ? null
                    : () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: npPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text('accstat_apply'.tr()),
              ),
            ],
          );
        });
      },
    );

    if (confirmed == true && tempStart != null && tempEnd != null) {
      setState(() {
        dateDebutPersonnalisee = tempStart;
        dateFinPersonnalisee = DateTime(
            tempEnd!.year, tempEnd!.month, tempEnd!.day, 23, 59, 59);
        periodeSelectorionnee = 'custom';
      });
      chargerStats();
    }
  }

  Widget _buildCustomButton() {
    bool isSelected = periodeSelectorionnee == 'custom';
    return ElevatedButton.icon(
      onPressed: _showCustomDateDialog,
      icon: const Icon(Icons.date_range),
      label: Text('cstat_period_calendar'.tr()),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? npPrimaryColor : Colors.grey.shade300,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildEmptyState() => Padding(
    padding: const EdgeInsets.all(40),
    child: Text('cstat_empty'.tr()),
  );

  String _getPeriodeLabel() {
    if (periodeSelectorionnee == 'today') return 'cstat_period_today'.tr();
    if (periodeSelectorionnee == 'week') return 'cstat_period_this_week'.tr();
    if (periodeSelectorionnee == 'month') return 'cstat_period_this_month'.tr();
    return 'cstat_period_custom'.tr();
  }
}
