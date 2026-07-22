import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:easy_localization/easy_localization.dart';

//Import de toutes les pages classer par ordre

import 'authentification/authen_personnel.dart';
import 'authentification/authen_patient.dart';

//Directeur
import 'Directeur/Dashboard/dashboard_directeur.dart';

//Accuiel
import 'accueil/dashboard/dashborA.dart';
import 'accueil/nouveau_patient/nouveau_patient.dart';
import 'accueil/liste_des_patients/liste.dart';
import 'accueil/liste_des_patients/detail.dart';
import 'accueil/Statistique/statistique.dart';
import 'accueil/dashboard/Profil.dart';
import 'accueil/dashboard/Parametre.dart';

// Caisse
import 'package:hostoman/Caisse/Dashboard/Dashboard.dart';
import 'package:hostoman/Caisse/Dashboard/Profil.dart';
import 'package:hostoman/Caisse/Dashboard/Parametre.dart';
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
import 'package:hostoman/medecin/dashboard/Parametre.dart';

//Laboratoire
import 'package:hostoman/Labo/Dashboard/Dashboard.dart';
import 'package:hostoman/Labo/Dashboard/Profil.dart';
import 'package:hostoman/Labo/Dashboard/Parametre.dart';
import 'package:hostoman/Labo/Examen_a_faire/examen_a_faire.dart';
import 'package:hostoman/Labo/Examen_a_faire/Detail.dart';
import 'package:hostoman/Labo/resultats_des_examens/resultat_des_examens.dart';
import 'package:hostoman/Labo/resultats_des_examens/Detail.dart';
import 'package:hostoman/Labo/historique/historique_ui.dart';
import 'package:hostoman/Labo/historique/detail/detail_historique_ui.dart';
import 'package:hostoman/Labo/statistique/statistique_ui.dart';

// Pharmacie
import 'package:hostoman/Pharmacie/Dashboard/Dashboard.dart';
import 'package:hostoman/Pharmacie/Dashboard/Profil.dart';
import 'package:hostoman/Pharmacie/Dashboard/Parametre.dart';
import 'package:hostoman/Pharmacie/Dashboard/gestion_medicaments.dart';
import 'package:hostoman/Pharmacie/Ordonnances/ordonnances_list.dart';
import 'package:hostoman/Pharmacie/Ordonnances/ordonnance_detail.dart';
import 'package:hostoman/Pharmacie/VenteLibre/vente_libre.dart';
import 'package:hostoman/Pharmacie/VenteLibre/vente_detail.dart';
import 'package:hostoman/Pharmacie/VenteLibre/nouvelle_vente.dart';
import 'package:hostoman/Pharmacie/Historique/historique.dart';
import 'package:hostoman/Pharmacie/Statistique/statistique.dart';
import 'package:hostoman/Pharmacie/Stock/stock_entree_list.dart';

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

    // Directeur
    GoRoute(
      path: '/Dashboard_Directeur',
      builder: (context, state) => const DirecteurDashboardPage(),
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

        GoRoute(
          path: 'parametre',
          builder: (context, state) => const ParametrePage(),
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
          path: 'parametrecaisse',
          builder: (context, state) => const ParametreCaissePage(),
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
        GoRoute(
          path: 'parametremedecin',
          builder: (context, state) => const ParametreMedecinPage(),
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
        GoRoute(
          path: 'parametrelaboratoire',
          builder: (context, state) => const ParametreLaboratoirePage(),
        ),
      ],
    ),

    // Pharmacie
    GoRoute(
      path: '/Dashboard_Pharmacie',
      builder: (context, state) => const DashboardPharmacie(),
      routes: [
        GoRoute(
          path: 'Ordonnances',
          builder: (context, state) => const OrdonnancesList(),
          routes: [
            GoRoute(
              path: ':idPrescription',
              builder: (context, state) {
                final id = int.parse(state.pathParameters['idPrescription']!);
                return OrdonnanceDetail(idPrescription: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: 'VenteLibre',
          builder: (context, state) => const VenteLibrePage(),
          routes: [
            GoRoute(
              path: 'NouvelleVente',
              builder: (context, state) => const NouvelleVentePage(),
            ),
            GoRoute(
              path: ':idPrescription',
              builder: (context, state) {
                final id = int.parse(state.pathParameters['idPrescription']!);
                return VenteDetailPage(idPrescription: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: 'Catalogue',
          builder: (context, state) => const GestionMedicaments(),
        ),
        GoRoute(
          path: 'Historique',
          builder: (context, state) => const HistoriquePharmacie(),
        ),
        GoRoute(
          path: 'Statistiques',
          builder: (context, state) => const StatistiquePharmacie(),
        ),
        GoRoute(
          path: 'Stock',
          builder: (context, state) => const StockEntreePage(),
        ),
        GoRoute(
          path: 'Profil',
          builder: (context, state) => const ProfilPharmacien(),
        ),
        GoRoute(
          path: 'Parametres',
          builder: (context, state) => const ParametrePharmacie(),
        ),
      ],
    ),
  ],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('en_US', null);
  await Supabase.initialize(
    url: 'http://localhost:8000',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE',
  );
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('fr', 'FR'),
      startLocale: const Locale('fr', 'FR'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Hopital de Manjo',
      themeMode: ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        // Force le texte saisi dans les TextField à du noir solide
        // (sinon Material 3 dérive une teinte rosée/violette de la seed).
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF1A237E),
          selectionColor: Color(0x331A237E),
          selectionHandleColor: Color(0xFF1A237E),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: const Color(0xFF0F172A),
          displayColor: const Color(0xFF0F172A),
        ),
      ),
      localizationsDelegates: [
        ...context.localizationDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerConfig: _router,
    );
  }
}
