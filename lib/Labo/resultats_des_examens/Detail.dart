import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'resultat_des_examens_service.dart';

// Couleurs
const Color labPrimaryColor = Color(0xFF212031);
const Color labSuccessColor = Color(0xFF4CAF50);
const Color labBlueColor = Color(0xFF2196F3);
const Color labOrangeColor = Color(0xFFFF9800);

class ResultatDetailScreen extends StatefulWidget {
  final int idConsultation;
  final String nomPatient;
  final String sexe;
  final String age;
  final String telephone;

  const ResultatDetailScreen({
    super.key,
    required this.idConsultation,
    required this.nomPatient,
    required this.sexe,
    required this.age,
    required this.telephone,
  });

  @override
  State<ResultatDetailScreen> createState() => _ResultatDetailScreenState();
}

class _ResultatDetailScreenState extends State<ResultatDetailScreen> {
  final ResultatsService resultatsService = ResultatsService(
    Supabase.instance.client,
  );

  List<Map<String, dynamic>> examens = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    chargerExamens();
  }

  Future<void> chargerExamens() async {
    setState(() => isLoading = true);
    try {
      final data = await resultatsService.getExamensEnAttenteResultat(
        widget.idConsultation,
      );
      setState(() {
        examens = data;
        isLoading = false;
      });
      print('✅ ${examens.length} examen(s) chargé(s)');

      // Si la liste est vide, on vérifie si on doit fermer l'écran
      if (examens.isEmpty && mounted) {
        _verifierEtFermer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement des examens : $e')),
        );
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _verifierEtFermer() async {
    // On revérifie s'il reste des examens côté serveur pour être sûr
    final restants = await resultatsService.getExamensEnAttenteResultat(
      widget.idConsultation,
    );
    if (restants.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '🎉 Tous les résultats sont saisis ! Consultation finalisée.',
          ),
          backgroundColor: labSuccessColor,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.pop();
    }
  }

  void _ouvrirExamen(Map<String, dynamic> examen) {
    // Navigation vers une page de saisie de résultat (à créer)
    // Ou affichage d'un dialog pour saisir le résultat
    _afficherDialogResultat(examen);
  }

  Future<void> _afficherDialogResultat(Map<String, dynamic> examen) async {
    final idExamen = examen['id_examen'] as int;
    final nomExamen = examen['nom_examen']?.toString() ?? 'Examen';

    final TextEditingController controller = TextEditingController();

    final resultat = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit_note, color: labBlueColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Résultat: $nomExamen',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Saisir le résultat',
                hintText: 'Ex: Positif, Négatif, 12.5 g/dL...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.science, color: labBlueColor),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: labSuccessColor),
            child: const Text(
              'Enregistrer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (resultat != null && resultat.isNotEmpty) {
      try {
        setState(() => isLoading = true);
        await resultatsService.enregistrerResultatExamen(
          idExamen,
          resultat,
          widget.idConsultation,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Résultat de "$nomExamen" enregistré'),
              backgroundColor: labSuccessColor,
            ),
          );
        }

        // On recharge la liste, ce qui va masquer l'examen traité
        // Et déclencher _verifierEtFermer si la liste devient vide
        await chargerExamens();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted && isLoading) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: labPrimaryColor,
      appBar: AppBar(
        backgroundColor: labPrimaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Saisie des résultats",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Bandeau Patient
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF33333D),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              widget.nomPatient.isNotEmpty
                                  ? widget.nomPatient[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            widget.nomPatient,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.sexe == 'Homme'
                                ? Colors.blue.shade600
                                : Colors.pink.shade600,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.sexe,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(
                      color: Colors.grey,
                      height: 1,
                      thickness: 0.5,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoItem(
                          icon: Icons.assignment_ind_outlined,
                          label: 'Consultation ID:',
                          value: widget.idConsultation.toString(),
                        ),
                        const SizedBox(width: 8),
                        _buildInfoItem(
                          icon: Icons.calendar_today_outlined,
                          label: 'Âge:',
                          value: '${widget.age} ans',
                        ),
                        const SizedBox(width: 8),
                        _buildInfoItem(
                          icon: Icons.phone_outlined,
                          label: 'Tél:',
                          value: widget.telephone,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Message d'instruction
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: labBlueColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: labBlueColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: labBlueColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Cliquez sur un examen pour saisir son résultat',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Liste des examens (cliquables)
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : examens.isEmpty
                  ? Center(
                      child: Text(
                        "Aucun examen disponible",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: examens.length,
                      itemBuilder: (context, index) {
                        final examen = examens[index];
                        final nomExamen =
                            examen['nom_examen']?.toString() ?? 'Examen';
                        final statutExamen =
                            examen['statut_examen']?.toString() ?? 'En cours';
                        final isTermine = statutExamen == 'Terminé';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Material(
                            color: isTermine
                                ? labSuccessColor.withOpacity(0.1)
                                : const Color(0xFF33333D),
                            borderRadius: BorderRadius.circular(12),
                            elevation: isTermine ? 0 : 2,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: isTermine
                                  ? null
                                  : () => _ouvrirExamen(examen),
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isTermine
                                        ? labSuccessColor.withOpacity(0.3)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isTermine
                                            ? labSuccessColor
                                            : labBlueColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isTermine ? Icons.check : Icons.science,
                                        color: isTermine
                                            ? Colors.white
                                            : labBlueColor,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nomExamen,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: isTermine
                                                  ? labSuccessColor
                                                  : Colors.white,
                                              fontWeight: FontWeight.w600,
                                              decoration: isTermine
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isTermine
                                                ? 'Résultat saisi ✓'
                                                : 'En attente de résultat',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isTermine
                                                  ? labSuccessColor.withOpacity(
                                                      0.8,
                                                    )
                                                  : Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isTermine)
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
