import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'Nbr&Caisse.dart';

// Couleurs
const Color npPrimaryColor = Color(0xFF4CAF50);
const Color npAccentColor = Color(0xFF378127);
const Color npSuccessColor = Color(0xFF4CAF50);
const Color npOrangeColor = Color(0xFFFF9800);
const Color fondColor = Color(0xFFF5F3F3);

class DashboardCaisse extends StatefulWidget {
  const DashboardCaisse({super.key});

  @override
  State<DashboardCaisse> createState() => _DashboardCaisseState();
}

class _DashboardCaisseState extends State<DashboardCaisse> {
  final DashboardStatsService statsService = DashboardStatsService(
    Supabase.instance.client,
  );

  int personnesRecues = 0;
  int totalEncaisse = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _chargerStats(); // Appel de la fonction une fois au démarrage

    // Pour rafraîchir le nombre de patients chaque 5 secondes depuis la base de données
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _chargerStats();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Annuler le timer quand on quitte la page
    super.dispose();
  }

  Future<void> _chargerStats() async {
    final stats = await statsService.getStatsJour();
    if (mounted) {
      setState(() {
        personnesRecues = stats['personnes_recues'] as int;
        totalEncaisse = stats['total_encaisse'] as int;
      });
    }
  }

  void _handleTap(BuildContext context, String action) {
    context.push('/Dashboard_Caisse/$action');
    print('Action sélectionnée : $action');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: fondColor,
      appBar: AppBar(
        backgroundColor: Color(0xFF274621),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: npPrimaryColor.withOpacity(0.2),
              border: Border.all(
                color: npPrimaryColor.withOpacity(0.3),
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
            color: Color(0xFF26AE6C),
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
              color: npPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: PopupMenuButton(
              icon: Icon(Icons.person, color: npPrimaryColor),
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
        color: Color(0xFFF5F3F3),
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
                          // Titre Dashboard Caisse
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [npPrimaryColor, npAccentColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: npPrimaryColor.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                "Dashboard Caisse",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isDesktop ? 50 : 30),

                          // Statistiques (Personne Reçue + Total Encaissé)
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Personnes Reçues (jour)',
                                  value: personnesRecues.toString(),
                                  color: npOrangeColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Total Encaissé (jour)',
                                  value:
                                      '${statsService.formatMontant(totalEncaisse)} FCFA',
                                  color: npSuccessColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isDesktop ? 32 : 40),

                          // Actions principales (2x2 grid)
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionCard(
                                  context: context,
                                  icon: Icons.access_time,
                                  label: 'Paiements en attente',
                                  action: 'paiementlist',
                                  color: npSuccessColor,
                                  onTap: _handleTap,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildActionCard(
                                  context: context,
                                  icon: Icons.history,
                                  label: 'Historique des Paiements',
                                  action: 'HistoriquePaiement',
                                  color: npAccentColor,
                                  onTap: _handleTap,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Statistiques (pleine largeur)
                          _buildActionCard(
                            context: context,
                            icon: Icons.analytics,
                            label: 'Statistiques',
                            action: 'Statistiques',
                            color: const Color(0xFF2196F3),
                            onTap: _handleTap,
                          ),
                          const SizedBox(height: 60),
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
                  color: Colors.black.withOpacity(0.02),
                ),
                child: Text(
                  '© 2025 Yamgai Mokube Franck Daniel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.95),
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
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
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
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
}
