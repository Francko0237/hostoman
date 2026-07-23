import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'historique_service.dart';

// Couleurs - Thème Laboratoire
const Color labPrimaryColor = Color(0xFF212031);
const Color labBlueColor = Color(0xFF009688);

class HistoriqueLaboUI extends StatefulWidget {
  const HistoriqueLaboUI({super.key});

  @override
  State<HistoriqueLaboUI> createState() => _HistoriqueLaboUIState();
}

class _HistoriqueLaboUIState extends State<HistoriqueLaboUI> {
  final HistoriqueLaboService historiqueService = HistoriqueLaboService(
    Supabase.instance.client,
  );

  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> filteredPatients = [];
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    chargerHistorique();
  }

  Future<void> chargerHistorique() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final data = await historiqueService.getPatientsUniques();
      setState(() {
        patients = data;
        filteredPatients = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'lex_server_error'.tr();
      });
    }
  }

  void _applyFilters() {
    setState(() {
      filteredPatients = patients.where((item) {
        final patientMap = item['Patient'] as Map<String, dynamic>;
        final nom = (patientMap['nom_complet'] ?? '').toString().toLowerCase();
        return nom.contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: labPrimaryColor,
        centerTitle: !isDesktop,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'lhist_title'.tr(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: chargerHistorique,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: labBlueColor))
          : errorMessage != null
          ? _buildErrorState()
          : Column(
              children: [
                _buildSearchBar(isDesktop),
                _buildCounter(isDesktop),
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 900 : double.infinity,
                      ),
                      child: filteredPatients.isEmpty
                          ? Center(
                              child: Text(
                                'lhist_empty'.tr(),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              itemCount: filteredPatients.length,
                              itemBuilder: (context, index) {
                                return _buildPatientCard(
                                  filteredPatients[index],
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: isDesktop ? null : _buildBottomNav(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: chargerHistorique,
            icon: const Icon(Icons.refresh),
            label: Text('lex_retry'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: labBlueColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 900 : double.infinity,
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'lhist_search_hint'.tr(),
              prefixIcon: const Icon(Icons.search, color: labBlueColor),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() => searchQuery = value);
              _applyFilters();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCounter(bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 900 : double.infinity,
          ),
          child: Text(
            (filteredPatients.length > 1 ? 'lhist_count_many' : 'lhist_count_one')
                .tr(namedArgs: {'count': '${filteredPatients.length}'}),
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> item) {
    final patientMap = item['Patient'] as Map<String, dynamic>;
    final String nom = patientMap['nom_complet']?.toString() ?? 'Patient';
    final String sexe = patientMap['sexe']?.toString() ?? '';
    final int? age = patientMap['age'] as int?;
    final String idPatient = patientMap['id_patient']?.toString() ?? '';
    final int sessions = item['nombre_sessions'] as int? ?? 1;
    final String initial = nom.isNotEmpty ? nom[0].toUpperCase() : 'P';

    return InkWell(
      onTap: () {
        context.push(
          '/Dashboard_Laboratoire/HistoriquePatient/$idPatient',
          extra: {'nom': nom, 'sexe': sexe, 'age': age},
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: labBlueColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: labBlueColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nom,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        sexe == 'Homme' ? Icons.male : Icons.female,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        sexe,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (age != null) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.cake, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Text(
                          'lhist_age_value'.tr(namedArgs: {'age': '$age'}),
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Badge sessions
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: labBlueColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$sessions session${sessions > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: labBlueColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 2,
      backgroundColor: Colors.white,
      selectedItemColor: labPrimaryColor,
      unselectedItemColor: Colors.grey.shade500,
      showUnselectedLabels: true,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/Dashboard_Laboratoire');
            break;
          case 1:
            context.push('/Dashboard_Laboratoire/Statistiques');
            break;
          case 2:
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard),
          label: 'labd_bottom_dashboard'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.bar_chart),
          label: 'labd_bottom_stats'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.history),
          label: 'labd_bottom_history'.tr(),
        ),
      ],
    );
  }
}
