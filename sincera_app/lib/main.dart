import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/feed_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/camera_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Cargamos las variables de entorno
  await dotenv.load(fileName: ".env");

  // 2. Inicializamos Supabase usando esas variables
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final session = Supabase.instance.client.auth.currentSession;
  final prefs = await SharedPreferences.getInstance();
  final String? username = prefs.getString('username');

  // Si no hay sesión de Supabase o no tenemos el username local, vamos a Login
  String rutaInicial = (session == null || username == null) ? '/login' : '/';

  runApp(SinceraApp(initialRoute: rutaInicial));
}

class SinceraApp extends StatelessWidget {
  final String initialRoute;
  const SinceraApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: SinceraTheme.darkTheme,
      initialRoute: initialRoute,
      routes: {
        '/': (context) => const FeedScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/camera': (context) => const CameraScreen(),
      },
    );
  }
}
