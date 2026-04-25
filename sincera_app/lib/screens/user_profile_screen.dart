import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'post_view_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String username; // El nombre del perfil que queremos ver

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

  Future<void> _handleLike(dynamic postId) async {
    if (myUsername == null) return;
    await ApiService.toggleLike(postId, myUsername!);
  }

  Future<void> _inicializarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        myUsername = prefs.getString('username');
      });
    }
    await _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final data = await ApiService.fetchProfile(widget.username);
    if (mounted) {
      setState(() {
        profileData = data;
        isLoading = false;
      });
    }
  }

  void _mostrarLista(String titulo, List lista) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
                    lista[i]['username'],
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
        foregroundColor: Colors.white,
        title: Text(
          widget.username.toUpperCase(),
          style: const TextStyle(fontSize: 14, letterSpacing: 2),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: SinceraTheme.accentNeon),
            )
          : profileData == null
          ? const Center(
              child: Text(
                "Usuario no encontrado",
                style: TextStyle(color: Colors.white24),
              ),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final photos = profileData!['photos'] as List;
    final bool alreadyFollowing = profileData!['already_following'] ?? false;

    return ListView(
      children: [
        const SizedBox(height: 20),
        const Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: SinceraTheme.accentNeon,
            child: Icon(Icons.person, size: 45, color: Colors.black),
          ),
        ),
        const SizedBox(height: 15),

        // LÓGICA DEL BOTÓN: Solo se muestra si el perfil NO es el mío
        if (myUsername != widget.username)
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: alreadyFollowing
                    ? Colors.white10
                    : SinceraTheme.accentNeon,
                foregroundColor: alreadyFollowing
                    ? Colors.white24
                    : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () async {
                if (myUsername != null) {
                  await ApiService.followUser(myUsername!, widget.username);
                  _cargarPerfil(); // Recargar para actualizar contador y botón
                }
              },
              child: Text(alreadyFollowing ? "SIGUIENDO" : "SEGUIR"),
            ),
          )
        else
          const SizedBox(height: 10), // Espacio si es mi propio perfil

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statItem("Posts", profileData!['posts_count'].toString(), () {}),
            _statItem(
              "Seguidores",
              profileData!['followers_count'].toString(),
              () {
                _mostrarLista(
                  "SEGUIDORES",
                  profileData!['followers_list'] ?? [],
                );
              },
            ),
            _statItem(
              "Siguiendo",
              profileData!['following_count'].toString(),
              () {
                _mostrarLista(
                  "SIGUIENDO",
                  profileData!['following_list'] ?? [],
                );
              },
            ),
          ],
        ),
        const Divider(color: Colors.white10, height: 40),
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
              final bool sigoAEstaPersona =
                  profileData!['already_following'] ?? false;
              photos[index]['already_following'] = sigoAEstaPersona;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostViewScreen(
                    posts: photos,
                    initialIndex: index,
                    onLike: (postId) => _handleLike(postId),
                  ),
                ),
              ).then((_) {
                // Cuando el usuario regresa de ver los posts, refrescamos el perfil
                // para que los contadores y estados de likes se sincronicen.
                _cargarPerfil();
              });
            },
            child: Image.network(photos[index]['image_url'], fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }

  Widget _statItem(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
