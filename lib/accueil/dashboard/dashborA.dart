import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Assurez-vous que l'import de votre service est correct
import 'Nbr_patient_service.dart';

const Color npPrimaryColor = Color(0xFF1565C0);
const Color npAccentColor = Color(0xFF2196F3);
const Color npSuccessColor = Color(0xFF4CAF50);
const Color npPurpleColor = Color(0xFF7B1FA2);
const Color npPageBackgroundStart = Color(0xFF0D47A1);
const Color npPageBackgroundEnd = Color(0xFF1976D2);
const Color npCardColor = Colors.white; // Nouvelle couleur pour la clarté

class DashboardAccueil extends StatefulWidget {
  const DashboardAccueil({super.key});

  @override
  State<DashboardAccueil> createState() => _DashboardAccueilState();
}

class _DashboardAccueilState extends State<DashboardAccueil> {
  final patientService = PatientDuJourService(Supabase.instance.client);
  int patientsDuJour = 0;
  bool loadingStats = true;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _loadStats(); //appel de la fonction une fois au demarage
    //Pour rafraichir le nombres de patients chaque 5 secondes de a base de données
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    // Simuler un léger délai pour voir l'état de chargement
    await Future.delayed(const Duration(milliseconds: 500));
    final total = await patientService.countPatientsDuJour();
    setState(() {
      patientsDuJour = total;
      loadingStats = false;
    });
  }

  //Pour liberer la mémoire
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _handleTap(BuildContext context, String action) {
    print('Action sélectionnée : $action');
    context.push(action);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: npPageBackgroundStart,
      appBar: AppBar(
        backgroundColor: npCardColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: npPrimaryColor.withOpacity(0.1),
              border: Border.all(
                color: npPrimaryColor.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.local_hospital, color: npPrimaryColor, size: 24),
              ),
            ),
          ),
        ),
        title: Text(
          'Hopital de District de Manjo',
          style: TextStyle(
            color: npPrimaryColor,
            fontSize: isDesktop ? 20 : 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: !isDesktop,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: npPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: PopupMenuButton(
              icon: Icon(Icons.person, color: npPrimaryColor),
              color: npCardColor,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) async {
                if (value == 'profile') {
                  context.push('/Dashboard_Accueil/profil');
                } else if (value == 'deconnexion') {
                  print('déconnexion sélectionnée');

                  try {
                    await Supabase.instance.client.auth.signOut();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Déconnexion réussie !'),
                        backgroundColor: npSuccessColor,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    if (context.mounted) {
                      context.go('/Authen_Personnel');
                    }
                  } catch (e) {
                    print('❌ Erreur de déconnexion : $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Erreur lors de la déconnexion'),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                _buildPopupMenuItem(
                  value: 'profile',
                  icon: Icons.person_outline,
                  label: 'Profile',
                  color: npPrimaryColor,
                ),

                _buildPopupMenuItem(
                  value: 'deconnexion',
                  icon: Icons.logout_outlined,
                  label: 'Déconnexion',
                  color: Colors.red[700]!,
                ),
              ],
            ),
          ),
        ],
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
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1200 : double.infinity,
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 48 : (isTablet ? 32 : 20),
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // En-tête "Actions Rapides"
                          _buildSectionHeader('Dashboard Accueil'),
                          SizedBox(height: isDesktop ? 70 : 80),

                          // Grille des actions
                          isDesktop
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: _buildActionButton(
                                        context,
                                        icon: Icons.person_add_outlined,
                                        label: 'Nouveau Patient',
                                        action:
                                            '/Dashboard_Accueil/nouveau-patient',
                                        color: npSuccessColor,
                                        onTap: _handleTap,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: _buildActionButton(
                                        context,
                                        icon: Icons.history_outlined,
                                        label: 'Liste & Historique',
                                        action:
                                            '/Dashboard_Accueil/liste-patient',
                                        color: npAccentColor,
                                        onTap: _handleTap,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: _buildActionButton(
                                        context,
                                        icon: Icons.bar_chart_outlined,
                                        label: 'Statistiques',
                                        action:
                                            '/Dashboard_Accueil/statistique',
                                        color: npPurpleColor,
                                        onTap: _handleTap,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildActionButton(
                                            context,
                                            icon: Icons.person_add_outlined,
                                            label: 'Nouveau Patient',
                                            action:
                                                '/Dashboard_Accueil/nouveau-patient',
                                            color: npSuccessColor,
                                            onTap: _handleTap,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildActionButton(
                                            context,
                                            icon: Icons.history_outlined,
                                            label: 'Liste & Historique',
                                            action:
                                                '/Dashboard_Accueil/liste-patient',
                                            color: npAccentColor,
                                            onTap: _handleTap,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // La carte "Statistiques" seule sur mobile/tablette prend toute la largeur
                                    _buildActionButton(
                                      context,
                                      icon: Icons.bar_chart_outlined,
                                      label: 'Statistiques',
                                      action: '/Dashboard_Accueil/statistique',
                                      color: npPurpleColor,
                                      onTap: _handleTap,
                                    ),
                                  ],
                                ),

                          SizedBox(height: isDesktop ? 48 : 32),

                          // Carte des statistiques du jour (Nouvelle disposition horizontale)
                          _buildTodayStatsCard(isDesktop, isTablet),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.03),
                ),
                child: Text(
                  '© 2025 Yamgai Mokube Franck Daniel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fonctions de construction existantes (PopupMenu, Header, ActionButton) ...
  PopupMenuEntry<String> _buildPopupMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: npCardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: npPrimaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home, color: npPrimaryColor, size: 30),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: npPrimaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String action,
    required Color color,
    required Function(BuildContext, String) onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: npCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onTap(context, action),
          splashColor: color.withOpacity(0.2),
          highlightColor: color.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.3), width: 2),
                  ),
                  child: Icon(icon, size: 36, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // NOUVELLE VERSION : Correction du débordement avec Expanded
  Widget _buildTodayStatsCard(bool isDesktop, bool isTablet) {
    // Si les données sont en cours de chargement
    if (loadingStats) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: npCardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: npPrimaryColor),
            const SizedBox(width: 16),
            Text(
              'Chargement des statistiques...',
              style: TextStyle(
                color: npPrimaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Carte Statistique en mode Ligne
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 28,
        vertical: isDesktop ? 32 : 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [npPrimaryColor, npAccentColor],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: npPrimaryColor.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bloc 1 : Icône et Labels (DOIT ÊTRE FLEXIBLE)
          Expanded(
            // <--- AJOUT CRUCIAL ICI
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône et fond blanc pour le contraste
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: npCardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.people_alt_outlined,
                    size: 36,
                    color: npPrimaryColor,
                  ),
                ),
                const SizedBox(width: 24),
                // Nous n'avons pas besoin d'Expanded ici car Column gère bien la verticalité
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bloc 2 : Le Nombre (Utilise la taille minimale requise)
                    Text(
                      '         $patientsDuJour',
                      style: TextStyle(
                        fontSize: isDesktop ? 45 : 35,
                        fontWeight: FontWeight.w900,
                        color: npCardColor,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Patients Aujourd\'hui',
                      style: TextStyle(
                        fontSize: isDesktop ? 20 : 18,
                        fontWeight: FontWeight.w600,
                        color: npCardColor.withOpacity(0.95),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
