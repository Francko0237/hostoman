import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'historique_service.dart';
import 'historique_detail.dart';

const Color _primary = Color(0xFF6A5ACD);
const Color _lightPurple = Color(0xFF8A7DF0);
const Color _green = Color(0xFF4CAF50);
const Color _orange = Color(0xFFFF9800);

// ---------------------------------------------------------------------------
// Page liste — historique d'UN patient
// ---------------------------------------------------------------------------

class HistoriquePatientPage extends StatefulWidget {
  final String idPatient;
  final String patientName;
  final int? excludeIdConsultation;

  const HistoriquePatientPage({
    super.key,
    required this.idPatient,
    required this.patientName,
    this.excludeIdConsultation,
  });

  @override
  State<HistoriquePatientPage> createState() => _HistoriquePatientPageState();
}

class _HistoriquePatientPageState extends State<HistoriquePatientPage> {
  late final HistoriqueConsultationService _service;
  List<Map<String, dynamic>> _consultations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = HistoriqueConsultationService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _service.getHistoriqueParPatient(
        widget.idPatient,
        excludeIdConsultation: widget.excludeIdConsultation,
      );
      if (mounted)
        setState(() {
          _consultations = data;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = '$e';
          _isLoading = false;
        });
    }
  }

  // ---- helpers ----

  String _formatDate(String? raw) {
    if (raw == null) return 'hist_no_data'.tr();
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('dd MMMM yyyy', 'fr_FR').format(dt.toLocal());
  }

  Color _statutColor(String statut) {
    switch (statut) {
      case 'terminer':
        return _green;
      case 'en-attente-consultation':
        return _primary;
      case 'en-attente-examen':
      case 'en-attente-resultat':
      case 'resultat-disponible':
        return _orange;
      default:
        return Colors.grey;
    }
  }

  String _statutLabel(String statut) {
    switch (statut) {
      case 'terminer':
        return 'hist_statut_termine'.tr();
      case 'en-attente-consultation':
        return 'hist_statut_att_consult'.tr();
      case 'en-attente-examen':
        return 'hist_statut_att_exam'.tr();
      case 'en-attente-resultat':
        return 'hist_statut_att_result'.tr();
      case 'resultat-disponible':
        return 'hist_statut_result_dispo'.tr();
      default:
        return statut;
    }
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F3),
      appBar: AppBar(
        backgroundColor: _primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.patientName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'hist_subtitle'.tr(),
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
            tooltip: 'hist_refresh'.tr(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
          ? _buildError()
          : _consultations.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _consultations.length,
              itemBuilder: (ctx, i) => _buildCard(ctx, _consultations[i]),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              'hist_error'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text('hist_retry'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_toggle_off,
                size: 56,
                color: _primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'histp_empty_title'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'histp_empty_msg'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> c) {
    final statut = (c['Statut_Consultation'] as String?) ?? '';
    final color = _statutColor(statut);
    final motif =
        (c['Parametres_vitaux']
                as Map<String, dynamic>?)?['motif_de_consultation']
            as String?;
    final diagFinal = c['diagnostic_final'] as String?;
    final date = _formatDate(c['date_derniere_mise_ajour'] as String?);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetail(context, c),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête date + statut
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 15, color: _primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      date,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statutLabel(statut),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              if (motif != null && motif.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.medical_services_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'hist_motif'.tr(namedArgs: {'motif': motif}),
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (diagFinal != null && diagFinal.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.biotech_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'hist_diag_short'.tr(namedArgs: {'diag': diagFinal}),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[800],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'hist_see_detail'.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: _primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, Map<String, dynamic> c) {
    final idConsultation = c['id_consultation'] as int?;
    if (idConsultation != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HistoriqueDetailPage(
            idConsultation: idConsultation,
          ),
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Page détail — une consultation de l'historique patient
// ---------------------------------------------------------------------------

class _HistoriquePatientDetailPage extends StatefulWidget {
  final Map<String, dynamic> consultation;
  final String patientName;
  final HistoriqueConsultationService service;

  const _HistoriquePatientDetailPage({
    required this.consultation,
    required this.patientName,
    required this.service,
  });

  @override
  State<_HistoriquePatientDetailPage> createState() =>
      _HistoriquePatientDetailPageState();
}

class _HistoriquePatientDetailPageState
    extends State<_HistoriquePatientDetailPage> {
  List<Map<String, dynamic>>? _examens;
  bool _examensLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExamens();
  }

  Future<void> _loadExamens() async {
    final id = widget.consultation['id_consultation'] as int?;
    if (id == null) {
      setState(() => _examensLoading = false);
      return;
    }
    try {
      final data = await widget.service.getExamensConsultation(id);
      if (mounted)
        setState(() {
          _examens = data;
          _examensLoading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _examens = [];
          _examensLoading = false;
        });
    }
  }

  String _formatDate(String? raw) {
    if (raw == null) return 'hist_no_data'.tr();
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat("dd MMMM yyyy 'à' HH:mm", 'fr_FR').format(dt.toLocal());
  }

  String _val(String? v) =>
      (v == null || v.trim().isEmpty) ? 'hist_no_data'.tr() : v;

  @override
  Widget build(BuildContext context) {
    final c = widget.consultation;
    final motif =
        (c['Parametres_vitaux']
                as Map<String, dynamic>?)?['motif_de_consultation']
            as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F3),
      appBar: AppBar(
        backgroundColor: _primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.patientName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              _formatDate(c['date_derniere_mise_ajour'] as String?),
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (motif != null && motif.isNotEmpty)
              _sectionChip(Icons.medical_services_outlined, motif, _orange),
            const SizedBox(height: 12),
            _sectionCard(
              icon: Icons.person_search_outlined,
              title: 'hist_section_general'.tr(),
              children: [
                _infoRow(
                  'hist_antecedents'.tr(),
                  _val(c['antecedents'] as String?),
                ),
                _infoRow(
                  'hist_signs'.tr(),
                  _val(c['signes_symptomes'] as String?),
                ),
                _infoRow(
                  'hist_diag_initial'.tr(),
                  _val(c['diagnostic_initial'] as String?),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              icon: Icons.assignment_turned_in_outlined,
              title: 'hist_section_final'.tr(),
              children: [
                _infoRow(
                  'hist_diag_final'.tr(),
                  _val(c['diagnostic_final'] as String?),
                ),
                _infoRow(
                  'hist_treatment'.tr(),
                  _val(c['traitement_prescrit'] as String?),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              icon: Icons.biotech_outlined,
              title: 'hist_section_examens'.tr(),
              children: [
                if (_examensLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _primary,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else if (_examens == null || _examens!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'hist_no_examens'.tr(),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  ..._examens!.map(_buildExamenRow),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: _primary),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _lightPurple,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[850],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamenRow(Map<String, dynamic> exam) {
    final nom = (exam['nom_examen'] as String?) ?? '—';
    final statut = (exam['statut_examen'] as String?) ?? '';
    final resultat = exam['resultat'] as String?;

    Color statutColor;
    switch (statut.toLowerCase()) {
      case 'disponible':
      case 'resultat-disponible':
        statutColor = _green;
        break;
      case 'en attente':
        statutColor = _orange;
        break;
      default:
        statutColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statutColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                if (resultat != null && resultat.isNotEmpty)
                  Text(
                    resultat,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statut,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statutColor,
            ),
          ),
        ],
      ),
    );
  }
}
