import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../../../utils.dart';
import '../../user_profile_screen.dart';
import '../../post_view_screen.dart';

class ProfileTab extends StatefulWidget {
  final Map<String, dynamic>? profileData;
  final String? currentUsername;
  final VoidCallback onRefresh;

  const ProfileTab({
    super.key,
    this.profileData,
    this.currentUsername,
    required this.onRefresh,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Widget para las estadísticas
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

  // Modal para ver seguidores/siguiendo
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

  // Modal para opciones de foto (Ahora sí referenciada)
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
            onTap: () {
              Navigator.pop(context);
              // Lógica de galería aquí
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.white),
            title: const Text(
              "Tomar foto",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              // Lógica de cámara aquí
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.profileData == null) {
      return const Center(
        child: CircularProgressIndicator(color: SinceraTheme.accentNeon),
      );
    }

    final List photos = widget.profileData!['posts'] ?? [];

    return ListView(
      key: const PageStorageKey('profile_scroll'),
      children: [
        const SizedBox(height: 30),

        // DISEÑO DEL AVATAR CON BOTÓN DE EDICIÓN
        Center(
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => SinceraUtils.verFotoGrande(
                  context,
                  widget.profileData!['avatar_url'],
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: SinceraTheme.accentNeon,
                  backgroundImage: widget.profileData!['avatar_url'] != null
                      ? NetworkImage(widget.profileData!['avatar_url'])
                      : null,
                  child: widget.profileData!['avatar_url'] == null
                      ? const Icon(Icons.person, size: 50, color: Colors.black)
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _mostrarOpcionesFoto, // <--- USO DE LA FUNCIÓN
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
              (widget.profileData!['followers'] ?? 0).toString(),
              widget.profileData!['followers_list'] ?? [],
            ),
            _buildStat(
              "Siguiendo",
              (widget.profileData!['following_list']?.length ?? 0).toString(),
              widget.profileData!['following_list'] ?? [],
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
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostViewScreen(
                    posts: photos,
                    initialIndex: index,
                    currentUsername: widget.currentUsername,
                  ),
                ),
              );
              widget.onRefresh();
            },
            child: Image.network(photos[index]['image_url'], fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }
}
