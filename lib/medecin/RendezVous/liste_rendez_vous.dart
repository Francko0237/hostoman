import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'rendez_vous_service.dart';

class ListeRendezVousPage extends StatefulWidget {
  const ListeRendezVousPage({super.key});

  @override
  State<ListeRendezVousPage> createState() => _ListeRendezVousPageState();
}

class _ListeRendezVousPageState extends State<ListeRendezVousPage> {
  late final RendezVousService _rendezVousService;
  List<Map<String, dynamic>> _rendezVousList = [];
  bool _isLoading = true;

  // Couleurs unifiées du Thème Médecin
  final Color primaryPurple = const Color(0xFF5A47C9);
  final Color lightPurple = const Color(0xFF8A7DF0);
  final Color medSuccessColor = const Color(0xFF4CAF50);
  final Color medErrorColor = const Color(0xFFD32F2F);
  final Color medOrangeColor = const Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    _rendezVousService = RendezVousService(Supabase.instance.client);
    _loadRendezVous();
  }

  Future<void> _loadRendezVous() async {
    try {
      final rdv = await _rendezVousService.getRendezVous();
      if (mounted) {
        setState(() {
          _rendezVousList = rdv;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('hclist_error_snack'.tr(namedArgs: {'msg': '$e'})),
          ),
        );
      }
    }
  }

  /// 📅 Reprogrammer un rendez-vous (Date & Heure)
  Future<void> _showReprogrammerDialog(int idConsultation, String patientName, DateTime? currentDate) async {
    DateTime selectedDate = currentDate ?? DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = currentDate != null ? TimeOfDay.fromDateTime(currentDate) : TimeOfDay.now();

    final dateController = TextEditingController(
      text: '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
    );
    final timeController = TextEditingController(
      text: selectedTime.format(context),
    );

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Reprogrammer le RDV',
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryPurple),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Modifier la date et l\'heure du rendez-vous de $patientName.',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    // Champ Date
                    TextFormField(
                      controller: dateController,
                      decoration: InputDecoration(
                        labelText: 'Date de rendez-vous',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                      ),
                      readOnly: true,
                      validator: (value) => value == null || value.isEmpty ? 'Veuillez choisir une date' : null,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setDialogState(() {
                            selectedDate = date;
                            dateController.text = '${date.day}/${date.month}/${date.year}';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    // Champ Heure
                    TextFormField(
                      controller: timeController,
                      decoration: InputDecoration(
                        labelText: 'Heure de rendez-vous',
                        prefixIcon: const Icon(Icons.access_time),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                      ),
                      readOnly: true,
                      validator: (value) => value == null || value.isEmpty ? 'Veuillez choisir une heure' : null,
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setDialogState(() {
                            selectedTime = time;
                            timeController.text = time.format(context);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final newDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                      Navigator.pop(context);
                      setState(() => _isLoading = true);
                      final success = await _rendezVousService.reprogrammerRendezVous(idConsultation, newDateTime);
                      if (!mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Le rendez-vous a bien été reprogrammé.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Erreur lors de la reprogrammation.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      _loadRendezVous();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Confirmer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// ❌ Annuler un rendez-vous (Confirmation)
  Future<void> _showAnnulerDialog(int idConsultation, String patientName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Annuler le RDV',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: Text(
            'Voulez-vous vraiment annuler le rendez-vous de $patientName ?',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Garder le RDV', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Oui, annuler'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _rendezVousService.annulerRendezVous(idConsultation);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le rendez-vous a été annulé avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'annulation du rendez-vous.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _loadRendezVous();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'rdv_title'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadRendezVous();
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: primaryPurple))
              : _rendezVousList.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  itemCount: _rendezVousList.length,
                  itemBuilder: (context, index) {
                    final rdv = _rendezVousList[index];
                    return _buildRendezVousCard(rdv);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'rdv_empty'.tr(),
            style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRendezVousCard(Map<String, dynamic> rdv) {
    final patient = rdv['Patient'] as Map<String, dynamic>;
    final String nom =
        patient['nom_complet']?.toString() ?? 'rdv_unknown_patient'.tr();
    final String telephone =
        patient['telephone']?.toString() ?? 'pay_value_na'.tr();
    final String sexe = patient['sexe']?.toString() ?? 'pay_value_na'.tr();
    final int? age = patient['age'];

    final rdvDateStr = rdv['date_rdv_prevu'];
    final DateTime? rdvDate = rdvDateStr != null
        ? DateTime.tryParse(rdvDateStr)
        : null;

    final bool isPast = rdvDate != null && rdvDate.isBefore(DateTime.now());
    final Color dateColor = isPast ? medErrorColor : medSuccessColor;

    final String initial = nom.isNotEmpty ? nom[0].toUpperCase() : 'P';

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: () {
          // Action par défaut : Consulter / Finaliser
          context.push(
            '/Dashboard_Medecin/FinalisationConsultation/${rdv['id_consultation']}',
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar stylé
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryPurple.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: primaryPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Contenu principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            nom,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPast)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: medErrorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'rdv_late_badge'.tr(),
                              style: TextStyle(
                                color: medErrorColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Infos additionnelles
                    Row(
                      children: [
                        Icon(
                          Icons.wc,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'rdv_sex_age'.tr(
                            namedArgs: {
                              'sexe': sexe,
                              'age': age?.toString() ?? 'rdv_age_unknown'.tr(),
                            },
                          ),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.phone,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          telephone,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Date & Heure
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_filled,
                          color: dateColor,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          rdvDate != null
                              ? DateFormat(
                                  'rdv_date_format'.tr(),
                                  context.locale.toString(),
                                ).format(rdvDate)
                              : 'rdv_date_unknown'.tr(),
                          style: TextStyle(
                            color: dateColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Menu 3 boutons (Trois points verticaux)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black54),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onSelected: (value) {
                  if (value == 'consulter') {
                    context.push(
                      '/Dashboard_Medecin/FinalisationConsultation/${rdv['id_consultation']}',
                    );
                  } else if (value == 'reprogrammer') {
                    _showReprogrammerDialog(rdv['id_consultation'], nom, rdvDate);
                  } else if (value == 'annuler') {
                    _showAnnulerDialog(rdv['id_consultation'], nom);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: 'consulter',
                    child: Row(
                      children: [
                        Icon(Icons.medical_services_outlined, size: 18, color: primaryPurple),
                        const SizedBox(width: 8),
                        const Text('Finaliser la consultation', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'reprogrammer',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 18, color: medOrangeColor),
                        const SizedBox(width: 8),
                        const Text('Reprogrammer', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'annuler',
                    child: Row(
                      children: [
                        Icon(Icons.cancel_outlined, size: 18, color: medErrorColor),
                        const SizedBox(width: 8),
                        Text('Annuler', style: TextStyle(fontSize: 13, color: medErrorColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
