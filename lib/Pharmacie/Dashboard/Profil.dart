import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/shared/responsive_wrapper.dart';
import 'package:hostoman/model_unifier.dart';
import '../shared/pharmacie_theme.dart';
import 'profil_service.dart';

class ProfilPharmacien extends StatefulWidget {
  const ProfilPharmacien({super.key});

  @override
  State<ProfilPharmacien> createState() => _ProfilPharmacienState();
}

class _ProfilPharmacienState extends State<ProfilPharmacien> {
  final _service = PharmacienService(Supabase.instance.client);
  Medecin? _user;
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = await _service.fetchPharmacienConnecte();
    final stats = await _service.fetchStatsPharmacien();
    if (mounted) {
      setState(() {
        _user = user;
        _stats = stats;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(mobile: _buildMobile(), pc: _buildPc());
  }

  Widget _buildMobile() {
    return Scaffold(
      backgroundColor: PharmacieTheme.background,
      drawer: const PharmacieDrawer(activeRoute: '/Dashboard_Pharmacie/Profil'),
      appBar: PharmacieAppBar(title: 'phar_profil_title'.tr()),
      body: _buildBody(),
    );
  }

  Widget _buildPc() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: PharmacieTheme.primary),
      );
    }
    if (_user == null) {
      return Center(child: Text('phar_profil_no_user'.tr()));
    }

    final delivrees = _stats['delivrees_total'] ?? 0;
    final ventesJour = (_stats['ventes_jour'] as double?) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Carte d'en-tête
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [PharmacieTheme.primary, PharmacieTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: PharmacieTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.local_pharmacy,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${_user!.nom} ${_user!.prenom}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _user!.specialite ?? 'Pharmacien',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stats
          Row(
            children: [
              Expanded(
                child: PharmacieKpiCard(
                  icon: Icons.local_shipping_outlined,
                  label: 'phar_profil_delivrees'.tr(),
                  value: '$delivrees',
                  color: PharmacieTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PharmacieKpiCard(
                  icon: Icons.payments_outlined,
                  label: 'phar_profil_ventes_jour'.tr(),
                  value: '${ventesJour.toStringAsFixed(0)} F',
                  color: PharmacieTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Coordonnées
          _infoCard([
            _infoRow(
              Icons.email_outlined,
              'phar_profil_email'.tr(),
              _user!.email ?? '—',
            ),
            _infoRow(
              Icons.phone_outlined,
              'phar_profil_phone'.tr(),
              _user!.telephone?.toString() ?? '—',
            ),
            _infoRow(
              Icons.home_outlined,
              'phar_profil_address'.tr(),
              _user!.adresse ?? '—',
            ),
            _infoRow(
              Icons.person_outline,
              'phar_profil_age'.tr(),
              _user!.age?.toString() ?? '—',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PharmacieTheme.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: PharmacieTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: PharmacieTheme.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: PharmacieTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
