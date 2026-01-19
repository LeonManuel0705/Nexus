import '../models/task.dart';
import '../models/event.dart';
import '../models/lesson.dart';
import '../models/drawing.dart';
import '../models/bookmark.dart';
import '../models/quick_note.dart';
import '../models/chat_message.dart';
import '../models/email.dart';
import '../models/vbb.dart';
import 'calendar_sync_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<List<Task>> getTasks() async => [];
  Future<List<Task>> getTodayTasks() async => [];
  Future<List<Task>> getOpenTasks() async => [];
  Future<void> insertTask(Task task) async {}
  Future<void> updateTask(Task task) async {}
  Future<void> deleteTask(String id) async {}
  Future<void> toggleTaskComplete(String id, bool completed) async {}

  Future<List<Event>> getEvents() async => [];
  Future<List<Event>> getTodayEvents() async => [];
  Future<List<Event>> getUpcomingEvents({int days = 7}) async => [];
  Future<void> insertEvent(Event event) async {}
  Future<void> updateEvent(Event event) async {}
  Future<void> deleteEvent(String id) async {}

  Future<List<Lesson>> getLessons() async => [];
  Future<List<Lesson>> getTodayLessons() async => [];
  Future<List<Lesson>> getLessonsByDay(int dayOfWeek) async => [];
  Future<void> insertLesson(Lesson lesson) async {}
  Future<void> updateLesson(Lesson lesson) async {}
  Future<void> deleteLesson(String id) async {}

  Future<int> getOpenTaskCount() async => 0;
  Future<int> getTodayEventCount() async => 0;

  Future<List<Drawing>> getDrawings() async => [];
  Future<Drawing?> getDrawing(String id) async => null;
  Future<void> insertDrawing(Drawing drawing) async {}
  Future<void> updateDrawing(Drawing drawing) async {}
  Future<void> deleteDrawing(String id) async {}

  Future<List<Bookmark>> getBookmarks() async => [];
  Future<List<Bookmark>> getBookmarksByCategory(String category) async => [];
  Future<void> insertBookmark(Bookmark bookmark) async {}
  Future<void> updateBookmark(Bookmark bookmark) async {}
  Future<void> deleteBookmark(String id) async {}

  Future<List<QuickNote>> getQuickNotes() async => [];
  Future<QuickNote?> getQuickNote(String id) async => null;
  Future<void> insertQuickNote(QuickNote note) async {}
  Future<void> updateQuickNote(QuickNote note) async {}
  Future<void> deleteQuickNote(String id) async {}

  Future<List<Map<String, dynamic>>> getSubjects() async => [];
  Future<int> insertSubject({required String name, String? shortName, String? color, String? teacher, String? room}) async => 0;
  Future<void> updateSubject(int id, {String? name, String? shortName, String? color, String? teacher, String? room}) async {}
  Future<void> deleteSubject(int id) async {}
  Future<List<Map<String, dynamic>>> getHomework() async => [];
  Future<List<Map<String, dynamic>>> getOpenHomework() async => [];
  Future<void> insertHomework({required String id, required String title, int? subjectId, String? notes, DateTime? dueDate}) async {}
  Future<void> updateHomework(String id, {String? title, int? subjectId, String? notes, DateTime? dueDate, bool? completed}) async {}
  Future<void> toggleHomeworkComplete(String id, bool completed) async {}
  Future<void> deleteHomework(String id) async {}

  Future<List<ChatMessage>> getChatMessages() async => [];
  Future<void> insertChatMessage(ChatMessage message) async {}
  Future<void> clearChatHistory() async {}

  Future<Map<String, dynamic>?> getSyncStatus(String tableName) async => null;
  Future<void> updateSyncStatus(String tableName, {String? syncToken, String? error}) async {}
  Future<List<Map<String, dynamic>>> getPendingOperations() async => [];
  Future<int> insertPendingOperation({required String operationType, required String entityType, String? entityId, String? payloadJson}) async => 0;
  Future<void> markOperationCompleted(int id) async {}
  Future<void> markOperationFailed(int id, String error) async {}
  Future<void> clearCompletedOperations() async {}
  Future<int> getPendingOperationCount() async => 0;

  Future<List<EmailAccount>> getEmailAccounts() async => [];
  Future<void> insertEmailAccount(EmailAccount account) async {}
  Future<void> updateEmailAccount(EmailAccount account) async {}
  Future<void> deleteEmailAccount(String id) async {}
  Future<List<EmailFolder>> getEmailFolders(String accountId) async => [];
  Future<void> insertEmailFolder(EmailFolder folder) async {}
  Future<void> updateEmailFolder(EmailFolder folder) async {}
  Future<List<Email>> getCachedEmails({required String accountId, required String folderId, int limit = 50, int offset = 0}) async => [];
  Future<Email?> getCachedEmail(String id) async => null;
  Future<void> insertCachedEmail(Email email) async {}
  Future<void> updateCachedEmail(Email email) async {}
  Future<void> deleteCachedEmail(String id) async {}

  Future<List<VbbLocation>> getCachedVbbLocations(String query) async => [];
  Future<void> cacheVbbLocations(String query, List<VbbLocation> locations) async {}
  Future<List<VbbJourney>> getCachedVbbRoutes(String cacheKey) async => [];
  Future<void> cacheVbbRoutes(String cacheKey, List<VbbJourney> journeys) async {}
  Future<List<VbbKnownLocation>> getVbbKnownLocations() async => [];
  Future<void> insertVbbKnownLocation(VbbKnownLocation location) async {}
  Future<void> deleteVbbKnownLocation(String id) async {}
  Future<List<VbbFavoriteRoute>> getVbbFavoriteRoutes() async => [];
  Future<void> insertVbbFavoriteRoute(VbbFavoriteRoute route) async {}
  Future<void> deleteVbbFavoriteRoute(String id) async {}
  Future<void> clearOldVbbCache() async {}

  Future<List<GoogleCalendar>> getGoogleCalendars() async => [];
  Future<void> upsertGoogleCalendar(GoogleCalendar calendar) async {}
  Future<GoogleEvent?> getGoogleEvent(String id) async => null;
  Future<List<GoogleEvent>> getGoogleEvents({required String calendarId, DateTime? from, DateTime? to}) async => [];
  Future<List<GoogleEvent>> getAllGoogleEvents({DateTime? from, DateTime? to}) async => [];
  Future<void> insertGoogleEvent(GoogleEvent event) async {}
  Future<void> updateGoogleEvent(GoogleEvent event) async {}
  Future<void> deleteGoogleEvent(String id) async {}
  Future<void> saveSyncToken(String calendarId, String token) async {}
  Future<String?> getSyncToken(String calendarId) async => null;

  Future<List<dynamic>> getTrainingSchedule({required bool isHoliday}) async => [];
  Future<void> saveTrainingSchedule(List<dynamic> schedule, {required bool isHoliday}) async {}
  Future<List<dynamic>> getTrainingSessionsList() async => [];
  Future<void> logTrainingSession(dynamic session) async {}
  Future<void> deleteTrainingSession(String id) async {}
  Future<List<dynamic>> getHealthLogsList() async => [];
  Future<void> saveHealthLog(dynamic log) async {}
  Future<List<dynamic>> getTrainingGoalsList() async => [];
  Future<void> saveTrainingGoal(dynamic goal) async {}
  Future<void> deleteTrainingGoal(String id) async {}
  Future<bool> getTrainingHolidayMode() async => false;
  Future<void> setTrainingHolidayMode(bool isHoliday) async {}

  Future<List<Map<String, dynamic>>> getProjectsList() async => [];
  Future<List<Map<String, dynamic>>> getProjectsByStatus(String status) async => [];
  Future<void> saveProject(Map<String, dynamic> project) async {}
  Future<void> updateProject(String id, Map<String, dynamic> updates) async {}
  Future<void> deleteProject(String id) async {}

  Future<dynamic> get database async => throw Exception('Database not available on web');
}
