import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/model_unifier.dart';
import 'service.dart';
import 'validators.dart';
import 'dart:ui';

/// ---------------------------
/// Variables globales (remises)
/// ---------------------------
final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

// Controllers globaux
final TextEditingController nom_completController = TextEditingController();
final TextEditingController age = TextEditingController();
final TextEditingController telephone = TextEditingController();
final TextEditingController adresse = TextEditingController();
final TextEditingController profession = TextEditingController();
final TextEditingController temperature = TextEditingController();
final TextEditingController poid = TextEditingController();
final TextEditingController test_VIH = TextEditingController();
final TextEditingController vaccination = TextEditingController();
final TextEditingController motif_consultation = TextEditingController();
final TextEditingController systolique = TextEditingController();
final TextEditingController diastolique = TextEditingController();

// Champs globaux simples
String? sexeTexte;
String? StatutMatrimonial = '';
String? sexe = '';
String? type_service = '';
String? _idMedecinSelectionne;

// Listes globales
final List<String> _services = [
  'Consultation',
  'Consultation prénatale CPN1',
  'Rendez-vous',
];
String? _typeServiceSelectionne;
List<Medecin> _medecins = [];

String? _value = '';
String? _statutMatrimonialSelectionne;
final List<String> _statutsMatrimoniaux = [
  'Marié Monogame',
  'Concubinage',
  'Veuve',
  'Marié Polygame',
  'Célibataire',
  'Divorcé',
];

// Couleurs
const Color npPrimaryColor = Color(0xFF1565C0);
const Color npAccentColor = Color(0xFF2196F3);
const Color npSuccessColor = Color(0xFF4CAF50);
const Color npErrorColor = Color(0xFFD32F2F);
const Color npPageBackgroundStart = Color(0xFF0D47A1);
const Color npPageBackgroundEnd = Color(0xFF1976D2);

/// ---------------------------
/// Widget Nouveau_Patient
/// ---------------------------
class Nouveau_Patient extends StatefulWidget {
  const Nouveau_Patient({super.key});

  @override
  State<Nouveau_Patient> createState() => _Nouveau_PatientState();
}

class _Nouveau_PatientState extends State<Nouveau_Patient> {
  final PatientService patientService = PatientService(
    Supabase.instance.client,
  );

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _chargerMedecins() async {
    try {
      final response = await Supabase.instance.client
          .from('Personnel_hopital')
          .select('id_personnel, Nom, Prenom, Specialite')
          .eq('es_medecin', true);

      setState(() {
        _medecins = (response as List).map((e) {
          final map = e as Map<String, dynamic>;
          return Medecin.fromMap({
            'id_personnel': map['id_personnel'],
            'Nom': map['Nom'],
            'Prenom': map['Prenom'],
            'Specialite': map['Specialite'],
          });
        }).toList();
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des médecins : $e');
      setState(() {
        _medecins = [];
      });
    }
  }

  void _showMessage(String message, {Color background = Colors.green}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              background == Colors.green ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: background,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildMedecinTile(Medecin med) {
    final isSelected = _idMedecinSelectionne == med.id_personnel;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? npAccentColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? npAccentColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        title: Text(
          '${med.nom} ${med.prenom}',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? npPrimaryColor : Colors.black87,
          ),
        ),
        subtitle: Text(
          med.specialite ?? 'Spécialité non trouver',
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? npAccentColor : Colors.grey[600],
          ),
        ),
        value: med.id_personnel,
        groupValue: _idMedecinSelectionne,
        onChanged: (val) => setState(() => _idMedecinSelectionne = val),
        activeColor: npAccentColor,
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    String? errorMessage;
    if (_value == null || _value!.isEmpty) {
      errorMessage = 'Veuillez sélectionner le sexe';
    } else if (_statutMatrimonialSelectionne == null) {
      errorMessage = 'Veuillez sélectionner le statut matrimonial';
    } else if (_typeServiceSelectionne == null) {
      errorMessage = 'Veuillez sélectionner le type de service';
    } else if ((_typeServiceSelectionne == 'Consultation' ||
            _typeServiceSelectionne == 'Rendez-vous') &&
        _idMedecinSelectionne == null) {
      errorMessage = 'Veuillez sélectionner un médecin';
    }

    if (errorMessage != null) {
      _showMessage(errorMessage, background: npErrorColor);
      return;
    }

    sexe = _value;
    StatutMatrimonial = _statutMatrimonialSelectionne;
    type_service = _typeServiceSelectionne;

    showDialog(
      context: context,
      barrierDismissible: false,
      // On réduit l'opacité de la barrière pour plus de douceur
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (_) => BackdropFilter(
        // Le flou rend l'apparition moins "violente" pour les yeux
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Center(
          child: Container(
            width: 180, // Largeur fixe pour un look plus compact
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9), // Légère transparence
              borderRadius: BorderRadius.circular(28), // Bords très arrondis
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Un loader plus fin et plus moderne
                SizedBox(
                  height: 45,
                  width: 45,
                  child: CircularProgressIndicator(
                    color: npPrimaryColor,
                    strokeWidth: 3, // Plus fin = plus élégant
                    strokeCap: StrokeCap.round, // Bords arrondis sur le trait
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Patientez...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: npPrimaryColor.withOpacity(0.8),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    decoration:
                        TextDecoration.none, // Pour éviter les traits jaunes
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await patientService.patientSave(
        context: context,
        idMedecin: _idMedecinSelectionne,
      );

      Navigator.pop(context);
      _showMessage(
        'Patient enregistré avec succès !',
        background: npSuccessColor,
      );

      setState(() {
        _value = '';
        _statutMatrimonialSelectionne = null;
        _typeServiceSelectionne = null;
        _idMedecinSelectionne = null;
        _medecins = [];
      });

      nom_completController.clear();
      age.clear();
      telephone.clear();
      adresse.clear();
      profession.clear();
      temperature.clear();
      poid.clear();
      test_VIH.clear();
      vaccination.clear();
      motif_consultation.clear();
      systolique.clear();
      diastolique.clear();
      sexe = '';
      StatutMatrimonial = null;
      type_service = null;
    } catch (e) {
      Navigator.pop(context);
      _showMessage('Erreur : ${e.toString()}', background: npErrorColor);
    }
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: npPrimaryColor) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: npAccentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: npErrorColor),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: npAccentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: npPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: npPageBackgroundStart,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: npPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.person_add, color: npPrimaryColor, size: 24),
            const SizedBox(width: 12),
            Text(
              '  Nouveau Patient',
              style: TextStyle(
                color: npPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: !isDesktop,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [npPageBackgroundStart, npPageBackgroundEnd],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 900 : double.infinity,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 40 : (isTablet ? 24 : 16),
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 100,
                                height: 100,
                                color: npPrimaryColor.withOpacity(0.1),
                                child: Icon(
                                  Icons.local_hospital,
                                  size: 50,
                                  color: npPrimaryColor,
                                ),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: npAccentColor.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: npErrorColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Veuillez remplir tous les champs requis',
                              style: TextStyle(
                                fontSize: 15,
                                color: npErrorColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Section Informations personnelles
                          _buildSectionCard(
                            title: 'Informations Personnelles',
                            children: [
                              _buildTextFormField(
                                controller: nom_completController,
                                label: 'Nom Complet *',
                                hint: 'Ex: Yamga Mokube Francko Daniel',
                                icon: Icons.person,
                                validator:
                                    PatientFormConfig.nomComplet.validator,
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'Sexe *',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _value == 'Homme'
                                            ? npAccentColor.withOpacity(0.1)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _value == 'Homme'
                                              ? npAccentColor
                                              : Colors.grey.shade300,
                                          width: _value == 'Homme' ? 2 : 1,
                                        ),
                                      ),
                                      child: RadioListTile<String>(
                                        value: 'Homme',
                                        title: const Text(
                                          'Homme',
                                          style: TextStyle(fontSize: 15),
                                        ),
                                        groupValue: _value,
                                        onChanged: (v) =>
                                            setState(() => _value = v),
                                        activeColor: npAccentColor,
                                        dense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _value == 'Femme'
                                            ? npAccentColor.withOpacity(0.1)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _value == 'Femme'
                                              ? npAccentColor
                                              : Colors.grey.shade300,
                                          width: _value == 'Femme' ? 2 : 1,
                                        ),
                                      ),
                                      child: RadioListTile<String>(
                                        value: 'Femme',
                                        title: const Text(
                                          'Femme',
                                          style: TextStyle(fontSize: 15),
                                        ),
                                        groupValue: _value,
                                        onChanged: (v) =>
                                            setState(() => _value = v),
                                        activeColor: npAccentColor,
                                        dense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextFormField(
                                      controller: age,
                                      label: 'Âge *',
                                      hint: 'Ex: 25',
                                      icon: Icons.cake,
                                      keyboardType: TextInputType.number,
                                      validator:
                                          PatientFormConfig.age.validator,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextFormField(
                                      controller: telephone,
                                      label: 'Téléphone *',
                                      hint: 'Ex: 670619582',
                                      icon: Icons.phone,
                                      keyboardType: TextInputType.phone,
                                      validator:
                                          PatientFormConfig.telephone.validator,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              _buildTextFormField(
                                controller: adresse,
                                label: 'Adresse *',
                                hint: 'Ex: Pk-14',
                                icon: Icons.house,
                                validator: PatientFormConfig.adresse.validator,
                              ),
                              const SizedBox(height: 16),

                              _buildTextFormField(
                                controller: profession,
                                label: 'Profession *',
                                hint: 'Ex: Etudiant',
                                icon: Icons.work,
                                validator:
                                    PatientFormConfig.profession.validator,
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'Statut Matrimonial *',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _statutMatrimonialSelectionne,
                                    isExpanded: true,
                                    hint: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text('Sélectionner un statut'),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    items: _statutsMatrimoniaux
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) => setState(
                                      () => _statutMatrimonialSelectionne = v,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Section Données médicales
                          _buildSectionCard(
                            title: 'Données Médicales',
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextFormField(
                                      controller: temperature,
                                      label: 'Température (°C)',
                                      hint: '37.2',
                                      icon: Icons.thermostat,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      validator: PatientFormConfig
                                          .temperature
                                          .validator,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextFormField(
                                      controller: poid,
                                      label: 'Poids (kg)',
                                      hint: '70.5',
                                      icon: Icons.scale,
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      validator:
                                          PatientFormConfig.poids.validator,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'Tension Artérielle *',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextFormField(
                                      controller: systolique,
                                      label: 'Systolique',
                                      hint: '120',
                                      icon: Icons.monitor_heart_outlined,
                                      keyboardType: TextInputType.number,
                                      validator: PatientFormConfig
                                          .tensionSystolique
                                          .validator,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextFormField(
                                      controller: diastolique,
                                      label: 'Diastolique',
                                      hint: '80',
                                      icon: Icons.monitor_heart_outlined,
                                      keyboardType: TextInputType.number,
                                      validator: PatientFormConfig
                                          .tensionDiastolique
                                          .validator,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              _buildTextFormField(
                                controller: test_VIH,
                                label: 'Statut Test VIH *',
                                icon: Icons.bloodtype,
                                validator: PatientFormConfig.testVIH.validator,
                              ),
                              const SizedBox(height: 16),

                              _buildTextFormField(
                                controller: vaccination,
                                label: 'Vaccination *',
                                icon: Icons.vaccines,
                                validator:
                                    PatientFormConfig.vaccination.validator,
                              ),
                              const SizedBox(height: 16),

                              _buildTextFormField(
                                controller: motif_consultation,
                                label: 'Motif de la Consultation *',
                                icon: Icons.medical_information,
                                keyboardType: TextInputType.multiline,
                                maxLines: 4,
                                validator: PatientFormConfig
                                    .motifConsultation
                                    .validator,
                              ),
                            ],
                          ),

                          // Section Service
                          _buildSectionCard(
                            title: 'Service et Attribution',
                            children: [
                              const Text(
                                'Type de Service *',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _typeServiceSelectionne,
                                    isExpanded: true,
                                    hint: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text('Sélectionner un service'),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    items: _services
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (service) async {
                                      setState(() {
                                        _typeServiceSelectionne = service;
                                        _idMedecinSelectionne = null;
                                        _medecins = [];
                                      });
                                      if (service == 'Consultation' ||
                                          service == 'Rendez-vous') {
                                        await _chargerMedecins();
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              if (_typeServiceSelectionne == 'Consultation' ||
                                  _typeServiceSelectionne == 'Rendez-vous') ...[
                                const Text(
                                  'Médecin Responsable *',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (_medecins.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.orange.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber,
                                          color: Colors.orange.shade700,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Aucun médecin disponible.',
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ..._medecins.map(_buildMedecinTile),
                              ],
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Bouton Enregistrer
                          ElevatedButton(
                            onPressed: _onSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: npSuccessColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: npSuccessColor.withOpacity(0.4),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save, size: 22),
                                SizedBox(width: 12),
                                Text(
                                  'Enregistrer le Patient',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                          Center(
                            child: Text(
                              '© 2025 Yamgai Mokube Franck Daniel',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
