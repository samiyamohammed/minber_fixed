// lib/widgets/media/media_shimmers.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class VideoListShimmer extends StatelessWidget {
  const VideoListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.splashColor.withOpacity(0.3),
      highlightColor: theme.cardColor.withOpacity(0.3),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) => Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 140, height: 80, color: Colors.white),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white),
                      const SizedBox(height: 8),
                      Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: 100, height: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaylistGridShimmer extends StatelessWidget {
  const PlaylistGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.splashColor.withOpacity(0.3),
      highlightColor: theme.cardColor.withOpacity(0.3),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0),
        itemCount: 6,
        itemBuilder: (context, index) => Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(color: Colors.white),
        ),
      ),
    );
  }
}
