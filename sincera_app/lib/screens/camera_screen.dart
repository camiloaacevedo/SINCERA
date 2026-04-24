import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // <--- IMPORTANTE
import 'dart:io';
import '../theme.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    setState(() {
      _initializeControllerFuture = _controller!.initialize();
    });
  }

  Future<void> _uploadImage(File imageFile) async {
    String miIpDeArch = "192.168.1.24";

    try {
      // 1. LEER EL NOMBRE DE USUARIO GUARDADO EN EL XIAOMI
      final prefs = await SharedPreferences.getInstance();
      final String? miNombre = prefs.getString('username');

      print("Subiendo foto de: ${miNombre ?? 'Anónimo'}");

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://$miIpDeArch:8000/upload'),
      );

      // 2. ENVIAR EL NOMBRE REAL AL SERVIDOR
      // El servidor de Python ahora espera este campo 'user_id'
      request.fields['user_id'] = miNombre ?? "anonimo";

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print("¡ÉXITO! Foto en Supabase bajo el usuario: $miNombre");
      } else {
        print("Error del servidor: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("ERROR DE RED CRÍTICO: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller!)),
                // Botón de Volver
                Positioned(
                  top: 40,
                  left: 20,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 50),
                    child: FloatingActionButton(
                      backgroundColor: SinceraTheme.accentNeon,
                      onPressed: () async {
                        try {
                          await _initializeControllerFuture;
                          final image = await _controller!.takePicture();
                          
                          // Mostramos un pequeño aviso de que se está subiendo
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Subiendo a Sincera..."), duration: Duration(seconds: 1)),
                            );
                          }

                          await _uploadImage(File(image.path));
                          
                          if (mounted) Navigator.pop(context);
                        } catch (e) {
                          print("Error al capturar: $e");
                        }
                      },
                      child: const Icon(
                        Icons.camera,
                        color: Colors.black,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator(color: SinceraTheme.accentNeon));
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}