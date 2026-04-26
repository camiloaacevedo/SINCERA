import 'package:flutter/material.dart';

class UserStatsBar extends StatelessWidget {
  final String postsCount;
  final String followersCount;
  final String followingCount;
  final Function(String, List) onStatTap;
  final List followersList;
  final List followingList;

  const UserStatsBar({
    super.key,
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    required this.onStatTap,
    required this.followersList,
    required this.followingList,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStat("Posts", postsCount, []),
        _buildStat("Seguidores", followersCount, followersList),
        _buildStat("Siguiendo", followingCount, followingList),
      ],
    );
  }

  Widget _buildStat(String label, String value, List lista) {
    return GestureDetector(
      onTap: () => onStatTap(label, lista),
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
