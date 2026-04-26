import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_profile_screen.dart';
import 'post_view_screen.dart';
import '../services/api_service.dart';
import '../widgets/post_item.dart';
import '../theme.dart';
import '../utils.dart';

final supabase = Supabase.instance.client;

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
      if (_tabController.indexIsChanging) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 1) _fetchFollowingPosts();
        if (_tabController.index == 2) _fetchProfileData();
      }
    });
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString('username');
    setState(() => currentUsername = user);
    await _fetchProfileData();
    await _fetchPosts();
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.white),
            title: const Text(
              "Elegir de la galería",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.white),
            title: const Text(
              "Tomar foto",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _fetchPosts() async {
    final data = await ApiService.fetchGlobalPosts(currentUsername);
    if (mounted) {
      final List followingList = profileData?['following_list'] ?? [];
      final setFollowed = followingList
          .map((u) => u['username']?.toString().trim().toLowerCase())
          .toSet();

      setState(() {
        posts = data.map((post) {
          final p = Map<String, dynamic>.from(post);
          String? author = p['username']?.toString().trim().toLowerCase();
          if (setFollowed.contains(author)) p['is_following'] = true;
          return p;
        }).toList();
        isLoading = false;
      });
    }
  }

  Future<void> _fetchFollowingPosts() async {
    if (currentUsername == null) return;
    setState(() => isFollowingLoading = true);
    try {
      final data = await ApiService.fetchFollowingFeed(currentUsername!);
      if (mounted) {
        setState(() {
          followingPosts = data.map((post) {
            final postModificable = Map<String, dynamic>.from(post);
            postModificable['is_following'] = true;
            return postModificable;
          }).toList();
          isFollowingLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isFollowingLoading = false);
    }
  }

  Future<void> _fetchProfileData() async {
    if (currentUsername == null) return;
    try {
      final data = await ApiService.fetchProfile(
        currentUsername!,
        currentUsername,
      );
      if (mounted && data != null) {
        setState(() {
          profileData = data;
          profileData!['followers_list'] ??= [];
          profileData!['following_list'] ??= [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildProfileTab() {
    if (profileData == null) {
      return const Center(
        child: CircularProgressIndicator(color: SinceraTheme.accentNeon),
      );
    }
    final List photos = profileData!['posts'] ?? [];
    return ListView(
      children: [
        const SizedBox(height: 30),
        Center(
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => SinceraUtils.verFotoGrande(
                  context,
                  profileData!['avatar_url'],
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: SinceraTheme.accentNeon,
                  backgroundImage: profileData!['avatar_url'] != null
                      ? NetworkImage(profileData!['avatar_url'])
                      : null,
                  child: profileData!['avatar_url'] == null
                      ? const Icon(Icons.person, size: 50, color: Colors.black)
                      : null,
                ),
              ),

              // TOCAR LÁPIZ: Abre opciones de edición
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _mostrarOpcionesFoto,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: SinceraTheme.accentNeon,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStat("Posts", photos.length.toString(), []),
            _buildStat(
              "Seguidores",
              (profileData!['followers'] ?? 0).toString(),
              profileData!['followers_list'] ?? [],
            ),
            _buildStat(
              "Siguiendo",
              (profileData!['following_list']?.length ?? 0).toString(),
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostViewScreen(
                  posts: photos,
                  initialIndex: index,
                  currentUsername: currentUsername,
                ),
              ),
            ),
            child: Image.network(photos[index]['image_url'], fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }

  Widget _buildPostList(
    List list,
    bool loading,
    Future<void> Function() onRefresh, {
    String? emptyMessage,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: loading
          ? const Center(
              child: CircularProgressIndicator(color: SinceraTheme.accentNeon),
            )
          : list.isEmpty
          ? ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Center(
                  child: Text(
                    emptyMessage ?? "NO HAY POSTS DISPONIBLES",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white24,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, i) => PostItem(
                post: list[i],
                currentUsername: currentUsername,
                onLikeUpdate: (n) {
                  setState(() {
                    list[i]['likes'] = n;
                    list[i]['liked'] = !(list[i]['liked'] ?? false);
                  });
                  ApiService.toggleLike(list[i]['id'], currentUsername!);
                },
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
        title: Text("SINCERA", style: SinceraTheme.headingStyle),
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.white24),
          onPressed: _logout,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.camera_alt_outlined,
              color: SinceraTheme.accentNeon,
              size: 28,
            ),
            onPressed: _goToCamera,
          ),
          const SizedBox(width: 10),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: SinceraTheme.accentNeon,
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
          _buildPostList(posts, isLoading, _fetchPosts),
          _buildPostList(
            followingPosts,
            isFollowingLoading,
            _fetchFollowingPosts,
            // MENSAJE ORIGINAL CORTO
            emptyMessage: "NO SIGUES A NADIE TODAVÍA.",
          ),
          _buildProfileTab(),
        ],
      ),
    );
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> _goToCamera() async {
    final bool? subido = await Navigator.pushNamed(context, '/camera') as bool?;
    if (subido == true) {
      setState(() => isLoading = true);
      _tabController.animateTo(0);
      await _fetchPosts();
    }
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
              ),
            ),
            const Divider(color: Colors.white10, height: 30),
            Expanded(
              child: lista.isEmpty
                  ? const Center(
                      child: Text(
                        "No hay usuarios todavía",
                        style: TextStyle(color: Colors.white24),
                      ),
                    )
                  : ListView.builder(
                      itemCount: lista.length,
                      itemBuilder: (context, i) => ListTile(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileScreen(
                                username: lista[i]['username'],
                              ),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundImage: lista[i]['avatar_url'] != null
                              ? NetworkImage(lista[i]['avatar_url'])
                              : null,
                          child: lista[i]['avatar_url'] == null
                              ? const Icon(Icons.person)
                              : null,
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

  Widget _buildStat(String label, String value, List lista) {
    return GestureDetector(
      onTap: () => _mostrarListaUsuarios(label, lista),
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
}
