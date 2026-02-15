import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/Directeur/Statistiques/stats_view.dart';
import 'package:hostoman/Directeur/GestionPersonnel/gestion_personnel_page.dart';

// Couleurs - Thème Directeur (Bleu Nuit / Or)
const Color dirPrimaryColor = Color(0xFF1A237E); // Bleu nuit profond
const Color dirAccentColor = Color(0xFFFFD700); // Or pour le prestige
const Color dirBackgroundColor = Color(0xFFF5F6FA);
const Color dirCardColor = Colors.white;

class DirecteurDashboardPage extends StatefulWidget {
  const DirecteurDashboardPage({super.key});

  @override
  State<DirecteurDashboardPage> createState() => _DirecteurDashboardPageState();
}

class _DirecteurDashboardPageState extends State<DirecteurDashboardPage> {
  int _selectedIndex = 0;

  // Liste des pages
  final List<Widget> _pages = [
    const stats_view(),
    const gestion_personnel_page(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        context.go('/Authen_Personnel');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la déconnexion: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dirBackgroundColor,
      appBar: AppBar(
        backgroundColor: dirPrimaryColor,
        elevation: 0,
        title: const Text(
          'Administration',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Se déconnecter',
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: dirPrimaryColor,
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_customize),
              label: 'Statistiques',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt),
              label: 'Personnel',
            ),
          ],
        ),
      ),
    );
  }
}
