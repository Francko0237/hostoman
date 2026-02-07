import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Couleurs
const Color medPrimaryColor = Color(0xFF5A47C9);
const Color medAccentColor = Color(0xFF5A47C9);
const Color fondColor = Color(0xFFF3F2F8);
const Color attentionColor = Colors.red;
const Color successColor = Colors.green;
const Color warningColor = Colors.amber;

class DashboardMedecin extends StatefulWidget {
  const DashboardMedecin({super.key});

  @override
  State<DashboardMedecin> createState() => _DashboardMedecinState();
}

class _DashboardMedecinState extends State<DashboardMedecin> {
  int consultationsJour = 12;
  int enAttente = 12;
  int terminer = 12;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _chargerStats();

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _chargerStats();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _chargerStats() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        // Mettre à jour les données
      });
    }
  }

  void _handleTap(BuildContext context, String action) {
    context.push('/Dashboard_Medecin/$action');
    print('Action sélectionnée : $action');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: medPrimaryColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: medPrimaryColor.withOpacity(0.2),
              border: Border.all(
                color: medPrimaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.local_hospital,
                  color: medPrimaryColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Hopital de District de Manjo',
          style: TextStyle(
            color: Colors.white,
            fontSize: isDesktop ? 20 : 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: !isDesktop,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: PopupMenuButton(
              icon: Icon(Icons.person, color: Colors.white),
              color: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) async {
                if (value == 'profile') {
                  context.push('/Dashboard_Caisse/profilcaisse');
                } else if (value == 'deconnexion') {
                  print('déconnexion sélectionnée');
                  try {
                    await Supabase.instance.client.auth.signOut();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Déconnexion réussie !'),
                        backgroundColor: successColor,
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
                  color: medPrimaryColor,
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

      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Header Background Pour le le design violet du haut
          Container(
            height: 210,
            decoration: const BoxDecoration(
              color: medPrimaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // AppBar
                  const SizedBox(height: 50),

                  // Stats Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            count: consultationsJour,
                            label: 'Consultation',
                            color: successColor,
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            count: enAttente,
                            label: 'En Attente',
                            color: attentionColor,
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            count: terminer,
                            label: 'Terminer',
                            color: warningColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 42),

                  // Titre Dashboard
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: medPrimaryColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Dashboard Médecin',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Cards Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 13.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                context: context,
                                icon: Icons.person_add,
                                label: 'Consultations',
                                action: 'ConsultationList',
                                color: Colors.blue,
                                onTap: _handleTap,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildActionCard(
                                context: context,
                                icon: Icons.history,
                                label: 'Historique',
                                action: 'historique',
                                color: Colors.green,
                                onTap: _handleTap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                context: context,
                                icon: Icons.timer,
                                label: 'En-Attente',
                                action: 'EnattenteExam',
                                color: Colors.redAccent,
                                onTap: _handleTap,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildActionCard(
                                context: context,
                                icon: Icons.calendar_month,
                                label: 'Statistiques',
                                action: 'statistiques',
                                color: Colors.teal,
                                onTap: _handleTap,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Gestion Rendez-vous
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildMainActionButton(),
                  ),

                  const SizedBox(height: 58),

                  // Footer
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        '© 2025 Yamgai Mokube Franck Daniel',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // pour les bouton du haut ou on se deconnect et on a les parametre et profil

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

  Widget _buildStatCard({
    required int count,
    required String label,
    required Color color,
  }) {
    final bool isPending = label == 'En Attente';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xfffffffff).withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Color(0xfffffffff).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String action,
    required Color color,
    required Function(BuildContext, String) onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEAEFF4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(2, 3),
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
                const SizedBox(height: 40),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
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

  Widget _buildMainActionButton() {
    return ElevatedButton(
      onPressed: () {
        context.push('/Dashboard_Medecin/rendez-vous');
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: medPrimaryColor,
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
      ),
      child: const Row(
        children: [
          Icon(Icons.calendar_today, size: 30),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion des Rendez-vous',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Programmer et gérer les rendez-vous Futurs',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
