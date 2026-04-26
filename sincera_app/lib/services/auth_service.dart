import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;

  // REGISTRO
  static Future<String?> signUp(
    String email,
    String password,
    String username,
  ) async {
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final String? userId = res.user?.id;

      if (userId != null) {
        // 1. Lo guardamos en SQL vinculando el UUID con el nombre
        await _supabase.from('profiles').upsert({
          'id': userId,
          'username': username.toLowerCase(),
        });

        // 2. Registramos el nodo en Neo4j usando el nombre para las relaciones sociales
        await ApiService.registerUser(username.toLowerCase());

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username.toLowerCase());
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // LOGIN
  static Future<String?> signIn(String email, String password) async {
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        // Buscamos el username asociado a este ID
        final data = await _supabase
            .from('profiles')
            .select('username')
            .eq('id', res.user!.id)
            .single();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', data['username']);
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // CERRAR SESIÓN
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
