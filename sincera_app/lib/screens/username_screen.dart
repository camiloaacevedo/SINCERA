import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final TextEditingController _controller = TextEditingController();
  final String miIp = "192.168.1.24"; 

  Future<void> _saveUsername() async {
    if (_controller.text.isEmpty) return;

    try {
      // 1. Registramos en el backend de Python
      final response = await http.post(
        Uri.parse('http://$miIp:8000/register?username=${_controller.text}'),
      );

      if (response.statusCode == 200) {
        // 2. Guardamos en la memoria del teléfono para no preguntarlo más
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', _controller.text);

        if (mounted) {
          // 3. Vamos al muro de fotos
          Navigator.pushReplacementNamed(context, '/');
        }
      }
    } catch (e) {
      debugPrint("Error al registrar: $e");
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
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: SinceraTheme.accentNeon),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: SinceraTheme.accentNeon, width: 2),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _saveUsername,
                child: const Text(
                  "CONTINUAR",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}