import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

// --- Configuration ---
const String YOUTUBE_API_KEY =
    "AIzaSyBVpcfaLy2mhuyNiaXM0Y1Dbu70tpZOrws"; // Your provided API key
const String TARGET_CHANNEL_ID =
    "UCMy0uzm0QfLbLSkBJLU3paA"; // The channel ID from your image

// --- YouTubePage Widget ---
class YouTubePage extends StatefulWidget {
  const YouTubePage({super.key});

  @override
  State<YouTubePage> createState() => _YouTubePageState();
}

class _YouTubePageState extends State<YouTubePage> {
  // Data structures to hold fetched content
  Map<String, List<Map<String, String>>> videosByCategory = {};
  List<Map<String, String>> allVideos = [];
  List<Map<String, String>> searchResults = []; // List for search results

  // State variables for UI
  String selectedCategory = "All";
  bool loading = true;
  String? errorMessage; // Stores any API-related errors

  // Search-related state
  final TextEditingController _searchController = TextEditingController();
  bool isSearching =
      false; // To differentiate between category view and search view

  @override
  void initState() {
    super.initState();
    if (YOUTUBE_API_KEY == "YOUR_YOUTUBE_API_KEY" || YOUTUBE_API_KEY.isEmpty) {
      _setErrorState("Please set your YouTube API key in the code.");
      return;
    }
    _fetchAllPlaylistsAndVideos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setErrorState(String message) {
    setState(() {
      loading = false;
      errorMessage = message;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });
  }

  Future<void> _fetchAllPlaylistsAndVideos() async {
    Map<String, List<Map<String, String>>> tempVideosByCategory = {};
    List<Map<String, String>> tempAllVideos = [];

    setState(() {
      loading = true;
      errorMessage = null;
    });

    String? playlistPageToken;
    bool fetchSuccess = true;

    try {
      int playlistFetchCount = 0;
      do {
        debugPrint(
          "Fetching playlists page with token: ${playlistPageToken ?? 'null'}",
        );
        final playlistUrl =
            "https://www.googleapis.com/youtube/v3/playlists?key=$YOUTUBE_API_KEY&channelId=$TARGET_CHANNEL_ID&part=snippet&maxResults=50&pageToken=${playlistPageToken ?? ""}";

        final playlistResponse = await http.get(Uri.parse(playlistUrl));

        if (playlistResponse.statusCode == 200) {
          final playlistData = json.decode(playlistResponse.body);
          final playlistItems = playlistData['items'] as List;

          debugPrint(
            "Fetched ${playlistItems.length} playlists from this page.",
          );

          for (var item in playlistItems) {
            String playlistId = item['id'];
            String playlistTitle = item['snippet']['title'];
            debugPrint(
              "Processing playlist: '$playlistTitle' (ID: $playlistId)",
            );
            await _fetchVideosForPlaylist(
              playlistId,
              playlistTitle,
              tempVideosByCategory,
              tempAllVideos,
            );
          }
          playlistPageToken = playlistData['nextPageToken'];
          playlistFetchCount++;
        } else {
          final errorData = json.decode(playlistResponse.body);
          String errorMsg =
              errorData['error']?['message'] ?? playlistResponse.body;
          debugPrint(
            "API Error fetching playlists (Status ${playlistResponse.statusCode}): $errorMsg",
          );
          _setErrorState("Failed to load playlists: $errorMsg");
          fetchSuccess = false;
          break;
        }
      } while (playlistPageToken != null && playlistFetchCount < 10);

      if (fetchSuccess) {
        debugPrint(
          "Finished fetching playlists. Total categories found: ${tempVideosByCategory.keys.length}",
        );
        setState(() {
          loading = false;
          videosByCategory = tempVideosByCategory;
          allVideos = tempAllVideos;
          selectedCategory = "All";
        });
      }
    } catch (e, stacktrace) {
      debugPrint("Exception during playlist and video fetch: $e\n$stacktrace");
      _setErrorState("An error occurred while fetching data.");
    }
  }

  Future<void> _fetchVideosForPlaylist(
    String playlistId,
    String playlistTitle,
    Map<String, List<Map<String, String>>> tempVideosByCategory,
    List<Map<String, String>> tempAllVideos,
  ) async {
    String? playlistItemPageToken;
    List<Map<String, String>> currentPlaylistVideos = [];
    int videoFetchCount = 0;

    try {
      do {
        debugPrint(
          "Fetching videos for playlist '$playlistTitle' with token: ${playlistItemPageToken ?? 'null'}",
        );
        final videoUrl =
            "https://www.googleapis.com/youtube/v3/playlistItems?key=$YOUTUBE_API_KEY&playlistId=$playlistId&part=snippet&maxResults=50&pageToken=${playlistItemPageToken ?? ""}";

        final videoResponse = await http.get(Uri.parse(videoUrl));

        if (videoResponse.statusCode == 200) {
          final videoData = json.decode(videoResponse.body);
          final videoItems = videoData['items'] as List;

          debugPrint(
            "Fetched ${videoItems.length} videos for playlist '$playlistTitle' from this page.",
          );

          for (var item in videoItems) {
            final snippet = item['snippet'];
            final resourceId = snippet['resourceId'];
            final thumbnails = snippet['thumbnails'];
            final highThumbnail = thumbnails?['high'];

            if (resourceId != null &&
                resourceId['videoId'] != null &&
                highThumbnail != null &&
                highThumbnail['url'] != null) {
              currentPlaylistVideos.add({
                'videoId': resourceId['videoId'],
                'title': snippet['title'],
                'thumbnail': highThumbnail['url'],
              });
            } else {
              debugPrint(
                "Skipping video due to missing data in playlist '$playlistTitle': ${item['snippet']['title'] ?? 'Unknown Video'}",
              );
            }
          }
          playlistItemPageToken = videoData['nextPageToken'];
          videoFetchCount++;
        } else {
          final errorData = json.decode(videoResponse.body);
          String errorMsg =
              errorData['error']?['message'] ?? videoResponse.body;
          debugPrint(
            "API Error fetching videos for '$playlistTitle' (Status ${videoResponse.statusCode}): $errorMsg",
          );
          playlistItemPageToken = null;
        }
      } while (playlistItemPageToken != null && videoFetchCount < 10);

      if (currentPlaylistVideos.isNotEmpty) {
        tempVideosByCategory[playlistTitle] = currentPlaylistVideos;
        tempAllVideos.addAll(currentPlaylistVideos);
        debugPrint(
          "Successfully collected category: '$playlistTitle' with ${currentPlaylistVideos.length} videos.",
        );
      } else {
        debugPrint(
          "Playlist '$playlistTitle' has no valid videos or failed to fetch them.",
        );
      }
    } catch (e, stacktrace) {
      debugPrint(
        "Exception fetching videos for playlist '$playlistTitle': $e\n$stacktrace",
      );
    }
  }

  /// Performs a search for videos based on a query.
  Future<void> _performSearch(String query) async {
    setState(() {
      loading = true; // Show loading indicator during search
      errorMessage = null;
      isSearching = true; // Indicate that we are in search mode
      searchResults.clear(); // Clear previous search results
    });

    try {
      // Encode the search query to handle special characters in URLs.
      final encodedQuery = Uri.encodeComponent(query);

      final searchUrl =
          "https://www.googleapis.com/youtube/v3/search?key=$YOUTUBE_API_KEY&q=$encodedQuery&part=snippet&type=video&maxResults=25"; // Increased maxResults for search

      final response = await http.get(Uri.parse(searchUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;

        setState(() {
          searchResults = items
              .map<Map<String, String>>((item) {
                // Ensure videoId exists
                if (item['id'] != null && item['id']['videoId'] != null) {
                  return {
                    'videoId': item['id']['videoId'],
                    'title': item['snippet']['title'] ?? 'Untitled Video',
                    'thumbnail':
                        item['snippet']['thumbnails']?['high']?['url'] ??
                        '', // Safely get thumbnail URL
                  };
                }
                return {}; // Return empty map if videoId is missing
              })
              .where((video) => video.isNotEmpty)
              .toList(); // Filter out any invalid entries
          loading = false; // Stop loading after successful search
        });
      } else {
        final errorData = json.decode(response.body);
        String errorMsg = errorData['error']?['message'] ?? response.body;
        debugPrint(
          "API Error performing search (Status ${response.statusCode}): $errorMsg",
        );
        _setErrorState("Search failed: $errorMsg");
      }
    } catch (e, stacktrace) {
      debugPrint("Exception during search: $e\n$stacktrace");
      _setErrorState("An error occurred during search.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    final categories = ["All", ...videosByCategory.keys.toList()..sort()];

    final List<Map<String, String>> displayedVideos = isSearching
        ? searchResults
        : selectedCategory == "All"
        ? allVideos
        : videosByCategory[selectedCategory] ?? [];

    debugPrint("Categories available for UI: ${categories.length}");

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "YouTube",
          style: TextStyle(color: theme.colorScheme.onBackground),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        actions: [
          // Search Icon Button
          IconButton(
            icon: Icon(Icons.search, color: theme.iconTheme.color),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  selectedCategory = "All";
                  searchResults.clear();
                }
              });
            },
          ),
        ],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            )
          : Column(
              children: [
                // --- Search Bar or Categories ---
                if (isSearching)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search YouTube...',
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              isSearching = false;
                              selectedCategory = "All";
                              searchResults.clear();
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                      ),
                      // Perform search when the user submits the text (e.g., presses Enter)
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          _performSearch(value);
                        }
                      },
                    ),
                  )
                else // Show categories if not searching
                  SizedBox(
                    height: 50,
                    child: categories.isEmpty
                        ? const Center(child: Text("No categories found."))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              final isSelected = category == selectedCategory;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedCategory = category;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 10,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.primaryColor
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                // --- Videos List Display ---
                Expanded(
                  child: displayedVideos.isEmpty && !loading
                      ? Center(
                          child: Text(
                            isSearching
                                ? "No search results found."
                                : "No videos found for this category.",
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: displayedVideos.length,
                          itemBuilder: (context, index) {
                            final video = displayedVideos[index];
                            if (video.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VideoPlayerPage(
                                      videoId: video['videoId']!,
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4.0),
                                      child: Image.network(
                                        video['thumbnail']!,
                                        width: size.width * 0.35,
                                        height: size.width * 0.22,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  width: size.width * 0.35,
                                                  height: size.width * 0.22,
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                      ),
                                    ),
                                    SizedBox(width: size.width * 0.04),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        child: Text(
                                          video['title'] ?? 'Untitled Video',
                                          style: TextStyle(
                                            fontSize: size.width * 0.038,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                theme.colorScheme.onBackground,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// --- VideoPlayerPage Widget (remains the same) ---
class VideoPlayerPage extends StatefulWidget {
  final String videoId;
  const VideoPlayerPage({super.key, required this.videoId});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        enableJavaScript: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Player"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: YoutubePlayer(controller: _controller, aspectRatio: 16 / 9),
      ),
    );
  }
}
