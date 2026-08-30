import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/shared/responsive_wrapper.dart';
import '../shared/pharmacie_theme.dart';
import '../Ordonnances/ordonnances_service.dart';

class VenteLibrePage extends StatefulWidget {
  const VenteLibrePage({super.key});

  @override
  State<VenteLibrePage> createState() => _VenteLibrePageState();
}

class _VenteLibrePageState extends State<VenteLibrePage> {
  final _service = OrdonnancesService(Supabase.instance.client);

  List<Map<String, dynamic>> _prescriptions = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.listerConsultationsEnAttente();
      if (mounted) {
        setState(() {
          _prescriptions = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _prescriptions;
    final q = _search.toLowerCase();
    return _prescriptions.where((p) {
      final nom = (p['Patient']?['nom_complet'] ?? '').toString().toLowerCase();
      return nom.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(mobile: _buildMobile(), pc: _buildPc());
  }

  Widget _buildMobile() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: PharmacieTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/Dashboard_Pharmacie'),
        ),
        title: Text(
          'phar_vl_title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildPc() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'phar_vl_title'.tr(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: PharmacieTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recherche
              TextField(
                onChanged: (v) =>
                    setState(() => _search = v.toLowerCase().trim()),
                decoration: InputDecoration(
                  hintText: 'phar_vl_search_patient'.tr(),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: PharmacieTheme.textMuted,
                  ),
                  suffixIcon: const Icon(
                    Icons.filter_alt_outlined,
                    color: PharmacieTheme.textMuted,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: PharmacieTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: PharmacieTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: PharmacieTheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Bouton nouvelle vente directe (sans consultation)
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context
                      .push('/Dashboard_Pharmacie/VenteLibre/NouvelleVente')
                      .then((_) => _load()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: PharmacieTheme.primary,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.playlist_add_rounded,
                          color: PharmacieTheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'phar_action_nouvelle_vente'.tr(),
                            style: const TextStyle(
                              color: PharmacieTheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: PharmacieTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'phar_vl_section_consultation'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: PharmacieTheme.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        // Liste patients
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: PharmacieTheme.primary,
                  ),
                )
              : _error != null
              ? _errorView()
              : _filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 56,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'phar_vl_empty'.tr(),
                        style: const TextStyle(color: PharmacieTheme.textMuted),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _patientCard(_filtered[i]),
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'fiche_footer'.tr(),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ),
      ],
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: PharmacieTheme.danger,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'phar_action_error'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PharmacieTheme.danger,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text('phar_retry'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: PharmacieTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _patientCard(Map<String, dynamic> prescription) {
    final patient = prescription['Patient'] as Map<String, dynamic>? ?? {};
    final consultation =
        prescription['Consultation'] as Map<String, dynamic>? ?? {};
    final pv = consultation['Parametres_vitaux'] as Map<String, dynamic>? ?? {};
    final nom = (patient['nom_complet'] ?? '—').toString();
    final motif = (pv['motif_de_consultation'] ?? '—').toString();
    final initial = nom.isNotEmpty ? nom[0].toUpperCase() : '?';
    final idPrescription = prescription['id_prescription'] as int;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context
            .push('/Dashboard_Pharmacie/Ordonnances/$idPrescription')
            .then((_) => _load()),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PharmacieTheme.border, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PharmacieTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: PharmacieTheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: PharmacieTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${'phar_vl_motif'.tr()}: $motif',
                      style: const TextStyle(
                        fontSize: 12,
                        color: PharmacieTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: PharmacieTheme.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
