import 'package:best_flutter_ui_templates/app_theme.dart';
import 'package:best_flutter_ui_templates/services/classroom_data_service.dart';
import 'package:best_flutter_ui_templates/services/google_login_service.dart';
import 'package:best_flutter_ui_templates/tasks_screen.dart';
import 'package:best_flutter_ui_templates/widgets/app_state_widgets.dart';
import 'package:flutter/material.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen>
    with TickerProviderStateMixin {
  late AnimationController animationController;

  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  String selectedCategory = 'All';
  int selectedCourseIndex = 0;
  double topBarOpacity = 0.0;

  bool isLoading = true;
  String errorText = '';

  List<RealClassroomCourse> realCourses = <RealClassroomCourse>[];

  final List<String> categories = const <String>[
    'All',
    'Active',
    'Archived',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    scrollController.addListener(updateTopBarOpacity);
    animationController.forward();

    loadCourses();
  }

  void updateTopBarOpacity() {
    final double opacity =
    (scrollController.offset / 24).clamp(0.0, 1.0).toDouble();

    if (topBarOpacity != opacity) {
      setState(() {
        topBarOpacity = opacity;
      });
    }
  }

  Future<void> loadCourses({bool forceRefresh = false}) async {
    setState(() {
      isLoading = true;
      errorText = '';
    });

    try {
      await GoogleLoginService.instance.signInSilently();

      final List<RealClassroomCourse> fetchedCourses =
      await ClassroomDataService.instance.getCourses(
        forceRefresh: forceRefresh,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        realCourses = fetchedCourses;
        selectedCourseIndex = 0;
        isLoading = false;
        errorText = '';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorText = error.toString();
      });
    }
  }

  List<CourseViewData> get courses {
    return realCourses.asMap().entries.map(
          (MapEntry<int, RealClassroomCourse> entry) {
        return CourseViewData.fromRealCourse(entry.value, entry.key);
      },
    ).toList();
  }

  List<CourseViewData> get visibleCourses {
    final String query = searchController.text.toLowerCase().trim();

    return courses.where((CourseViewData course) {
      final bool categoryOk =
          selectedCategory == 'All' || course.category == selectedCategory;

      final bool searchOk = query.isEmpty ||
          course.title.toLowerCase().contains(query) ||
          course.teacher.toLowerCase().contains(query) ||
          course.category.toLowerCase().contains(query);

      return categoryOk && searchOk;
    }).toList();
  }

  CourseViewData? get selectedCourse {
    final List<CourseViewData> list = visibleCourses;

    if (list.isEmpty) {
      return null;
    }

    final int safeIndex = selectedCourseIndex >= list.length
        ? 0
        : selectedCourseIndex;

    return list[safeIndex];
  }

  @override
  void dispose() {
    animationController.dispose();
    scrollController.removeListener(updateTopBarOpacity);
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
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
            buildBody(isLightMode),
            buildAppBar(isLightMode),
          ],
        ),
      ),
    );
  }

  Widget buildBody(bool isLightMode) {
    return RefreshIndicator(
      color: const Color(0xFF2633C5),
      backgroundColor: isLightMode ? Colors.white : AppTheme.nearlyBlack,
      onRefresh: () async {
        await loadCourses(forceRefresh: true);
      },
      child: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          top: AppBar().preferredSize.height +
              MediaQuery.of(context).padding.top +
              28,
          bottom: 32 + MediaQuery.of(context).padding.bottom,
        ),
        children: <Widget>[
          animatedWidget(0, buildHeaderCard(isLightMode)),
          animatedWidget(1, buildSearchBox(isLightMode)),
          animatedWidget(2, buildCategorySection(isLightMode)),
          animatedWidget(
            3,
            buildSectionTitle(
              title: 'Classroom Courses',
              subtitle:
              isLoading ? 'Loading' : '${visibleCourses.length} found',
              isLightMode: isLightMode,
            ),
          ),
          if (isLoading) animatedWidget(4, loadingCard(isLightMode)),
          if (!isLoading && errorText.isNotEmpty)
            animatedWidget(4, errorCard(isLightMode)),
          if (!isLoading && errorText.isEmpty && visibleCourses.isEmpty)
            animatedWidget(4, emptyCard(isLightMode)),
          if (!isLoading && errorText.isEmpty && visibleCourses.isNotEmpty)
            animatedWidget(4, buildCourseList(isLightMode)),
          if (!isLoading && errorText.isEmpty && selectedCourse != null)
            animatedWidget(5, buildCourseDetail(isLightMode)),
        ],
      ),
    );
  }

  Widget animatedWidget(int index, Widget child) {
    final Animation<double> animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(
          index * 0.10,
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
              30 * (1.0 - animation.value),
              0.0,
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget buildAppBar(bool isLightMode) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: (isLightMode ? Colors.white : AppTheme.nearlyBlack)
                .withOpacity(topBarOpacity),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: isLightMode
                    ? AppTheme.grey.withOpacity(0.35 * topBarOpacity)
                    : Colors.black.withOpacity(0.40 * topBarOpacity),
                blurRadius: 10,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).padding.top),
              Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16 - 8 * topBarOpacity,
                  bottom: 12 - 8 * topBarOpacity,
                ),
                child: Row(
                  children: <Widget>[
                    circleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      isLightMode: isLightMode,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Courses',
                        style: TextStyle(
                          fontFamily: AppTheme.fontName,
                          fontSize: 28 - 6 * topBarOpacity,
                          fontWeight: FontWeight.w800,
                          color:
                          isLightMode ? AppTheme.darkText : AppTheme.white,
                        ),
                      ),
                    ),
                    circleButton(
                      icon: Icons.refresh_rounded,
                      isLightMode: isLightMode,
                      onTap: () => loadCourses(forceRefresh: true),
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

  Widget circleButton({
    required IconData icon,
    required bool isLightMode,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
          boxShadow: cardShadow(isLightMode),
        ),
        child: Icon(
          icon,
          color: isLightMode ? const Color(0xFF2633C5) : Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget buildHeaderCard(bool isLightMode) {
    final CourseViewData? course = selectedCourse;

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(22),
            topRight: Radius.circular(76),
          ),
          boxShadow: cardShadow(isLightMode),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Choose your',
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 13,
                      color: isLightMode
                          ? AppTheme.grey
                          : AppTheme.white.withOpacity(0.65),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Classroom Course',
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isLightMode ? AppTheme.darkText : AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Real courses are loaded from your signed-in Google Classroom account.',
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 12.5,
                      height: 1.35,
                      color: isLightMode
                          ? AppTheme.grey
                          : AppTheme.white.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            courseIconBox(
              course ?? CourseViewData.placeholder(),
              86,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSearchBox(bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 14),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          boxShadow: cardShadow(isLightMode),
        ),
        child: TextField(
          controller: searchController,
          onChanged: (_) {
            setState(() {
              selectedCourseIndex = 0;
            });
          },
          style: TextStyle(
            fontFamily: AppTheme.fontName,
            color: isLightMode ? AppTheme.darkText : AppTheme.white,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: 'Search for course',
            hintStyle: TextStyle(
              color: isLightMode
                  ? AppTheme.grey.withOpacity(0.75)
                  : AppTheme.white.withOpacity(0.45),
              fontSize: 13,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isLightMode ? AppTheme.grey : Colors.white54,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.only(top: 12),
          ),
        ),
      ),
    );
  }

  Widget buildCategorySection(bool isLightMode) {
    return Column(
      children: <Widget>[
        buildSectionTitle(
          title: 'Category',
          subtitle: selectedCategory,
          isLightMode: isLightMode,
        ),
        SizedBox(
          height: 44,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 20, right: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            itemBuilder: (BuildContext context, int index) {
              final String category = categories[index];
              final bool selected = selectedCategory == category;

              return Padding(
                padding: const EdgeInsets.only(left: 4, right: 8, bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                      selectedCourseIndex = 0;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const LinearGradient(
                        colors: <Color>[
                          Color(0xFF2633C5),
                          Color(0xFF6A88E5),
                        ],
                      )
                          : null,
                      color: selected
                          ? null
                          : isLightMode
                          ? Colors.white
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          fontFamily: AppTheme.fontName,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : isLightMode
                              ? AppTheme.darkText
                              : AppTheme.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildSectionTitle({
    required String title,
    required String subtitle,
    required bool isLightMode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 6, bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isLightMode ? AppTheme.darkText : AppTheme.white,
              ),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: AppTheme.fontName,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isLightMode
                  ? AppTheme.grey
                  : AppTheme.white.withOpacity(0.62),
            ),
          ),
        ],
      ),
    );
  }

  Widget loadingCard(bool isLightMode) {
    return const AppLoadingCard(
      title: 'Loading courses...',
      subtitle: 'Fetching your Google Classroom courses.',
      icon: Icons.cloud_sync_rounded,
      color: Color(0xFF42A5F5),
    );
  }

  Widget errorCard(bool isLightMode) {
    return AppErrorCard(
      title: 'Unable to load courses',
      subtitle: errorText,
      icon: Icons.error_outline_rounded,
      color: const Color(0xFFEF5350),
      onRetry: () {
        loadCourses(forceRefresh: true);
      },
    );
  }

  Widget emptyCard(bool isLightMode) {
    return AppEmptyCard(
      title: 'No courses found',
      subtitle: selectedCategory == 'All'
          ? 'No Google Classroom courses were found for this account.'
          : 'No course matched the "$selectedCategory" category.',
      icon: Icons.school_rounded,
      color: const Color(0xFFFFA726),
      buttonText: 'Refresh',
      onButtonTap: () {
        loadCourses(forceRefresh: true);
      },
    );
  }

  Widget buildCourseList(bool isLightMode) {
    final List<CourseViewData> list = visibleCourses;

    return SizedBox(
      height: 166,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (BuildContext context, int index) {
          return CourseSmallCard(
            course: list[index],
            isSelected: selectedCourseIndex == index,
            isLightMode: isLightMode,
            onTap: () {
              setState(() {
                selectedCourseIndex = index;
              });
            },
          );
        },
      ),
    );
  }

  Widget buildCourseDetail(bool isLightMode) {
    final CourseViewData? course = selectedCourse;

    if (course == null) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(26),
            bottomLeft: Radius.circular(26),
            bottomRight: Radius.circular(26),
            topRight: Radius.circular(82),
          ),
          boxShadow: cardShadow(isLightMode),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(child: courseIconBox(course, 130)),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    course.title,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: isLightMode ? AppTheme.darkText : AppTheme.white,
                    ),
                  ),
                ),
                Container(
                  height: 42,
                  width: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00AEEF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              course.teacher,
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: course.color,
              ),
            ),
            const SizedBox(height: 14),
            progressRow(course, isLightMode),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                detailBox(course.classes.toString(), 'Classes', isLightMode),
                const SizedBox(width: 10),
                detailBox(course.hours, 'Source', isLightMode),
                const SizedBox(width: 10),
                detailBox(
                  course.pendingTasks.toString(),
                  'Pending',
                  isLightMode,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              course.description,
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontSize: 12.5,
                height: 1.45,
                color: isLightMode
                    ? AppTheme.grey
                    : AppTheme.white.withOpacity(0.68),
              ),
            ),
            const SizedBox(height: 18),
            openTasksButton(),
          ],
        ),
      ),
    );
  }

  Widget progressRow(CourseViewData course, bool isLightMode) {
    return Row(
      children: <Widget>[
        Text(
          '${(course.progress * 100).round()}%',
          style: TextStyle(
            fontFamily: AppTheme.fontName,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: course.color,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: course.progress,
              minHeight: 8,
              backgroundColor: course.color.withOpacity(0.13),
              valueColor: AlwaysStoppedAnimation<Color>(course.color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${course.rating} ★',
          style: TextStyle(
            fontFamily: AppTheme.fontName,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isLightMode ? AppTheme.darkText : AppTheme.white,
          ),
        ),
      ],
    );
  }

  Widget detailBox(String value, String label, bool isLightMode) {
    return Expanded(
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: isLightMode
              ? const Color(0xFFF6F7FB)
              : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: isLightMode ? AppTheme.darkText : AppTheme.white,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontWeight: FontWeight.w500,
                fontSize: 10.5,
                color: isLightMode
                    ? AppTheme.grey
                    : AppTheme.white.withOpacity(0.60),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget openTasksButton() {
    return Row(
      children: <Widget>[
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F3F8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: AppTheme.grey,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) =>
                  const TasksScreen(initialFilter: 'All'),
                ),
              );
            },
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[
                    Color(0xFF00AEEF),
                    Color(0xFF2633C5),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'Open Tasks',
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget courseIconBox(CourseViewData course, double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: course.color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          height: size * 0.54,
          width: size * 0.54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                course.color,
                course.color.withOpacity(0.65),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.15),
          ),
          child: Icon(
            course.icon,
            color: Colors.white,
            size: size * 0.30,
          ),
        ),
      ),
    );
  }

  List<BoxShadow> cardShadow(bool isLightMode) {
    return <BoxShadow>[
      BoxShadow(
        color: isLightMode
            ? AppTheme.grey.withOpacity(0.15)
            : Colors.black.withOpacity(0.22),
        offset: const Offset(1, 3),
        blurRadius: 10,
      ),
    ];
  }
}

class CourseSmallCard extends StatelessWidget {
  const CourseSmallCard({
    super.key,
    required this.course,
    required this.isSelected,
    required this.isLightMode,
    required this.onTap,
  });

  final CourseViewData course;
  final bool isSelected;
  final bool isLightMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? course.color : Colors.transparent,
                width: 1.4,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: isLightMode
                      ? AppTheme.grey.withOpacity(0.14)
                      : Colors.black.withOpacity(0.20),
                  offset: const Offset(1, 3),
                  blurRadius: 9,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: course.color.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        course.icon,
                        color: course.color,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${course.rating} ★',
                      style: TextStyle(
                        fontFamily: AppTheme.fontName,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: course.color,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isLightMode ? AppTheme.darkText : AppTheme.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  course.teacher,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontSize: 11,
                    color: isLightMode
                        ? AppTheme.grey
                        : AppTheme.white.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: course.progress,
                    minHeight: 6,
                    backgroundColor: course.color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(course.color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CourseViewData {
  const CourseViewData({
    required this.title,
    required this.teacher,
    required this.category,
    required this.progress,
    required this.rating,
    required this.pendingTasks,
    required this.classes,
    required this.hours,
    required this.color,
    required this.icon,
    required this.description,
  });

  factory CourseViewData.fromRealCourse(
      RealClassroomCourse course,
      int index,
      ) {
    final Color color = _colors[index % _colors.length];
    final IconData icon = _icons[index % _icons.length];

    final String category = course.courseState.toUpperCase() == 'ACTIVE'
        ? 'Active'
        : course.courseState.toUpperCase() == 'ARCHIVED'
        ? 'Archived'
        : 'Other';

    final double progress = 0.55 + ((index % 4) * 0.10);
    final double rating = 4.2 + ((index % 4) * 0.1);

    return CourseViewData(
      title: course.name,
      teacher: course.section.isNotEmpty
          ? course.section
          : course.descriptionHeading.isNotEmpty
          ? course.descriptionHeading
          : course.courseState.isNotEmpty
          ? course.courseState
          : 'Google Classroom',
      category: category,
      progress: progress.clamp(0.0, 0.95),
      rating: double.parse(rating.toStringAsFixed(1)),
      pendingTasks: 0,
      classes: index + 1,
      hours: 'API',
      color: color,
      icon: icon,
      description: course.descriptionHeading.isNotEmpty
          ? course.descriptionHeading
          : 'This course is loaded from your real Google Classroom account using Google Classroom API.',
    );
  }

  factory CourseViewData.placeholder() {
    return const CourseViewData(
      title: 'Google Classroom',
      teacher: 'Real API Data',
      category: 'All',
      progress: 0.7,
      rating: 4.5,
      pendingTasks: 0,
      classes: 0,
      hours: 'API',
      color: Color(0xFF42A5F5),
      icon: Icons.menu_book_rounded,
      description: 'Real classroom course data will appear here.',
    );
  }

  static const List<Color> _colors = <Color>[
    Color(0xFF42A5F5),
    Color(0xFF738AE6),
    Color(0xFF66BB6A),
    Color(0xFFFFA726),
    Color(0xFFEF5350),
  ];

  static const List<IconData> _icons = <IconData>[
    Icons.menu_book_rounded,
    Icons.school_rounded,
    Icons.assignment_rounded,
    Icons.psychology_rounded,
    Icons.storage_rounded,
  ];

  final String title;
  final String teacher;
  final String category;
  final double progress;
  final double rating;
  final int pendingTasks;
  final int classes;
  final String hours;
  final Color color;
  final IconData icon;
  final String description;
}