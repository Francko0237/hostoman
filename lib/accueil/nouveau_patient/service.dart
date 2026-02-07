import 'dart:ffi';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hostoman/model_unifier.dart';
import 'nouveau_patient.dart';

// Couleurs
const Color npPrimaryColor = Color(0xFF1565C0);
const Color npAccentColor = Color(0xFF2196F3);
const Color npSuccessColor = Color(0xFF4CAF50);
const Color npErrorColor = Color(0xFFD32F2F);
const Color npWarningColor = Color(0xFFFF9800);

/// Utilitaire pour récupérer l'ID du personnel connecté
class AuthUtils {
  static String? get idPersonnel {
    return Supabase.instance.client.auth.currentUser?.id;
  }
}

final idPersonnel = AuthUtils.idPersonnel;

/// Service principal pour gérer l'enregistrement des patients
class PatientService {
  final SupabaseClient supabase;
  PatientService(this.supabase);

  /// Méthode principale pour enregistrer ou mettre à jour un patient
  Future<void> patientSave({
    required BuildContext context,
    String? idMedecin,
  }) async {
    // 🔒 Validation des champs obligatoires
    if (sexe == null || sexe!.isEmpty) {
      showMessage(context, 'Le sexe doit être sélectionné', isError: true);
      return;
    }
    if (StatutMatrimonial == null || StatutMatrimonial!.isEmpty) {
      showMessage(
        context,
        'Le statut matrimonial doit être sélectionné',
        isError: true,
      );
      return;
    }
    if (type_service == null || type_service!.isEmpty) {
      showMessage(
        context,
        'Le type de service doit être sélectionné',
        isError: true,
      );
      return;
    }
    if ((type_service == 'Consultation' || type_service == 'Rendez-vous') &&
        idMedecin == null) {
      showMessage(
        context,
        'Un médecin doit être sélectionné pour ce type de service',
        isError: true,
      );
      return;
    }

    // 📦 Récupération des données saisies
    final nom = nom_completController.text.trim();
    final tel = int.tryParse(telephone.text.trim()) ?? 0;

    // 🔍 Recherche des patients existants par nom (souple)
    final patientsExistants = await supabase
        .from('Patient')
        .select('id_patient, nom_complet, age, telephone, sexe')
        .ilike('nom_complet', '%$nom%');

    String? patientId;

    // 🧠 Si des patients existent, afficher un dialogue de choix
    if (patientsExistants.isNotEmpty) {
      final choix = await showDialog<String>(
        context: context,
        builder: (context) {
          final screenHeight = MediaQuery.of(context).size.height;
          final screenWidth = MediaQuery.of(context).size.width;
          final isSmallScreen = screenWidth < 600;

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? screenWidth * 0.9 : 500,
                maxHeight: screenHeight * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // En-tête
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [npPrimaryColor, npAccentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patientsExistants.length == 1
                                    ? 'Patient déjà enregistré'
                                    : 'Plusieurs patients trouvés',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                patientsExistants.length == 1
                                    ? '1 correspondance trouvée'
                                    : '${patientsExistants.length} correspondances trouvées',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contenu
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (patientsExistants.length == 1) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: npAccentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: npAccentColor.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(
                                    Icons.person,
                                    "Nom",
                                    patientsExistants[0]['nom_complet'],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    Icons.cake,
                                    "Âge",
                                    "${patientsExistants[0]['age']} ans",
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    Icons.phone,
                                    "Téléphone",
                                    "${patientsExistants[0]['telephone']}",
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    Icons.wc,
                                    "Sexe",
                                    patientsExistants[0]['sexe'],
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Text(
                              "Patients correspondants :",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: npPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...patientsExistants.map(
                              (p) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${p['nom_complet']}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.cake,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "${p['age']} ans",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Icon(
                                                Icons.phone,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "${p['telephone']}",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: npAccentColor.withOpacity(0.05),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(12),
                                          bottomRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(12),
                                            bottomRight: Radius.circular(12),
                                          ),
                                          onTap: () => Navigator.pop(
                                            context,
                                            'update_${p['id_patient']}',
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.edit,
                                                  size: 18,
                                                  color: npAccentColor,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Mettre à jour ce patient',
                                                  style: TextStyle(
                                                    color: npAccentColor,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.help_outline,
                                  color: Colors.grey[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Que souhaitez-vous faire ?",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Actions (compact)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Wrap(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, 'cancel'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            'Annuler',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context, 'new'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            side: BorderSide(color: npPrimaryColor, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            'Créer nouveau',
                            style: TextStyle(
                              color: npPrimaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(
                            context,
                            'update_${patientsExistants[0]['id_patient']}',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: npSuccessColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 2,
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Mettre à jour',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // 🚫 Annulation
      if (choix == 'cancel') {
        showMessage(context, 'Opération annulée', isWarning: true);
        return;
      }

      // 🆕 Création d'un nouveau patient malgré doublon
      if (choix == 'new') {
        showMessage(
          context,
          "Création d'un nouveau dossier patient",
          isSuccess: true,
        );
      }

      // 🔄 Mise à jour d'un patient existant
      if (choix != null && choix.startsWith('update_')) {
        final id = choix.replaceFirst('update_', '');
        await supabase
            .from('Patient')
            .update(
              Patient(
                nom_complet: nom,
                age: int.tryParse(age.text) ?? 0,
                telephone: tel,
                adresse: adresse.text.trim(),
                profession: profession.text.trim(),
                sexe: sexe!,
                statut_matrimonial: StatutMatrimonial!,
                date_enregistrement: DateTime.now(),
              ).toMap(),
            )
            .eq('id_patient', id);
        patientId = id;
        showMessage(context, 'Patient mis à jour avec succès', isSuccess: true);
        print('✅ Patient mis à jour - ID: $patientId');
      }
    }

    // 🆕 Si aucun patient existant → insertion normale
    if (patientId == null) {
      final patient = Patient(
        nom_complet: nom,
        age: int.tryParse(age.text) ?? 0,
        telephone: tel,
        adresse: adresse.text.trim(),
        profession: profession.text.trim(),
        sexe: sexe!,
        statut_matrimonial: StatutMatrimonial!,
        date_enregistrement: DateTime.now(),
      );

      final response = await supabase
          .from('Patient')
          .insert(patient.toMap())
          .select()
          .single();
      patientId = response['id_patient'];
      showMessage(context, 'Patient enregistré avec succès', isSuccess: true);
      print('✅ Nouveau patient créé - ID: $patientId');
    }

    // 🩺 Enregistrement des paramètres vitaux
    final parametreVitaux = Parametres_vitaux(
      id_patient: patientId!,
      poid: double.tryParse(poid.text) ?? 0.0,
      temperature: double.tryParse(temperature.text) ?? 0.0,
      systolique: double.tryParse(systolique.text) ?? 0.0,
      diastolique: double.tryParse(diastolique.text) ?? 0.0,
      statut_VIH: test_VIH.text.trim(),
      vaccination: vaccination.text.trim(),
      motif_de_consultation: motif_consultation.text.trim(),

      date_enregistrement: DateTime.now(),
      type_service: type_service!,
      id_personnel: AuthUtils.idPersonnel ?? 'unknown',
    );

    final parametreResponse = await supabase
        .from('Parametres_vitaux')
        .insert(parametreVitaux.toMap())
        .select()
        .single();

    final parametreid = parametreResponse['id_parametres_vitaux'];
    print('✅ Paramètres vitaux créés - ID: $parametreid');

    // 🩺 Création de la consultation
    final consultation = Consultation(
      Statut_Consultation: 'en-attente-consultation',
      date_enregistrement: DateTime.now().toIso8601String(),
      date_derniere_mise_ajour: DateTime.now().toIso8601String(),
      type_service: type_service!,
      id_patient: patientId,
      id_parametres_vitaux: parametreid,
      id_personnel: idMedecin,
      payer: 'non',
    );

    final consultationResponse = await supabase
        .from('Consultation')
        .insert(consultation.toMap())
        .select()
        .single();

    final idConsultation = consultationResponse['id_consultation'];
    print(
      '✅ Consultation créée - ID: ${consultationResponse['id_consultation']}',
    );
    showMessage(
      context,
      'Consultation enregistrée avec succès',
      isSuccess: true,
    );
    print('=== ENREGISTREMENT TERMINÉ AVEC SUCCÈS ===');

    final paiement = await supabase.from('paiement').insert({
      'id_consultation': idConsultation,
      'prix_a_paye': 600,
      'statut_paiement': 'non payer',
      'motif': 'Frais de Consultation',
      'date_paiement': DateTime.now().toIso8601String(),
    });
    print("paiement enregistrer avec succes $paiement");

    // 🧹 Nettoyage du formulaire
    _clearFormFields();
  }

  /// Widget pour afficher une ligne d'information
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: npPrimaryColor),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }

  /// 🔔 Affiche un message utilisateur en bas de l'écran
  void showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
    bool isWarning = false,
  }) {
    Color backgroundColor;
    IconData icon;

    if (isError) {
      backgroundColor = npErrorColor;
      icon = Icons.error_outline;
    } else if (isSuccess) {
      backgroundColor = npSuccessColor;
      icon = Icons.check_circle_outline;
    } else if (isWarning) {
      backgroundColor = npWarningColor;
      icon = Icons.warning_amber_rounded;
    } else {
      backgroundColor = npPrimaryColor;
      icon = Icons.info_outline;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 6,
      ),
    );
  }

  /// 🧹 Réinitialise tous les champs du formulaire
  void _clearFormFields() {
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
  }
}
