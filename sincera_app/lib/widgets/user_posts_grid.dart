import 'package:flutter/material.dart';

class UserPostsGrid extends StatelessWidget {
  final List photos;
  final Function(int) onPostTap;

  const UserPostsGrid({
    super.key,
    required this.photos,
    required this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) => GestureDetector(
        onTap: () => onPostTap(index),
        child: Image.network(photos[index]['image_url'], fit: BoxFit.cover),
      ),
    );
  }
}
