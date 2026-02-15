import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'stats_service.dart';

class stats_view extends StatefulWidget {
  const stats_view({super.key});

  @override
  State<stats_view> createState() => _stats_viewState();
}

class _stats_viewState extends State<stats_view> {
  final StatsService _service = StatsService(Supabase.instance.client);

  Map<String, dynamic> globalStats = {
    'revenu': 0.0,
    'patients': 0,
    'consultations': 0,
  };
  List<Map<String, dynamic>> dailyActivity = [];
  Map<String, dynamic> demographics = {
    'gender': {'M': 0, 'F': 0},
    'ageRanges': {'0-18': 0, '19-35': 0, '36-60': 0, '60+': 0},
  };
  Map<String, int> operationalStats = {
    'terminer': 0,
    'en attente': 0,
    'annuler': 0,
  };
  List<Map<String, dynamic>> revenueTrend = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stats = await _service.getGlobalStats();
    final activity = await _service.getDailyActivity();
    final demo = await _service.getDemographics();
    final op = await _service.getOperationalStats();
    final trend = await _service.getRevenueTrend();

    if (mounted) {
      setState(() {
        globalStats = stats;
        dailyActivity = activity;
        demographics = demo;
        operationalStats = op;
        revenueTrend = trend;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: const TabBar(
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: [
            Tab(text: 'Résumé', icon: Icon(Icons.dashboard)),
            Tab(text: 'Finances', icon: Icon(Icons.monetization_on)),
            Tab(text: 'Patients', icon: Icon(Icons.people)),
          ],
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(),
            _buildFinanceTab(),
            _buildPatientsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          const Text(
            'Consultations (7 jours)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildActivityChart(),
          const SizedBox(height: 24),
          const Text(
            'Statut des Opérations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildOperationalStatus(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        _buildStatCard(
          'Revenus',
          '${globalStats['revenu']} FCFA',
          Icons.account_balance_wallet,
          Colors.green,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Patients',
          '${globalStats['patients']}',
          Icons.person_add,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationalStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSmallIndicator(
          'Terminées',
          operationalStats['terminer']!,
          Colors.green,
        ),
        _buildSmallIndicator(
          'En cours',
          operationalStats['en attente']!,
          Colors.orange,
        ),
        _buildSmallIndicator(
          'Annulées',
          operationalStats['annuler']!,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildSmallIndicator(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActivityChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < dailyActivity.length) {
                    return Text(
                      dailyActivity[index]['day'],
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: dailyActivity
                  .asMap()
                  .entries
                  .map(
                    (e) => FlSpot(
                      e.key.toDouble(),
                      (e.value['count'] as int).toDouble(),
                    ),
                  )
                  .toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenu sur 30 jours',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: BarChart(
              BarChartData(
                barGroups: revenueTrend.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: (e.value['amount'] as double),
                        color: Colors.green,
                        width: 6,
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index % 5 == 0 && index < revenueTrend.length) {
                          return Text(
                            revenueTrend[index]['date'],
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildStatCard(
            'Total du Mois',
            '${globalStats['revenu']} FCFA',
            Icons.trending_up,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsTab() {
    int total = demographics['gender']['M'] + demographics['gender']['F'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Répartition par Genre',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: demographics['gender']['M'].toDouble(),
                    title: 'H',
                    color: Colors.blue,
                    radius: 50,
                  ),
                  PieChartSectionData(
                    value: demographics['gender']['F'].toDouble(),
                    title: 'F',
                    color: Colors.pink,
                    radius: 50,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Répartition par Âge',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...demographics['ageRanges'].entries.map((e) {
            double percent = total > 0 ? (e.value / total) : 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${e.key} ans : ${e.value} patients'),
                  LinearProgressIndicator(
                    value: percent,
                    backgroundColor: Colors.grey[200],
                    color: Colors.blue,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
