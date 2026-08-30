import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hostoman/SuperAdmin/superadmin_service.dart';
import 'package:hostoman/SuperAdmin/hopital_dashboard_page.dart';
import 'package:hostoman/shared/user_profile_helper.dart';

class DashboardSuperAdmin extends StatefulWidget {
  const DashboardSuperAdmin({super.key});

  @override
  State<DashboardSuperAdmin> createState() => _DashboardSuperAdminState();
}

class _DashboardSuperAdminState extends State<DashboardSuperAdmin>
    with SingleTickerProviderStateMixin {
  late final SuperAdminService _service;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  bool _isLoading = true;
  List<Map<String, dynamic>> _hospitaux = [];
  String _searchQuery = '';

  // ── Palette sobre alignée sur le reste de l'application ──
  static const Color _bg       = Color(0xFFF5F6FA);
  static const Color _surface  = Colors.white;
  static const Color _primary  = Color(0xFF1A237E); // bleu marine (même que Directeur)
  static const Color _text     = Color(0xFF0F172A);
  static const Color _subtext  = Color(0xFF64748B);
  static const Color _border   = Color(0xFFE2E8F0);
  static const Color _success  = Color(0xFF16A34A);
  static const Color _danger   = Color(0xFFDC2626);
  static const Color _warning  = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _service = SuperAdminService(Supabase.instance.client);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _chargerDonnees();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _isLoading = true);
    final list = await _service.getHospitaux();
    if (mounted) {
      setState(() {
        _hospitaux = list;
        _isLoading = false;
      });
      _animController.forward(from: 0);
    }
  }

  List<Map<String, dynamic>> get _filteredHospitaux {
    if (_searchQuery.isEmpty) return _hospitaux;
    final q = _searchQuery.toLowerCase();
    return _hospitaux
        .where((h) =>
            (h['nom_hopital'] ?? '').toLowerCase().contains(q) ||
            (h['adresse'] ?? '').toLowerCase().contains(q))
        .toList();
  }

  // ─────────────────────────────────────────────────────────────────
  //  Modale Création Hôpital
  // ─────────────────────────────────────────────────────────────────
  void _ouvrirModalCreation() {
    final formKey        = GlobalKey<FormState>();
    final nomHopitalCtrl = TextEditingController();
    final codeHopitalCtrl = TextEditingController();
    final adresseCtrl    = TextEditingController();
    final telHopitalCtrl = TextEditingController();
    final emailCtrl      = TextEditingController();
    final nomDirCtrl     = TextEditingController();
    final prenomDirCtrl  = TextEditingController();
    final telDirCtrl     = TextEditingController();
    final ageDirCtrl     = TextEditingController(text: '40');
    String sexeDir = 'M';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: _surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_location_alt_outlined, color: _primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Nouveau Centre de Santé',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _text)),
              ),
            ]),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9 < 560
                    ? MediaQuery.of(context).size.width * 0.9
                    : 560,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      _formLabel('Centre de Santé'),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          flex: 2,
                          child: _field(
                            controller: nomHopitalCtrl,
                            label: 'Nom du centre *',
                            icon: Icons.local_hospital_outlined,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: _field(
                            controller: codeHopitalCtrl,
                            label: 'Code (ex: HDM) *',
                            icon: Icons.subtitles_outlined,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _field(controller: adresseCtrl, label: 'Ville / Adresse', icon: Icons.place_outlined)),
                        const SizedBox(width: 10),
                        Expanded(child: _field(controller: telHopitalCtrl, label: 'Téléphone', icon: Icons.phone_outlined)),
                      ]),
                      const SizedBox(height: 10),
                      _field(controller: emailCtrl, label: 'Email institutionnel', icon: Icons.mail_outline),
                      const SizedBox(height: 20),
                      const Divider(color: _border),
                      const SizedBox(height: 12),
                      _formLabel('Directeur Désigné'),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _field(controller: nomDirCtrl, label: 'Nom *', icon: Icons.person_outline,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null)),
                        const SizedBox(width: 10),
                        Expanded(child: _field(controller: prenomDirCtrl, label: 'Prénom', icon: Icons.person_outline)),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _field(controller: telDirCtrl, label: 'Téléphone *', icon: Icons.phone_android_outlined,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: sexeDir,
                            decoration: _inputDecoration('Sexe', Icons.wc_outlined),
                            items: const [
                              DropdownMenuItem(value: 'M', child: Text('Masculin')),
                              DropdownMenuItem(value: 'F', child: Text('Féminin')),
                            ],
                            onChanged: (val) { if (val != null) sexeDir = val; },
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _warning.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _warning.withValues(alpha: 0.25)),
                        ),
                        child: Row(children: [
                          Icon(Icons.info_outline, color: _warning, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            'Un ID unique (ex: ${codeHopitalCtrl.text.isEmpty ? 'HDM' : codeHopitalCtrl.text.toUpperCase()}-12345) sera généré pour l\'activation du Directeur.',
                            style: TextStyle(fontSize: 12, color: _warning.withValues(alpha: 0.95)),
                          )),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Annuler', style: TextStyle(color: _subtext)),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSubmitting ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  setDialogState(() => isSubmitting = true);
                  final err = await _service.enregistrerHopitalEtDirecteur(
                    nomHopital: nomHopitalCtrl.text.trim(),
                    codeHopital: codeHopitalCtrl.text.trim(),
                    adresse: adresseCtrl.text.trim(),
                    telephone: telHopitalCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    nomDirecteur: nomDirCtrl.text.trim(),
                    prenomDirecteur: prenomDirCtrl.text.trim(),
                    telDirecteur: telDirCtrl.text.trim(),
                    sexeDirecteur: sexeDir,
                    ageDirecteur: ageDirCtrl.text.trim(),
                  );
                  if (mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(err ?? 'Centre de santé créé avec succès.'),
                      backgroundColor: err != null ? _danger : _success,
                    ));
                    if (err == null) _chargerDonnees();
                  }
                },
                icon: isSubmitting
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check, size: 18),
                label: const Text('Créer', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        });
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Modale Suppression Sécurisée
  // ─────────────────────────────────────────────────────────────────
  void _ouvrirModalSuppression(Map<String, dynamic> hopital) {
    final formKey       = GlobalKey<FormState>();
    final passwordCtrl  = TextEditingController();
    final confirmCtrl   = TextEditingController();
    final String nomExact  = hopital['nom_hopital'] ?? '';
    final String idHopital = hopital['id_hopital'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isDeleting   = false;
        bool confirmMatch = false;

        return StatefulBuilder(builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: _surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _danger, width: 1),
            ),
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: _danger, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Suppression Définitive',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _danger)),
              ),
            ]),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _danger.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _danger.withValues(alpha: 0.2)),
                        ),
                        child: const Text(
                          '⚠️ Action irréversible — patients, consultations et toutes les données seront effacées.',
                          style: TextStyle(fontSize: 13, color: _danger),
                        ),
                      ),
                      const SizedBox(height: 16),
                      RichText(text: TextSpan(
                        style: const TextStyle(fontSize: 13, color: _text),
                        children: [
                          const TextSpan(text: 'Tapez le nom exact pour confirmer : '),
                          TextSpan(text: '"$nomExact"',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: _primary)),
                        ],
                      )),
                      const SizedBox(height: 8),
                      _field(controller: confirmCtrl, label: 'Nom de confirmation', icon: Icons.verified_outlined,
                          onChanged: (val) => setDialogState(() {
                            confirmMatch = (val.trim() == nomExact.trim());
                          })),
                      const SizedBox(height: 14),
                      _field(controller: passwordCtrl, label: 'Votre mot de passe Super-Admin *',
                          icon: Icons.lock_outline, obscureText: true,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Annuler', style: TextStyle(color: _subtext)),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: (!confirmMatch || isDeleting) ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  setDialogState(() => isDeleting = true);
                  final err = await _service.supprimerHopital(
                    idHopital: idHopital,
                    motDePasseAdmin: passwordCtrl.text.trim(),
                  );
                  if (mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(err ?? 'Centre supprimé définitivement.'),
                      backgroundColor: err != null ? _danger : _success,
                    ));
                    if (err == null) _chargerDonnees();
                  }
                },
                icon: isDeleting
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.delete_forever, size: 18),
                label: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        });
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Modale Profil Super-Admin
  // ─────────────────────────────────────────────────────────────────
  void _ouvrirModalProfil() async {
    final user = Supabase.instance.client.auth.currentUser;
    final userData = await UserProfileHelper.getUserData();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person, color: _primary, size: 24),
              ),
              const SizedBox(width: 12),
              Text('sa_profile_title'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _text)),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: _primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.person, color: _primary, size: 40),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${userData?['Nom'] ?? 'Super'} ${userData?['Prenom'] ?? 'Admin'}'.trim(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _text),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('sa_principal_admin'.tr(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _primary)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: _border),
                const SizedBox(height: 10),
                _infoRow(Icons.email_outlined, 'sa_email'.tr(), user?.email ?? 'N/A'),
                const SizedBox(height: 10),
                _infoRow(Icons.phone_outlined, 'sa_phone'.tr(), userData?['telephone']?.toString() ?? 'N/A'),
                const SizedBox(height: 10),
                _infoRow(Icons.shield_outlined, 'sa_access'.tr(), 'sa_global_admin'.tr()),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('sa_close'.tr(), style: const TextStyle(color: _subtext)),
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _subtext),
        const SizedBox(width: 10),
        Text('$label : ', style: const TextStyle(fontSize: 13, color: _subtext)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Modale Paramètres Super-Admin
  // ─────────────────────────────────────────────────────────────────
  void _ouvrirModalParametres() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final currentLocale = context.locale;
            final isEn = currentLocale.languageCode == 'en';
            final currentLangLabel = isEn ? 'English (US)' : 'Français (FR)';

            return AlertDialog(
              backgroundColor: _surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.settings, color: _primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text('sa_system_settings'.tr(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _text)),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language_outlined, color: _primary),
                      title: Text('sa_app_language'.tr()),
                      subtitle: Text(currentLangLabel),
                      trailing: const Icon(Icons.chevron_right, color: _subtext),
                      onTap: () async {
                        final picked = await showDialog<Locale>(
                          context: context,
                          builder: (pickerCtx) => AlertDialog(
                            title: Text('sa_choose_lang'.tr()),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.flag_outlined, color: _primary),
                                  title: const Text('Français (FR)'),
                                  trailing: !isEn ? const Icon(Icons.check, color: _success) : null,
                                  onTap: () => Navigator.pop(pickerCtx, const Locale('fr', 'FR')),
                                ),
                                const Divider(color: _border),
                                ListTile(
                                  leading: const Icon(Icons.flag_outlined, color: _primary),
                                  title: const Text('English (US)'),
                                  trailing: isEn ? const Icon(Icons.check, color: _success) : null,
                                  onTap: () => Navigator.pop(pickerCtx, const Locale('en', 'US')),
                                ),
                              ],
                            ),
                          ),
                        );

                        if (picked != null && mounted) {
                          await context.setLocale(picked);
                          setDialogState(() {});
                          if (mounted) setState(() {});
                        }
                      },
                    ),
                    const Divider(color: _border),
                    ListTile(
                      leading: const Icon(Icons.security_outlined, color: _primary),
                      title: Text('sa_security'.tr()),
                      subtitle: Text('sa_security_sub'.tr()),
                      trailing: const Icon(Icons.chevron_right, color: _subtext),
                      onTap: () {},
                    ),
                    const Divider(color: _border),
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined, color: _primary),
                      title: Text('sa_notifications'.tr()),
                      subtitle: Text('sa_notifications_sub'.tr()),
                      trailing: const Icon(Icons.chevron_right, color: _subtext),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('sa_close'.tr(), style: const TextStyle(color: _subtext)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  BUILD PRINCIPAL
  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final actifs   = _hospitaux.where((h) => h['actif'] == true).length;
    final inactifs = _hospitaux.length - actifs;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('sa_title'.tr(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('sa_subtitle'.tr(),
                  style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ]),
        actions: [
          IconButton(
            tooltip: 'sa_refresh'.tr(),
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _chargerDonnees,
          ),
          PopupMenuButton<String>(
            tooltip: 'sa_account'.tr(),
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 22),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            offset: const Offset(0, 48),
            onSelected: (value) async {
              if (value == 'profil') {
                _ouvrirModalProfil();
              } else if (value == 'parametres') {
                _ouvrirModalParametres();
              } else if (value == 'deconnexion') {
                UserProfileHelper.clearCache();
                await Supabase.instance.client.auth.signOut();
                if (mounted) context.go('/Authen_Personnel');
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                value: 'profil',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, color: _primary, size: 20),
                    const SizedBox(width: 10),
                    Text('sa_profile'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'parametres',
                child: Row(
                  children: [
                    const Icon(Icons.settings_outlined, color: _primary, size: 20),
                    const SizedBox(width: 10),
                    Text('sa_settings'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'deconnexion',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: _danger, size: 20),
                    const SizedBox(width: 10),
                    Text('sa_logout'.tr(), style: const TextStyle(color: _danger, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Bandeau KPI ──
          _buildKpiStrip(actifs, inactifs),
          // ── Barre recherche + bouton ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(children: [
              Expanded(child: _buildSearchBar()),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _ouvrirModalCreation,
                icon: const Icon(Icons.add, size: 18),
                label: Text('sa_new_center'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ]),
          ),
          // ── Liste ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _primary))
                : _filteredHospitaux.isEmpty
                    ? _buildEmptyState()
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: _filteredHospitaux.length,
                          itemBuilder: (_, i) =>
                              _buildHospitalCard(_filteredHospitaux[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Bandeau KPI cartes élégantes & très visibles ──
  Widget _buildKpiStrip(int actifs, int inactifs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final kpiItems = [
          {
            'label': 'sa_total_centers'.tr(),
            'value': _hospitaux.length.toString(),
            'icon': Icons.location_city_rounded,
            'color': _primary,
          },
          {
            'label': 'sa_active'.tr(),
            'value': actifs.toString(),
            'icon': Icons.check_circle_rounded,
            'color': _success,
          },
          {
            'label': 'sa_suspended'.tr(),
            'value': inactifs.toString(),
            'icon': Icons.block_rounded,
            'color': _danger,
          },
        ];

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 20,
            vertical: isMobile ? 12 : 16,
          ),
          child: Row(
            children: kpiItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < kpiItems.length - 1 ? (isMobile ? 8 : 14) : 0,
                  ),
                  child: _kpiCard(
                    item['label'] as String,
                    item['value'] as String,
                    item['icon'] as IconData,
                    item['color'] as Color,
                    isMobile: isMobile,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color, {bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 16,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: isMobile ? 20 : 26),
          ),
          SizedBox(width: isMobile ? 8 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 26,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 13,
                    fontWeight: FontWeight.w500,
                    color: _subtext,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      style: const TextStyle(color: _text, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'sa_search_hint'.tr(),
        hintStyle: const TextStyle(color: _subtext, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: _subtext, size: 20),
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
      onChanged: (v) => setState(() => _searchQuery = v),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_hospital_outlined, size: 56, color: _subtext.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('sa_no_center'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _text)),
          const SizedBox(height: 8),
          Text('sa_create_first'.tr(),
              style: const TextStyle(color: _subtext, fontSize: 14)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _ouvrirModalCreation,
            icon: const Icon(Icons.add),
            label: Text('sa_create_center'.tr()),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Carte hôpital sobre, claire et responsive ──
  Widget _buildHospitalCard(Map<String, dynamic> hopital) {
    final directeurs = hopital['directeurs'] as List<dynamic>? ?? [];
    final directeur  = directeurs.isNotEmpty ? directeurs.first : null;
    final bool estActif = hopital['actif'] ?? true;
    final String nom    = hopital['nom_hopital'] ?? 'Sans nom';
    final String adresse = hopital['adresse'] ?? '';
    final String tel    = hopital['telephone'] ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HopitalDashboardPage(hopital: hopital),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Ligne principale ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.local_hospital_outlined, color: _primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    nom,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _text,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _statusBadge(estActif),
                              ],
                            ),
                            if (adresse.isNotEmpty || tel.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 4,
                                  children: [
                                    if (adresse.isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.place_outlined, size: 13, color: _subtext),
                                          const SizedBox(width: 3),
                                          Flexible(
                                            child: Text(
                                              adresse,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 12, color: _subtext),
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (tel.isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.phone_outlined, size: 13, color: _subtext),
                                          const SizedBox(width: 3),
                                          Text(tel, style: const TextStyle(fontSize: 12, color: _subtext)),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: _border, height: 1),
                  const SizedBox(height: 10),

                  // ── Ligne ou Colonne des actions (Responsive) ──
                  if (isMobile) ...[
                    // Sur mobile : Nom Directeur + ID en haut, Boutons en dessous
                    Row(
                      children: [
                        Icon(Icons.badge_outlined, size: 16, color: directeur != null ? _subtext : _danger),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            directeur != null
                                ? '${directeur['Prenom'] ?? ''} ${directeur['Nom'] ?? ''} ${(directeur['id_utilisateur'] ?? directeur['username']) != null ? '(${directeur['id_utilisateur'] ?? directeur['username']})' : ''}'.trim()
                                : 'sa_no_director'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: directeur != null ? _text : _danger,
                              fontStyle: directeur == null ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HopitalDashboardPage(hopital: hopital),
                            ),
                          ),
                          icon: const Icon(Icons.bar_chart_outlined, size: 16),
                          label: Text('sa_stats'.tr()),
                          style: TextButton.styleFrom(
                            foregroundColor: _primary,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          tooltip: estActif ? 'sa_suspend_access'.tr() : 'sa_reactivate'.tr(),
                          icon: Icon(
                            estActif ? Icons.block_outlined : Icons.check_circle_outline,
                            color: estActif ? _warning : _success,
                            size: 20,
                          ),
                          onPressed: () async {
                            await _service.toggleHopitalActif(hopital['id_hopital'], !estActif);
                            _chargerDonnees();
                          },
                        ),
                        IconButton(
                          tooltip: 'sa_delete_perm'.tr(),
                          icon: Icon(Icons.delete_outline, color: _danger.withValues(alpha: 0.8), size: 20),
                          onPressed: () => _ouvrirModalSuppression(hopital),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Sur PC / Écran large : Ligne unique
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.badge_outlined, size: 16, color: directeur != null ? _subtext : _danger),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  directeur != null
                                      ? '${directeur['Prenom'] ?? ''} ${directeur['Nom'] ?? ''} ${(directeur['id_utilisateur'] ?? directeur['username']) != null ? '(${directeur['id_utilisateur'] ?? directeur['username']})' : ''}'.trim()
                                      : 'sa_no_director'.tr(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: directeur != null ? _text : _danger,
                                    fontStyle: directeur == null ? FontStyle.italic : FontStyle.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HopitalDashboardPage(hopital: hopital),
                            ),
                          ),
                          icon: const Icon(Icons.bar_chart_outlined, size: 16),
                          label: Text('sa_stats'.tr()),
                          style: TextButton.styleFrom(
                            foregroundColor: _primary,
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: estActif ? 'sa_suspend_access'.tr() : 'sa_reactivate'.tr(),
                          icon: Icon(
                            estActif ? Icons.block_outlined : Icons.check_circle_outline,
                            color: estActif ? _warning : _success,
                            size: 20,
                          ),
                          onPressed: () async {
                            await _service.toggleHopitalActif(hopital['id_hopital'], !estActif);
                            _chargerDonnees();
                          },
                        ),
                        IconButton(
                          tooltip: 'sa_delete_perm'.tr(),
                          icon: Icon(Icons.delete_outline, color: _danger.withValues(alpha: 0.8), size: 20),
                          onPressed: () => _ouvrirModalSuppression(hopital),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statusBadge(bool estActif) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (estActif ? _success : _danger).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: (estActif ? _success : _danger).withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: estActif ? _success : _danger),
        ),
        const SizedBox(width: 5),
        Text(
          estActif ? 'Actif' : 'Suspendu',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: estActif ? _success : _danger),
        ),
      ]),
    );
  }

  // ── Helpers formulaire ──
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _subtext, fontSize: 13),
      prefixIcon: Icon(icon, color: _subtext, size: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _danger, width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFFAFAFC),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: _text, fontSize: 14),
      onChanged: onChanged,
      validator: validator,
      decoration: _inputDecoration(label, icon),
    );
  }

  Widget _formLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.bold, color: _primary),
    );
  }
}
