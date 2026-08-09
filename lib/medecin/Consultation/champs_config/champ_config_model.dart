class ChampConfig {
  final String? id;
  final String idPersonnel;
  final String cle;
  final String label;
  final String type; // 'numerique' ou 'alphanumerique'
  final bool obligatoire;
  final int hauteurLignes;
  final int ordre;
  final bool visible;
  final bool isDefault;
  final String? categorie; // 'personnel' ou 'medical' (utilisé à l'accueil)

  ChampConfig({
    this.id,
    required this.idPersonnel,
    required this.cle,
    required this.label,
    required this.type,
    required this.obligatoire,
    required this.hauteurLignes,
    required this.ordre,
    required this.visible,
    required this.isDefault,
    this.categorie,
  });

  factory ChampConfig.fromMap(Map<String, dynamic> map) {
    return ChampConfig(
      id: map['id']?.toString(),
      idPersonnel: map['id_personnel']?.toString() ?? '',
      cle: map['cle']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
      type: map['type']?.toString() ?? 'alphanumerique',
      obligatoire: map['obligatoire'] == true,
      hauteurLignes: (map['hauteur_lignes'] as num?)?.toInt() ?? 3,
      ordre: (map['ordre'] as num?)?.toInt() ?? 0,
      visible: map['visible'] == true,
      isDefault: map['is_default'] == true,
      categorie: map['categorie']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'id_personnel': idPersonnel,
      'cle': cle,
      'label': label,
      'type': type,
      'obligatoire': obligatoire,
      'hauteur_lignes': hauteurLignes,
      'ordre': ordre,
      'visible': visible,
      'is_default': isDefault,
      if (categorie != null) 'categorie': categorie,
    };
  }

  ChampConfig copyWith({
    String? id,
    String? idPersonnel,
    String? cle,
    String? label,
    String? type,
    bool? obligatoire,
    int? hauteurLignes,
    int? ordre,
    bool? visible,
    bool? isDefault,
    String? categorie,
  }) {
    return ChampConfig(
      id: id ?? this.id,
      idPersonnel: idPersonnel ?? this.idPersonnel,
      cle: cle ?? this.cle,
      label: label ?? this.label,
      type: type ?? this.type,
      obligatoire: obligatoire ?? this.obligatoire,
      hauteurLignes: hauteurLignes ?? this.hauteurLignes,
      ordre: ordre ?? this.ordre,
      visible: visible ?? this.visible,
      isDefault: isDefault ?? this.isDefault,
      categorie: categorie ?? this.categorie,
    );
  }
}
