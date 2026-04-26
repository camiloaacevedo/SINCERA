import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/api_service.dart';
import '../../../theme.dart';
import 'tabs/global_tab.dart';
import 'tabs/following_tab.dart';
import 'tabs/profile_tab.dart';

final supabase = Supabase.instance.client;

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  String? currentUsername;

  // Datos de las listas
  List posts = [];
  List followingPosts = [];
  Map<String, dynamic>? profileData;

  // Estados de carga
  bool isLoading = true;
  bool isFollowingLoading = false;

  @override
  bool get wantKeepAlive => true;

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
    final user = prefs.getString('username');
    setState(() => currentUsername = user);
    await _fetchProfileData();
    await _fetchPosts();
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
          p['is_following'] = setFollowed.contains(author);
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
            final p = Map<String, dynamic>.from(post);
            p['is_following'] = true;
            return p;
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

          // Sincronizar estados de seguimiento en las listas locales
          final List followingList = profileData!['following_list'] ?? [];
          final setFollowed = followingList
              .map((u) => u['username']?.toString().trim().toLowerCase())
              .toSet();

          for (var p in posts) {
            String? author = p['username']?.toString().trim().toLowerCase();
            p['is_following'] = setFollowed.contains(author);
          }
        });
      }
    } catch (e) {
      debugPrint("Error perfil: $e");
    }
  }

  // Manejador central de actualizaciones (Likes y Seguimiento)
  void _handlePostUpdate(int index, int newLikes, String type) async {
    setState(() {
      if (type == "global") {
        posts[index]['likes'] = newLikes;
        posts[index]['liked'] = !(posts[index]['liked'] ?? false);
      } else {
        followingPosts[index]['likes'] = newLikes;
        followingPosts[index]['liked'] =
            !(followingPosts[index]['liked'] ?? false);
      }
    });

    // Llamamos a refrescar perfil para actualizar la lista de "siguiendo"
    // Esto disparará la actualización de los botones automáticamente
    await _fetchProfileData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
          GlobalTab(
            posts: posts,
            isLoading: isLoading,
            onRefresh: _fetchPosts,
            currentUsername: currentUsername,
            onPostUpdate: (i, n) => _handlePostUpdate(i, n, "global"),
          ),
          FollowingTab(
            posts: followingPosts,
            isLoading: isFollowingLoading,
            onRefresh: _fetchFollowingPosts,
            currentUsername: currentUsername,
            onPostUpdate: (i, n) => _handlePostUpdate(i, n, "following"),
          ),
          ProfileTab(
            profileData: profileData,
            currentUsername: currentUsername,
            onRefresh: _fetchProfileData,
          ),
        ],
      ),
    );
  }

  // Métodos de navegación simples
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
      _tabController.animateTo(0);
      _fetchPosts();
    }
  }
}
