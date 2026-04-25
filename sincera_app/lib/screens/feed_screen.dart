import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/post_item.dart';
import '../theme.dart';
import 'post_view_screen.dart';
import 'user_profile_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? currentUsername;
  List posts = [];
  List followingPosts = [];
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  bool isFollowingLoading = false;

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

  Future<void> _fetchPosts() async {
    final data = await ApiService.fetchGlobalPosts(currentUsername);
    setState(() {
      posts = data;
      isLoading = false;
    });
  }

  Future<void> _fetchFollowingPosts() async {
    if (currentUsername == null) return;
    setState(() => isFollowingLoading = true);
    final data = await ApiService.fetchFollowingFeed(currentUsername!);
    setState(() {
      followingPosts = data;
      isFollowingLoading = false;
    });
  }

  Future<void> _fetchProfileData() async {
    if (currentUsername == null) return;

    final data = await ApiService.fetchProfile(currentUsername!);

    if (mounted && data != null) {
      setState(() {
        profileData = data;
      });
    }
  }

  // --- VISTA DE PERFIL ---
  Widget _buildProfileTab() {
    if (profileData == null) {
      return const Center(
        child: CircularProgressIndicator(color: SinceraTheme.accentNeon),
      );
    }
    final photos = profileData!['photos'] as List;

    return ListView(
      children: [
        const SizedBox(height: 30),
        Center(
          child: CircleAvatar(
            radius: 45,
            backgroundColor: SinceraTheme.accentNeon,
            child: const Icon(Icons.person, size: 50, color: Colors.black),
          ),
        ),
        const SizedBox(height: 15),
        Center(
          child: Text(
            "@${currentUsername?.toUpperCase()}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStat(
              "Posts",
              profileData!['posts_count'].toString(),
              [],
            ), // Lista vacía para posts por ahora
            _buildStat(
              "Seguidores",
              profileData!['followers_count'].toString(),
              profileData!['followers_list'] ?? [],
            ),
            _buildStat(
              "Siguiendo",
              profileData!['following_count'].toString(),
              profileData!['following_list'] ?? [],
            ),
          ],
        ),
        const Divider(
          color: Colors.white10,
          height: 40,
          indent: 20,
          endIndent: 20,
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () {
              // AQUÍ ES DONDE VA EL CARRUSEL
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostViewScreen(
                    posts: photos, // Usamos la lista de fotos del perfil
                    initialIndex: index, // Empezamos en la que el usuario tocó
                  ),
                ),
              );
            },
            child: Image.network(photos[index]['image_url'], fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value, List lista) {
    return GestureDetector(
      onTap: () {
        // Solo abrimos la lista si hay elementos (Seguidores o Siguiendo)
        if (lista.isNotEmpty) {
          _mostrarListaUsuarios(label, lista);
        }
      },
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  void _mostrarListaUsuarios(String titulo, List lista) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            Text(
              titulo.toUpperCase(),
              style: const TextStyle(
                color: SinceraTheme.accentNeon,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Divider(color: Colors.white10, height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: lista.length,
                itemBuilder: (context, i) => ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UserProfileScreen(username: lista[i]['username']),
                      ),
                    );
                  },
                  leading: const CircleAvatar(
                    backgroundColor: SinceraTheme.accentNeon,
                    child: Icon(Icons.person, color: Colors.black),
                  ),
                  title: Text(
                    lista[i]['username'] ?? "Usuario",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
        // LOGO SINCERA
        title: Text("SINCERA", style: SinceraTheme.headingStyle),
        // BOTÓN DE SALIDA (PUERTA GRIS) A LA IZQUIERDA
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.white24, size: 22),
          onPressed: _logout,
        ),
        // BOTÓN DE CÁMARA A LA DERECHA
        actions: [
          IconButton(
            icon: const Icon(
              Icons.camera_alt_outlined,
              color: SinceraTheme.accentNeon,
              size: 28,
            ),
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
          tabs: const [
            Tab(text: "GLOBAL"),
            Tab(text: "SIGUIENDO"),
            Tab(text: "PERFIL"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: _fetchPosts,
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: SinceraTheme.accentNeon,
                    ),
                  )
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
                ? const Center(
                    child: CircularProgressIndicator(
                      color: SinceraTheme.accentNeon,
                    ),
                  )
                : followingPosts.isEmpty
                ? const Center(
                    child: Text(
                      "No sigues a nadie aún",
                      style: TextStyle(color: Colors.white24),
                    ),
                  )
                : ListView.builder(
                    itemCount: followingPosts.length,
                    itemBuilder: (context, i) => PostItem(
                      post: followingPosts[i],
                      onLikeUpdate: (nuevoTotal) {
                        setState(
                          () => followingPosts[i]['likes_count'] = nuevoTotal,
                        );
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
    if (currentUsername == null) return;
    await ApiService.toggleLike(postId, currentUsername!);
  }
}
