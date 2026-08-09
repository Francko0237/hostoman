import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hostoman/app_config.dart';

//Import de toutes les pages classer par ordre

import 'authentification/authen_personnel.dart';
import 'authentification/authen_patient.dart';
import 'authentification/premiere_connexion.dart';
import 'authentification/mot_de_passe_oublie.dart';

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
import 'package:hostoman/medecin/Consultation/historique_consultation/historique_patient_page.dart';
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
import 'package:hostoman/Labo/historique/labo_dates_patient_page.dart';
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
import 'package:hostoman/Pharmacie/shared/pharmacie_theme.dart';

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
      path: '/PremiereConnexion',
      builder: (context, state) => const PremiereConnexionPage(),
    ),
    GoRoute(
      path: '/MotDePasseOublie',
      builder: (context, state) => const MotDePasseOubliePage(),
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
          path: 'HistoriquePatient/:idPatient',
          builder: (context, state) {
            final idPatient = state.pathParameters['idPatient']!;
            final extra = state.extra as Map<String, dynamic>?;
            return HistoriquePatientPage(
              idPatient: idPatient,
              patientName: extra?['nom']?.toString() ?? 'Patient',
            );
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
          path: 'HistoriquePatient/:idPatient',
          builder: (context, state) {
            final idPatient = state.pathParameters['idPatient']!;
            final extra = state.extra as Map<String, dynamic>?;
            return LaboPatientDatesPage(
              idPatient: idPatient,
              nomPatient: extra?['nom']?.toString() ?? 'Patient',
              sexe: extra?['sexe']?.toString(),
              age: extra?['age'] as int?,
            );
          },
        ),
        GoRoute(
          path: 'HistoriqueDetail/:idConsultation',
          builder: (context, state) {
            final idConsultation = int.parse(
              state.pathParameters['idConsultation']!,
            );
            final extra = state.extra as Map<String, dynamic>?;
            return DetailHistoriqueLaboUI(
              idConsultation: idConsultation,
              nomPatient: extra?['nom']?.toString(),
            );
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
    // Pharmacie ShellRoute to keep the sidebar static on PC
    ShellRoute(
      builder: (context, state, child) {
        final isDesktop = MediaQuery.of(context).size.width >= 700;
        if (isDesktop) {
          final location = state.matchedLocation;
          String activeRoute = '/Dashboard_Pharmacie';
          String breadcrumbKey = 'phar_breadcrumb_dashboard';

          if (location.startsWith('/Dashboard_Pharmacie/Ordonnances')) {
            activeRoute = '/Dashboard_Pharmacie/Ordonnances';
            breadcrumbKey = location.split('/').length > 3
                ? 'phar_breadcrumb_ordo_detail'
                : 'phar_breadcrumb_ordonnances';
          } else if (location.startsWith('/Dashboard_Pharmacie/VenteLibre')) {
            activeRoute = '/Dashboard_Pharmacie/VenteLibre';
            if (location.endsWith('/NouvelleVente')) {
              breadcrumbKey = 'phar_nv_title';
            } else if (location.split('/').length > 3) {
              breadcrumbKey = 'phar_breadcrumb_ordo_detail';
            } else {
              breadcrumbKey = 'phar_breadcrumb_vente_libre';
            }
          } else if (location.startsWith('/Dashboard_Pharmacie/Catalogue')) {
            activeRoute = '/Dashboard_Pharmacie/Catalogue';
            breadcrumbKey = 'phar_breadcrumb_catalogue';
          } else if (location.startsWith('/Dashboard_Pharmacie/Historique')) {
            activeRoute = '/Dashboard_Pharmacie/Historique';
            breadcrumbKey = 'phar_breadcrumb_historique';
          } else if (location.startsWith('/Dashboard_Pharmacie/Statistiques')) {
            activeRoute = '/Dashboard_Pharmacie/Statistiques';
            breadcrumbKey = 'phar_breadcrumb_stats';
          } else if (location.startsWith('/Dashboard_Pharmacie/Stock')) {
            activeRoute = '/Dashboard_Pharmacie/Stock';
            breadcrumbKey = 'phar_breadcrumb_stock';
          } else if (location.startsWith('/Dashboard_Pharmacie/Profil')) {
            activeRoute = '/Dashboard_Pharmacie/Profil';
            breadcrumbKey = 'phar_breadcrumb_profil';
          } else if (location.startsWith('/Dashboard_Pharmacie/Parametres')) {
            activeRoute = '/Dashboard_Pharmacie/Parametres';
            breadcrumbKey = 'phar_breadcrumb_parametres';
          }

          return PharmaciePcLayout(
            activeRoute: activeRoute,
            breadcrumbKey: breadcrumbKey,
            body: child,
          );
        }
        return child;
      },
      routes: [
        GoRoute(
          path: '/Dashboard_Pharmacie',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardPharmacie(),
          ),
        ),
        GoRoute(
          path: '/Dashboard_Pharmacie/Ordonnances',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: OrdonnancesList(),
          ),
        ),
        GoRoute(
          path: '/Dashboard_Pharmacie/Ordonnances/:idPrescription',
          pageBuilder: (context, state) {
            final id = int.parse(state.pathParameters['idPrescription']!);
            return NoTransitionPage(child: OrdonnanceDetail(idPrescription: id));
          },
        ),
        GoRoute(
          path: '/Dashboard_Pharmacie/VenteLibre',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: VenteLibrePage(),
          ),
        ),
        GoRoute(
          path: '/Dashboard_Pharmacie/VenteLibre/NouvelleVente',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: NouvelleVentePage(),
          ),
        ),
        GoRoute(
          path: '/Dashboard_Pharmacie/VenteLibre/:idPrescription',
          pageBuilder: (context, state) {
            final id = int.parse(state.pathParameters['idPrescription']!);
            return NoTransitionPage(child: VenteDetailPage(idPrescription: id));
          },
        ),
        GoRoute(
          path: '/Dashboard_Pharmacie/Catalogue',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: GestionMedicaments(),
          ),
        ),
        GoRoute(
          path: '/Dashboard_Pharmacie/Historique',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HistoriquePharmacie(),
          ),
        ),
        GoRoute(
          path: '/Dashboard_Pharmacie/Statistiques',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StatistiquePharmacie(),
          ),
        ),
        GoRoute(
          path: '/Dashboard_Pharmacie/Stock',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StockEntreePage(),
          ),
        ),
        GoRoute(
          path: '/Dashboard_Pharmacie/Profil',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfilPharmacien(),
          ),
        ),
        GoRoute(
          path: '/Dashboard_Pharmacie/Parametres',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ParametrePharmacie(),
          ),
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
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF64748B), // gris-bleu neutre, pas de violet
          surface: Colors.white,
        ),
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
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
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
