import 'dart:convert';

import 'package:best_flutter_ui_templates/services/classroom_api_service.dart';
import 'package:googleapis/classroom/v1.dart' as classroom;
import 'package:shared_preferences/shared_preferences.dart';

class ClassroomDataService {
  ClassroomDataService._internal();

  static final ClassroomDataService instance =
  ClassroomDataService._internal();

  static const int keepLateTasksForDays = 7;
  static const int keepNoDueDateTasksForDays = 60;

  static const String _coursesCacheKey = 'offline_cached_courses';
  static const String _tasksCacheKey = 'offline_cached_tasks';
  static const String _lastSyncCacheKey = 'offline_last_sync_time';

  List<RealClassroomCourse>? _cachedCourses;
  List<RealClassroomTask>? _cachedTasks;
  DateTime? _lastSyncTime;
  bool _isUsingOfflineData = false;

  DateTime? get lastSyncTime => _lastSyncTime;

  bool get isUsingOfflineData => _isUsingOfflineData;

  bool get hasCachedData {
    return _cachedCourses != null && _cachedTasks != null;
  }

  String get lastSyncText {
    if (_lastSyncTime == null) {
      return 'Not synced yet';
    }

    final DateTime now = DateTime.now();
    final DateTime syncDay = DateTime(
      _lastSyncTime!.year,
      _lastSyncTime!.month,
      _lastSyncTime!.day,
    );
    final DateTime today = DateTime(now.year, now.month, now.day);

    final String hour = _lastSyncTime!.hour.toString().padLeft(2, '0');
    final String minute = _lastSyncTime!.minute.toString().padLeft(2, '0');

    if (syncDay == today) {
      return _isUsingOfflineData
          ? 'Offline data from today at $hour:$minute'
          : 'Today at $hour:$minute';
    }

    return _isUsingOfflineData
        ? 'Offline data from ${_lastSyncTime!.day}/${_lastSyncTime!.month}/${_lastSyncTime!.year} at $hour:$minute'
        : '${_lastSyncTime!.day}/${_lastSyncTime!.month}/${_lastSyncTime!.year} at $hour:$minute';
  }

  Future<void> preloadClassroomData() async {
    await loadOfflineCache();

    try {
      await GoogleLoginService.instance.signInSilently();
    } catch (_) {
      // Keep app fast. Dashboard will handle sync/refresh later.
    }
  }

  Future<bool> loadOfflineCache() async {
    final bool coursesLoaded = await _loadCoursesFromLocalCache();
    final bool tasksLoaded = await _loadTasksFromLocalCache();
    await _loadLastSyncTimeFromLocalCache();

    _isUsingOfflineData = coursesLoaded || tasksLoaded;

    return coursesLoaded || tasksLoaded;
  }

  Future<List<RealClassroomCourse>> getCourses({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedCourses != null) {
      return _cachedCourses!;
    }

    try {
      final classroom.ClassroomApi api =
      await GoogleLoginService.instance.getClassroomApi();

      final classroom.ListCoursesResponse response =
      await api.courses.list(pageSize: 100);

      final List<classroom.Course> courses =
          response.courses ?? <classroom.Course>[];

      final List<RealClassroomCourse> activeCourses = courses
          .where((classroom.Course course) {
        final String state = (course.courseState ?? '').toUpperCase();
        return course.id != null && state == 'ACTIVE';
      })
          .map(
            (classroom.Course course) => RealClassroomCourse(
          id: course.id ?? '',
          name: course.name ?? 'Untitled Course',
          section: course.section ?? '',
          descriptionHeading: course.descriptionHeading ?? '',
          courseState: course.courseState ?? '',
          alternateLink: course.alternateLink ?? '',
        ),
      )
          .toList();

      _cachedCourses = activeCourses;
      _lastSyncTime = DateTime.now();
      _isUsingOfflineData = false;

      await _saveCoursesToLocalCache(activeCourses);
      await _saveLastSyncTimeToLocalCache();

      return activeCourses;
    } catch (_) {
      final bool loaded = await _loadCoursesFromLocalCache();
      await _loadLastSyncTimeFromLocalCache();

      if (loaded && _cachedCourses != null) {
        _isUsingOfflineData = true;
        return _cachedCourses!;
      }

      rethrow;
    }
  }
  Future<List<RealClassroomTask>> getCourseWorkForCourse({
    required String courseId,
    required String courseName,
  }) async {
    try {
      final classroom.ClassroomApi api =
      await GoogleLoginService.instance.getClassroomApi();

      final List<classroom.CourseWork> courseWork =
      await _getAllCourseWorkForSingleCourse(
        api: api,
        courseId: courseId,
      );

      final Map<String, classroom.StudentSubmission> submissionMap =
      await _getStudentSubmissionMapForCourse(
        api: api,
        courseId: courseId,
      );

      final List<RealClassroomTask> tasks = <RealClassroomTask>[];

      for (final classroom.CourseWork work in courseWork) {
        if (work.id == null) {
          continue;
        }

        final classroom.StudentSubmission? submission =
        submissionMap[work.id];

        final RealClassroomTask task = RealClassroomTask(
          id: work.id ?? '',
          courseId: courseId,
          courseName: courseName,
          title: work.title ?? 'Untitled Assignment',
          description: work.description ?? '',
          state: work.state ?? '',
          workType: work.workType ?? '',
          alternateLink: work.alternateLink ?? '',
          maxPoints: work.maxPoints,
          dueDateTime: parseDueDateTime(
            date: work.dueDate,
            time: work.dueTime,
          ),
          createdAt: DateTime.tryParse(work.creationTime ?? ''),
          updatedAt: DateTime.tryParse(work.updateTime ?? ''),
          submissionState: submission?.state ?? '',
          isLateSubmission: submission?.late ?? false,
          assignedGrade: submission?.assignedGrade,
          draftGrade: submission?.draftGrade,
        );

        if (isRelevantTask(task)) {
          tasks.add(task);
        }
      }

      return tasks;
    } catch (_) {
      if (_cachedTasks == null) {
        await _loadTasksFromLocalCache();
        await _loadLastSyncTimeFromLocalCache();
      }

      _isUsingOfflineData = true;

      return (_cachedTasks ?? <RealClassroomTask>[])
          .where((RealClassroomTask task) => task.courseId == courseId)
          .toList();
    }
  }

  Future<List<classroom.CourseWork>> _getAllCourseWorkForSingleCourse({
    required classroom.ClassroomApi api,
    required String courseId,
  }) async {
    final List<classroom.CourseWork> allCourseWork =
    <classroom.CourseWork>[];

    String? pageToken;

    do {
      final classroom.ListCourseWorkResponse response =
      await api.courses.courseWork.list(
        courseId,
        pageSize: 100,
        pageToken: pageToken,
      );

      allCourseWork.addAll(response.courseWork ?? <classroom.CourseWork>[]);

      pageToken = response.nextPageToken;
    } while (pageToken != null && pageToken!.isNotEmpty);

    return allCourseWork;
  }

  Future<Map<String, classroom.StudentSubmission>>
  _getStudentSubmissionMapForCourse({
    required classroom.ClassroomApi api,
    required String courseId,
  }) async {
    final Map<String, classroom.StudentSubmission> submissionMap =
    <String, classroom.StudentSubmission>{};

    try {
      String? pageToken;

      do {
        final classroom.ListStudentSubmissionsResponse response =
        await api.courses.courseWork.studentSubmissions.list(
          courseId,
          '-',
          userId: 'me',
          pageSize: 100,
          pageToken: pageToken,
        );

        final List<classroom.StudentSubmission> submissions =
            response.studentSubmissions ?? <classroom.StudentSubmission>[];

        for (final classroom.StudentSubmission submission in submissions) {
          final String? courseWorkId = submission.courseWorkId;

          if (courseWorkId != null && courseWorkId.isNotEmpty) {
            submissionMap[courseWorkId] = submission;
          }
        }

        pageToken = response.nextPageToken;
      } while (pageToken != null && pageToken!.isNotEmpty);
    } catch (_) {
      return submissionMap;
    }

    return submissionMap;
  }

  Future<List<RealClassroomTask>> getAllCourseWork({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedTasks != null) {
      return _cachedTasks!;
    }

    try {
      final List<RealClassroomCourse> courses = await getCourses(
        forceRefresh: forceRefresh,
      );

      await GoogleLoginService.instance.getClassroomApi();

      final List<RealClassroomTask> tasks = <RealClassroomTask>[];
      int failedCourseCount = 0;

      for (final RealClassroomCourse course in courses) {
        try {
          final List<RealClassroomTask> courseTasks =
          await getCourseWorkForCourse(
            courseId: course.id,
            courseName: course.name,
          );

          tasks.addAll(courseTasks);
        } catch (_) {
          failedCourseCount++;
        }
      }

      if (tasks.isEmpty &&
          courses.isNotEmpty &&
          failedCourseCount == courses.length) {
        final bool loaded = await _loadTasksFromLocalCache();
        await _loadLastSyncTimeFromLocalCache();

        if (loaded && _cachedTasks != null) {
          _isUsingOfflineData = true;
          return _cachedTasks!;
        }
      }

      tasks.sort(sortTasksByDueDate);

      _cachedTasks = tasks;
      _lastSyncTime = DateTime.now();
      _isUsingOfflineData = false;

      await _saveTasksToLocalCache(tasks);
      await _saveLastSyncTimeToLocalCache();

      return tasks;
    } catch (_) {
      final bool loaded = await _loadTasksFromLocalCache();
      await _loadLastSyncTimeFromLocalCache();

      if (loaded && _cachedTasks != null) {
        _isUsingOfflineData = true;
        return _cachedTasks!;
      }

      return <RealClassroomTask>[];
    }
  }

  Future<void> refreshAllData() async {
    try {
      await getCourses(forceRefresh: true);
      await getAllCourseWork(forceRefresh: true);
    } catch (_) {
      await loadOfflineCache();
    }
  }

  Future<void> clearCache() async {
    _cachedCourses = null;
    _cachedTasks = null;
    _lastSyncTime = null;
    _isUsingOfflineData = false;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_coursesCacheKey);
    await prefs.remove(_tasksCacheKey);
    await prefs.remove(_lastSyncCacheKey);
  }

  Future<void> _saveCoursesToLocalCache(
      List<RealClassroomCourse> courses,
      ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String encodedCourses = jsonEncode(
      courses
          .map((RealClassroomCourse course) => course.toJson())
          .toList(),
    );

    await prefs.setString(_coursesCacheKey, encodedCourses);
  }

  Future<void> _saveTasksToLocalCache(
      List<RealClassroomTask> tasks,
      ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String encodedTasks = jsonEncode(
      tasks.map((RealClassroomTask task) => task.toJson()).toList(),
    );

    await prefs.setString(_tasksCacheKey, encodedTasks);
  }

  Future<void> _saveLastSyncTimeToLocalCache() async {
    if (_lastSyncTime == null) {
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncCacheKey, _lastSyncTime!.toIso8601String());
  }

  Future<bool> _loadCoursesFromLocalCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? encodedCourses = prefs.getString(_coursesCacheKey);

    if (encodedCourses == null || encodedCourses.isEmpty) {
      return false;
    }

    try {
      final List<dynamic> decodedCourses =
      jsonDecode(encodedCourses) as List<dynamic>;

      _cachedCourses = decodedCourses
          .map(
            (dynamic item) => RealClassroomCourse.fromJson(
          Map<String, dynamic>.from(item as Map),
        ),
      )
          .toList();

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _loadTasksFromLocalCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? encodedTasks = prefs.getString(_tasksCacheKey);

    if (encodedTasks == null || encodedTasks.isEmpty) {
      return false;
    }

    try {
      final List<dynamic> decodedTasks = jsonDecode(encodedTasks) as List<dynamic>;

      _cachedTasks = decodedTasks
          .map(
            (dynamic item) => RealClassroomTask.fromJson(
          Map<String, dynamic>.from(item as Map),
        ),
      )
          .toList();

      _cachedTasks!.sort(sortTasksByDueDate);

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadLastSyncTimeFromLocalCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? lastSyncString = prefs.getString(_lastSyncCacheKey);

    if (lastSyncString == null || lastSyncString.isEmpty) {
      return;
    }

    _lastSyncTime = DateTime.tryParse(lastSyncString);
  }

  bool isRelevantTask(RealClassroomTask task) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    final DateTime oldDueLimit =
    today.subtract(const Duration(days: keepLateTasksForDays));

    final DateTime noDueDateLimit =
    now.subtract(const Duration(days: keepNoDueDateTasksForDays));

    if (task.dueDateTime != null) {
      final DateTime dueDay = DateTime(
        task.dueDateTime!.year,
        task.dueDateTime!.month,
        task.dueDateTime!.day,
      );

      return !dueDay.isBefore(oldDueLimit);
    }

    final DateTime? referenceDate = task.updatedAt ?? task.createdAt;

    if (referenceDate == null) {
      return false;
    }

    return referenceDate.isAfter(noDueDateLimit);
  }

  int sortTasksByDueDate(RealClassroomTask a, RealClassroomTask b) {
    final DateTime? aDate = a.dueDateTime;
    final DateTime? bDate = b.dueDateTime;

    if (aDate == null && bDate == null) {
      final DateTime aUpdated = a.updatedAt ?? a.createdAt ?? DateTime(2000);
      final DateTime bUpdated = b.updatedAt ?? b.createdAt ?? DateTime(2000);
      return bUpdated.compareTo(aUpdated);
    }

    if (aDate == null) {
      return 1;
    }

    if (bDate == null) {
      return -1;
    }

    return aDate.compareTo(bDate);
  }

  DateTime? parseDueDateTime({
    required classroom.Date? date,
    required classroom.TimeOfDay? time,
  }) {
    if (date == null ||
        date.year == null ||
        date.month == null ||
        date.day == null) {
      return null;
    }

    return DateTime(
      date.year!,
      date.month!,
      date.day!,
      time?.hours ?? 23,
      time?.minutes ?? 59,
    );
  }
}

class RealClassroomCourse {
  const RealClassroomCourse({
    required this.id,
    required this.name,
    required this.section,
    required this.descriptionHeading,
    required this.courseState,
    required this.alternateLink,
  });

  factory RealClassroomCourse.fromJson(Map<String, dynamic> json) {
    return RealClassroomCourse(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Course',
      section: json['section'] as String? ?? '',
      descriptionHeading: json['descriptionHeading'] as String? ?? '',
      courseState: json['courseState'] as String? ?? '',
      alternateLink: json['alternateLink'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String section;
  final String descriptionHeading;
  final String courseState;
  final String alternateLink;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'section': section,
      'descriptionHeading': descriptionHeading,
      'courseState': courseState,
      'alternateLink': alternateLink,
    };
  }
}

class RealClassroomTask {
  const RealClassroomTask({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.title,
    required this.description,
    required this.state,
    required this.workType,
    required this.alternateLink,
    required this.maxPoints,
    required this.dueDateTime,
    required this.createdAt,
    required this.updatedAt,
    required this.submissionState,
    required this.isLateSubmission,
    required this.assignedGrade,
    required this.draftGrade,
  });

  factory RealClassroomTask.fromJson(Map<String, dynamic> json) {
    return RealClassroomTask(
      id: json['id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      courseName: json['courseName'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Assignment',
      description: json['description'] as String? ?? '',
      state: json['state'] as String? ?? '',
      workType: json['workType'] as String? ?? '',
      alternateLink: json['alternateLink'] as String? ?? '',
      maxPoints: (json['maxPoints'] as num?)?.toDouble(),
      dueDateTime: DateTime.tryParse(json['dueDateTime'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      submissionState: json['submissionState'] as String? ?? '',
      isLateSubmission: json['isLateSubmission'] as bool? ?? false,
      assignedGrade: (json['assignedGrade'] as num?)?.toDouble(),
      draftGrade: (json['draftGrade'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String courseId;
  final String courseName;
  final String title;
  final String description;
  final String state;
  final String workType;
  final String alternateLink;
  final double? maxPoints;
  final DateTime? dueDateTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String submissionState;
  final bool isLateSubmission;
  final double? assignedGrade;
  final double? draftGrade;

  bool get isSubmitted {
    final String value = submissionState.toUpperCase();

    return value == 'TURNED_IN' ||
        value == 'RETURNED' ||
        value == 'SUBMITTED';
  }

  bool get isLateNotSubmitted {
    if (isSubmitted) {
      return false;
    }

    if (isLateSubmission) {
      return true;
    }

    if (dueDateTime == null) {
      return false;
    }

    return dueDateTime!.isBefore(DateTime.now());
  }

  String get submissionStatus {
    if (isSubmitted) {
      return 'Submitted';
    }

    if (isLateNotSubmitted) {
      return 'Late Not Submitted';
    }

    return 'Pending';
  }

  String get gradeText {
    final double? grade = assignedGrade ?? draftGrade;

    if (grade == null) {
      return 'Not graded';
    }

    if (maxPoints == null) {
      return grade.toStringAsFixed(1);
    }

    return '${grade.toStringAsFixed(1)} / ${maxPoints!.toStringAsFixed(1)}';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'courseId': courseId,
      'courseName': courseName,
      'title': title,
      'description': description,
      'state': state,
      'workType': workType,
      'alternateLink': alternateLink,
      'maxPoints': maxPoints,
      'dueDateTime': dueDateTime?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'submissionState': submissionState,
      'isLateSubmission': isLateSubmission,
      'assignedGrade': assignedGrade,
      'draftGrade': draftGrade,
    };
  }
}