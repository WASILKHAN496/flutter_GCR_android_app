import 'package:best_flutter_ui_templates/app_theme.dart';
import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with TickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> topBarAnimation;

  final ScrollController scrollController = ScrollController();
  final TextEditingController feedbackController = TextEditingController();

  double topBarOpacity = 0.0;
  int selectedRating = 4;
  String selectedCategory = 'UI';

  final List<FeedbackCategory> categories = <FeedbackCategory>[
    FeedbackCategory(
      title: 'UI',
      icon: Icons.dashboard_customize_rounded,
      color: Color(0xFF738AE6),
    ),
    FeedbackCategory(
      title: 'Tasks',
      icon: Icons.assignment_rounded,
      color: Color(0xFFFFA726),
    ),
    FeedbackCategory(
      title: 'Deadlines',
      icon: Icons.calendar_month_rounded,
      color: Color(0xFFEF5350),
    ),
    FeedbackCategory(
      title: 'Google Login',
      icon: Icons.login_rounded,
      color: Color(0xFF66BB6A),
    ),
    FeedbackCategory(
      title: 'Other',
      icon: Icons.more_horiz_rounded,
      color: Color(0xFF7E57C2),
    ),
  ];

  @override
  void initState() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    topBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0, 0.5, curve: Curves.fastOutSlowIn),
      ),
    );

    scrollController.addListener(() {
      if (scrollController.offset >= 24) {
        if (topBarOpacity != 1.0) {
          setState(() {
            topBarOpacity = 1.0;
          });
        }
      } else if (scrollController.offset <= 24 &&
          scrollController.offset >= 0) {
        if (topBarOpacity != scrollController.offset / 24) {
          setState(() {
            topBarOpacity = scrollController.offset / 24;
          });
        }
      } else if (scrollController.offset <= 0) {
        if (topBarOpacity != 0.0) {
          setState(() {
            topBarOpacity = 0.0;
          });
        }
      }
    });

    animationController.forward();
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    scrollController.dispose();
    feedbackController.dispose();
    super.dispose();
  }

  Future<bool> getData() async {
    await Future<dynamic>.delayed(const Duration(milliseconds: 50));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final bool isLightMode = Theme.of(context).brightness == Brightness.light;

    return Container(
      color: isLightMode ? const Color(0xFFF2F3F8) : AppTheme.nearlyBlack,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: <Widget>[
            getMainListViewUI(isLightMode),
            getAppBarUI(isLightMode),
          ],
        ),
      ),
    );
  }

  Widget getMainListViewUI(bool isLightMode) {
    return FutureBuilder<bool>(
      future: getData(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        return ListView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            top: AppBar().preferredSize.height +
                MediaQuery.of(context).padding.top +
                28,
            bottom: 32 + MediaQuery.of(context).padding.bottom,
          ),
          children: <Widget>[
            animatedItem(
              index: 0,
              count: 6,
              child: heroFeedbackCard(),
            ),
            animatedItem(
              index: 1,
              count: 6,
              child: sectionTitle(
                title: 'Your Experience',
                subtitle: 'Rate this app',
                isLightMode: isLightMode,
              ),
            ),
            animatedItem(
              index: 2,
              count: 6,
              child: ratingCard(isLightMode),
            ),
            animatedItem(
              index: 3,
              count: 6,
              child: sectionTitle(
                title: 'Feedback Type',
                subtitle: selectedCategory,
                isLightMode: isLightMode,
              ),
            ),
            animatedItem(
              index: 4,
              count: 6,
              child: categoryList(isLightMode),
            ),
            animatedItem(
              index: 5,
              count: 6,
              child: feedbackComposer(isLightMode),
            ),
          ],
        );
      },
    );
  }

  Widget animatedItem({
    required int index,
    required int count,
    required Widget child,
  }) {
    final Animation<double> animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(
          (1 / count) * index,
          1.0,
          curve: Curves.fastOutSlowIn,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animationController,
      builder: (BuildContext context, Widget? widgetChild) {
        return FadeTransition(
          opacity: animation,
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              35 * (1.0 - animation.value),
              0.0,
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget getAppBarUI(bool isLightMode) {
    return Column(
      children: <Widget>[
        AnimatedBuilder(
          animation: animationController,
          builder: (BuildContext context, Widget? child) {
            return FadeTransition(
              opacity: topBarAnimation,
              child: Transform(
                transform: Matrix4.translationValues(
                  0.0,
                  30 * (1.0 - topBarAnimation.value),
                  0.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: (isLightMode ? Colors.white : AppTheme.nearlyBlack)
                        .withOpacity(topBarOpacity),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32.0),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: isLightMode
                            ? AppTheme.grey.withOpacity(0.35 * topBarOpacity)
                            : Colors.black.withOpacity(0.40 * topBarOpacity),
                        offset: const Offset(1.1, 1.1),
                        blurRadius: 10.0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: MediaQuery.of(context).padding.top),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 58,
                          right: 16,
                          top: 16 - 8.0 * topBarOpacity,
                          bottom: 12 - 8.0 * topBarOpacity,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Feedback',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontName,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 28 - 6 * topBarOpacity,
                                  letterSpacing: 0.7,
                                  color: isLightMode
                                      ? AppTheme.darkText
                                      : AppTheme.white,
                                ),
                              ),
                            ),
                            Container(
                              height: 38,
                              width: 38,
                              decoration: BoxDecoration(
                                color: isLightMode
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.08),
                                shape: BoxShape.circle,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: isLightMode
                                        ? AppTheme.grey.withOpacity(0.18)
                                        : Colors.black.withOpacity(0.22),
                                    blurRadius: 8,
                                    offset: const Offset(1, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.feedback_rounded,
                                color: isLightMode
                                    ? const Color(0xFF2633C5)
                                    : Colors.white,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget heroFeedbackCard() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 18),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[
              Color(0xFFFE95B6),
              Color(0xFFFF5287),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18.0),
            bottomLeft: Radius.circular(18.0),
            bottomRight: Radius.circular(18.0),
            topRight: Radius.circular(72.0),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFFFF5287).withOpacity(0.30),
              offset: const Offset(4.0, 8.0),
              blurRadius: 16.0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 18,
            right: 18,
            top: 20,
            bottom: 20,
          ),
          child: Row(
            children: <Widget>[
              Container(
                height: 66,
                width: 66,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rate_review_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Help Us Improve',
                      style: TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Share your thoughts about the dashboard, deadlines, tasks or Google Classroom features.',
                      style: TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionTitle({
    required String title,
    required String subtitle,
    required bool isLightMode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: 0.3,
                color: isLightMode ? AppTheme.darkText : AppTheme.white,
              ),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: AppTheme.fontName,
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: isLightMode
                  ? AppTheme.grey
                  : AppTheme.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget ratingCard(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14.0),
            bottomLeft: Radius.circular(14.0),
            bottomRight: Radius.circular(14.0),
            topRight: Radius.circular(56.0),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: isLightMode
                  ? AppTheme.grey.withOpacity(0.16)
                  : Colors.black.withOpacity(0.22),
              offset: const Offset(1.1, 1.1),
              blurRadius: 10.0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'How was your experience?',
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isLightMode ? AppTheme.darkText : AppTheme.white,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List<Widget>.generate(5, (int index) {
                final int rating = index + 1;
                final bool isSelected = selectedRating >= rating;

                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    setState(() {
                      selectedRating = rating;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFA726).withOpacity(0.16)
                          : isLightMode
                          ? const Color(0xFFF2F3F8)
                          : Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSelected
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: isSelected
                          ? const Color(0xFFFFA726)
                          : isLightMode
                          ? AppTheme.grey
                          : Colors.white.withOpacity(0.55),
                      size: 28,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget categoryList(bool isLightMode) {
    return SizedBox(
      height: 118,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (BuildContext context, int index) {
          final FeedbackCategory category = categories[index];
          final bool isSelected = selectedCategory == category.title;

          return Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  selectedCategory = category.title;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 122,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                    colors: <Color>[
                      category.color,
                      category.color.withOpacity(0.72),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                  color: isSelected
                      ? null
                      : isLightMode
                      ? Colors.white
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: isSelected
                          ? category.color.withOpacity(0.28)
                          : isLightMode
                          ? AppTheme.grey.withOpacity(0.13)
                          : Colors.black.withOpacity(0.18),
                      offset: const Offset(1.1, 3.0),
                      blurRadius: 8.0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      category.icon,
                      color: isSelected
                          ? Colors.white
                          : isLightMode
                          ? category.color
                          : Colors.white,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isSelected
                            ? Colors.white
                            : isLightMode
                            ? AppTheme.darkText
                            : AppTheme.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget feedbackComposer(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 2, bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: isLightMode
                  ? AppTheme.grey.withOpacity(0.16)
                  : Colors.black.withOpacity(0.22),
              offset: const Offset(1.1, 1.1),
              blurRadius: 10.0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF42A5F5).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: Color(0xFF42A5F5),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Write your feedback',
                      style: TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isLightMode ? AppTheme.darkText : AppTheme.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                constraints: const BoxConstraints(
                  minHeight: 120,
                  maxHeight: 190,
                ),
                padding: const EdgeInsets.only(left: 14, right: 14),
                decoration: BoxDecoration(
                  color: isLightMode
                      ? const Color(0xFFF2F3F8)
                      : Colors.black.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: feedbackController,
                  maxLines: null,
                  cursorColor: Colors.blue,
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontSize: 15,
                    color: isLightMode ? AppTheme.darkText : AppTheme.white,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText:
                    'Example: Dashboard looks good, but I want real Google Classroom data soon...',
                    hintStyle: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 14,
                      color: isLightMode
                          ? AppTheme.grey
                          : AppTheme.white.withOpacity(0.45),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode());

                  final String feedback = feedbackController.text.trim();

                  if (feedback.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please write your feedback first.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  feedbackController.clear();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Thanks! Feedback submitted for $selectedCategory.',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[
                        Color(0xFF2633C5),
                        Color(0xFF6A88E5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF2633C5).withOpacity(0.24),
                        offset: const Offset(4, 8),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Send Feedback',
                      style: TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
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

class FeedbackCategory {
  FeedbackCategory({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;
}