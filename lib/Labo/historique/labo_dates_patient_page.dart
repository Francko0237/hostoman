import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'historique_service.dart';

// Couleurs - Thème Laboratoire
const Color labPrimaryColor = Color(0xFF212031);
const Color labBlueColor = Color(0xFF009688);

/// Page intermédiaire : dates des sessions du patient au labo
class LaboPatientDatesPage extends StatefulWidget {
  final String idPatient;
  final String nomPatient;
  final String? sexe;
  final int? age;

  const LaboPatientDatesPage({
    super.key,
    required this.idPatient,
    required this.nomPatient,
    this.sexe,
    this.age,
  });

  @override
  State<LaboPatientDatesPage> createState() => _LaboPatientDatesPageState();
}

class _LaboPatientDatesPageState extends State<LaboPatientDatesPage> {
  final HistoriqueLaboService _service = HistoriqueLaboService(
    Supabase.instance.client,
  );

  List<Map<String, dynamic>> sessions = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _chargerSessions();
  }

  Future<void> _chargerSessions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final data = await _service.getSessionsParPatient(widget.idPatient);
      setState(() {
        sessions = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'lex_server_error'.tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final initial =
        widget.nomPatient.isNotEmpty ? widget.nomPatient[0].toUpperCase() : 'P';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: labPrimaryColor,
        centerTitle: !isDesktop,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.nomPatient,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _chargerSessions,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: labBlueColor))
          : errorMessage != null
          ? Center(
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 800 : double.infinity,
                ),
                child: CustomScrollView(
                  slivers: [
                    // En-tête patient
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: labBlueColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: labBlueColor,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.nomPatient,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (widget.sexe != null) ...[
                                          Icon(
                                            widget.sexe == 'Homme'
                                                ? Icons.male
                                                : Icons.female,
                                            size: 14,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            widget.sexe!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                        if (widget.age != null) ...[
                                          const SizedBox(width: 10),
                                          Icon(
                                            Icons.cake,
                                            size: 14,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            'lhist_age_value'.tr(
                                              namedArgs: {'age': '${widget.age}'},
                                            ),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: labBlueColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${sessions.length} session${sessions.length > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    color: labBlueColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Titre de la liste de dates
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Text(
                          'Dates de passage au laboratoire',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    // Liste des dates groupées
                    sessions.isEmpty
                        ? SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40.0),
                                child: Text(
                                  'lhist_empty'.tr(),
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildDateCard(sessions[index], index);
                              },
                              childCount: sessions.length,
                            ),
                          ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDateCard(Map<String, dynamic> sessionGroup, int index) {
    final String dayKey = sessionGroup['day_key'] as String;
    final List<Map<String, dynamic>> consultationsDuJour =
        (sessionGroup['consultations'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();

    final dt = DateTime.parse(dayKey);
    final dayName = _getDayName(dt.weekday);
    final dateFormatted =
        '$dayName ${dt.day.toString().padLeft(2, '0')} ${_getMonthName(dt.month)} ${dt.year}';

    // Si plusieurs consultations dans la journée, on affiche toutes les heures
    final bool multipleConsultations = consultationsDuJour.length > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        onTap: () {
          if (multipleConsultations) {
            // Afficher un bottom sheet avec les heures pour choisir
            _showHeureSelector(context, consultationsDuJour, dateFormatted);
          } else {
            // Navigation directe vers le détail
            final idConsultation =
                consultationsDuJour.first['id_consultation'] as int;
            context.push(
              '/Dashboard_Laboratoire/HistoriqueDetail/$idConsultation',
              extra: {'nom': widget.nomPatient},
            );
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              // Icône calendrier stylée
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: labBlueColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${dt.day}',
                      style: const TextStyle(
                        color: labBlueColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    Text(
                      _getMonthAbbr(dt.month),
                      style: const TextStyle(
                        color: labBlueColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Date et infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormatted,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (multipleConsultations)
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 13,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${consultationsDuJour.length} consultations ce jour — choisir l\'heure',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          const Icon(
                            Icons.biotech,
                            size: 13,
                            color: labBlueColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Examens effectués',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Icon(
                multipleConsultations
                    ? Icons.expand_more
                    : Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Affiche un bottom sheet pour choisir l'heure quand plusieurs consultations le même jour
  void _showHeureSelector(
    BuildContext context,
    List<Map<String, dynamic>> consultations,
    String dateLabel,
  ) {
    // Trier les consultations par heure
    consultations.sort((a, b) {
      final dtA = DateTime.parse(a['date_enregistrement'] as String);
      final dtB = DateTime.parse(b['date_enregistrement'] as String);
      return dtA.compareTo(dtB);
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${consultations.length} consultations ce jour — choisissez l\'heure',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ...consultations.asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                final dt = DateTime.parse(c['date_enregistrement'] as String);
                final heureStr =
                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                final idConsultation = c['id_consultation'] as int;

                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(
                      '/Dashboard_Laboratoire/HistoriqueDetail/$idConsultation',
                      extra: {'nom': widget.nomPatient},
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: labBlueColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: labBlueColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: labBlueColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Consultation à $heureStr',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Réf. #$idConsultation',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right,
                          color: labBlueColor,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _getDayName(int weekday) {
    const days = ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];
    return days[(weekday - 1) % 7];
  }

  String _getMonthName(int month) {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return months[month - 1];
  }

  String _getMonthAbbr(int month) {
    const abbrs = [
      'jan',
      'fév',
      'mar',
      'avr',
      'mai',
      'juin',
      'juil',
      'août',
      'sep',
      'oct',
      'nov',
      'déc',
    ];
    return abbrs[month - 1];
  }
}
