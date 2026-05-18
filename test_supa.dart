import 'package:supabase/supabase.dart';

Future<void> main() async {
  final supabase = SupabaseClient(
    'https://mzgyccyaywncafocmdnd.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im16Z3ljY3lheXduY2Fmb2NtZG5kIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU4NDQyNDIsImV4cCI6MjA5MTQyMDI0Mn0.qPO38QBVOZL-5lJx-nItTZVNRJcXpbm2Hk_WOylkjPI',
  );
  try {
    // Try a simple select to see what happens
    final res = await supabase.from('Personnel_hopital').select('Specialite').limit(1);
    print('Query success: $res');
  } catch (e) {
    print('Error: $e');
  }
}
