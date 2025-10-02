import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class YouTubeChannelDetailPage extends StatefulWidget {
  const YouTubeChannelDetailPage({super.key});

  @override
  State<YouTubeChannelDetailPage> createState() =>
      _YouTubeChannelDetailPageState();
}

class _YouTubeChannelDetailPageState extends State<YouTubeChannelDetailPage> {
  int _selectedTab = 0; // 0 = Latest, 1 = Popular, 2 = Oldest
  int _selectedNav =
      0; // 0 = Home, 1 = Videos, 2 = Shorts, 3 = Live, 4 = Playlists

  final List<Map<String, dynamic>> _videos = [
    {
      'title': 'Meweda Infotainment',
      'subtitle': 'Trailer II',
      'views': '6.7K views',
      'time': '7 years ago',
      'thumbnail': 'https://picsum.photos/400/225?random=1',
      'channelThumbnail': 'https://picsum.photos/50/50?random=10',
    },
    {
      'title': '"ENEDEMANET" short comedy II',
      'subtitle': '',
      'views': '17K views',
      'time': '7 years ago',
      'thumbnail': 'https://picsum.photos/400/225?random=2',
      'channelThumbnail': 'https://picsum.photos/50/50?random=11',
    },
    {
      'title': 'Islamic Lecture Series',
      'subtitle': 'Part 3 - Patience',
      'views': '12.5K views',
      'time': '2 months ago',
      'thumbnail': 'https://picsum.photos/400/225?random=3',
      'channelThumbnail': 'https://picsum.photos/50/50?random=12',
    },
    {
      'title': 'Quran Recitation',
      'subtitle': 'Surah Al-Fatihah',
      'views': '45K views',
      'time': '1 year ago',
      'thumbnail': 'https://picsum.photos/400/225?random=4',
      'channelThumbnail': 'https://picsum.photos/50/50?random=13',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          "YouTube",
          style: TextStyle(color: theme.colorScheme.onBackground),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.colorScheme.onBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.cast, color: theme.iconTheme.color),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.notifications_none, color: theme.iconTheme.color),
            onPressed: () => Navigator.pushNamed(context, "/notifications"),
          ),
          IconButton(
            icon: Icon(Icons.search, color: theme.iconTheme.color),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: size.height * 0.02),

            // Divider
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
              child: Divider(color: theme.dividerColor, thickness: 1),
            ),
            SizedBox(height: size.height * 0.02),

            // Channel Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Minber TV",
                    style: TextStyle(
                      fontSize: size.width * 0.06,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                  SizedBox(height: size.height * 0.005),
                  Text(
                    "@minbertv1",
                    style: TextStyle(
                      fontSize: size.width * 0.04,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.7,
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Text(
                    "742K subscribers - 6.4K videos",
                    style: TextStyle(
                      fontSize: size.width * 0.035,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.7,
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.02),

                  // Subscribe Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: size.height * 0.015,
                        ),
                      ),
                      child: Text(
                        "Subscribed",
                        style: TextStyle(
                          fontSize: size.width * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.03),

            // Navigation Tabs
            SizedBox(
              height: size.height * 0.06,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                children: [
                  _buildNavTab("Home", 0, size, theme),
                  _buildNavTab("Videos", 1, size, theme),
                  _buildNavTab("Shorts", 2, size, theme),
                  _buildNavTab("Live", 3, size, theme),
                  _buildNavTab("Playlists", 4, size, theme),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.02),

            // Sort Tabs
            SizedBox(
              height: size.height * 0.05,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSortTab("Latest", 0, size, theme),
                  _buildSortTab("Popular", 1, size, theme),
                  _buildSortTab("Oldest", 2, size, theme),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.02),

            // Divider
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
              child: Divider(color: theme.dividerColor, thickness: 1),
            ),
            SizedBox(height: size.height * 0.02),

            // Videos List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _videos.length,
              itemBuilder: (context, index) =>
                  _buildVideoItem(_videos[index], size, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTab(String title, int index, Size size, ThemeData theme) {
    final bool selected = _selectedNav == index;
    return Padding(
      padding: EdgeInsets.only(right: size.width * 0.04),
      child: TextButton(
        onPressed: () => setState(() => _selectedNav = index),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.03,
            vertical: size.height * 0.005,
          ),
          backgroundColor: selected
              ? theme.dividerColor.withOpacity(0.3)
              : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: size.width * 0.04,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected
                ? theme.colorScheme.onBackground
                : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildSortTab(String title, int index, Size size, ThemeData theme) {
    final bool selected = _selectedTab == index;
    return Expanded(
      child: TextButton(
        onPressed: () => setState(() => _selectedTab = index),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: size.height * 0.005),
          backgroundColor: selected
              ? theme.dividerColor.withOpacity(0.3)
              : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: size.width * 0.04,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected
                ? theme.colorScheme.onBackground
                : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoItem(
    Map<String, dynamic> video,
    Size size,
    ThemeData theme,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: size.height * 0.02),
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Thumbnail
          Container(
            width: double.infinity,
            height: size.height * 0.2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(video['thumbnail']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: size.height * 0.01),

          // Video Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: size.width * 0.04,
                backgroundImage: NetworkImage(video['channelThumbnail']),
              ),
              SizedBox(width: size.width * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video['title'],
                      style: TextStyle(
                        fontSize: size.width * 0.04,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onBackground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (video['subtitle'] != null &&
                        video['subtitle'].isNotEmpty)
                      Text(
                        video['subtitle'],
                        style: TextStyle(
                          fontSize: size.width * 0.035,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.7,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: size.height * 0.005),
                    Text(
                      "${video['views']} - ${video['time']}",
                      style: TextStyle(
                        fontSize: size.width * 0.033,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  size: size.width * 0.05,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
