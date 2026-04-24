import '../services/api_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    // 1. Obtenemos el nombre de usuario de SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String miNombre = prefs.getString('username') ?? "anonimo";

    // 2. Llamamos al servicio
    final bool exito = await ApiService.uploadImage(imageFile.path, miNombre);

    if (exito) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("¡Sincera publicada!")));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error al subir la foto")));
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
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
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

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Subiendo a Sincera..."),
                              duration: Duration(seconds: 1),
                            ),
                          );

                          // Llamamos a la función de subir
                          await _uploadImage(File(image.path));

                          if (!mounted) return;
                          Navigator.pop(
                            context,
                          ); // Cerramos la cámara y volvemos al feed
                        } catch (e) {
                          debugPrint("Error al capturar: $e");
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
          return const Center(
            child: CircularProgressIndicator(color: SinceraTheme.accentNeon),
          );
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
