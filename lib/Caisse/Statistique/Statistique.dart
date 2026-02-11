import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:hostoman/model_unifier.dart'; // Assure-toi que le chemin est correct
import 'Service.dart'; // Assure-toi que le chemin vers ton service est correct
import '../HistoriquePaiement/detail/detail_historique_ui.dart'; // Import pour la navigation

// Couleurs (Tes couleurs d'origine)
const Color npPrimaryColor = Color(0xFF4CAF50);
const Color npAccentColor = Color(0xFF378127);
const Color npSuccessColor = Color(0xFF4CAF50);
const Color npErrorColor = Color(0xFFD32F2F);
const Color npBlueColor = Color(0xFF2196F3);

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final StatsService statsService = StatsService(Supabase.instance.client);

  bool isLoading = true;
  String periodeSelectorionnee = 'today';
  String typePaiement = 'payer'; // Type de paiement : 'payer' ou 'annuler'
  Map<String, dynamic>? statsData;
  List<Map<String, dynamic>> consultations = [];
  List<Map<String, dynamic>> filteredConsultations = [];
  String searchQuery = '';

  DateTime? dateDebutPersonnalisee;
  DateTime? dateFinPersonnalisee;

  @override
  void initState() {
    super.initState();
    chargerStats();
  }

  Future<void> chargerStats() async {
    setState(() => isLoading = true);
    try {
      Map<String, dynamic> data;
      switch (periodeSelectorionnee) {
        case 'today':
          data = await statsService.getStatsToday(statutPaiement: typePaiement);
          break;
        case 'week':
          data = await statsService.getStatsThisWeek(
            statutPaiement: typePaiement,
          );
          break;
        case 'month':
          data = await statsService.getStatsThisMonth(
            statutPaiement: typePaiement,
          );
          break;
        case 'custom':
          data = await statsService.getStatsByPeriod(
            dateDebut: dateDebutPersonnalisee!,
            dateFin: dateFinPersonnalisee!,
            statutPaiement: typePaiement,
          );
          break;
        default:
          data = await statsService.getStatsToday(statutPaiement: typePaiement);
      }

      setState(() {
        statsData = data;
        consultations = List<Map<String, dynamic>>.from(data['consultations']);
        filteredConsultations = consultations;
        isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar(e.toString());
    }
  }

  void _applyFilters() {
    setState(() {
      filteredConsultations = consultations.where((item) {
        final patientMap = item['Patient'] as Map<String, dynamic>;
        final nom = (patientMap['nom_complet'] ?? '').toString().toLowerCase();
        return nom.contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF274621),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: npPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Statistiques',
          style: TextStyle(
            color: Color(0xFF26AE6C),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: npSuccessColor),
            onPressed: chargerStats,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: npPrimaryColor),
            )
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 1200 : double.infinity,
                  ),
                  child: Column(
                    children: [
                      _buildPeriodSelector(),
                      _buildTypePaiementSelector(),
                      _buildStatSection(isDesktop),
                      _buildPatientListSection(isDesktop),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // --- Widgets de construction ---

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPeriodButton('today', 'Aujourd\'hui', Icons.today),
              _buildPeriodButton('week', 'Semaine', Icons.calendar_view_week),
              _buildPeriodButton('month', 'Mois', Icons.calendar_month),
              _buildCustomButton(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Période : ${_getPeriodeLabel()}',
            style: const TextStyle(
              color: npAccentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypePaiementSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => typePaiement = 'payer');
                chargerStats();
              },
              icon: const Icon(Icons.check_circle, size: 20),
              label: const Text('Paiements Validés'),
              style: ElevatedButton.styleFrom(
                backgroundColor: typePaiement == 'payer'
                    ? npSuccessColor
                    : Colors.grey.shade300,
                foregroundColor: typePaiement == 'payer'
                    ? Colors.white
                    : Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => typePaiement = 'annuler');
                chargerStats();
              },
              icon: const Icon(Icons.cancel, size: 20),
              label: const Text('Paiements Annulés'),
              style: ElevatedButton.styleFrom(
                backgroundColor: typePaiement == 'annuler'
                    ? npErrorColor
                    : Colors.grey.shade300,
                foregroundColor: typePaiement == 'annuler'
                    ? Colors.white
                    : Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatSection(bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Patients',
                  '${statsData?['nombre_patients']}',
                  Icons.people,
                  npBlueColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Revenus',
                  '${_formatNumber(statsData?['somme_generee'] ?? 0)} FCFA',
                  Icons.payments,
                  npSuccessColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSmallInfo(
                  Icons.male,
                  "Hommes: ${statsData?['hommes']}",
                  Colors.blue,
                ),
                _buildSmallInfo(
                  Icons.female,
                  "Femmes: ${statsData?['femmes']}",
                  Colors.pink,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientListSection(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Liste des patients',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: npAccentColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 16),
          if (filteredConsultations.isEmpty)
            _buildEmptyState()
          else
            ...filteredConsultations.map((item) => _buildPatientTile(item)),
        ],
      ),
    );
  }

  Widget _buildPatientTile(Map<String, dynamic> item) {
    final patientMap = item['Patient'] as Map<String, dynamic>;
    final patient = Patient.fromMap(patientMap);
    final date = DateTime.parse(item['date_enregistrement']);
    final listPaiements = item['paiement'] as List;
    final montant = listPaiements.isNotEmpty
        ? listPaiements[0]['prix_a_paye']
        : 0;
    final idConsultation = item['id_consultation'].toString();

    return InkWell(
      onTap: () {
        // Note: Statistique affiche les consultations, pas les paiements individuels
        // On utilise donc l'ancienne méthode avec idConsultation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DetailHistoriqueUI(idConsultation: idConsultation),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: npPrimaryColor,
            child: Text(
              patient.nom_complet[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            patient.nom_complet,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(DateFormat('dd/MM/yyyy à HH:mm').format(date)),
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: npSuccessColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_formatNumber(montant.toInt())} FCFA',
              style: const TextStyle(
                color: npSuccessColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Fonctions utilitaires ---

  Widget _buildPeriodButton(String value, String label, IconData icon) {
    bool isSelected = periodeSelectorionnee == value;
    return ElevatedButton.icon(
      onPressed: () {
        setState(() => periodeSelectorionnee = value);
        chargerStats();
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? npPrimaryColor : Colors.grey.shade300,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Rechercher un patient...',
        prefixIcon: const Icon(Icons.search, color: npAccentColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (v) {
        setState(() => searchQuery = v);
        _applyFilters();
      },
    );
  }

  String _formatNumber(int n) =>
      NumberFormat('#,###', 'fr_FR').format(n).replaceAll(',', ' ');

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: npErrorColor));
  }

  Widget _buildStatCard(String t, String v, IconData i, Color c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(i, color: c),
          const SizedBox(height: 8),
          Text(t, style: TextStyle(color: Colors.grey[600])),
          Text(
            v,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfo(IconData i, String t, Color c) {
    return Row(
      children: [
        Icon(i, color: c, size: 18),
        const SizedBox(width: 4),
        Text(t),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        '© 2026 Yamgai Mokube Franck Daniel',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
    );
  }

  // (Code pour showDateRangePicker identique à ton original)
  Widget _buildCustomButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            dateDebutPersonnalisee = picked.start;
            dateFinPersonnalisee = picked.end;
            periodeSelectorionnee = 'custom';
          });
          chargerStats();
        }
      },
      icon: const Icon(Icons.date_range),
      label: const Text('Calendrier'),
    );
  }

  Widget _buildEmptyState() => const Padding(
    padding: EdgeInsets.all(40),
    child: Text("Aucun patient trouvé."),
  );

  String _getPeriodeLabel() {
    if (periodeSelectorionnee == 'today') return "Aujourd'hui";
    if (periodeSelectorionnee == 'week') return "Cette semaine";
    if (periodeSelectorionnee == 'month') return "Ce mois";
    return "Personnalisé";
  }
}
