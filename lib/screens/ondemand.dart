import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../core/app_colors.dart';

class OnDemandPage extends StatefulWidget {
  const OnDemandPage({super.key});

  @override
  State<OnDemandPage> createState() => _OnDemandPageState();
}

class _OnDemandPageState extends State<OnDemandPage> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategory =
      0; // 0 = All, 1 = Movies, 2 = Series, 3 = Documentaries
  int _selectedIndex = 1; // Default = Media tab

  final List<Map<String, dynamic>> _continueWatching = [
    {
      'title': 'A Journey Through Time',
      'description': 'An epic tale of discovery and adventure',
      'progress': 0.7,
      'thumbnail': 'https://picsum.photos/300/169?random=101',
    },
    {
      'title': 'Dinner',
      'description': 'Culinary adventures around the world',
      'progress': 0.4,
      'thumbnail': 'https://picsum.photos/300/169?random=102',
    },
  ];

  final List<Map<String, dynamic>> _downloaded = [
    {
      'title': 'The Silent Hunter',
      'description': 'Top-rated action thriller of the year',
      'thumbnail': 'https://picsum.photos/300/169?random=105',
      'size': '1.2GB',
    },
    {
      'title': 'Wild Wonders: Amazon',
      'description': 'Explore the hidden gems of the rainforest',
      'thumbnail': 'https://picsum.photos/300/169?random=106',
      'size': '2.1GB',
    },
  ];

  final List<Map<String, dynamic>> _trendingVideos = [
    {
      'title': 'The Lost Expedition',
      'description': 'A team of engineers embark on a perfect mission',
      'thumbnail': 'https://picsum.photos/300/169?random=108',
      'views': '15K views',
    },
    {
      'title': 'Echoes of the Past',
      'description': 'Unraveling ancient species in a modern world',
      'thumbnail': 'https://picsum.photos/300/169?random=109',
      'views': '23K views',
    },
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        break; // already on Media
      case 2:
        Navigator.pushReplacementNamed(context, '/prayer');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/wallet');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/subapps');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          "On Demand",
          style: TextStyle(
            fontSize: size.width * 0.045,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onBackground,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.colorScheme.onBackground,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              size: size.width * 0.06,
              color: theme.iconTheme.color,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.notifications_none,
              size: size.width * 0.06,
              color: theme.iconTheme.color,
            ),
            onPressed: () =>
                Fluttertoast.showToast(msg: "Notifications clicked"),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                  decoration: InputDecoration(
                    hintText: "Search videos...",
                    hintStyle: TextStyle(color: theme.hintColor),
                    prefixIcon: Icon(
                      Icons.search,
                      size: size.width * 0.05,
                      color: theme.hintColor,
                    ),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(size.width * 0.06),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.04,
                      vertical: size.height * 0.015,
                    ),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.03),

              // Continue Watching Section
              _buildSectionHeader(size, "Continue Watching", "See All", theme),
              SizedBox(height: size.height * 0.01),
              SizedBox(
                height: size.height * 0.25,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                  itemCount: _continueWatching.length,
                  itemBuilder: (context, index) => _buildContinueWatchingItem(
                    _continueWatching[index],
                    size,
                    theme,
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.03),

              // Downloaded Section
              _buildSectionHeader(size, "Downloaded", "", theme),
              SizedBox(height: size.height * 0.01),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                itemCount: _downloaded.length,
                itemBuilder: (context, index) =>
                    _buildDownloadedItem(_downloaded[index], size, theme),
              ),
              SizedBox(height: size.height * 0.03),

              // Trending Videos Section
              _buildSectionHeader(size, "Trending Videos", "", theme),
              SizedBox(height: size.height * 0.02),

              // Category Tabs
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(
                      4,
                      (index) => Padding(
                        padding: EdgeInsets.only(right: size.width * 0.02),
                        child: _buildCategoryTab(
                          ["All", "Movies", "Series", "Documentaries"][index],
                          index,
                          size,
                          theme,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.02),

              // Trending Videos Grid
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: size.width * 0.03,
                    mainAxisSpacing: size.height * 0.02,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _trendingVideos.length,
                  itemBuilder: (context, index) => _buildTrendingVideoItem(
                    _trendingVideos[index],
                    size,
                    theme,
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.03),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: theme.iconTheme.color?.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: size.width * 0.03,
        unselectedFontSize: size.width * 0.03,
        iconSize: size.width * 0.06,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.tv), label: "Media"),
          BottomNavigationBarItem(icon: Icon(Icons.mosque), label: "Prayer"),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: "Wallet",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Sub Apps"),
        ],
      ),
    );
  }

  // Section header
  Widget _buildSectionHeader(
    Size size,
    String title,
    String action,
    ThemeData theme,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: size.width * 0.045,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
          ),
          if (action.isNotEmpty)
            TextButton(
              onPressed: () {},
              child: Text(
                action,
                style: TextStyle(
                  fontSize: size.width * 0.032,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Category tab
  Widget _buildCategoryTab(
    String title,
    int index,
    Size size,
    ThemeData theme,
  ) {
    final isSelected = _selectedCategory == index;
    return Container(
      constraints: BoxConstraints(minWidth: size.width * 0.18),
      child: TextButton(
        onPressed: () => setState(() => _selectedCategory = index),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.02,
            vertical: size.height * 0.005,
          ),
          backgroundColor: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size.width * 0.03),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: size.width * 0.032,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? AppColors.primary
                : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  // Continue Watching Item
  Widget _buildContinueWatchingItem(
    Map<String, dynamic> item,
    Size size,
    ThemeData theme,
  ) {
    return Container(
      width: size.width * 0.65,
      margin: EdgeInsets.only(right: size.width * 0.03),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(size.width * 0.04),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: size.height * 0.12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(size.width * 0.04),
                    topRight: Radius.circular(size.width * 0.04),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(item['thumbnail']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: item['progress'],
                  backgroundColor: theme.dividerColor,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(size.width * 0.03),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: TextStyle(
                    fontSize: size.width * 0.038,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
                SizedBox(height: size.height * 0.005),
                Text(
                  item['description'],
                  style: TextStyle(
                    fontSize: size.width * 0.03,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Downloaded item
  Widget _buildDownloadedItem(
    Map<String, dynamic> item,
    Size size,
    ThemeData theme,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: size.height * 0.02),
      padding: EdgeInsets.all(size.width * 0.03),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(size.width * 0.04),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: size.width * 0.22,
            height: size.height * 0.09,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size.width * 0.03),
              image: DecorationImage(
                image: NetworkImage(item['thumbnail']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: size.width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: TextStyle(
                    fontSize: size.width * 0.038,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
                SizedBox(height: size.height * 0.003),
                Text(
                  item['description'],
                  style: TextStyle(
                    fontSize: size.width * 0.03,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: size.height * 0.003),
                Text(
                  item['size'],
                  style: TextStyle(
                    fontSize: size.width * 0.028,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Trending Video Item
  Widget _buildTrendingVideoItem(
    Map<String, dynamic> item,
    Size size,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(size.width * 0.04),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: size.height * 0.12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(size.width * 0.04),
                topRight: Radius.circular(size.width * 0.04),
              ),
              image: DecorationImage(
                image: NetworkImage(item['thumbnail']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(size.width * 0.03),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: TextStyle(
                    fontSize: size.width * 0.036,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: size.height * 0.003),
                Text(
                  item['description'],
                  style: TextStyle(
                    fontSize: size.width * 0.028,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
