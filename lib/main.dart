import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅ indispensable pour initializeDateFormatting

//Import de toutes les pages classer par ordre

import 'authentification/authen_personnel.dart';
import 'authentification/authen_patient.dart';

//Accuiel
import 'accueil/dashboard/dashborA.dart';
import 'accueil/nouveau_patient/nouveau_patient.dart';
import 'accueil/liste_des_patients/liste.dart';
import 'accueil/liste_des_patients/detail.dart';
import 'accueil/Statistique/statistique.dart';
import 'accueil/dashboard/Profil.dart';

// Caisse
import 'package:hostoman/Caisse/Dashboard/Dashboard.dart';
import 'package:hostoman/Caisse/Dashboard/Profil.dart';
import 'package:hostoman/Caisse/Paiement_en_attente/paiementList.dart';
import 'package:hostoman/Caisse/HistoriquePaiement/HistoriquePaiement.dart';
import 'package:hostoman/Caisse/Statistique/Statistique.dart';

//Médecin
import 'package:hostoman/medecin/dashboard/dashboard.dart';
import 'package:hostoman/medecin/Consultation/liste_patients_consultation/liste_patients_consultation.dart';
import 'package:hostoman/medecin/Consultation/fiche_de_consultation/fiche_consultation.dart';
import 'package:hostoman/medecin/Consultation/finalisation_consultation/finalisation.dart';
import 'package:hostoman/medecin/Consultation/historique_consultation/historique_liste.dart';
import 'package:hostoman/medecin/Consultation/historique_consultation/historique_detail.dart';
import 'package:hostoman/medecin/Consultation/statistiques/statistiques_ui.dart';
import 'package:hostoman/medecin/Consultation/liste_patient_attente_examen/liste_patient_attente.dart';
import 'package:hostoman/medecin/RendezVous/liste_rendez_vous.dart';
import 'package:hostoman/medecin/dashboard/profil_medecin.dart'
    as doctor_profile;

//Laboratoire
import 'package:hostoman/Labo/Dashboard/Dashboard.dart';
import 'package:hostoman/Labo/Dashboard/Profil.dart';
import 'package:hostoman/Labo/Examen_a_faire/examen_a_faire.dart';
import 'package:hostoman/Labo/Examen_a_faire/Detail.dart';
import 'package:hostoman/Labo/resultats_des_examens/resultat_des_examens.dart';
import 'package:hostoman/Labo/resultats_des_examens/Detail.dart';
import 'package:hostoman/Labo/historique/historique_ui.dart';
import 'package:hostoman/Labo/historique/detail/detail_historique_ui.dart';
import 'package:hostoman/Labo/statistique/statistique_ui.dart';

//Configuration de toutes les route du projets
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => Authen_Personnel()),
    GoRoute(
      path: '/Authen_Personnel',
      builder: (context, state) => Authen_Personnel(),
    ),
    GoRoute(
      path: '/Authen_Patient',
      builder: (context, state) => Authen_Patient(),
    ),

    // Accueil
    GoRoute(
      path: '/Dashboard_Accueil',
      builder: (context, state) => DashboardAccueil(),
      routes: [
        GoRoute(
          path:
              'nouveau-patient', // Le chemin complet sera go.context('/Dashboard_Accueil/nouveau_patient');
          builder: (context, state) => Nouveau_Patient(),
        ),
        GoRoute(
          path:
              'liste-patient', // Le chemin complet sera go.context('/Dashboard_Accueil/liste-patient');
          builder: (context, state) => ListePatients(),
        ),
        GoRoute(
          path:
              'statistique', // Le chemin complet sera go.context('/Dashboard_Accueil/statistique');
          builder: (context, state) => RapportPatientPage(),
        ),
        GoRoute(
          path: 'Detail_Patient/:id',
          name: 'detail_patient',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return DetailPatientPage(idPatient: id);
          },
        ),

        GoRoute(
          path:
              'profil', // Le chemin complet sera context.push('/Dashboard_Accueil/profil');
          builder: (context, state) => const ProfilMedecinPage(),
        ),

        // Ajoute d'autres sous-routes ici
      ],
    ),

    // Caisse
    GoRoute(
      path: '/Dashboard_Caisse',
      builder: (context, state) => const DashboardCaisse(),
      routes: [
        GoRoute(
          path:
              'profilcaisse', // Le chemin complet sera context.push('/Dashboard_Caisse/profilcaisse');
          builder: (context, state) => const ProfilCaissier(),
        ),
        GoRoute(
          path:
              'paiementlist', // Le chemin complet sera context.push('/Dashboard_Caisse/paiementlist');
          builder: (context, state) => const Paiementlist(),
        ),
        GoRoute(
          path:
              'HistoriquePaiement', // Le chemin complet sera context.push('/Dashboard_Caisse/HistoriquePaiement');
          builder: (context, state) => const PaiementHistorique(),
        ),
        GoRoute(
          path:
              'Statistiques', // Le chemin complet sera context.push('/Dashboard_Caisse/Statistiques');
          builder: (context, state) => const StatsPage(),
        ),
      ],
    ),

    //Médecin
    GoRoute(
      path: '/Dashboard_Medecin',
      builder: (context, state) => const DashboardMedecin(),
      routes: [
        GoRoute(
          path:
              'ConsultationList', // Le chemin complet sera context.push('/Dashboard_Medecin/ConsultationList')
          builder: (context, state) => const ConsultationList(),
        ),
        GoRoute(
          path:
              'FicheConsultation/:idConsultation', // Le chemin complet sera context.push('/Dashboard_Medecin/FicheConsultation')
          builder: (context, state) {
            // 🛑 CORRECTION ICI : Récupère la String de l'URL et la convertit en INT
            final String idConsultationstring =
                state.pathParameters['idConsultation']!;
            final int idConsultation = int.parse(idConsultationstring);
            return ConsultationPage(idConsultation: idConsultation);
          },
        ),
        GoRoute(
          path: 'FinalisationConsultation/:idConsultation',
          builder: (context, state) {
            final String idConsultationstring =
                state.pathParameters['idConsultation']!;
            final int idConsultation = int.parse(idConsultationstring);
            return FinalisationConsultationPage(idConsultation: idConsultation);
          },
        ),
        GoRoute(
          path: 'HistoriqueConsultations',
          builder: (context, state) => const HistoriqueConsultationPage(),
        ),
        GoRoute(
          path: 'HistoriqueDetail/:idConsultation',
          builder: (context, state) {
            final String idConsultationstring =
                state.pathParameters['idConsultation']!;
            final int idConsultation = int.parse(idConsultationstring);
            return HistoriqueDetailPage(idConsultation: idConsultation);
          },
        ),
        GoRoute(
          path: 'Statistiques',
          builder: (context, state) => const StatistiquesPage(),
        ),
        GoRoute(
          path:
              'EnattenteExam', // Le chemin complet sera context.push('/Dashboard_Medecin/EnattenteExam')
          builder: (context, state) => const EnattenteExam(),
        ),
        GoRoute(
          path: 'rendez-vous',
          builder: (context, state) => const ListeRendezVousPage(),
        ),
        GoRoute(
          path: 'Profil',
          builder: (context, state) => const doctor_profile.ProfilMedecinPage(),
        ),
      ],
    ),

    //Laboratoire

    // Laboratoire
    GoRoute(
      path: '/Dashboard_Laboratoire',
      builder: (context, state) => const DashboardLaboratoire(),
      routes: [
        GoRoute(
          path: 'ExamensAFaire',
          builder: (context, state) => const ExamensAFaire(),
        ),
        GoRoute(
          path: 'ExamenDetail/:id',
          builder: (context, state) {
            final idConsultationString = state.pathParameters['id']!;
            final int idConsultation = int.parse(idConsultationString);

            // Récupérer l'objet PatientDetailData directement
            // NOTE : PatientDetailData doit être accessible (dans model_unifier.dart ou main.dart)
            final dataObject = state.extra as PatientDetailData?;

            // Extraction des données avec valeurs par défaut de sécurité
            final nomPatient = dataObject?.nomComplet ?? 'Patient Inconnu';
            final sexe = dataObject?.sexe ?? 'N/A';
            final age = dataObject?.age ?? 'N/A';
            final telephone = dataObject?.telephone ?? 'N/A';

            return ExamenDetailScreen(
              idConsultation: idConsultation,
              nomPatient: nomPatient,
              sexe: sexe,
              age: age,
              telephone: telephone,
            );
          },
        ),

        GoRoute(
          path: 'Resultats',
          builder: (context, state) => const ResultatsListe(),
        ),
        GoRoute(
          path: 'ResultatDetail/:idConsultation',
          builder: (context, state) {
            final idConsultation = int.parse(
              state.pathParameters['idConsultation']!,
            );
            final data = state.extra as PatientResultatData;
            return ResultatDetailScreen(
              idConsultation: idConsultation,
              nomPatient: data.nomComplet,
              sexe: data.sexe,
              age: data.age,
              telephone: data.telephone,
            );
          },
        ),
        GoRoute(
          path: 'Historique',
          builder: (context, state) => const HistoriqueLaboUI(),
        ),
        GoRoute(
          path: 'HistoriqueDetail/:idConsultation',
          builder: (context, state) {
            final idConsultation = int.parse(
              state.pathParameters['idConsultation']!,
            );
            return DetailHistoriqueLaboUI(idConsultation: idConsultation);
          },
        ),
        GoRoute(
          path: 'Statistiques',
          builder: (context, state) => const StatistiqueLaboUI(),
        ),
        GoRoute(
          path: 'Profil',
          builder: (context, state) => const ProfilLaborantinPage(),
        ),
      ],
    ),
  ],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await Supabase.initialize(
    url:
        'http://10.54.115.183:8001', // ⬅️ API URL                   PC " localhost "        Android " 10.61.24.183 "      Emulateur:  " 10.0.2.2 "
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE', // ⬅️ Copiez depuis supabase status
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hopital de Manjo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      locale: const Locale('fr', 'FR'),
      routerConfig: _router, // ⬅️ ici tu mets ton GoRouter
    );
  }
}
