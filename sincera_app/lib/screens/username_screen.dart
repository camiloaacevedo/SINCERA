import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _saveUsername() async {
    final String nombre = _controller.text.trim();
    if (nombre.isEmpty) return;

    final bool exito = await ApiService.registerUser(nombre);

    if (exito) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', nombre);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error de conexión con el servidor")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("SINCERA", style: SinceraTheme.headingStyle),
            const SizedBox(height: 20),
            const Text(
              "Para empezar, elige cómo quieres que te vean los demás.",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 22),
              decoration: InputDecoration(
                hintText: "tu_usuario",
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: SinceraTheme.accentNeon),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: SinceraTheme.accentNeon,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SinceraTheme.accentNeon,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _saveUsername,
                child: const Text(
                  "CONTINUAR",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
