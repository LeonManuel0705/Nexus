// SPDX-FileCopyrightText: 2026 Leon Manuel Töpper
// SPDX-License-Identifier: AGPL-3.0-only

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
