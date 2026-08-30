import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:hostoman/app_config.dart';
import 'dart:convert';

class PremiereConnexionPage extends StatefulWidget {
  const PremiereConnexionPage({super.key});

  @override
  State<PremiereConnexionPage> createState() => _PremiereConnexionPageState();
}

class _PremiereConnexionPageState extends State<PremiereConnexionPage> {
  int _etape = 1;

  final _formKey1 = GlobalKey<FormState>();
  final _telCtrl = TextEditingController();

  final _formKey2 = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _pw1Ctrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePw1 = true;
  bool _obscurePw2 = true;
  Map<String, dynamic>? _ficheTrouvee;

  String? _pw2Error;
  bool get _pwHasMinLength => _pw1Ctrl.text.length >= 6;
  bool get _pwHasLetter => RegExp(r'[a-zA-ZÀ-ÿ]').hasMatch(_pw1Ctrl.text);
  bool get _pwHasDigit => RegExp(r'\d').hasMatch(_pw1Ctrl.text);
  bool get _pwMatch =>
      _pw1Ctrl.text.isNotEmpty && _pw1Ctrl.text == _pw2Ctrl.text;

  static const Color _primary = Color(0xFF1565C0);
  static const Color _success = Color(0xFF2E7D32);
  static const Color _error = Color(0xFFC62828);

  @override
  void dispose() {
    _telCtrl.dispose();
    _usernameCtrl.dispose();
    _pw1Ctrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _verifierIdAgentOuTel() async {
    if (!_formKey1.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final input = _telCtrl.text.trim();

      // 1. Rechercher d'abord par id_utilisateur (ID agent d'activation personnalisé ex: HDM-58392)
      List<dynamic> results = await Supabase.instance.client
          .from('utilisateur')
          .select('*, hopital(nom_hopital)')
          .ilike('id_utilisateur', input);

      if (results.isEmpty) {
        results = await Supabase.instance.client
            .from('utilisateur')
            .select('*, hopital(nom_hopital)')
            .ilike('username', input);
      }

      // 2. Si non trouvé, tenter par numéro de téléphone
      if (results.isEmpty) {
        final tel = int.tryParse(input);
        if (tel != null) {
          results = await Supabase.instance.client
              .from('utilisateur')
              .select('*, hopital(nom_hopital)')
              .eq('telephone', tel);
        }
      }

      if (results.isEmpty) {
        _showSnack('Aucun compte trouvé pour l\'ID "$input". Vérifiez votre ID d\'activation.', isError: true);
        return;
      }

      // Isoler toutes les fiches non encore activées (compte_actif false)
      final List<Map<String, dynamic>> fichesAActiver = [];
      for (final r in results) {
        final Map<String, dynamic> row = Map<String, dynamic>.from(r);
        if (row['compte_actif'] == false) {
          fichesAActiver.add(row);
        }
      }

      // Si le compte est déjà actif
      if (fichesAActiver.isEmpty) {
        final Map<String, dynamic> first = Map<String, dynamic>.from(results.first);
        if (first['compte_actif'] == true) {
          _showSnack('pc_error_already_active'.tr(), isError: true);
          return;
        }
        _showSnack('Aucun compte disponible pour la première connexion.', isError: true);
        return;
      }

      // Sélectionner la fiche à activer
      setState(() {
        _ficheTrouvee = fichesAActiver.first;
        _etape = 2;
      });
    } catch (e) {
      _showSnack(
        'pc_error_unexpected'.tr(namedArgs: {'msg': '$e'}),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _activerCompte() async {
    if (!_formKey2.currentState!.validate()) return;
    if (!_pwHasMinLength || !_pwHasLetter || !_pwHasDigit) {
      _showSnack('pc_pw_strength'.tr(), isError: true);
      return;
    }
    if (!_pwMatch) {
      _showSnack('pc_pw_mismatch'.tr(), isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final chosenUsername = _usernameCtrl.text.trim().toLowerCase();
    final email = '$chosenUsername@gmail.com';
    final password = _pw1Ctrl.text;

    try {
      // Vérifier si le nom d'utilisateur choisi n'est pas déjà pris par une autre personne active
      final List<dynamic> existingList = await Supabase.instance.client
          .from('utilisateur')
          .select('username')
          .eq('username', chosenUsername)
          .eq('compte_actif', true);

      if (existingList.isNotEmpty) {
        _showSnack('pc_error_username_taken'.tr(), isError: true);
        return;
      }

      final createResponse = await http
          .post(
            Uri.parse(AppConfig.adminCreateUserUrl),
            headers: AppConfig.adminHeaders,
            body: jsonEncode({
              'email': email,
              'password': password,
              'email_confirm': true,
            }),
          )
          .timeout(AppConfig.adminApiTimeout);

      if (createResponse.statusCode != 200 &&
          createResponse.statusCode != 201) {
        _showSnack('pc_error_create'.tr(), isError: true);
        return;
      }

      final body = jsonDecode(createResponse.body) as Map<String, dynamic>;
      final authUserId = body['id']?.toString();

      if (authUserId == null) {
        _showSnack('pc_error_create'.tr(), isError: true);
        return;
      }

      await Supabase.instance.client
          .from('utilisateur')
          .update({
            'auth_id': authUserId,
            'username': chosenUsername,
            'compte_actif': true,
            'email': email,
          })
          .eq('id_utilisateur', _ficheTrouvee!['id_utilisateur']);

      if (!mounted) return;
      _showSnack('pc_success_activated'.tr());
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) context.go('/Authen_Personnel');
    } on AuthException catch (e) {
      _showSnack(
        'pc_error_auth'.tr(namedArgs: {'msg': e.message}),
        isError: true,
      );
    } catch (e) {
      _showSnack(
        'pc_error_unexpected'.tr(namedArgs: {'msg': '$e'}),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? _error : _success,
        duration: const Duration(seconds: 3),
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
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.local_hospital,
                        size: 50,
                        color: _primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'pc_title'.tr(),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStepIndicator(),
                const SizedBox(height: 32),
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
                          width: 120,
                          height: 120,
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
                                size: 60,
                                color: _primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'pc_left_title'.tr(),
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
                      _buildInfoBadge(
                        Icons.phone_android,
                        'pc_step1_badge'.tr(),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoBadge(Icons.person_add, 'pc_step2_badge'.tr()),
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
                          'pc_title'.tr(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStepIndicator(),
                        const SizedBox(height: 28),
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

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepDot(1, 'pc_step_phone'.tr()),
        Expanded(
          child: Container(
            height: 2,
            color: _etape >= 2 ? _primary : Colors.grey.shade300,
          ),
        ),
        _stepDot(2, 'pc_step_account'.tr()),
      ],
    );
  }

  Widget _stepDot(int step, String label) {
    final isActive = _etape >= step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? _primary : Colors.grey.shade300,
          ),
          child: Center(
            child: isActive && _etape > step
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? _primary : Colors.grey,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
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
          const Text(
            'Activation de compte',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Entrez l\'ID agent personnalisé qui vous a été transmis par votre administration (ex: HDM-58392).',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _telCtrl,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.1),
            decoration: _inputDecoration(
              label: 'ID Agent (ex: HDM-58392)',
              icon: Icons.badge_outlined,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Veuillez entrer votre ID d\'activation agent';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifierIdAgentOuTel,
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
                      'pc_continue'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
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
                'pc_back_login'.tr(),
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
                    'pc_welcome'.tr(
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
          const SizedBox(height: 14),
          Text(
            'pc_username_title'.tr(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _usernameCtrl,
            style: const TextStyle(fontSize: 15),
            decoration: _inputDecoration(
              label: 'pc_username_label'.tr(),
              icon: Icons.person_outline,
              hint: 'pc_username_hint'.tr(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return 'pc_username_required'.tr();
              if (v.trim().contains(' ')) return 'pc_username_spaces'.tr();
              if (v.trim().length < 3) return 'pc_username_min'.tr();
              return null;
            },
          ),
          const SizedBox(height: 16),
          Text(
            'pc_password_title'.tr(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _pw1Ctrl,
            obscureText: _obscurePw1,
            style: const TextStyle(fontSize: 15),
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration(
              label: 'pc_password_label'.tr(),
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
                (v == null || v.isEmpty) ? 'pc_pw_required'.tr() : null,
          ),
          const SizedBox(height: 10),
          _buildPasswordIndicators(),
          const SizedBox(height: 16),
          Text(
            'pc_confirm_title'.tr(),
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
                    ? 'pc_pw_mismatch'.tr()
                    : null;
              });
            },
            decoration: _inputDecoration(
              label: 'pc_confirm_label'.tr(),
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
              if (v == null || v.isEmpty) return 'pc_pw_required'.tr();
              if (v != _pw1Ctrl.text) return 'pc_pw_mismatch'.tr();
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _activerCompte,
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
                      'pc_activate'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _etape = 1;
                _ficheTrouvee = null;
              }),
              child: Text(
                'pc_back'.tr(),
                style: const TextStyle(color: _primary, fontSize: 13),
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
        _indicator(_pwHasMinLength, 'pc_pw_min6'.tr()),
        const SizedBox(height: 4),
        _indicator(_pwHasLetter, 'pc_pw_letter'.tr()),
        const SizedBox(height: 4),
        _indicator(_pwHasDigit, 'pc_pw_digit'.tr()),
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
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
        borderSide: const BorderSide(color: Color(0xFFC62828), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC62828), width: 2),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
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
}
