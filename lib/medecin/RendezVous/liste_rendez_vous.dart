import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'rendez_vous_service.dart';

class ListeRendezVousPage extends StatefulWidget {
  const ListeRendezVousPage({super.key});

  @override
  State<ListeRendezVousPage> createState() => _ListeRendezVousPageState();
}

class _ListeRendezVousPageState extends State<ListeRendezVousPage> {
  late final RendezVousService _rendezVousService;
  List<Map<String, dynamic>> _rendezVousList = [];
  bool _isLoading = true;

  // Couleurs
  final Color primaryPurple = const Color(0xFF6A5ACD);
  final Color lightPurple = const Color(0xFF8A7DF0);

  @override
  void initState() {
    super.initState();
    _rendezVousService = RendezVousService(Supabase.instance.client);
    _loadRendezVous();
  }

  Future<void> _loadRendezVous() async {
    try {
      final rdv = await _rendezVousService.getRendezVous();
      if (mounted) {
        setState(() {
          _rendezVousList = rdv;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F3),
      appBar: AppBar(
        title: const Text(
          "Rendez-vous Programmés",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadRendezVous();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryPurple))
          : _rendezVousList.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _rendezVousList.length,
              itemBuilder: (context, index) {
                final rdv = _rendezVousList[index];
                return _buildRendezVousCard(rdv);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "Aucun rendez-vous programmé",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRendezVousCard(Map<String, dynamic> rdv) {
    final patient = rdv['Patient'] as Map<String, dynamic>;
    final String nom = patient['nom_complet']?.toString() ?? 'Inconnu';
    final String telephone = patient['telephone']?.toString() ?? 'N/A';
    final String sexe = patient['sexe']?.toString() ?? 'N/A';
    final int? age = patient['age'];

    final rdvDateStr = rdv['date_rdv_prevu'];
    final DateTime? rdvDate = rdvDateStr != null
        ? DateTime.tryParse(rdvDateStr)
        : null;

    final bool isPast = rdvDate != null && rdvDate.isBefore(DateTime.now());
    final Color dateColor = isPast ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigation vers la page de finalisation
          context.push(
            '/Dashboard_Medecin/FinalisationConsultation/${rdv['id_consultation']}',
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      nom,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isPast)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "EN RETARD",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.monitor_heart_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "$sexe, ${age ?? '?'} ans",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(telephone, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Icon(Icons.access_time_filled, color: dateColor),
                  const SizedBox(width: 8),
                  Text(
                    rdvDate != null
                        ? DateFormat(
                            'EEE d MMM yyyy à HH:mm',
                            'fr_FR',
                          ).format(rdvDate)
                        : "Date inconnue",
                    style: TextStyle(
                      color: dateColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
