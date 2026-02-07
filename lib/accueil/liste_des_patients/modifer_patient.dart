import 'package:flutter/material.dart';
import 'package:hostoman/model_unifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui'; // <--- Ajoute cette ligne tout en haut

// Couleurs
const Color npPrimaryColor = Color(0xFF1565C0);
const Color npAccentColor = Color(0xFF2196F3);
const Color npSuccessColor = Color(0xFF4CAF50);
const Color npPageBackgroundStart = Color(0xFF0D47A1);
const Color npPageBackgroundEnd = Color(0xFF1976D2);

class ModifierPatientPage extends StatefulWidget {
  final Patient patient;
  const ModifierPatientPage({super.key, required this.patient});

  @override
  State<ModifierPatientPage> createState() => _ModifierPatientPageState();
}

class _ModifierPatientPageState extends State<ModifierPatientPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nomController;
  late TextEditingController ageController;
  late TextEditingController telController;
  late TextEditingController adresseController;
  late TextEditingController professionController;

  @override
  void initState() {
    super.initState();
    nomController = TextEditingController(text: widget.patient.nom_complet);
    ageController = TextEditingController(text: widget.patient.age.toString());
    telController = TextEditingController(
      text: widget.patient.telephone.toString(),
    );
    adresseController = TextEditingController(text: widget.patient.adresse);
    professionController = TextEditingController(
      text: widget.patient.profession,
    );
  }

  @override
  void dispose() {
    nomController.dispose();
    ageController.dispose();
    telController.dispose();
    adresseController.dispose();
    professionController.dispose();
    super.dispose();
  }

  Future<void> _modifierPatient() async {
    if (!_formKey.currentState!.validate()) return;

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
      final updatedPatient = Patient(
        id_patient: widget.patient.id_patient,
        nom_complet: nomController.text.trim(),
        age: int.tryParse(ageController.text.trim()) ?? 0,
        telephone: int.tryParse(telController.text.trim()) ?? 0,
        adresse: adresseController.text.trim(),
        profession: professionController.text.trim(),
        sexe: widget.patient.sexe,
        statut_matrimonial: widget.patient.statut_matrimonial,
        date_enregistrement: DateTime.now(),
      );

      await Supabase.instance.client
          .from('Patient')
          .update(updatedPatient.toMap())
          .eq('id_patient', widget.patient.id_patient!);

      Navigator.pop(context); // Fermer loader

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(width: 12),
              const Text(
                '✅ Patient mis à jour avec succès',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: npSuccessColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          elevation: 6,
        ),
      );

      Navigator.pop(context, updatedPatient);
    } catch (e) {
      Navigator.pop(context); // Fermer loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Erreur: ${e.toString()}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          elevation: 6,
        ),
      );
    }
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: npPrimaryColor),
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
          borderSide: const BorderSide(color: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;
    final isTablet = size.width > 400;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
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
            Icon(Icons.edit, color: npPrimaryColor, size: 24),
            const SizedBox(width: 12),
            Text(
              'Modifier le patient',
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
                padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // En-tête Patient
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [npPrimaryColor, npAccentColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: npAccentColor.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  widget.patient.nom_complet[0].toUpperCase(),
                                  style: TextStyle(
                                    color: npPrimaryColor,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.patient.nom_complet,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${widget.patient.id_patient}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Formulaire
                      Container(
                        padding: const EdgeInsets.all(20),
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
                                Icon(
                                  Icons.edit_document,
                                  color: npAccentColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Informations à modifier',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: npPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            _buildTextFormField(
                              controller: nomController,
                              label: 'Nom complet *',
                              icon: Icons.person,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Champ requis'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            _buildTextFormField(
                              controller: ageController,
                              label: 'Âge',
                              icon: Icons.cake,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),

                            _buildTextFormField(
                              controller: telController,
                              label: 'Téléphone',
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),

                            _buildTextFormField(
                              controller: adresseController,
                              label: 'Adresse',
                              icon: Icons.house,
                            ),
                            const SizedBox(height: 16),

                            _buildTextFormField(
                              controller: professionController,
                              label: 'Profession',
                              icon: Icons.work,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Bouton Enregistrer
                      ElevatedButton(
                        onPressed: _modifierPatient,
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
                              'Enregistrer les modifications',
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
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
