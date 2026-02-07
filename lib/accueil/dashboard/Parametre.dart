import 'package:flutter/material.dart';



const Color npPrimaryColor = Color(0xFF1A73E8); // Bleu plus vif et moderne
class ParametrePage extends StatelessWidget {
  const ParametrePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
            SizedBox(width: 50,),
            Icon(Icons.person, color: npPrimaryColor, size: 24),
            const SizedBox(width: 12),
            Text(
              '  Paramètres',
              style: TextStyle(
                color: npPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Préférences'),
          _buildSettingTile(
            icon: Icons.language,
            title: 'Langue',
            subtitle: 'Français',
            onTap: () {
              print('Changer la langue');
            },
          ),
          _buildSettingTile(
            icon: Icons.dark_mode,
            title: 'Thème',
            subtitle: 'Clair',
            onTap: () {
              print('Changer le thème');
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Système'),
          _buildSettingTile(
            icon: Icons.sync,
            title: 'Synchronisation',
            subtitle: 'Dernière sync: aujourd\'hui',
            onTap: () {
              print('Lancer la synchronisation');
            },
          ),
          _buildSettingTile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: 'v1.0.0',
            onTap: () {
              print('Afficher les infos de version');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue.shade700),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
