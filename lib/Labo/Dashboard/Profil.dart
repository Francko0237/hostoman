import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Assurez-vous que ces imports sont corrects
import 'package:hostoman/model_unifier.dart';
import 'profil_service.dart';

// Couleurs - Thème Laboratoire
const Color labPrimaryColor = Color(0xFF212031);
const Color labAccentColor = Color(0xFF4285F4);
const Color labSuccessColor = Color(0xFF34A853);
const Color labErrorColor = Color(0xFFEA4335);
const Color labBackgroundColor = Color(0xFFF5F3F3);
const Color labCardColor = Colors.white;
const Color labTextColor = Color(0xFF3C4043);
const Color labLightTextColor = Color(0xFF5F6368);

class ProfilLaborantinPage extends StatefulWidget {
  const ProfilLaborantinPage({super.key});

  @override
  State<ProfilLaborantinPage> createState() => _ProfilLaborantinPageState();
}

class _ProfilLaborantinPageState extends State<ProfilLaborantinPage> {
  final service = LaborantinService(Supabase.instance.client);
  Medecin? laborantin;
  int totalExamens = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadLaborantin();
  }

  Future<void> _loadLaborantin() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final result = await service.fetchLaborantinConnecte();
    if (result != null) {
      final total = await service.countExamensEnCoursTotal();
      setState(() {
        laborantin = result;
        totalExamens = total;
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
          Icon(icon, size: 22, color: labPrimaryColor.withOpacity(0.8)),
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
                    color: labLightTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: labTextColor,
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
      backgroundColor: labBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: labPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            SizedBox(width: 75),
            Icon(Icons.person, color: labPrimaryColor, size: 24),
            const SizedBox(width: 12),
            Text(
              '  Profil',
              style: TextStyle(
                color: labPrimaryColor,
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
          color: labBackgroundColor,
          child: loading
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: labCardColor,
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
                        CircularProgressIndicator(color: labPrimaryColor),
                        const SizedBox(height: 20),
                        Text(
                          'Chargement des données...',
                          style: TextStyle(
                            color: labPrimaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : laborantin == null
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: labCardColor,
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
                            color: labErrorColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_off,
                            size: 64,
                            color: labErrorColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Aucune donnée de médecin trouvée',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: labErrorColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Veuillez vous assurer d\'être connecté.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: labLightTextColor,
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
                                colors: [labPrimaryColor, labAccentColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(
                                28,
                              ), // Rayon plus grand
                              boxShadow: [
                                BoxShadow(
                                  color: labPrimaryColor.withOpacity(
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
                                    color: labCardColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: labCardColor.withOpacity(0.5),
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
                                      (laborantin!.nom.isNotEmpty
                                              ? laborantin!.nom[0]
                                              : '')
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: labPrimaryColor,
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
                                  'Mr. ${laborantin!.prenom} ${laborantin!.nom}', // Affichage "Dr."
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 28, // Taille de texte plus grande
                                    fontWeight: FontWeight.w700,
                                    color: labCardColor,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (laborantin!.specialite != null &&
                                    laborantin!.specialite!.isNotEmpty)
                                  Chip(
                                    // Utilisation d'un Chip pour la spécialité
                                    label: Text(
                                      laborantin!.specialite!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: labPrimaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    backgroundColor: labCardColor,
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
                              color: labCardColor,
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
                                      color: labPrimaryColor,
                                      size: 28,
                                    ), // Icône plus grande
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Coordonnées et Information',
                                      style: TextStyle(
                                        fontSize:
                                            20, // Taille de texte augmentée
                                        fontWeight: FontWeight.w700,
                                        color: labTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(
                                  height: 30,
                                  thickness: 1,
                                  color: labBackgroundColor,
                                ), // Séparateur
                                _buildInfoCardRow(
                                  Icons.phone,
                                  'Téléphone',
                                  laborantin!.telephone.toString(),
                                ),
                                _buildInfoCardRow(
                                  Icons.email,
                                  'Email',
                                  laborantin!.email ?? 'Non renseigné',
                                ),
                                _buildInfoCardRow(
                                  Icons.location_on,
                                  'Adresse',
                                  laborantin!.adresse ?? 'Non renseigné',
                                ),
                                _buildInfoCardRow(
                                  Icons.cake,
                                  'Âge',
                                  '${laborantin!.age ?? 'N/A'} ans',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32), // Espacement augmenté
                          // Section Statistiques
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: labCardColor,
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
                                      Icons.bar_chart,
                                      color: labPrimaryColor,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Statistiques',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: labTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Carte 1: Total examens effectués
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        labSuccessColor.withOpacity(0.1),
                                        labSuccessColor.withOpacity(0.05),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: labSuccessColor.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: labSuccessColor.withOpacity(
                                            0.2,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check_circle_outline,
                                          size: 32,
                                          color: labSuccessColor,
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$totalExamens',
                                              style: TextStyle(
                                                fontSize: 36,
                                                fontWeight: FontWeight.w900,
                                                color: labSuccessColor,
                                                height: 1,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Examens effectués',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: labLightTextColor,
                                              ),
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

                          const SizedBox(
                            height: 50,
                          ), // Espacement final augmenté
                          Center(
                            child: Text(
                              '© 2025 Yamgai Mokube Franck Daniel',
                              style: TextStyle(
                                fontSize: 14,
                                color: labLightTextColor.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
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
