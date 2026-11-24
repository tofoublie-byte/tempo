/// Les deux espaces de Tempo : vie privée et travail.
enum Espace {
  perso('perso', 'Perso'),
  pro('pro', 'Pro');

  const Espace(this.key, this.label);

  /// Valeur enregistrée dans la base et les préférences.
  final String key;

  /// Texte affiché (sélecteur, notifications).
  final String label;

  /// Tout ce qui n'est pas « pro » (y compris les anciennes données) est « perso ».
  static Espace fromKey(Object? key) => key == 'pro' ? Espace.pro : Espace.perso;
}
