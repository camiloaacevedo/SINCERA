import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Centralizamos la IP.
  static const String baseUrl = "http://192.168.1.24:8000";

  // --- OBTENER POSTS GLOBALES ---
  static Future<List> fetchGlobalPosts(String? username) async {
    try {
      final url = '$baseUrl/posts?current_user=$username';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint("Error en fetchGlobalPosts: $e");
      return [];
    }
  }

  // --- OBTENER FEED DE SEGUIDOS ---
  static Future<List> fetchFollowingFeed(String username) async {
    try {
      final url = '$baseUrl/feed/following/$username';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint("Error en fetchFollowingFeed: $e");
      return [];
    }
  }

  // --- OBTENER DATOS DE PERFIL ---
  static Future<Map<String, dynamic>?> fetchProfile(
    String username,
    String? myUsername,
  ) async {
    try {
      final url = Uri.parse(
        '$baseUrl/profile/$username?current_user=$myUsername',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("Error en fetchProfile: $e");
      return null;
    }
  }

  // --- SET PROFILE PICTURE ---
  static Future<String?> updateAvatar(String filePath, String username) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload_avatar'),
      );

      request.fields['username'] = username;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['avatar_url']; // Devolvemos la nueva URL para actualizar la UI
      }
      return null;
    } catch (e) {
      debugPrint("Error subiendo avatar: $e");
      return null;
    }
  }

  // --- DAR/QUITAR LIKE ---
  static Future<void> toggleLike(dynamic postId, String username) async {
    try {
      final url = '$baseUrl/like?post_id=$postId&username=$username';
      await http.post(Uri.parse(url));
    } catch (e) {
      debugPrint("Error en toggleLike: $e");
    }
  }

  // --- SUBIR IMAGEN (CÁMARA) ---
  static Future<bool> uploadImage(String filePath, String username) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));

      // Enviamos el nombre del usuario
      request.fields['user_id'] = username;

      // Adjuntamos el archivo
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        debugPrint("Éxito: Foto subida correctamente");
        return true;
      } else {
        debugPrint("Error del servidor: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("Error de red al subir imagen: $e");
      return false;
    }
  }

  // --- REGISTRAR USUARIO ---
  static Future<bool> registerUser(String username) async {
    try {
      final url = '$baseUrl/register?username=$username';
      final response = await http.post(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error en registerUser: $e");
      return false;
    }
  }

  // --- SEGUIR USUARIO ---
  static Future<void> followUser(String follower, String following) async {
    try {
      final url = '$baseUrl/follow?follower=$follower&following=$following';
      await http.post(Uri.parse(url));
    } catch (e) {
      debugPrint("Error en followUser: $e");
    }
  }
}
