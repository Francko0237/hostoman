import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hostoman/app_config.dart';

const Color _primary = Color(0xFF1565C0);
const Color _success = Color(0xFF2E7D32);
const Color _error = Color(0xFFC62828);
const Color _orange = Color(0xFFE65100);

class MotDePasseOubliePage extends StatefulWidget {
  const MotDePasseOubliePage({super.key});

  @override
  State<MotDePasseOubliePage> createState() => _MotDePasseOubliePageState();
}

class _MotDePasseOubliePageState extends State<MotDePasseOubliePage> {
  int _etape = 1;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _pw1Ctrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePw1 = true;
  bool _obscurePw2 = true;
  String? _pw2Error;
  Map<String, dynamic>? _ficheTrouvee;

  bool get _pwHasMinLength => _pw1Ctrl.text.length >= 6;
  bool get _pwHasLetter => RegExp(r'[a-zA-ZÀ-ÿ]').hasMatch(_pw1Ctrl.text);
  bool get _pwHasDigit => RegExp(r'\d').hasMatch(_pw1Ctrl.text);
  bool get _pwMatch =>
      _pw1Ctrl.text.isNotEmpty && _pw1Ctrl.text == _pw2Ctrl.text;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _pw1Ctrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _soumettreDemande() async {
    if (!_formKey1.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final input = _usernameCtrl.text.trim();

    try {
      List<dynamic> results = await Supabase.instance.client
          .from('utilisateur')
          .select('id_utilisateur, Nom, Prenom, compte_actif, reset_password_statut, auth_id, username')
          .ilike('id_utilisateur', input);

      if (results.isEmpty) {
        results = await Supabase.instance.client
            .from('utilisateur')
            .select('id_utilisateur, Nom, Prenom, compte_actif, reset_password_statut, auth_id, username')
            .ilike('username', input);
      }

      if (results.isEmpty) {
        _showSnack('Aucun compte trouvé avec l\'ID Agent "$input".', isError: true);
        return;
      }

      final fiche = results.first as Map<String, dynamic>;

      if (fiche['compte_actif'] != true) {
        _showSnack('mdpo_error_inactive'.tr(), isError: true);
        return;
      }

      final statut = fiche['reset_password_statut']?.toString();

      if (statut == 'valide') {
        setState(() {
          _ficheTrouvee = fiche;
          _etape = 2;
        });
        return;
      }

      if (statut == 'en_attente') {
        _showSnack('mdpo_error_pending'.tr(), isWarning: true);
        return;
      }

      if (statut == 'rejete') {
        if (!mounted) return;
        final reSubmit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.info_outline, color: _orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'mdpo_dlg_rejected_title'.tr(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Text(
              'mdpo_dlg_rejected_content'.tr(),
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('mdpo_dlg_cancel'.tr()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                ),
                child: Text('mdpo_dlg_new_request'.tr()),
              ),
            ],
          ),
        );

        if (reSubmit != true) return;
      }

      await Supabase.instance.client
          .from('utilisateur')
          .update({'reset_password_statut': 'en_attente'})
          .eq('id_utilisateur', fiche['id_utilisateur']);

      _showSnack('mdpo_success_sent'.tr());
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/Authen_Personnel');
    } catch (e) {
      _showSnack(
        'mdpo_error_unexpected'.tr(namedArgs: {'msg': '$e'}),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reinitialiserMotDePasse() async {
    if (!_formKey2.currentState!.validate()) return;
    if (!_pwHasMinLength || !_pwHasLetter || !_pwHasDigit) {
      _showSnack('mdpo_pw_strength'.tr(), isError: true);
      return;
    }
    if (!_pwMatch) {
      _showSnack('mdpo_pw_mismatch'.tr(), isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authId = _ficheTrouvee!['auth_id']?.toString();
      if (authId == null) {
        _showSnack('mdpo_error_auth'.tr(), isError: true);
        return;
      }

      final response = await http
          .put(
            Uri.parse(AppConfig.adminUpdateUserUrl(authId)),
            headers: AppConfig.adminHeaders,
            body: jsonEncode({'password': _pw1Ctrl.text}),
          )
          .timeout(AppConfig.adminApiTimeout);

      if (response.statusCode != 200) {
        _showSnack('mdpo_error_reset'.tr(), isError: true);
        return;
      }

      await Supabase.instance.client
          .from('utilisateur')
          .update({'reset_password_statut': null})
          .eq('id_utilisateur', _ficheTrouvee!['id_utilisateur']);

      _showSnack('mdpo_success_reset'.tr());
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) context.go('/Authen_Personnel');
    } catch (e) {
      _showSnack(
        'mdpo_error_unexpected'.tr(namedArgs: {'msg': '$e'}),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifierStatutPourReinit() async {
    if (!_formKey1.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final input = _usernameCtrl.text.trim();
    try {
      List<dynamic> results = await Supabase.instance.client
          .from('utilisateur')
          .select('id_utilisateur, Nom, Prenom, auth_id, compte_actif, reset_password_statut, username')
          .ilike('id_utilisateur', input);

      if (results.isEmpty) {
        results = await Supabase.instance.client
            .from('utilisateur')
            .select('id_utilisateur, Nom, Prenom, auth_id, compte_actif, reset_password_statut, username')
            .ilike('username', input);
      }

      if (results.isEmpty) {
        _showSnack('mdpo_error_not_found'.tr(), isError: true);
        return;
      }

      final fiche = results.first as Map<String, dynamic>;
      final statut = fiche['reset_password_statut']?.toString();
      if (statut == 'valide') {
        setState(() {
          _ficheTrouvee = fiche;
          _etape = 2;
        });
      } else if (statut == 'en_attente') {
        _showSnack('mdpo_error_pending'.tr(), isWarning: true);
      } else if (statut == 'rejete') {
        _showSnack('mdpo_error_rejected'.tr(), isError: true);
      } else {
        _showSnack('mdpo_error_no_request'.tr(), isError: true);
      }
    } catch (e) {
      _showSnack(
        'mdpo_error_unexpected'.tr(namedArgs: {'msg': '$e'}),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false, bool isWarning = false}) {
    if (!mounted) return;
    Color color = _success;
    if (isError) color = _error;
    if (isWarning) color = _orange;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 700) return _buildPcLayout();
    return _buildMobileLayout();
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.local_hospital,
                        size: 44,
                        color: _primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'mdpo_title'.tr(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 28),
                _buildFormCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPcLayout() {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0D47A1),
                    Color(0xFF1565C0),
                    Color(0xFF1976D2),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.local_hospital,
                                size: 55,
                                color: _primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'mdpo_left_title'.tr(),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 48,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _infoRow(Icons.send_rounded, 'mdpo_step1_badge'.tr()),
                      const SizedBox(height: 12),
                      _infoRow(Icons.lock_reset, 'mdpo_step2_badge'.tr()),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFFF8FAFF),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 40,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'mdpo_title'.tr(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildFormCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: _etape == 1 ? _buildStep1() : _buildStep2(),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'mdpo_username_title'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'mdpo_username_subtitle'.tr(),
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _usernameCtrl,
            style: const TextStyle(fontSize: 15),
            decoration: _inputDeco(
              label: 'mdpo_username_label'.tr(),
              icon: Icons.badge_outlined,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return 'mdpo_username_required'.tr();
              return null;
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _isLoading ? null : _verifierStatutPourReinit,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'mdpo_check_btn'.tr(),
                style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _soumettreDemande,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'mdpo_send_btn'.tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context.go('/Authen_Personnel'),
              child: Text(
                'mdpo_back_login'.tr(),
                style: const TextStyle(color: _primary, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF4CAF50)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: _success, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'mdpo_validated_banner'.tr(
                      namedArgs: {
                        'prenom': _ficheTrouvee?['Prenom'] ?? '',
                        'nom': _ficheTrouvee?['Nom'] ?? '',
                      },
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'mdpo_new_password_title'.tr(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _pw1Ctrl,
            obscureText: _obscurePw1,
            style: const TextStyle(fontSize: 15),
            onChanged: (_) => setState(() {}),
            decoration: _inputDeco(
              label: 'mdpo_new_password_label'.tr(),
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePw1 ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => _obscurePw1 = !_obscurePw1),
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'mdpo_pw_required'.tr() : null,
          ),
          const SizedBox(height: 10),
          _buildPasswordIndicators(),
          const SizedBox(height: 16),
          Text(
            'mdpo_confirm_title'.tr(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _pw2Ctrl,
            obscureText: _obscurePw2,
            style: const TextStyle(fontSize: 15),
            onChanged: (v) {
              setState(() {
                _pw2Error = v.isNotEmpty && v != _pw1Ctrl.text
                    ? 'mdpo_pw_mismatch'.tr()
                    : null;
              });
            },
            decoration: _inputDeco(
              label: 'mdpo_confirm_label'.tr(),
              icon: Icons.lock_outline,
              errorText: _pw2Error,
              suffixIcon: _pw2Ctrl.text.isNotEmpty
                  ? Icon(
                      _pwMatch ? Icons.check_circle : Icons.cancel,
                      color: _pwMatch ? _success : _error,
                    )
                  : IconButton(
                      icon: Icon(
                        _obscurePw2 ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePw2 = !_obscurePw2),
                    ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'mdpo_pw_required'.tr();
              if (v != _pw1Ctrl.text) return 'mdpo_pw_mismatch'.tr();
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _reinitialiserMotDePasse,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'mdpo_reset_btn'.tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordIndicators() {
    return Column(
      children: [
        _indicator(_pwHasMinLength, 'mdpo_pw_min6'.tr()),
        const SizedBox(height: 4),
        _indicator(_pwHasLetter, 'mdpo_pw_letter'.tr()),
        const SizedBox(height: 4),
        _indicator(_pwHasDigit, 'mdpo_pw_digit'.tr()),
      ],
    );
  }

  Widget _indicator(bool ok, String label) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: ok ? _success : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: ok ? _success : Colors.grey[600],
            fontWeight: ok ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDeco({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      errorText: errorText,
      prefixIcon: Icon(icon, color: _primary, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _error, width: 2),
      ),
    );
  }
}
