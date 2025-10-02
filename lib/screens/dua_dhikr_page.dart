import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class DuaDhikrPage extends StatelessWidget {
  const DuaDhikrPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Dua & Dhikr"),
          bottom: const TabBar(
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green,
            tabs: [
              Tab(text: "Morning"),
              Tab(text: "Evening"),
              Tab(text: "Thursday"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAzkarList(morningAzkar, isDark),
            _buildAzkarList(eveningAzkar, isDark),
            _buildAzkarList(thursdaySalawat, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAzkarList(List<Map<String, String>> items, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Arabic text
                Text(
                  item["arabic"]!,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 10),

                // Translation
                Text(
                  item["translation"]!,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Repeat count + Audio button placeholder
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Repeat: ${item["repeat"]}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: add audio play here
                      },
                      icon: const Icon(Icons.volume_up, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// -------------------------
/// 🌅 Morning Azkar
/// -------------------------
final List<Map<String, String>> morningAzkar = [
  {
    "arabic":
        "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ",
    "translation":
        "Allah! None has the right to be worshipped except Him, the Ever Living, the One Who sustains and protects all that exists. Neither slumber nor sleep overtakes Him. To Him belongs whatever is in the heavens and whatever is in the earth. Who is he that can intercede with Him except with His Permission? He knows what happens to them in this world, and what will happen to them in the Hereafter. And they will never compass anything of His Knowledge except that which He wills. His Kursi extends over the heavens and the earth, and He feels no fatigue in guarding and preserving them. And He is the Most High, the Most Great.",
    "repeat": "1x",
  },
  {
    "arabic":
        "قُلْ هُوَ اللَّهُ أَحَدٌ\nاللَّهُ الصَّمَدُ\nلَمْ يَلِدْ وَلَمْ يُولَدْ\nوَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ",
    "translation":
        "Say: He is Allah, the One and Only; Allah, the Eternal, Absolute. He begets not, nor is He begotten. And there is none comparable to Him.",
    "repeat": "3x",
  },
  {
    "arabic":
        "قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ\nمِن شَرِّ مَا خَلَقَ\nوَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ\nوَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ\nوَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ",
    "translation":
        "Say: I seek refuge in the Lord of daybreak, from the evil of all that He created, from the evil of darkness as it spreads, from the evil of those who practice witchcraft by blowing on knots, and from the evil of an envier when he envies.",
    "repeat": "3x",
  },
  {
    "arabic":
        "قُلْ أَعُوذُ بِرَبِّ النَّاسِ\nمَلِكِ النَّاسِ\nإِلَٰهِ النَّاسِ\nمِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ\nالَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ\nمِنَ الْجِنَّةِ وَالنَّاسِ",
    "translation":
        "Say: I seek refuge in the Lord of mankind, the Sovereign of mankind, the God of mankind, from the evil of the whisperer who withdraws, who whispers in the hearts of mankind, whether from among the jinn or mankind.",
    "repeat": "3x",
  },
  {
    "arabic":
        "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ",
    "translation":
        "In the Name of Allah, with Whose name nothing on earth or in heaven can cause harm, and He is the All-Hearing, All-Knowing.",
    "repeat": "3x",
  },
  {
    "arabic":
        "رَضِيتُ بِاللَّهِ رَبًّا، وَبِالإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا",
    "translation":
        "I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad ﷺ as my Prophet.",
    "repeat": "3x",
  },
];

/// -------------------------
/// 🌙 Evening Azkar
/// -------------------------
final List<Map<String, String>> eveningAzkar = [
  {
    "arabic":
        "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ",
    "translation":
        "Allah! None has the right to be worshipped except Him, the Ever Living, the One Who sustains and protects all that exists. Neither slumber nor sleep overtakes Him. To Him belongs whatever is in the heavens and whatever is in the earth. Who is he that can intercede with Him except with His Permission? He knows what happens to them in this world, and what will happen to them in the Hereafter. And they will never compass anything of His Knowledge except that which He wills. His Kursi extends over the heavens and the earth, and He feels no fatigue in guarding and preserving them. And He is the Most High, the Most Great.",
    "repeat": "1x",
  },
  {
    "arabic":
        "قُلْ هُوَ اللَّهُ أَحَدٌ\nاللَّهُ الصَّمَدُ\nلَمْ يَلِدْ وَلَمْ يُولَدْ\nوَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ",
    "translation":
        "Say: He is Allah, the One and Only; Allah, the Eternal, Absolute. He begets not, nor is He begotten. And there is none comparable to Him.",
    "repeat": "3x",
  },
  {
    "arabic":
        "قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ\nمِن شَرِّ مَا خَلَقَ\nوَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ\nوَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ\nوَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ",
    "translation":
        "Say: I seek refuge in the Lord of daybreak, from the evil of all that He created, from the evil of darkness as it spreads, from the evil of those who practice witchcraft by blowing on knots, and from the evil of an envier when he envies.",
    "repeat": "3x",
  },
  {
    "arabic":
        "قُلْ أَعُوذُ بِرَبِّ النَّاسِ\nمَلِكِ النَّاسِ\nإِلَٰهِ النَّاسِ\nمِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ\nالَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ\nمِنَ الْجِنَّةِ وَالنَّاسِ",
    "translation":
        "Say: I seek refuge in the Lord of mankind, the Sovereign of mankind, the God of mankind, from the evil of the whisperer who withdraws, who whispers in the hearts of mankind, whether from among the jinn or mankind.",
    "repeat": "3x",
  },
  {
    "arabic":
        "اللَّهُمَّ إِنِّي أَمْسَيْتُ أُشْهِدُكَ، وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلَائِكَتَكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللَّهُ لَا إِلَهَ إِلَّا أَنْتَ، وَحْدَكَ لَا شَرِيكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُولُكَ",
    "translation":
        "O Allah, this evening I testify to You, the bearers of Your Throne, Your angels, and all of Your creation, that You are Allah, none has the right to be worshipped except You, alone without partner, and that Muhammad ﷺ is Your servant and Messenger.",
    "repeat": "4x",
  },
];

/// -------------------------
/// 🤲 Thursday Salawat
/// -------------------------
final List<Map<String, String>> thursdaySalawat = [
  {
    "arabic":
        "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ. اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ.",
    "translation":
        "O Allah, send prayers upon Muhammad and upon the family of Muhammad, as You sent prayers upon Ibrahim and the family of Ibrahim. Verily, You are Praiseworthy, Glorious. O Allah, bless Muhammad and the family of Muhammad, as You blessed Ibrahim and the family of Ibrahim. Verily, You are Praiseworthy, Glorious.",
    "repeat": "1x (Thursday)",
  },
];
