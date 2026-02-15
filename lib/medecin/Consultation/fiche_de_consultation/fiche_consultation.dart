import 'package:flutter/material.dart';
import 'fiche_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

// --- Page de Consultation (StatefulWidget) ---
class ConsultationPage extends StatefulWidget {
  final int idConsultation;
  const ConsultationPage({super.key, required this.idConsultation});

  @override
  State<ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage> {
  // 🔑 Clé globale pour gérer l'état et la validation du formulaire
  final _formKey = GlobalKey<FormState>();

  late final MedecinServices medecinService;
  String _patientName = "Chargement...";

  // --- Contrôleurs ---
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

  // --- Variables d'État du Formulaire ---
  String? _statutConsultation;
  String? _programmationRdv;
  DateTime? _selectedRdvDate;
  TimeOfDay? _selectedRdvTime;
  bool _showExamens = false;
  bool _showRdvDateTime = false;

  // État des examens (Chargés depuis la base de données)
  List<Map<String, dynamic>> _examens = [];
  bool _examensLoading = true;

  // --- Couleurs et Styles (Consolidés) ---
  final Color fieldBackgroundColor = const Color(0xFFF8F9FA);
  final Color fieldBorderColor = const Color(0xFFE0E0E0);
  final Color primaryPurple = const Color(0xFF6A5ACD);
  final Color primaryBlue = const Color(0xFF007BFF);
  final Color lightPurple = const Color(0xFF8A7DF0);

  @override
  void initState() {
    super.initState();
    medecinService = MedecinServices(Supabase.instance.client);
    _loadPatientName();
    _loadExamens();
  }

  @override
  void dispose() {
    _antecedentsController.dispose();
    _signesSymptomesController.dispose();
    _diagnosticInitialController.dispose();
    _diagnosticFinalController.dispose();
    _traitementPrescritController.dispose();
    _rdvDateController.dispose();
    _rdvHeureController.dispose();
    super.dispose();
  }

  // --- LOGIQUE DE CHARGEMENT ET D'AFFICHAGE ---

  Future<void> _loadPatientName() async {
    // ... (Logique inchangée pour le chargement du nom)
    try {
      final data = await medecinService.infosPatient(widget.idConsultation);
      if (data.isNotEmpty) {
        final patient = data[0]['Patient'] as Map<String, dynamic>;
        final String nomComplet =
            (patient['nom_complet']?.toString() ?? 'Patient Inconnu');
        if (mounted) {
          setState(() {
            _patientName = nomComplet;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _patientName = "Erreur de chargement";
        });
      }
      print('Erreur de chargement du nom: $e');
    }
  }

  Future<void> _loadExamens() async {
    try {
      final examensData = await medecinService.getListeExamens();
      if (mounted) {
        setState(() {
          _examens = examensData.map((examen) {
            return {
              'id_examlist': examen['id_examlist'],
              'nom_examen': examen['nom_examen'],
              'prix_examen': examen['prix_examen'],
              'selected': false,
            };
          }).toList();
          _examensLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _examensLoading = false;
        });
      }
      print('Erreur de chargement des examens: $e');
    }
  }

  void _showPatientInfoModal(BuildContext context) {
    // ... (Logique inchangée pour le modal d'information patient)
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text("Informations du Patient "),
          content: SingleChildScrollView(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: medecinService.infosPatient(widget.idConsultation),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erreur de chargement: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Aucune information patient trouvée.'),
                  );
                }

                final consultationData = snapshot.data![0];
                final patient =
                    consultationData['Patient'] as Map<String, dynamic>;
                final parametresVitaux =
                    consultationData['Parametres_vitaux']
                        as Map<String, dynamic>? ??
                    {};

                final String nomComplet =
                    (patient['nom_complet']?.toString() ?? 'N/A');
                final String sexe = (patient['sexe']?.toString() ?? 'INE');
                final String telephone =
                    (patient['telephone']?.toString() ?? 'INE');
                final String adresse =
                    (patient['adresse']?.toString() ?? 'INE');
                final int? age = patient['age'] as int?;
                final profesion = patient['profession'] ?? 'INE';
                final StatutMatrimonial = patient['statut_matrimonial'];
                final temperature = parametresVitaux['temperature'] ?? 0;
                final poid = parametresVitaux['poid'] ?? 0;
                final systolique = parametresVitaux['systolique'];
                final diastolique = parametresVitaux['diastolique'];
                final statutVih = parametresVitaux['statut_VIH'];
                final vaccination = parametresVitaux['vaccination'];
                final motif = parametresVitaux['motif_de_consultation'];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Infos Administratives",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    Text("Nom Complet: $nomComplet"),
                    Text("Sexe : $sexe"),
                    Text("Âge : ${age?.toString() ?? 'INE'} ans"),
                    Text("Téléphone : $telephone"),
                    Text("Profession : $profesion"),
                    Text("Statut Matrimonial : $StatutMatrimonial"),
                    Text("Adress : $adresse"),
                    const SizedBox(height: 20),
                    const Text(
                      "Paramètres Vitaux",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    Text("Temperature : $temperature"),
                    Text("Tension : $systolique/$diastolique"),
                    Text("Poids : $poid"),
                    Text('Statut VIH : $statutVih'),
                    Text('Vaccination : $vaccination'),
                    Text("Motif de la consultation : $motif"),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Fermer"),
            ),
          ],
        );
      },
    );
  }

  // --- WIDGETS DE FORMULAIRE RÉUTILISABLES ---

  /// Construit un champ de texte stylisé avec validation (Utilise TextFormField)
  Widget _buildFormField({
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        // 🛑 Utilisation de TextFormField pour la validation
        controller: controller,
        minLines: 3,
        maxLines: 5,
        validator: validator, // 🛑 Ajout du validateur
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          errorStyle: const TextStyle(
            height: 0.5,
          ), // Réduit l'espace des messages d'erreur
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
            borderSide: const BorderSide(
              color: Colors.red,
            ), // Mettre en évidence les erreurs
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
  }

  /// Construit une case à cocher pour un examen
  Widget _buildExamCheckbox({
    required Map<String, dynamic> examen,
    required int index,
  }) {
    return CheckboxListTile(
      title: Text(
        '${examen['nom_examen']} (Prix: ${examen['prix_examen']} FCFA)',
        style: const TextStyle(fontSize: 14),
      ),
      value: examen['selected'] as bool,
      onChanged: (bool? newValue) {
        setState(() {
          _examens[index]['selected'] = newValue!;
        });
      },
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: primaryPurple,
    );
  }

  // --- FONCTION DE SOUMISSION AVEC VALIDATION ---

  Future<void> _finalizeConsultation() async {
    // 🛑 VALIDATION: Tente de valider tous les champs du formulaire
    if (!_formKey.currentState!.validate()) {
      // Si la validation échoue (champs obligatoires vides), arrêter l'exécution
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez remplir tous les champs obligatoires du formulaire.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 1. Collecte des examens prescrits
    final List<Map<String, dynamic>> examensPrescrits = _examens
        .where((examen) => examen['selected'] == true)
        .map(
          (examen) => {
            'nom': examen['nom_examen'],
            'prix': examen['prix_examen'],
          },
        )
        .toList();

    // 2. Calcul de la date et heure du RDV
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

    // 3. Appel du service d'enregistrement
    try {
      await medecinService.saveConsultationData(
        idConsultation: widget.idConsultation,
        antecedents: _antecedentsController.text,
        signesSymptomes: _signesSymptomesController.text,
        diagnosticInitial: _diagnosticInitialController.text,
        statutConsultation: _statutConsultation ?? 'pas_examen',
        examensPrescrits: examensPrescrits,
        diagnosticFinal: _diagnosticFinalController.text,
        traitementPrescrit: _traitementPrescritController.text,
        programmationRdv: _programmationRdv == 'programmer'
            ? 'RDV_programmer'
            : null,
        rdvDate: finalRdvDate,
      );

      if (mounted) {
        // Utiliser context.go au lieu de context.push pour remplacer la route
        // Cela évite de revenir à la fiche de consultation lors du retour
        context.go('/Dashboard_Medecin/ConsultationList');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Consultation finalisée et enregistrée avec succès. ✅',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de la base de données: ${e.message} ❌'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur inattendue lors de l\'enregistrement: $e 💥'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- WIDGETS DE CONSTRUCTION DE SECTION ---

  Widget _buildGeneralInfoSection() {
    // 🛑 VALIDATION : Les 3 champs principaux sont rendus obligatoires
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormField(
          hint: "Antécédents *",
          controller: _antecedentsController,
          validator: (value) =>
              value == null || value.isEmpty ? 'Champ obligatoire' : null,
        ),
        _buildFormField(
          hint: "Signes et symptomes *",
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
      ],
    );
  }

  Widget _buildExamStatusDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          hintStyle: const TextStyle(color: Colors.grey),
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
        hint: const Text("Statut Consultation *"),
        initialValue: _statutConsultation,
        // 🛑 VALIDATION: Statut consultation est obligatoire
        validator: (value) => value == null ? 'Sélection obligatoire' : null,
        items: const [
          DropdownMenuItem(value: 'examen', child: Text("Examen à effectuer")),
          DropdownMenuItem(
            value: 'pas_examen',
            child: Text("Pas d'examen à effectuer"),
          ), // ⬅️ Corrigé
        ],
        onChanged: (String? newValue) {
          setState(() {
            _statutConsultation = newValue;
            _showExamens = (newValue == 'examen');
          });
        },
      ),
    );
  }

  Widget _buildFinalizationSection() {
    // 🛑 VALIDATION : Diagnostic et Traitement sont rendus obligatoires
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Finalisation de la consultation",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
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
      ],
    );
  }

  Widget _buildRdvDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          hintStyle: const TextStyle(color: Colors.grey),
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
        initialValue: _programmationRdv,
        // 🛑 VALIDATION: Programmation RDV est obligatoire
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
            // Réinitialiser les champs de date/heure si on annule la programmation
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
    // 🛑 VALIDATION : Si programmer est sélectionné, la date/heure devient obligatoire
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
              // Champ Date
              Expanded(
                child: TextFormField(
                  // 🛑 Utilisation de TextFormField
                  controller: _rdvDateController,
                  validator:
                      rdvValidator, // 🛑 Ajout de la validation contextuelle
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
                    focusedErrorBorder: OutlineInputBorder(
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
                      // Si la date change, forcer la revalidation du formulaire pour le champ
                      _formKey.currentState!.validate();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Champ Heure
              Expanded(
                child: TextFormField(
                  // 🛑 Utilisation de TextFormField
                  controller: _rdvHeureController,
                  validator:
                      rdvValidator, // 🛑 Ajout de la validation contextuelle
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
                    focusedErrorBorder: OutlineInputBorder(
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
                      // Si l'heure change, forcer la revalidation du formulaire pour le champ
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

  // --- WIDGET PRINCIPAL ---

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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Titre "Formulire de Consultation"
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                decoration: BoxDecoration(
                  color: lightPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    "Formulaire de Consultation",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // --- Carte blanche principale (Formulaire) ---
              Container(
                width: double.infinity,
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
                  // 🔑 Enveloppe tout le contenu du formulaire dans le widget Form
                  key: _formKey,
                  autovalidateMode: AutovalidateMode
                      .onUserInteraction, // Validation lors de l'interaction
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Infos générales (obligatoires)
                      _buildGeneralInfoSection(),

                      // Dropdown Statut Consultation (obligatoire)
                      _buildExamStatusDropdown(),

                      // Liste des examens (conditionnel)
                      if (_showExamens)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 15.0,
                            bottom: 8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Liste des examens à effectuer :",
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 5),
                              _examensLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: fieldBackgroundColor,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: fieldBorderColor,
                                        ),
                                      ),
                                      child: _examens.isEmpty
                                          ? const Padding(
                                              padding: EdgeInsets.all(16.0),
                                              child: Text(
                                                'Aucun examen disponible',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            )
                                          : Column(
                                              children: _examens
                                                  .asMap()
                                                  .entries
                                                  .map((entry) {
                                                    return _buildExamCheckbox(
                                                      examen: entry.value,
                                                      index: entry.key,
                                                    );
                                                  })
                                                  .toList(),
                                            ),
                                    ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 25),

                      // Section 2: Finalisation (obligatoire)
                      _buildFinalizationSection(),

                      // Dropdown Programmation RDV (obligatoire)
                      _buildRdvDropdown(),

                      // Date et Heure du RDV (conditionnel et obligatoire si 'programmer')
                      if (_showRdvDateTime) _buildRdvDateTimeFields(context),

                      const SizedBox(height: 20),

                      // --- Bouton "Finaliser" ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _finalizeConsultation,
                          // 🛑 Déclenche la validation avant la sauvegarde
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            "Finaliser la consultation",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // --- Footer ---
              const Text(
                "@2025 Yamgai Mokube Franck Daniel",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
