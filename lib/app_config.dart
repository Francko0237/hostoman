/// Configuration centrale de l'application Hostoman.
///
/// Toutes les variables d'environnement Supabase sont centralisées ici.
/// Pour migrer vers une autre instance (cloud, production, edge functions),
/// il suffit de modifier ce seul fichier.
///
/// ⚠️  Ne jamais committer ce fichier avec de vraies clés de production.
///     En production, utiliser des variables d'environnement injectées
///     au build (--dart-define) ou des edge functions côté serveur.
class AppConfig {
  AppConfig._(); // Classe non instanciable

  // ─── Supabase ────────────────────────────────────────────────────────────

  /// URL de l'instance Supabase.
  /// Local  : 'http://localhost:8000'
  /// Cloud  : 'https://<project-ref>.supabase.co'
  static const String supabaseUrl = 'http://localhost:8000';

  /// Clé publique anonyme (anon key) — lecture seule, safe côté client.
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0'
      '.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE';

  /// Clé service_role — droits admin, contourne les RLS.
  /// ⚠️  Ne JAMAIS exposer cette clé en production côté client.
  ///     À terme, la déplacer vers une Edge Function.
  static const String supabaseServiceRoleKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyAgCiAgICAicm9sZSI6ICJzZXJ2aWNlX3JvbGUiLAogICAgImlzcyI6ICJzdXBhYmFzZS1kZW1vIiwKICAgICJpYXQiOiAxNjQxNzY5MjAwLAogICAgImV4cCI6IDE3OTk1MzU2MDAKfQ'
      '.DaYlNEoUrrEn2Ig7tqibS-PHK5vgusbcbo7X36XVt4Q';

  // ─── Endpoints Admin API ─────────────────────────────────────────────────

  /// Endpoint pour créer un utilisateur Auth sans confirmation email.
  /// Futur : remplacer par une Edge Function '/functions/v1/create-user'
  static String get adminCreateUserUrl => '$supabaseUrl/auth/v1/admin/users';

  /// Endpoint pour supprimer un utilisateur Auth.
  /// Futur : remplacer par une Edge Function '/functions/v1/delete-user'
  static String adminDeleteUserUrl(String userId) =>
      '$supabaseUrl/auth/v1/admin/users/$userId';

  /// Endpoint pour mettre à jour un utilisateur Auth (ex: reset mot de passe).
  /// Futur : remplacer par une Edge Function '/functions/v1/update-user'
  static String adminUpdateUserUrl(String userId) =>
      '$supabaseUrl/auth/v1/admin/users/$userId';

  // ─── Headers Admin API ───────────────────────────────────────────────────

  /// Headers standards pour les appels Admin API.
  static Map<String, String> get adminHeaders => {
    'apikey': supabaseServiceRoleKey,
    'Authorization': 'Bearer $supabaseServiceRoleKey',
    'Content-Type': 'application/json',
  };

  // ─── Paramètres métier ───────────────────────────────────────────────────

  /// Timeout pour les appels HTTP vers l'Admin API.
  static const Duration adminApiTimeout = Duration(seconds: 10);

  /// Prix de la consultation (en FCFA).
  static const int prixConsultation = 600;
}
