import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../fiche_de_consultation/fiche_services.dart';

/// 📄 Page de Finalisation de Consultation (Tabbed View)
class FinalisationConsultationPage extends StatefulWidget {
  final int idConsultation;
  const FinalisationConsultationPage({super.key, required this.idConsultation});

  @override
  State<FinalisationConsultationPage> createState() =>
      _FinalisationConsultationPageState();
}

class _FinalisationConsultationPageState
    extends State<FinalisationConsultationPage>
    with SingleTickerProviderStateMixin {
  late final MedecinServices medecinService;
  late TabController _tabController;

  // --- Données Patient ---
  String _patientName = "Chargement...";
  Map<String, dynamic>? _patientData;
  Map<String, dynamic>? _parametresVitaux;
  Map<String, dynamic>? _consultationData;

  // --- Données Examens ---
  List<Map<String, dynamic>> _examensResultats = [];
  bool _examensLoading = true;

  // --- Contrôleurs de Formulaire ---
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _antecedentsController = TextEditingController();
  final TextEditingController _signesSymptomesController =
      TextEditingController();
  final TextEditingController _diagnosticInitialController =
      TextEditingController();
  final TextEditingController _diagnosticFinalController =
      TextEditingController();
  final TextEditingController _traitementPrescritController =
      TextEditingController();
  final TextEditingController _rdvDateController = TextEditingController();
  final TextEditingController _rdvHeureController = TextEditingController();

  String? _programmationRdv;
  DateTime? _selectedRdvDate;
  TimeOfDay? _selectedRdvTime;
  bool _showRdvDateTime = false;

  // --- Couleurs ---
  final Color primaryPurple = const Color(0xFF6A5ACD);
  final Color lightPurple = const Color(0xFF8A7DF0);
  final Color fieldBackgroundColor = const Color(0xFFF8F9FA);
  final Color fieldBorderColor = const Color(0xFFE0E0E0);
  final Color primaryBlue = const Color(0xFF007BFF);

  @override
  void initState() {
    super.initState();
    medecinService = MedecinServices(Supabase.instance.client);
    _tabController = TabController(length: 2, vsync: this);
    _loadPatientData();
    _loadConsultationData();
    _loadExamensResultats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _antecedentsController.dispose();
    _signesSymptomesController.dispose();
    _diagnosticInitialController.dispose();
    _diagnosticFinalController.dispose();
    _traitementPrescritController.dispose();
    _rdvDateController.dispose();
    _rdvHeureController.dispose();
    super.dispose();
  }

  // --- CHARGEMENT DES DONNÉES ---

  Future<void> _loadPatientData() async {
    try {
      final data = await medecinService.infosPatient(widget.idConsultation);
      if (data.isNotEmpty && mounted) {
        final patient = data[0]['Patient'] as Map<String, dynamic>;
        final vitaux = data[0]['Parametres_vitaux'] as Map<String, dynamic>?;
        setState(() {
          _patientName =
              patient['nom_complet']?.toString() ?? 'Patient Inconnu';
          _patientData = patient;
          _parametresVitaux = vitaux;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _patientName = "Erreur de chargement");
      }
    }
  }

  Future<void> _loadConsultationData() async {
    try {
      final response = await Supabase.instance.client
          .from('Consultation')
          .select('*')
          .eq('id_consultation', widget.idConsultation)
          .single();

      if (mounted) {
        setState(() {
          _consultationData = response;
          // Pré-remplir les champs
          _antecedentsController.text = _consultationData!['antecedents'] ?? '';
          _signesSymptomesController.text =
              _consultationData!['signes_symptomes'] ?? '';
          _diagnosticInitialController.text =
              _consultationData!['diagnostic_initial'] ?? '';
          _diagnosticFinalController.text =
              _consultationData!['diagnostic_final'] ?? '';
          _traitementPrescritController.text =
              _consultationData!['traitement_prescrit'] ?? '';

          // Mapping de la valeur DB vers la valeur interne du Dropdown
          final dbRdv = _consultationData!['programmation_rdv'];
          _programmationRdv = (dbRdv == 'RDV_programmer')
              ? 'programmer'
              : 'pas_programmer';

          // Pré-remplir la date de RDV si elle existe
          if (_consultationData!['date_rdv_prevu'] != null) {
            final rdvDate = DateTime.parse(
              _consultationData!['date_rdv_prevu'],
            );
            _selectedRdvDate = rdvDate;
            _selectedRdvTime = TimeOfDay(
              hour: rdvDate.hour,
              minute: rdvDate.minute,
            );
            _rdvDateController.text =
                '${rdvDate.day}/${rdvDate.month}/${rdvDate.year}';
            _rdvHeureController.text = _selectedRdvTime!.format(context);
            // Afficher les champs date/heure seulement si programmé
            _showRdvDateTime = (_programmationRdv == 'programmer');
          } else {
            // Si pas de date, s'assurer que les champs sont cachés/vidés
            _showRdvDateTime = false;
            _selectedRdvDate = null;
            _selectedRdvTime = null;
            _rdvDateController.clear();
            _rdvHeureController.clear();
          }
        });
      }
    } catch (e) {
      print('Erreur de chargement de la consultation: $e');
    }
  }

  Future<void> _loadExamensResultats() async {
    try {
      final examens = await medecinService.getExamensResultats(
        widget.idConsultation,
      );
      if (mounted) {
        setState(() {
          _examensResultats = examens;
          _examensLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _examensLoading = false);
      }
    }
  }

  // --- MODAL INFOS PATIENT ---

  void _showPatientInfoModal(BuildContext context) {
    if (_patientData == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Informations du Patient",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Infos Administratives",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Divider(),
                  _buildInfoRow("Nom Complet", _patientData!['nom_complet']),
                  _buildInfoRow("Sexe", _patientData!['sexe']),
                  _buildInfoRow("Âge", "${_patientData!['age']} ans"),
                  _buildInfoRow("Téléphone", _patientData!['telephone']),
                  _buildInfoRow("Profession", _patientData!['profession']),
                  _buildInfoRow(
                    "Statut Matrimonial",
                    _patientData!['statut_matrimonial'],
                  ),
                  _buildInfoRow("Adress", _patientData!['adresse']),
                  const SizedBox(height: 15),
                  const Text(
                    "Paramètres Vitaux",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Divider(),
                  if (_parametresVitaux != null) ...[
                    _buildInfoRow(
                      "Temperature",
                      _parametresVitaux!['temperature'],
                    ),
                    _buildInfoRow(
                      "Tension",
                      "${_parametresVitaux!['systolique']}/${_parametresVitaux!['diastolique']}",
                    ),
                    _buildInfoRow("Poids", _parametresVitaux!['poid']),
                    _buildInfoRow(
                      "Statut VIH",
                      _parametresVitaux!['statut_VIH'],
                    ),
                    _buildInfoRow(
                      "Vaccination",
                      _parametresVitaux!['vaccination'],
                    ),
                    _buildInfoRow(
                      "Motif de la consultation",
                      _parametresVitaux!['motif_de_consultation'],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "Fermer",
                        style: TextStyle(color: primaryPurple, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text("$label : ${value ?? 'N/A'}"),
    );
  }

  // --- WIDGETS DE FORMULAIRE ---

  Widget _buildFormField({
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        minLines: 3,
        maxLines: 5,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          errorStyle: const TextStyle(height: 0.5),
          filled: true,
          fillColor: fieldBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: fieldBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primaryBlue.withOpacity(0.5)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildRdvDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          filled: true,
          fillColor: fieldBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: fieldBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primaryBlue.withOpacity(0.5)),
          ),
          errorStyle: const TextStyle(height: 0.5),
        ),
        hint: const Text("Programmation de rendez-vous *"),
        value: _programmationRdv,
        validator: (value) => value == null ? 'Sélection obligatoire' : null,
        items: const [
          DropdownMenuItem(
            value: 'programmer',
            child: Text("Rendez-vous à effectuer"),
          ),
          DropdownMenuItem(
            value: 'pas_programmer',
            child: Text("Pas de nouveau rendez-vous"),
          ),
        ],
        onChanged: (String? newValue) {
          setState(() {
            _programmationRdv = newValue;
            _showRdvDateTime = (newValue == 'programmer');
            if (newValue == 'pas_programmer') {
              _selectedRdvDate = null;
              _selectedRdvTime = null;
              _rdvDateController.clear();
              _rdvHeureController.clear();
            }
          });
        },
      ),
    );
  }

  Widget _buildRdvDateTimeFields(BuildContext context) {
    String? rdvValidator(String? value) {
      if (_programmationRdv == 'programmer' &&
          (value == null || value.isEmpty)) {
        return 'Date/Heure obligatoire';
      }
      return null;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 5.0, bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Choisir la date et l'heure :",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _rdvDateController,
                  validator: rdvValidator,
                  decoration: InputDecoration(
                    hintText: 'Date *',
                    errorStyle: const TextStyle(height: 0.5),
                    filled: true,
                    fillColor: fieldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: fieldBorderColor),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate:
                          _selectedRdvDate ??
                          DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedRdvDate = date;
                        _rdvDateController.text =
                            '${date.day}/${date.month}/${date.year}';
                      });
                      _formKey.currentState!.validate();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _rdvHeureController,
                  validator: rdvValidator,
                  decoration: InputDecoration(
                    hintText: 'Heure *',
                    errorStyle: const TextStyle(height: 0.5),
                    filled: true,
                    fillColor: fieldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: fieldBorderColor),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedRdvTime ?? TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _selectedRdvTime = time;
                        _rdvHeureController.text = time.format(context);
                      });
                      _formKey.currentState!.validate();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SOUMISSION ---

  Future<void> _finalizeConsultation() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    DateTime? finalRdvDate;
    if (_programmationRdv == 'programmer' &&
        _selectedRdvDate != null &&
        _selectedRdvTime != null) {
      finalRdvDate = DateTime(
        _selectedRdvDate!.year,
        _selectedRdvDate!.month,
        _selectedRdvDate!.day,
        _selectedRdvTime!.hour,
        _selectedRdvTime!.minute,
      );
    }

    try {
      // Mise à jour de la consultation (sans examens prescrits ici)
      await Supabase.instance.client
          .from('Consultation')
          .update({
            'antecedents': _antecedentsController.text,
            'signes_symptomes': _signesSymptomesController.text,
            'diagnostic_initial': _diagnosticInitialController.text,
            'diagnostic_final': _diagnosticFinalController.text,
            'traitement_prescrit': _traitementPrescritController.text,
            // Logique demandée : "RDV_programmer" si programmé, sinon null
            'programmation_rdv': _programmationRdv == 'programmer'
                ? 'RDV_programmer'
                : null,
            // Date si programmé, sinon explicitement null
            'date_rdv_prevu': _programmationRdv == 'programmer'
                ? finalRdvDate?.toIso8601String()
                : null,
            'Statut_Consultation': 'terminer',
            'date_derniere_mise_ajour': DateTime.now().toIso8601String(),
          })
          .eq('id_consultation', widget.idConsultation);

      if (mounted) {
        context.go('/Dashboard_Medecin/ConsultationList');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consultation finalisée avec succès. ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la finalisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- ONGLETS ---

  Widget _buildFinaliserTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Diagnostic Initial",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildFormField(
                hint: "Antécédent *",
                controller: _antecedentsController,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Champ obligatoire' : null,
              ),
              _buildFormField(
                hint: "Signe et symptomes *",
                controller: _signesSymptomesController,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Champ obligatoire' : null,
              ),
              _buildFormField(
                hint: "Diagnostic initial *",
                controller: _diagnosticInitialController,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 20),
              const Text(
                "Diagnostic Final et Traitement",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildFormField(
                hint: "Diagnostic final *",
                controller: _diagnosticFinalController,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Champ obligatoire' : null,
              ),
              _buildFormField(
                hint: "Traitement prescrit *",
                controller: _traitementPrescritController,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 20),
              _buildRdvDropdown(),
              if (_showRdvDateTime) _buildRdvDateTimeFields(context),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _finalizeConsultation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Terminer la Consultation",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultatsTab() {
    if (_examensLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_examensResultats.isEmpty) {
      return const Center(
        child: Text(
          "Aucun examen prescrit pour cette consultation.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _examensResultats.length,
      itemBuilder: (context, index) {
        final examen = _examensResultats[index];
        final String nomExamen = examen['nom_examen'] ?? 'Examen inconnu';
        final String statutExamen = examen['statut_examen'] ?? 'en attente';
        final String? resultatExamen = examen['resultat_examen'];

        // Couleur du statut selon les règles utilisateur
        Color statutColor = Colors.grey; // Gris par défaut ("en attente")
        final String statutLower = statutExamen.toLowerCase();

        if (statutLower == 'en cours') {
          statutColor = Colors.orange;
        } else if (statutLower == 'terminé') {
          statutColor = Colors.green;
        } else if (statutLower == 'annuler') {
          statutColor = Colors.red;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomExamen,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      "Statut : ",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    Text(
                      statutExamen,
                      style: TextStyle(
                        color: statutColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Résultats :",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  resultatExamen ?? "N/A",
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryPurple,
      appBar: AppBar(
        backgroundColor: primaryPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _patientName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => _showPatientInfoModal(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Finaliser"),
            Tab(text: "Résultats Examens"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFinaliserTab(), _buildResultatsTab()],
      ),
    );
  }
}
