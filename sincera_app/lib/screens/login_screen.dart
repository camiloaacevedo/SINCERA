import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    final error = await AuthService.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (error == null) {
        // Si no hay error, vamos al Feed
        Navigator.pushReplacementNamed(context, '/');
      } else {
        // Si hay error (ej: contraseña mal), lo mostramos
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $error"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "SINCERA",
                  style: SinceraTheme.headingStyle.copyWith(fontSize: 40),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Bienvenido de nuevo",
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 50),

                // Campo Email
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration(
                    "Email",
                    Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 20),

                // Campo Contraseña
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration(
                    "Contraseña",
                    Icons.lock_outline,
                  ),
                ),
                const SizedBox(height: 40),

                // Botón Entrar
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SinceraTheme.accentNeon,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            "ENTRAR",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Botón ir a Registro
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text(
                    "¿No tienes cuenta? Regístrate aquí",
                    style: TextStyle(color: SinceraTheme.accentNeon),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38),
      prefixIcon: Icon(icon, color: SinceraTheme.accentNeon),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: SinceraTheme.accentNeon),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: .05),
    );
  }
}
