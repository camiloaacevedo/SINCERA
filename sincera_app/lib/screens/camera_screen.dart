import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/api_service.dart';
import '../theme.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      _controller = CameraController(cameras![0], ResolutionPreset.high);
      await _controller!.initialize();
      if (mounted) setState(() {});
    }
  }

  Future<void> _takeAndUpload() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isUploading) {
      return;
    }

    setState(() => _isUploading = true);

    try {
      final XFile image = await _controller!.takePicture();
      if (!mounted) return;

      // Mostrar snackbar de progreso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Subiendo publicación..."),
          duration: Duration(seconds: 2),
        ),
      );

      final success = await ApiService.uploadImage(image.path);
      if (!mounted) return;

      if (success) {
        // VITAL: Pasamos true para que el FeedScreen sepa que debe recargar
        Navigator.pop(context, true);
      } else {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al subir la imagen")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      debugPrint("Error cámara: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: SinceraTheme.accentNeon),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Previsualización de cámara
          Center(child: CameraPreview(_controller!)),

          // Botón de cerrar
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Botón de captura (Círculo Neon)
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _isUploading ? null : _takeAndUpload,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: SinceraTheme.accentNeon,
                      width: 5,
                    ),
                  ),
                  child: Center(
                    child: _isUploading
                        ? const CircularProgressIndicator(
                            color: SinceraTheme.accentNeon,
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: SinceraTheme.accentNeon,
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
