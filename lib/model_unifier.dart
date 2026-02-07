
class Patient {
  final String ?  id_patient;
  final String nom_complet;
  final String sexe;
  final int age;
  final int telephone;
  final String adresse;
  final String profession;
  final String statut_matrimonial;
  final DateTime date_enregistrement;

  Patient({
    this.id_patient,
    required this.nom_complet,
    required this.sexe,
    required this.age,
    required this.telephone,
    required this.adresse,
    required this.profession,
    required this.statut_matrimonial,
    required this.date_enregistrement,
  });

  Map<String, dynamic> toMap() => {
    'nom_complet': nom_complet,
    'sexe': sexe,
    'age': age,
    'telephone': telephone,
    'adresse': adresse,
    'profession': profession,
    'statut_matrimonial': statut_matrimonial,

    'date_enregistrement': date_enregistrement.toIso8601String(),
  };

  factory Patient.fromMap(Map<String, dynamic> map) => Patient(
    id_patient: map['id_patient']?.toString() ?? 'idError',
    nom_complet: map['nom_complet'] ?? 'nameError',
    sexe: map['sexe']?? 'sexeError',
    age: map['age']?? 0,
    telephone: map['telephone']?? 'sexeError',
    adresse: map['adresse']??'adresseError',
    profession: map['profession']??'professionError',
    statut_matrimonial: map['statut_matrimonial']??'statutError',
      date_enregistrement: DateTime.parse(map['date_enregistrement']??'dateError'),

  );
}

//Parametres vitaux
class Parametres_vitaux {
  String id_patient;
  double poid;
  double temperature;
  double systolique;
  double diastolique;
  String statut_VIH;
  String vaccination;
  String motif_de_consultation;
  String id_personnel;
  DateTime date_enregistrement;
  String? type_service;

  Parametres_vitaux({
    required this.id_patient,
    required this.poid,
    required this.temperature,
    required this.systolique,
    required this.diastolique,
    required this.statut_VIH,
    required this.vaccination,
    required this.motif_de_consultation,
   required this.id_personnel,
    required this.date_enregistrement,
    required this.type_service,

  });

  Map<String, dynamic> toMap() {
    return {
      'id_patient': id_patient,
      'poid': poid,
      'temperature': temperature,
      'systolique': systolique,
      'diastolique': diastolique,
      'statut_VIH': statut_VIH,
      'vaccination': vaccination,
      'motif_de_consultation': motif_de_consultation,
      'id_personnel': id_personnel,
      'date_enregistrement': date_enregistrement.toIso8601String(),
      'type_service': type_service,
    };
  }

  factory Parametres_vitaux.fromMap(Map<String, dynamic> map) {
    return Parametres_vitaux(
      id_patient: (map['id_patient']),
      poid: (map['poid'] as num).toDouble(),
      temperature: (map['temperature'] as num).toDouble(),
      systolique: (map['systolique'] as num).toDouble(),
      diastolique: (map['diastolique'] as num).toDouble(),
      statut_VIH: map['statut_VIH'],
      vaccination: map['vaccination'],
      motif_de_consultation: map['motif_de_consultation'],
      id_personnel: map['id_personnel'],
      date_enregistrement: DateTime.parse(map['date_enregistrement']),
      type_service: map['type_service'],
    );
  }
}

//Medcins

class Medecin {
  String id_personnel;
  String nom;
  String? prenom;
  int? telephone;
  String? adresse;
  String? email;
  int? patient_enregistre;
  int? age;
  String? specialite;
String? sexe;
  Medecin({
    required this.nom,
    required this.prenom,
    required this.specialite,
    required this.id_personnel,
    required this.telephone,
    required this.adresse,
    required this.email,
    required this.patient_enregistre,
    required this.age,
    this.sexe
  });

  Map<String, dynamic> toMap() {
    return {
      'Nom': nom,
      'Prenom': prenom,
      'telephone': telephone,
      'adresse': adresse,
      'email': email,
      'patient_enregistre':patient_enregistre,
      'age':age,
      'Specialite': specialite,
    'id_personnel':id_personnel,
      'sexe':sexe
    };
  }

  factory Medecin.fromMap(Map<String, dynamic> map) {
    return Medecin(
      nom: (map['Nom'] ?? 'nomError'),
      prenom: (map['Prenom'] ?? 'prenomError'),
      specialite: (map['Specialite'] ?? 'specialiteError'),
        id_personnel:(map['id_personnel']),
      telephone: (map['telephone']),
      adresse: (map['adresse']),
      email: (map['email']),
      age: (map['age']),
      patient_enregistre: (map['patient_enregistre']),
      sexe: (map['sexe'])
    );
  }
}

//consultation

class Consultation {
  String Statut_Consultation;
  String date_enregistrement;
  String date_derniere_mise_ajour;
  String? type_service;
  String id_patient;
  int id_parametres_vitaux;
  bool? Disponibilite;
  String?antecedents;
  String? id_personnel;
  String? payer;

String?signes_symptomes;
String?diagnostic_initial;
String?diagnostic_final;
String?traitement_prescrit;
String?programmation_rdv;
String?date_rdv_prevu;


  Consultation({
    required this.Statut_Consultation,
    required this.date_enregistrement,
    required this.type_service,
    required this.id_patient,
    required this.id_parametres_vitaux,
    required this.id_personnel,
   this.payer,
    this.antecedents,
    this.Disponibilite,
    this.signes_symptomes,
    this.diagnostic_initial,
    this.diagnostic_final,
    this.traitement_prescrit,
    this.programmation_rdv,
    this.date_rdv_prevu,
required this.date_derniere_mise_ajour

  });

  Map<String, dynamic> toMap() {
    return {
      'Statut_Consultation': Statut_Consultation,
      'date_enregistrement': date_enregistrement,
      'type_service': type_service,
      'id_patient': id_patient,
      'id_parametres_vitaux': id_parametres_vitaux,
      'id_personnel':id_personnel,
      'payer':payer,
      'date_derniere_mise_ajour':date_derniere_mise_ajour,
      'antecedents':antecedents,
      'signes_symptomes':signes_symptomes,
      'diagnostic_initial':diagnostic_initial,
      'diagnostic_final':diagnostic_final,
      'traitement_prescrit':traitement_prescrit,
      'programmation_rdv':programmation_rdv,
      'date_rdv_prevu':date_rdv_prevu,
    };
  }

  factory Consultation.fromMap(Map<String, dynamic> map) {
    return Consultation(
      Statut_Consultation: (map['Statut_Consultation']),
      date_enregistrement: (map['date_enregistrement']),
      type_service: (map['type_service']),
      id_patient: (map['id_patient']),
      id_parametres_vitaux: (map['id_parametres_vitaux']),
      id_personnel: (map['id_personnel']),
      payer: (map['payer']),
        date_derniere_mise_ajour:(map['date_derniere_mise_ajour']),
        antecedents:(map['antecedents']),
        signes_symptomes:(map['signes_symptomes']),
        diagnostic_initial:(map['diagnostic_initial']),
        diagnostic_final:(map['diagnostic_final']),
        traitement_prescrit:(map['traitement_prescrit']),
        programmation_rdv:(map['programmation_rdv']),
        date_rdv_prevu:(map['date_rdv_prevu'])
    );
  }

}
//Paiement

class Paiement {
  final prix_a_paye;

  Paiement({
    this.prix_a_paye
  });

  Map<String, dynamic> toMap() {
    return {
      'prix_a_paye': prix_a_paye
    };
  }
  factory Paiement.fromMap(Map<String, dynamic>map){
    return Paiement(
      prix_a_paye: (map['prix_a_paye'])
    );
  }

}
