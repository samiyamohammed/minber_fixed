// lib/widgets/media/playlist_grid_view.dart
import 'package:flutter/material.dart';
import '../../models/playlist_model.dart';

class PlaylistGridView extends StatelessWidget {
  final List<Playlist> playlists;
  final Function(Playlist) onPlaylistTapped;
  const PlaylistGridView(
      {super.key, required this.playlists, required this.onPlaylistTapped});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          color: Theme.of(context).cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => onPlaylistTapped(playlist),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (playlist.thumbnailUrl.isNotEmpty)
                  Image.network(
                    playlist.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Center(
                        child: Icon(Icons.broken_image,
                            size: 50, color: Colors.grey[400])),
                  )
                else
                  Container(
                      color: Colors.grey,
                      child: const Icon(Icons.video_library)),
                Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent
                ], begin: Alignment.bottomCenter, end: Alignment.center))),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(playlist.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      // The 'itemCount' Text widget has been removed from here
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
