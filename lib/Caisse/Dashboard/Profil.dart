import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Assurez-vous que ces imports sont corrects
import 'package:hostoman/model_unifier.dart';
import 'profil_service.dart';

// Couleurs
const Color npPrimaryColor = Color(0xFF34A853); // Bleu plus vif et moderne
const Color npAccentColor = Color(
  0xFF34A853,
); // Une nuance plus claire pour l'accentuation
const Color npSuccessColor = Color(0xFF4285F4); // Vert Google pour le succès
const Color npErrorColor = Color(
  0xFFEA4335,
); // Rouge Google pour les erreurs/absence de données
const Color npBackgroundColor = Color(0xFFF0F2F5); // Arrière-plan doux et clair
const Color npCardColor = Colors.white; // Couleur des cartes
const Color npTextColor = Color(0xFF3C4043); // Texte sombre pour la lisibilité
const Color npLightTextColor = Color(0xFF5F6368); // Texte secondaire plus clair

class ProfilCaissier extends StatefulWidget {
  const ProfilCaissier({super.key});

  @override
  State<ProfilCaissier> createState() => _ProfilCaissierState();
}

class _ProfilCaissierState extends State<ProfilCaissier> {
  final service = MedecinService(Supabase.instance.client);
  Medecin? medecin;
  int totalPatients = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadMedecin();
  }

  Future<void> _loadMedecin() async {
    // Simuler un délai de chargement pour l'exemple
    await Future.delayed(const Duration(seconds: 1));

    final result = await service.fetchMedecinConnecte();
    if (result != null) {
      final total = await service.countPatientsEnregistres();
      setState(() {
        medecin = result;
        totalPatients = total;
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  // Widget pour afficher une ligne d'information simple (utilisé dans la section personnelle)
  Widget _buildInfoCardRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: npPrimaryColor.withOpacity(0.8)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: npLightTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: npTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900; // Adapter pour des écrans plus larges
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: npBackgroundColor,
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
            SizedBox(width: 75),
            Icon(Icons.person, color: npPrimaryColor, size: 24),
            const SizedBox(width: 12),
            Text(
              '  Profil',
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
      body: SafeArea(
        child: Container(
          // Retrait du dégradé de l'arrière-plan du body pour un look plus épuré
          color: npBackgroundColor,
          child: loading
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: npCardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: npPrimaryColor),
                        const SizedBox(height: 20),
                        Text(
                          'Chargement des données...',
                          style: TextStyle(
                            color: npPrimaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : medecin == null
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: npCardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: npErrorColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_off,
                            size: 64,
                            color: npErrorColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Aucune donnée de médecin trouvée',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: npErrorColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Veuillez vous assurer d\'être connecté.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: npLightTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop
                          ? 900
                          : (isTablet ? 700 : double.infinity),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.all(
                        isDesktop ? 32 : (isTablet ? 24 : 16),
                      ),
                      child: Column(
                        children: [
                          // Card principale avec avatar
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [npPrimaryColor, npAccentColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(
                                28,
                              ), // Rayon plus grand
                              boxShadow: [
                                BoxShadow(
                                  color: npPrimaryColor.withOpacity(
                                    0.4,
                                  ), // Ombre plus prononcée
                                  blurRadius: 25,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 120, // Avatar plus grand
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: npCardColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: npCardColor.withOpacity(0.5),
                                      width: 3,
                                    ), // Bordure légère
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      // Afficher la première lettre du prénom, puis du nom si le prénom est vide
                                      (medecin!.nom.isNotEmpty
                                              ? medecin!.nom[0]
                                              : '')
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: npPrimaryColor,
                                        fontSize:
                                            56, // Taille de texte plus grande
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 24,
                                ), // Espacement augmenté

                                     Text(
                                        'Mr. ${medecin!.prenom} ${medecin!.nom}', // Affichage "Mr."
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize:
                                              28, // Taille de texte plus grande
                                          fontWeight: FontWeight.w700,
                                          color: npCardColor,
                                        ),
                                      ),

                                const SizedBox(height: 10),
                                if (medecin!.specialite != null &&
                                    medecin!.specialite!.isNotEmpty)
                                  Chip(
                                    // Utilisation d'un Chip pour la spécialité
                                    label: Text(
                                      medecin!.specialite!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: npPrimaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    backgroundColor: npCardColor,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    materialTapTargetSize: MaterialTapTargetSize
                                        .shrinkWrap, // Réduire la zone de touche
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 32,
                          ), // Espacement augmenté entre les sections
                          // Section Informations Personnelles
                          Container(
                            padding: const EdgeInsets.all(
                              24,
                            ), // Espacement intérieur ajusté
                            decoration: BoxDecoration(
                              color: npCardColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      color: npPrimaryColor,
                                      size: 28,
                                    ), // Icône plus grande
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Coordonnées et Information',
                                      style: TextStyle(
                                        fontSize:
                                            20, // Taille de texte augmentéef
                                        fontWeight: FontWeight.w700,
                                        color: npTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(
                                  height: 30,
                                  thickness: 1,
                                  color: npBackgroundColor,
                                ), // Séparateur
                                _buildInfoCardRow(
                                  Icons.phone,
                                  'Téléphone',
                                  medecin!.telephone.toString(),
                                ),
                                _buildInfoCardRow(
                                  Icons.email,
                                  'Email',
                                  medecin!.email ?? 'Non renseigné',
                                ),
                                _buildInfoCardRow(
                                  Icons.location_on,
                                  'Adresse',
                                  medecin!.adresse ?? 'Non renseigné',
                                ),
                                _buildInfoCardRow(
                                  Icons.cake,
                                  'Âge',
                                  '${medecin!.age ?? 'N/A'} ans',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32), // Espacement augmenté
                          // Section Statistiques
                          Container(
                            padding: const EdgeInsets.all(
                              20,
                            ), // Espacement augmenté
                            decoration: BoxDecoration(
                              color: npCardColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(
                                    20,
                                  ), // Padding augmenté
                                  decoration: BoxDecoration(
                                    color: npSuccessColor.withOpacity(
                                      0.15,
                                    ), // Opacité augmentée
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.people_alt_outlined, // Nouvelle icône
                                    size: 48, // Taille d'icône augmentée
                                    color: npSuccessColor,
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ), // Espacement augmenté
                                Text(
                                  '$totalPatients',
                                  style: TextStyle(
                                    fontSize:
                                        64, // Taille de texte beaucoup plus grande
                                    fontWeight: FontWeight.w900,
                                    color: npSuccessColor,
                                    height: 1, // Hauteur de ligne réduite
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Patients enregistrés',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18, // Taille de texte augmentée
                                    fontWeight: FontWeight.w700,
                                    color: npLightTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            height: 110,
                          ), // Espacement final augmenté
                          Center(
                            child: Text(
                              '© 2025 Yamgai Mokube Franck Daniel',
                              style: TextStyle(
                                fontSize: 14,
                                color: npLightTextColor.withOpacity(0.7),
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
    );
  }
}
