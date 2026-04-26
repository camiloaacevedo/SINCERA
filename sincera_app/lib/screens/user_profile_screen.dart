import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sincera_app/widgets/user_avatar.dart';
import 'post_view_screen.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;
  const UserProfileScreen({super.key, required this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  String? myUsername;

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => myUsername = prefs.getString('username'));
    await _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final data = await ApiService.fetchProfile(widget.username, myUsername);
    if (mounted) {
      debugPrint("DATOS RECIBIDOS: $data");
      setState(() {
        profileData = data;
        isLoading = false;
      });
    }
  }

  void _mostrarLista(String titulo, dynamic dataRaw) {
    List items = [];
    if (dataRaw is List) {
      items = dataRaw;
    } else if (dataRaw is Map) {
      items = dataRaw['users'] ?? dataRaw['data'] ?? [];
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: SinceraTheme.accentNeon,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Divider(color: Colors.white10),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          "No hay usuarios todavía",
                          style: TextStyle(
                            color: Colors.white24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final user = items[i]['username'] ?? "usuario";
                          return ListTile(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UserProfileScreen(username: user),
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              backgroundColor: SinceraTheme.accentNeon,
                              backgroundImage: items[i]['avatar_url'] != null
                                  ? NetworkImage(items[i]['avatar_url'])
                                  : null,
                              child: items[i]['avatar_url'] == null
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.black,
                                    )
                                  : null,
                            ),
                            title: Text(
                              user,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
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
        foregroundColor: Colors.white,
        title: Text(widget.username),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: SinceraTheme.accentNeon),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final List posts = profileData?['posts'] ?? [];
    final avatar = profileData?['avatar_url'];
    // Verificamos si ya seguimos al usuario según los datos de la API
    final bool isFollowing = profileData?['is_following'] ?? false;

    return ListView(
      children: [
        const SizedBox(height: 20),
        // 1. FOTO DE PERFIL
        Center(
          child: GestureDetector(
            onTap: () => SinceraUtils.verFotoGrande(context, avatar),
            child: UserAvatar(avatarUrl: avatar),
          ),
        ),

        const SizedBox(height: 20),

        // 2. BOTÓN DE SEGUIR / SIGUIENDO
        Center(
          child: isFollowing
              ? SizedBox(
                  width: 150,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Colors.white24,
                      ), // Borde gris
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () async {
                      // Lógica para dejar de seguir
                      await ApiService.unfollowUser(
                        myUsername!,
                        widget.username,
                      );

                      if (mounted) {
                        // Cartel de confirmación (SnackBar)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Dejaste de seguir a ${widget.username}",
                            ),
                            backgroundColor: Colors.grey[900],
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        _cargarPerfil();
                      }
                    },
                    child: const Text(
                      "SIGUIENDO",
                      style: TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                )
              : SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SinceraTheme.accentNeon,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () async {
                      await ApiService.followUser(myUsername!, widget.username);
                      if (mounted) _cargarPerfil();
                    },
                    child: const Text(
                      "SEGUIR",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
        ),

        const SizedBox(height: 25),

        // 3. CONTADORES (Stats)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statItem(
              "POSTS",
              (profileData?['posts_count'] ?? 0).toString(),
              () {},
            ),
            _statItem(
              "SEGUIDORES",
              (profileData?['followers'] ?? 0).toString(),
              () {
                _mostrarLista("SEGUIDORES", profileData?['followers_list']);
              },
            ),
            _statItem(
              "SIGUIENDO",
              (profileData?['following'] ?? 0).toString(),
              () {
                _mostrarLista("SIGUIENDO", profileData?['following_list']);
              },
            ),
          ],
        ),

        const Divider(color: Colors.white10, height: 40),

        // 4. GRID DE FOTOS
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) => GestureDetector(
            // En user_profile_screen.dart -> GridView
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostViewScreen(
                    posts: posts,
                    initialIndex: index,
                    currentUsername: myUsername,
                    // Pasamos el estado real de seguimiento del perfil actual
                    isFollowingProfile: profileData?['is_following'] ?? false,
                  ),
                ),
              );
              _cargarPerfil();
            },
            child: Image.network(posts[index]['image_url'], fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }

  Widget _statItem(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
