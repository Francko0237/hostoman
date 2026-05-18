import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'personnel_service.dart';

const Color dirPrimaryColor = Color(0xFF1A237E);
const Color dirAccentColor = Color(0xFFFFD700);

// R\u00f4les disponibles
const List<String> _kRoles = [
  'Directeur',
  'M\u00e9decin G\u00e9n\u00e9raliste',
  'Major Accueil',
  'Caissier',
  'Laborantin',
  'Infirmier',
];

String _roleKey(String role) {
  switch (role) {
    case 'Directeur':
      return 'role_director';
    case 'M\u00e9decin G\u00e9n\u00e9raliste':
      return 'role_doctor';
    case 'Major Accueil':
      return 'role_major';
    case 'Caissier':
      return 'role_cashier';
    case 'Laborantin':
      return 'role_lab';
    case 'Infirmier':
      return 'role_nurse';
    default:
      return role;
  }
}

String _trRole(String role) {
  final key = _roleKey(role);
  if (key == role) return role;
  return key.tr();
}

class GestionPersonnelPage extends StatefulWidget {
  const GestionPersonnelPage({super.key});

  @override
  State<GestionPersonnelPage> createState() => _GestionPersonnelPageState();
}

class _GestionPersonnelPageState extends State<GestionPersonnelPage> {
  final PersonnelService _service = PersonnelService(Supabase.instance.client);

  List<Map<String, dynamic>> _personnelList = [];
  List<Map<String, dynamic>> _filteredList = [];
  bool _isLoading = true;
  String _selectedRole = 'Tous';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPersonnel();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonnel() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final list = await _service.getAllPersonnel();
    if (mounted) {
      setState(() {
        _personnelList = list;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _filteredList = _personnelList.where((p) {
      final roleOk =
          _selectedRole == 'Tous' || p['Specialite'] == _selectedRole;
      final q = _searchQuery.toLowerCase();
      final nomOk =
          q.isEmpty ||
          (p['Nom'] ?? '').toString().toLowerCase().contains(q) ||
          (p['Prenom'] ?? '').toString().toLowerCase().contains(q) ||
          (p['email'] ?? '').toString().toLowerCase().contains(q);
      return roleOk && nomOk;
    }).toList();
  }

  // ---------- DIALOG AJOUT / MODIF ----------
  void _showFormDialog({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final formKey = GlobalKey<FormState>();
    final nomCtrl = TextEditingController(text: existing?['Nom'] ?? '');
    final prenomCtrl = TextEditingController(text: existing?['Prenom'] ?? '');
    final emailCtrl = TextEditingController(text: existing?['email'] ?? '');
    final telCtrl = TextEditingController(
      text: existing?['telephone']?.toString() ?? '',
    );
    final adresseCtrl = TextEditingController(text: existing?['adresse'] ?? '');
    final ageCtrl = TextEditingController(
      text: existing?['age']?.toString() ?? '',
    );
    final pwCtrl = TextEditingController();
    String selectedRole = (_kRoles.contains(existing?['Specialite']))
        ? existing!['Specialite']
        : 'M\u00e9decin G\u00e9n\u00e9raliste';
    // Normalise: DB peut stocker 'Homme'/'Femme' ou 'M'/'F'
    final rawSexe = existing?['sexe']?.toString() ?? 'Homme';
    String selectedSexe =
        (rawSexe == 'F' || rawSexe == 'Femme' || rawSexe == 'F\u00e9minin')
        ? 'Femme'
        : 'Homme';
    bool obscure = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: dirPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isEdit
                                ? Icons.edit_rounded
                                : Icons.person_add_rounded,
                            color: dirPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          isEdit
                              ? 'staff_edit_title'.tr()
                              : 'staff_add_title'.tr(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: dirPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Form(
                          key: formKey,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildField(
                                      nomCtrl,
                                      'staff_field_name'.tr(),
                                      Icons.person,
                                      required: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildField(
                                      prenomCtrl,
                                      'staff_field_firstname'.tr(),
                                      Icons.person_outline,
                                      required: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildField(
                                emailCtrl,
                                'staff_field_email'.tr(),
                                Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                required: !isEdit,
                              ),
                              if (!isEdit) ...[
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: pwCtrl,
                                  obscureText: obscure,
                                  validator: (v) => (v == null || v.length < 4)
                                      ? 'staff_min_chars'.tr()
                                      : null,
                                  decoration: InputDecoration(
                                    labelText: 'staff_field_password'.tr(),
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscure
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () =>
                                          setDlgState(() => obscure = !obscure),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildField(
                                      telCtrl,
                                      'staff_field_phone'.tr(),
                                      Icons.phone,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(9),
                                      ],
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return null;
                                        }
                                        final digits = v.trim().replaceAll(
                                          RegExp(r'\D'),
                                          '',
                                        );
                                        if (digits.length != 9) {
                                          return 'staff_phone_digits'.tr();
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildField(
                                      ageCtrl,
                                      'staff_field_age'.tr(),
                                      Icons.cake,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildField(adresseCtrl, 'staff_field_address'.tr(), Icons.home),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: selectedRole,
                                decoration: InputDecoration(
                                  labelText: 'staff_field_role'.tr(),
                                  prefixIcon: const Icon(Icons.badge),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: _kRoles
                                    .map(
                                      (r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(_trRole(r)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setDlgState(() => selectedRole = v!),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: selectedSexe,
                                decoration: InputDecoration(
                                  labelText: 'staff_field_gender'.tr(),
                                  prefixIcon: const Icon(Icons.wc),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'Homme',
                                    child: Text('staff_gender_male'.tr()),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Femme',
                                    child: Text('staff_gender_female'.tr()),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setDlgState(() => selectedSexe = v!),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('staff_cancel'.tr()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final data = {
                                'Nom': nomCtrl.text.trim(),
                                'Prenom': prenomCtrl.text.trim(),
                                if (!isEdit) 'email': emailCtrl.text.trim(),
                                'telephone': int.tryParse(telCtrl.text) ?? 0,
                                'adresse': adresseCtrl.text.trim(),
                                'Specialite': selectedRole,
                                'sexe': selectedSexe,
                                'age': int.tryParse(ageCtrl.text) ?? 0,
                              };
                              Navigator.pop(ctx);
                              String? error;
                              if (isEdit) {
                                error = await _service.updatePersonnel(
                                  existing['id_personnel'],
                                  data,
                                );
                              } else {
                                error = await _service.addPersonnel(
                                  data,
                                  pwCtrl.text,
                                );
                              }
                              if (!mounted) return;
                              if (error == null) {
                                _loadPersonnel();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEdit
                                          ? 'staff_updated_ok'.tr()
                                          : 'staff_added_ok'.tr(),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(error)));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: dirPrimaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(isEdit ? 'staff_save'.tr() : 'staff_add'.tr()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator:
          validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty) ? 'staff_field_required'.tr() : null
              : null),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> p) {
    final name = '${p['Prenom']} ${p['Nom']}';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('staff_confirm_delete'.tr()),
        content: Text('staff_confirm_delete_msg'.tr(namedArgs: {'name': name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('staff_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await _service.deletePersonnel(p['id_personnel']);
              if (!mounted) return;
              if (error == null) {
                _loadPersonnel();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('staff_deleted_ok'.tr()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('staff_delete'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          // Zone de recherche et filtres
          Container(
            padding: const EdgeInsets.all(18),
            color: Colors.white,
            child: isDesktop
                ? Row(
                    children: [
                      Expanded(child: _buildSearchBar()),
                      const SizedBox(width: 16),
                      _buildRoleFilter(),
                    ],
                  )
                : Column(
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 10),
                      _buildRoleFilter(),
                    ],
                  ),
          ),
          // Liste
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: dirPrimaryColor),
                  )
                : _filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'staff_none_found'.tr(),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 24 : 12,
                      vertical: 14,
                    ),
                    itemCount: _filteredList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) =>
                        _buildPersonnelCard(_filteredList[idx], isDesktop),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        backgroundColor: dirPrimaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: Text('staff_new'.tr()),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (v) {
        setState(() {
          _searchQuery = v;
          _applyFilters();
        });
      },
      decoration: InputDecoration(
        hintText: 'staff_search'.tr(),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _applyFilters();
                  });
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
      ),
    );
  }

  Widget _buildRoleFilter() {
    final roles = ['Tous', ..._kRoles];
    return DropdownButton<String>(
      value: _selectedRole,
      underline: const SizedBox(),
      borderRadius: BorderRadius.circular(12),
      items: roles
          .map((r) => DropdownMenuItem(
              value: r,
              child: Text(r == 'Tous' ? 'staff_all'.tr() : _trRole(r))))
          .toList(),
      onChanged: (v) {
        setState(() {
          _selectedRole = v!;
          _applyFilters();
        });
      },
    );
  }

  Widget _buildPersonnelCard(Map<String, dynamic> p, bool isDesktop) {
    final rawNom = '${p['Prenom'] ?? ''} ${p['Nom'] ?? ''}'.trim();
    final role = p['Specialite'] ?? 'N/A';
    final isMedecin =
        role.toString().toLowerCase().contains('m\u00e9decin') ||
        role.toString().toLowerCase().contains('medecin');
    final nom = (isMedecin && rawNom.isNotEmpty) ? 'Dr $rawNom' : rawNom;
    final email = p['email'] ?? '';
    final tel = p['telephone']?.toString() ?? '';
    final rawSexe = p['sexe']?.toString() ?? 'Homme';
    final sexe = (rawSexe == 'F' || rawSexe == 'Femme' || rawSexe == 'F\u00e9minin')
        ? 'Femme'
        : 'Homme';
    final initial = rawNom.isNotEmpty ? rawNom[0].toUpperCase() : '?';

    final roleColors = {
      'Directeur': const Color(0xFF7C3AED),
      'M\u00e9decin G\u00e9n\u00e9raliste': const Color(0xFF0284C7),
      'Major Accueil': const Color(0xFF059669),
      'Caissier': const Color(0xFFD97706),
      'Laborantin': const Color(0xFFDC2626),
      'Infirmier': const Color(0xFF2563EB),
    };
    final roleColor = roleColors[role] ?? dirPrimaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 26,
            backgroundColor: roleColor.withOpacity(0.12),
            child: Text(
              initial,
              style: TextStyle(
                color: roleColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _trRole(role),
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      sexe == 'F' ? Icons.female_rounded : Icons.male_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
                if (isDesktop) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      if (tel.isNotEmpty) ...[
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.phone_outlined,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Actions
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') _showFormDialog(existing: p);
              if (v == 'delete') _confirmDelete(p);
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Text('staff_edit'.tr()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Text('staff_delete'.tr()),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
