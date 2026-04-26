import 'package:flutter/material.dart';
import 'user_avatar.dart';
import '../theme.dart';
import '../screens/user_profile_screen.dart';

class UserListModal extends StatelessWidget {
  final String title;
  final List items;

  const UserListModal({super.key, required this.title, required this.items});

  static void show(BuildContext context, String title, List items) {
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
        builder: (_, controller) => UserListModal(title: title, items: items),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: SinceraTheme.accentNeon,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Divider(color: Colors.white10, height: 30),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      "No hay usuarios todavía",
                      style: TextStyle(color: Colors.white24),
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final user = items[i]['username'] ?? "usuario";
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: UserAvatar(
                          avatarUrl: items[i]['avatar_url'],
                          radius: 18,
                          iconSize: 18,
                        ),
                        title: Text(
                          user,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
