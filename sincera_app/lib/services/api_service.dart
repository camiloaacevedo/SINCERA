import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static const String baseUrl = "http://192.168.1.24:8000";

  static Future<List> fetchGlobalPosts(String? username) async {
    try {
      final url = '$baseUrl/posts?current_user=$username';
      final response = await http.get(Uri.parse(url));
      return response.statusCode == 200 ? json.decode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  static Future<List> fetchFollowingFeed(String username) async {
    try {
      final url = '$baseUrl/feed/following/$username';
      final response = await http.get(Uri.parse(url));
      return response.statusCode == 200 ? json.decode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> fetchProfile(
    String username,
    String? myUsername,
  ) async {
    try {
      final url = '$baseUrl/profile/$username?current_user=$myUsername';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        data['followers_list'] = await fetchFollowers(username);
        data['following_list'] = await fetchFollowing(username);
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List> fetchFollowers(String username) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/followers/$username'));
      return res.statusCode == 200 ? json.decode(res.body) : [];
    } catch (e) {
      return [];
    }
  }

  static Future<List> fetchFollowing(String username) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/following/$username'));
      return res.statusCode == 200 ? json.decode(res.body) : [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> uploadImage(String filePath) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      request.fields['user_id'] = user.id;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      var res = await request.send();
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<void> toggleLike(dynamic postId, String username) async {
    try {
      await http.post(
        Uri.parse(
          '$baseUrl/like?post_id=${postId.toString()}&username=$username',
        ),
      );
    } catch (e) {
      debugPrint("Error like: $e");
    }
  }

  static Future<bool> registerUser(String username) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final url = '$baseUrl/register?username=$username&user_id=${user?.id}';
      final response = await http.post(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<void> followUser(String follower, String following) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/follow?follower=$follower&following=$following'),
      );
    } catch (e) {
      debugPrint("Error follow: $e");
    }
  }

  static Future<void> unfollowUser(String follower, String followed) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/unfollow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'follower': follower, 'followed': followed}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al dejar de seguir');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<String?> updateAvatar(String filePath, String username) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload_avatar'),
      );
      request.fields['username'] = username;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      var res = await http.Response.fromStream(await request.send());
      return res.statusCode == 200 ? json.decode(res.body)['avatar_url'] : null;
    } catch (e) {
      return null;
    }
  }
}
