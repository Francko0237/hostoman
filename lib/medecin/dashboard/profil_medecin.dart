import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hostoman/model_unifier.dart';
import 'profil_medecin_service.dart';

// Couleurs - Thème Médecin (Violet)
const Color medPrimaryColor = Color(0xFF5A47C9);
const Color medAccentColor = Color(
  0xFF7B6AD8,
); // Un peu plus clair pour le dégradé
const Color medBackgroundColor = Color(0xFFF3F2F8);
const Color medCardColor = Colors.white;
const Color medTextColor = Color(0xFF2D2D2D);
const Color medLightTextColor = Color(0xFF757575);

class ProfilMedecinPage extends StatefulWidget {
  const ProfilMedecinPage({super.key});

  @override
  State<ProfilMedecinPage> createState() => _ProfilMedecinPageState();
}

class _ProfilMedecinPageState extends State<ProfilMedecinPage> {
  final service = ProfilMedecinService(Supabase.instance.client);
  Medecin? medecin;
  int totalConsultations = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadMedecin();
  }

  Future<void> _loadMedecin() async {
    // Simuler un léger délai pour l'expérience utilisateur
    await Future.delayed(const Duration(milliseconds: 500));

    final result = await service.fetchMedecinConnecte();
    if (result != null) {
      final total = await service.countConsultationsTerminees();
      if (mounted) {
        setState(() {
          medecin = result;
          totalConsultations = total;
          loading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // Widget pour afficher une ligne d'information
  Widget _buildInfoCardRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: medPrimaryColor.withOpacity(0.8)),
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
                    color: medLightTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: medTextColor,
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
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: medBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: medPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mon Profil',
          style: TextStyle(
            color: medPrimaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: !isDesktop,
      ),
      body: SafeArea(
        child: loading
            ? Center(child: CircularProgressIndicator(color: medPrimaryColor))
            : medecin == null
            ? _buildErrorState()
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(isDesktop ? 32 : 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 24),
                        _buildInfoSection(),
                        const SizedBox(height: 24),
                        _buildStatsCard(),
                        const SizedBox(height: 40),
                        Text(
                          '© 2025 Yamgai Mokube Franck Daniel',
                          style: TextStyle(
                            fontSize: 12,
                            color: medLightTextColor.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Impossible de charger le profil',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [medPrimaryColor, medAccentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: medPrimaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 4,
              ),
            ),
            child: Center(
              child: Text(
                (medecin!.nom.isNotEmpty ? medecin!.nom[0] : '').toUpperCase(),
                style: const TextStyle(
                  color: medPrimaryColor,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Dr. ${medecin!.prenom} ${medecin!.nom}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (medecin!.specialite != null && medecin!.specialite!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                medecin!.specialite!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: medCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.contact_mail_outlined, color: medPrimaryColor),
              SizedBox(width: 12),
              Text(
                'Information de contact',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: medTextColor,
                ),
              ),
            ],
          ),
          const Divider(height: 30),
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
          _buildInfoCardRow(Icons.cake, 'Âge', '${medecin!.age ?? 'N/A'} ans'),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: medCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: medPrimaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_turned_in,
              size: 40,
              color: medPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$totalConsultations',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: medPrimaryColor,
            ),
          ),
          const Text(
            'Consultations Terminées',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: medLightTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
