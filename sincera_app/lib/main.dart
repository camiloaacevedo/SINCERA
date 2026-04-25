import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/feed_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/username_screen.dart';
import 'theme.dart';

void main() async {
  // Garantiza que los servicios de Flutter estén listos antes de usar SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  
  // Obtenemos la instancia de almacenamiento local
  final prefs = await SharedPreferences.getInstance();
  final String? username = prefs.getString('username');

  // LÓGICA DE RUTA INICIAL:
  // Si el 'username' es nulo o está vacío, mandamos al usuario a registrarse (/username).
  // Si ya existe un nombre, lo mandamos directo al Feed principal (/).
  String rutaInicial = (username == null || username.isEmpty) ? '/username' : '/';

  runApp(SinceraApp(initialRoute: rutaInicial));
}

class SinceraApp extends StatelessWidget {
  final String initialRoute;
  
  const SinceraApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sincera',
      debugShowCheckedModeBanner: false,
      
      // Aplicamos un tema oscuro personalizado
      theme: SinceraTheme.darkTheme,
      
      // Definimos la ruta de inicio basada en la comprobación del main
      initialRoute: initialRoute,
      
      // Mapa de rutas de la aplicación
      routes: {
        '/': (context) => const FeedScreen(),
        '/username': (context) => const UsernameScreen(),
        '/camera': (context) => const CameraScreen(),
      },
    );
  }
}