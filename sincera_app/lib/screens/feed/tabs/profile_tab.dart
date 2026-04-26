import 'package:flutter/material.dart';
import 'package:sincera_app/widgets/user_avatar.dart';
import '../../../theme.dart';
import '../../../utils.dart';
import '../../post_view_screen.dart';
import '../../user_profile_screen.dart';
import '../../../widgets/user_stats_bar.dart';
import '../../../widgets/user_posts_grid.dart';

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

  void _handleStatTap(String titulo, List lista) {
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
        // Avatar Section
        Center(
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => SinceraUtils.verFotoGrande(
                  context,
                  widget.profileData!['avatar_url'],
                ),
                child: UserAvatar(avatarUrl: widget.profileData!['avatar_url']),
              ),
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

        UserStatsBar(
          postsCount: photos.length.toString(),
          followersCount: (widget.profileData!['followers'] ?? 0).toString(),
          followingCount: (widget.profileData!['following_list']?.length ?? 0)
              .toString(),
          followersList: widget.profileData!['followers_list'] ?? [],
          followingList: widget.profileData!['following_list'] ?? [],
          onStatTap: _handleStatTap,
        ),

        const Divider(
          color: Colors.white10,
          height: 40,
          indent: 20,
          endIndent: 20,
        ),

        UserPostsGrid(
          photos: photos,
          onPostTap: (index) async {
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
        ),
      ],
    );
  }
}
