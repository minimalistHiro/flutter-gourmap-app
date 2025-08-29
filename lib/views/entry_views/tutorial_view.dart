import 'package:flutter/material.dart';
import '../home_view.dart';

class TutorialView extends StatefulWidget {
  const TutorialView({super.key});

  @override
  State<TutorialView> createState() => _TutorialViewState();
}

class _TutorialViewState extends State<TutorialView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<TutorialSlide> _slides = [
    TutorialSlide(
      icon: Icons.restaurant,
      title: 'GourMapへようこそ！',
      description: 'おいしいお店を見つけて、\nポイントやスタンプを集めよう！',
      backgroundColor: const Color(0xFFFF6B35),
    ),
    TutorialSlide(
      icon: Icons.qr_code_scanner,
      title: 'QRコードでポイント獲得',
      description: 'お店のQRコードを読み取って\nポイントやスタンプをゲット！',
      backgroundColor: const Color(0xFF2196F3),
    ),
    TutorialSlide(
      icon: Icons.local_offer,
      title: 'お得なクーポンを使おう',
      description: 'ポイントを使って割引クーポンを\n利用できます！',
      backgroundColor: const Color(0xFF4CAF50),
    ),
    TutorialSlide(
      icon: Icons.emoji_events,
      title: 'ランキングに参加',
      description: 'ゴールドスタンプを集めて\nランキング上位を目指そう！',
      backgroundColor: const Color(0xFFFFC107),
    ),
    TutorialSlide(
      icon: Icons.people,
      title: '友達を招待してボーナス',
      description: '友達を招待すると\nお互いに1000ポイントもらえる！',
      backgroundColor: const Color(0xFF9C27B0),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishTutorial();
    }
  }

  void _skipTutorial() {
    _finishTutorial();
  }

  void _finishTutorial() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeView(
          selectedTab: 0,
          isShowCouponView: false,
          onTabChanged: (int tab) {},
          onCouponViewChanged: (bool show) {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _skipTutorial,
                  child: const Text(
                    'スキップ',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            
            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(_slides.length, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: index <= _currentPage 
                            ? _slides[_currentPage].backgroundColor
                            : Colors.grey[300],
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _buildSlide(_slides[index]);
                },
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text(
                        '戻る',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 60),

                  // Page indicator dots
                  Row(
                    children: List.generate(_slides.length, (index) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentPage
                              ? _slides[_currentPage].backgroundColor
                              : Colors.grey[300],
                        ),
                      );
                    }),
                  ),

                  // Next/Finish button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _slides[_currentPage].backgroundColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      _currentPage == _slides.length - 1 ? '始める' : '次へ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(TutorialSlide slide) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: slide.backgroundColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: slide.backgroundColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              slide.icon,
              size: 60,
              color: slide.backgroundColor,
            ),
          ),

          const SizedBox(height: 40),

          // Title
          Text(
            slide.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: slide.backgroundColor,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            slide.description,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

class TutorialSlide {
  final IconData icon;
  final String title;
  final String description;
  final Color backgroundColor;

  TutorialSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.backgroundColor,
  });
}