import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'post_view_screen.dart';
import '../services/api_service.dart';
import '../theme.dart';

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
    final data = await ApiService.fetchProfile(widget.username, myUsername);
    if (mounted) {
      setState(() {
        profileData = data;
        isLoading = false;
      });
    }
  }

  // Función para elegir entre cámara o galería
  Future<void> _seleccionarOrigenImagen() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(
              Icons.camera_alt,
              color: SinceraTheme.accentNeon,
            ),
            title: const Text("Cámara", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _cambiarFotoPerfil(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.photo_library,
              color: SinceraTheme.accentNeon,
            ),
            title: const Text("Galería", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _cambiarFotoPerfil(ImageSource.gallery);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _cambiarFotoPerfil(ImageSource fuente) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: fuente,
      imageQuality: 50,
    );

    if (!mounted) return;

    if (image != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Actualizando foto de perfil...")),
      );

      final String? nuevaUrl = await ApiService.updateAvatar(
        image.path,
        widget.username,
      );

      if (nuevaUrl != null) {
        _cargarPerfil();
      }
    }
  }

  void _verFotoGrande(String? url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: url != null
                    ? Image.network(url, fit: BoxFit.contain)
                    : Container(
                        height: 250,
                        width: 250,
                        color: SinceraTheme.accentNeon,
                        child: const Icon(
                          Icons.person,
                          size: 120,
                          color: Colors.black,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
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
    final String? avatarUrl = profileData!['avatar_url'];
    final bool esMiPerfil = myUsername == widget.username;

    return ListView(
      children: [
        const SizedBox(height: 20),
        Center(
          child: Stack(
            children: [
              // Avatar
              GestureDetector(
                onTap: () => _verFotoGrande(avatarUrl),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: SinceraTheme.accentNeon,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.person, size: 50, color: Colors.black)
                      : null,
                ),
              ),
              // Botón de Edición (Lápiz)
              if (esMiPerfil)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _seleccionarOrigenImagen,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: SinceraTheme.accentOrange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 15),

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
                  _cargarPerfil();
                }
              },
              child: Text(alreadyFollowing ? "SIGUIENDO" : "SEGUIR"),
            ),
          )
        else
          const Center(
            child: Text(
              "TU PERFIL",
              style: TextStyle(
                color: Colors.white24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

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
              ).then((_) => _cargarPerfil());
            },
            child: Image.network(
              photos[index]['image_url'],
              fit: BoxFit.cover,
              // Esto es lo que añadimos:
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.white10,
                  child: const Icon(Icons.broken_image, color: Colors.white24),
                );
              },
            ),
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
