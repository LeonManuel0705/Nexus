class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  Future<void> initialize() async {
  }

  Future<void> registerTasks() async {
  }

  Future<void> cancelAllTasks() async {
  }

  Future<void> cancelTask(String taskName) async {
  }

  Future<void> syncNow() async {
  }
}
