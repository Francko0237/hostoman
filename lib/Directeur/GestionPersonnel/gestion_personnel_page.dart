import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'personnel_service.dart';

class gestion_personnel_page extends StatefulWidget {
  const gestion_personnel_page({super.key});

  @override
  State<gestion_personnel_page> createState() => _gestion_personnel_pageState();
}

class _gestion_personnel_pageState extends State<gestion_personnel_page> {
  final PersonnelService _service = PersonnelService(Supabase.instance.client);
  List<Map<String, dynamic>> _personnelList = [];
  List<Map<String, dynamic>> _filteredList = [];
  bool _isLoading = true;
  String _selectedRole = 'Tous';
  final List<String> _roles = [
    'Tous',
    'Directeur',
    'Médecin Généraliste',
    'Major Accueil',
    'Caissier',
    'Laborantin',
    'Infirmier',
  ];

  @override
  void initState() {
    super.initState();
    _loadPersonnel();
  }

  Future<void> _loadPersonnel() async {
    final list = await _service.getAllPersonnel();
    if (mounted) {
      setState(() {
        _personnelList = list;
        _filterList();
        _isLoading = false;
      });
    }
  }

  void _filterList() {
    if (_selectedRole == 'Tous') {
      _filteredList = List.from(_personnelList);
    } else {
      _filteredList = _personnelList
          .where((p) => p['Specialite'] == _selectedRole)
          .toList();
    }
  }

  void _showAddPersonnelDialog() {
    final _formKey = GlobalKey<FormState>();
    final nomController = TextEditingController();
    final prenomController = TextEditingController();
    final emailController = TextEditingController();
    final telephoneController = TextEditingController();
    final adresseController = TextEditingController();
    final passwordController = TextEditingController();
    final ageController = TextEditingController();
    String selectedSpecialite = 'Médecin Généraliste';
    String selectedSexe = 'M';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajouter un Personnel'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nomController,
                    decoration: const InputDecoration(labelText: 'Nom'),
                  ),
                  TextFormField(
                    controller: prenomController,
                    decoration: const InputDecoration(labelText: 'Prénom'),
                  ),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                    ),
                    obscureText: true,
                  ),
                  TextFormField(
                    controller: telephoneController,
                    decoration: const InputDecoration(labelText: 'Téléphone'),
                    keyboardType: TextInputType.phone,
                  ),
                  TextFormField(
                    controller: adresseController,
                    decoration: const InputDecoration(labelText: 'Adresse'),
                  ),
                  TextFormField(
                    controller: ageController,
                    decoration: const InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedSpecialite,
                    decoration: const InputDecoration(labelText: 'Rôle'),
                    items: _roles.where((r) => r != 'Tous').map((role) {
                      return DropdownMenuItem(value: role, child: Text(role));
                    }).toList(),
                    onChanged: (val) => selectedSpecialite = val!,
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedSexe,
                    decoration: const InputDecoration(labelText: 'Sexe'),
                    items: ['M', 'F'].map((sexe) {
                      return DropdownMenuItem(value: sexe, child: Text(sexe));
                    }).toList(),
                    onChanged: (val) => selectedSexe = val!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final data = {
                    'Nom': nomController.text,
                    'Prenom': prenomController.text,
                    'email': emailController.text,
                    'telephone': int.tryParse(telephoneController.text) ?? 0,
                    'adresse': adresseController.text,
                    'Specialite': selectedSpecialite,
                    'sexe': selectedSexe,
                    'age': int.tryParse(ageController.text) ?? 0,
                  };

                  final error = await _service.addPersonnel(
                    data,
                    passwordController.text,
                  );
                  if (error == null) {
                    Navigator.pop(context);
                    _loadPersonnel();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Personnel ajouté avec succès'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error)));
                  }
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filtre
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text(
                  'Filtrer par rôle: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedRole,
                  items: _roles.map((role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedRole = val!;
                      _filterList();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filteredList.length,
                    itemBuilder: (context, index) {
                      final p = _filteredList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Text(
                              p['Nom'][0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text('${p['Nom']} ${p['Prenom']}'),
                          subtitle: Text('${p['Specialite']} - ${p['email']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              // Confirmation de suppression
                              bool confirm = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirmer la suppression'),
                                  content: Text(
                                    'Voulez-vous vraiment supprimer ${p['Nom']} ?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Supprimer'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm) {
                                await _service.deletePersonnel(
                                  p['id_personnel'],
                                );
                                _loadPersonnel();
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPersonnelDialog,
        backgroundColor: const Color(0xFF1A237E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
