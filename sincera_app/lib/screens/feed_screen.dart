import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/post_item.dart';
import '../theme.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? currentUsername;
  List posts = [];
  List followingPosts = [];
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  bool isFollowingLoading = false;
  final String miIp = "192.168.1.24";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 1) _fetchFollowingPosts();
        if (_tabController.index == 2) _fetchProfileData();
      }
    });
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => currentUsername = prefs.getString('username'));
    await _fetchPosts();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.pushReplacementNamed(context, '/username');
  }

  // --- MÉTODOS DE DATOS (Mismo funcionamiento) ---
  Future<void> _fetchPosts() async {
    try {
      final response = await http.get(Uri.parse('http://$miIp:8000/posts'));
      if (response.statusCode == 200) setState(() { posts = json.decode(response.body); isLoading = false; });
    } catch (e) { debugPrint("Error: $e"); }
  }

  Future<void> _fetchFollowingPosts() async {
    if (currentUsername == null) return;
    setState(() => isFollowingLoading = true);
    try {
      final response = await http.get(Uri.parse('http://$miIp:8000/feed/following/$currentUsername'));
      if (response.statusCode == 200) setState(() { followingPosts = json.decode(response.body); isFollowingLoading = false; });
    } catch (e) { setState(() => isFollowingLoading = false); }
  }

  Future<void> _fetchProfileData() async {
    if (currentUsername == null) return;
    try {
      final response = await http.get(Uri.parse('http://$miIp:8000/profile/$currentUsername'));
      if (response.statusCode == 200) setState(() => profileData = json.decode(response.body));
    } catch (e) { debugPrint("Error: $e"); }
  }

  void _verFotoGrande(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(child: Image.network(url)),
            Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context))),
          ],
        ),
      ),
    );
  }

  // --- VISTA DE PERFIL RESTAURADA ---
  Widget _buildProfileTab() {
    if (profileData == null) return const Center(child: CircularProgressIndicator(color: SinceraTheme.accentNeon));
    final photos = profileData!['photos'] as List;

    return ListView(
      children: [
        const SizedBox(height: 30),
        // EL AVATAR VERDE QUE PEDISTE
        Center(
          child: CircleAvatar(
            radius: 45,
            backgroundColor: SinceraTheme.accentNeon,
            child: const Icon(Icons.person, size: 50, color: Colors.black),
          ),
        ),
        const SizedBox(height: 15),
        Center(child: Text("@${currentUsername?.toUpperCase()}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStat("Posts", photos.length.toString()),
            _buildStat("Seguidores", profileData!['followers'].toString()),
            _buildStat("Siguiendo", profileData!['following'].toString()),
          ],
        ),
        const Divider(color: Colors.white10, height: 40, indent: 20, endIndent: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
          itemCount: photos.length,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => _verFotoGrande(photos[index]['image_url']),
            child: Image.network(photos[index]['image_url'], fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        // LOGO SINCERA (Sin modificaciones de escala para que no se vea aplastado)
        title: Text("SINCERA", style: SinceraTheme.headingStyle),
        // BOTÓN DE SALIDA (PUERTA GRIS) A LA IZQUIERDA
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.white24, size: 22),
          onPressed: _logout,
        ),
        // BOTÓN DE CÁMARA A LA DERECHA
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: SinceraTheme.accentNeon, size: 28),
            onPressed: () => Navigator.pushNamed(context, '/camera'),
          ),
          const SizedBox(width: 10),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: SinceraTheme.accentNeon,
          labelColor: SinceraTheme.accentNeon,
          unselectedLabelColor: Colors.white54,
          indicatorWeight: 3,
          tabs: const [Tab(text: "GLOBAL"), Tab(text: "SIGUIENDO"), Tab(text: "PERFIL")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: _fetchPosts,
            child: isLoading 
              ? const Center(child: CircularProgressIndicator(color: SinceraTheme.accentNeon))
              : ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, i) => PostItem(
                    post: posts[i],
                    onLikeUpdate: (nuevoTotal) {
                      setState(() => posts[i]['likes_count'] = nuevoTotal);
                      _handleLike(posts[i]['id']);
                    },
                  ),
                ),
          ),
          RefreshIndicator(
            onRefresh: _fetchFollowingPosts,
            child: isFollowingLoading
              ? const Center(child: CircularProgressIndicator(color: SinceraTheme.accentNeon))
              : followingPosts.isEmpty
                ? const Center(child: Text("No sigues a nadie aún", style: TextStyle(color: Colors.white24)))
                : ListView.builder(
                    itemCount: followingPosts.length,
                    itemBuilder: (context, i) => PostItem(
                      post: followingPosts[i],
                      onLikeUpdate: (nuevoTotal) {
                        setState(() => followingPosts[i]['likes_count'] = nuevoTotal);
                        _handleLike(followingPosts[i]['id']);
                      },
                    ),
                  ),
          ),
          _buildProfileTab(),
        ],
      ),
    );
  }

  Future<void> _handleLike(dynamic postId) async {
    try { await http.post(Uri.parse('http://$miIp:8000/like?post_id=$postId&username=$currentUsername')); } catch (e) {}
  }
}