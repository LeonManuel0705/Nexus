import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show ValueNotifier, kDebugMode;

enum FlaskServerState { idle, starting, ready, error, alreadyRunning }

enum SetupResult { success, brewNotFound, error }

class FlaskServerService {
  static final FlaskServerService _instance = FlaskServerService._internal();
  factory FlaskServerService() => _instance;
  FlaskServerService._internal();

  Process? _flaskProcess;
  bool _externalServer = false;
  String? _errorMessage;

  bool isPythonMissing = false;
  bool isSettingUp = false;
  final ValueNotifier<String> setupProgress = ValueNotifier('');

  final ValueNotifier<FlaskServerState> state =
      ValueNotifier(FlaskServerState.idle);

  String get errorMessage => _errorMessage ?? '';
  bool get isReady =>
      state.value == FlaskServerState.ready ||
      state.value == FlaskServerState.alreadyRunning;
  int get port => 5050;
  String get url => 'http://localhost:$port';

  Future<void> start() async {
    if (isReady) return;

    state.value = FlaskServerState.starting;
    _errorMessage = null;
    isPythonMissing = false;

    await _killExistingServerOnPort();

    await _extractBundledBackend();

    var root = await _resolveProjectRoot();
    if (root == null) {
      _errorMessage = 'Nexus-Projektordner nicht gefunden.\n'
          'Erwartet: ~/Documents/Nexus mit app/app.py';
      state.value = FlaskServerState.error;
      return;
    }

    final pythonPath = await _findPythonPath(root);
    if (pythonPath == null) {
      isPythonMissing = true;
      _errorMessage = 'Python 3 wurde nicht gefunden.\n'
          'Du kannst Python automatisch installieren lassen.';
      state.value = FlaskServerState.error;
      return;
    }
    await _syncPipDependencies(root, pythonPath);

    try {
      if (kDebugMode) {
        print('FlaskServer: Starting with $pythonPath in $root');
      }

      _flaskProcess = await Process.start(
        pythonPath,
        ['-m', 'app.app'],
        workingDirectory: root,
        environment: {
          ...Platform.environment,
          'NEXUS_HOST': '127.0.0.1',
          'FLASK_ENV': 'development',
        },
      );

      _flaskProcess!.stdout.transform(const SystemEncoding().decoder).listen(
        (data) {
          if (kDebugMode) print('Flask stdout: $data');
        },
      );

      _flaskProcess!.stderr.transform(const SystemEncoding().decoder).listen(
        (data) {
          if (kDebugMode) print('Flask stderr: $data');
        },
      );

      _flaskProcess!.exitCode.then((code) {
        if (state.value == FlaskServerState.ready ||
            state.value == FlaskServerState.starting) {
          if (kDebugMode) print('FlaskServer: Process exited with code $code');
          _errorMessage = 'Server unerwartet beendet (Code: $code)';
          state.value = FlaskServerState.error;
          _flaskProcess = null;
        }
      });

      final ready = await _waitForServer();
      if (ready) {
        state.value = FlaskServerState.ready;
        if (kDebugMode) print('FlaskServer: Ready on port $port');
      } else {
        _errorMessage = 'Server konnte nicht gestartet werden.\n'
            'Timeout nach 15 Sekunden.';
        state.value = FlaskServerState.error;
        await _killProcess();
      }
    } catch (e) {
      _errorMessage = 'Fehler beim Starten: $e';
      state.value = FlaskServerState.error;
      await _killProcess();
    }
  }

  Future<void> restart() async {
    await shutdown();
    _externalServer = false;
    await start();
  }

  Future<void> shutdown() async {
    if (_externalServer) {
      if (kDebugMode) print('FlaskServer: External server, skipping shutdown');
      state.value = FlaskServerState.idle;
      return;
    }
    await _killProcess();
    state.value = FlaskServerState.idle;
  }

  Future<SetupResult> setupPython() async {
    if (isSettingUp) return SetupResult.error;
    isSettingUp = true;
    setupProgress.value = 'Python-Installation wird vorbereitet...';

    try {
      final root = await _resolveProjectRoot();
      if (root == null) {
        setupProgress.value = 'Projektordner nicht gefunden.';
        isSettingUp = false;
        return SetupResult.error;
      }

      // Step 1: Find or install Python 3
      String? pythonPath;

      pythonPath = await _findSystemPython3();

      if (pythonPath == null) {
        setupProgress.value = 'Prüfe ob Homebrew verfügbar ist...';
        final brewWhich = await Process.run('which', ['brew']);
        if (brewWhich.exitCode == 0) {
          setupProgress.value = 'Installiere Python 3 via Homebrew...\n'
              'Das kann einige Minuten dauern.';
          final brewResult = await _runProcessWithProgress(
            'brew',
            ['install', 'python3'],
            progressPrefix: 'Homebrew',
          );
          if (brewResult != 0) {
            setupProgress.value = 'Homebrew-Installation fehlgeschlagen.';
            isSettingUp = false;
            return SetupResult.error;
          }
          pythonPath = await _findSystemPython3();
        } else {
          setupProgress.value = 'Homebrew nicht gefunden.\n'
              'Prüfe Xcode Command Line Tools...';
          if (File('/usr/bin/python3').existsSync()) {
            pythonPath = '/usr/bin/python3';
          }
        }
      }

      if (pythonPath == null) {
        setupProgress.value = 'Python 3 konnte nicht installiert werden.\n'
            'Bitte installiere Homebrew oder Python manuell.';
        isSettingUp = false;
        return SetupResult.brewNotFound;
      }

      if (kDebugMode) print('FlaskServer: Setup using Python at $pythonPath');

      final venvPath = '$root/venv';
      if (!Directory(venvPath).existsSync()) {
        setupProgress.value = 'Erstelle virtuelle Umgebung...';
        final venvResult = await Process.run(
          pythonPath,
          ['-m', 'venv', 'venv'],
          workingDirectory: root,
        );
        if (venvResult.exitCode != 0) {
          final stderr = (venvResult.stderr as String).trim();
          setupProgress.value = 'venv-Erstellung fehlgeschlagen.\n$stderr';
          isSettingUp = false;
          return SetupResult.error;
        }
      }

      // Step 3: Install requirements
      final pipPath = '$venvPath/bin/pip';
      final reqPath = '$root/requirements.txt';
      if (File(reqPath).existsSync()) {
        setupProgress.value = 'Installiere Abhängigkeiten...\n'
            'Das kann einige Minuten dauern.';
        final pipResult = await _runProcessWithProgress(
          pipPath,
          ['install', '-r', reqPath],
          progressPrefix: 'pip',
        );
        if (pipResult != 0) {
          setupProgress.value = 'pip install fehlgeschlagen.';
          isSettingUp = false;
          return SetupResult.error;
        }
      }

      // Step 4: Success — start server
      setupProgress.value = 'Installation abgeschlossen. Server wird gestartet...';
      isPythonMissing = false;
      isSettingUp = false;

      await start();
      return SetupResult.success;
    } catch (e) {
      setupProgress.value = 'Unerwarteter Fehler: $e';
      isSettingUp = false;
      return SetupResult.error;
    }
  }

  /// Find python3 on the system (not in a venv).
  Future<String?> _findSystemPython3() async {
    // Check common system paths first
    for (final path in ['/usr/bin/python3', '/usr/local/bin/python3', '/opt/homebrew/bin/python3']) {
      if (File(path).existsSync()) {
        try {
          final version = await Process.run(path, ['--version']);
          final versionStr = '${version.stdout}${version.stderr}';
          if (versionStr.contains('Python 3')) return path;
        } catch (_) {}
      }
    }

    // Fallback: which python3
    try {
      final result = await Process.run('which', ['python3']);
      if (result.exitCode == 0) {
        final path = (result.stdout as String).trim();
        if (path.isNotEmpty) {
          final version = await Process.run(path, ['--version']);
          final versionStr = '${version.stdout}${version.stderr}';
          if (versionStr.contains('Python 3')) return path;
        }
      }
    } catch (_) {}

    return null;
  }

  /// Runs a process and streams stderr/stdout lines into [setupProgress].
  /// Returns the exit code.
  Future<int> _runProcessWithProgress(
    String executable,
    List<String> args, {
    String progressPrefix = '',
  }) async {
    try {
      final process = await Process.start(executable, args);
      final prefix = progressPrefix.isNotEmpty ? '$progressPrefix: ' : '';

      process.stdout.transform(const SystemEncoding().decoder).listen((data) {
        final line = data.trim();
        if (line.isNotEmpty) {
          setupProgress.value = '$prefix$line';
          if (kDebugMode) print('Setup stdout: $line');
        }
      });

      process.stderr.transform(const SystemEncoding().decoder).listen((data) {
        final line = data.trim();
        if (line.isNotEmpty) {
          setupProgress.value = '$prefix$line';
          if (kDebugMode) print('Setup stderr: $line');
        }
      });

      return await process.exitCode;
    } catch (e) {
      if (kDebugMode) print('Setup process error: $e');
      return -1;
    }
  }

  /// Kill any Python process listening on our port (stale server from previous launch).
  Future<void> _killExistingServerOnPort() async {
    try {
      final result = await Process.run('lsof', ['-ti', ':$port']);
      final pids = (result.stdout as String)
          .trim()
          .split('\n')
          .where((s) => s.isNotEmpty);
      for (final pid in pids) {
        final pidInt = int.tryParse(pid.trim());
        if (pidInt != null) {
          if (kDebugMode) print('FlaskServer: Killing stale process $pidInt on port $port');
          Process.killPid(pidInt, ProcessSignal.sigterm);
        }
      }
      if (pids.isNotEmpty) {
        // Give the old process a moment to release the port
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      if (kDebugMode) print('FlaskServer: Could not check for stale server: $e');
    }
  }

  Future<bool> _isServerRunning() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);
      final request = await client.getUrl(Uri.parse('http://localhost:$port/'));
      final response = await request.close().timeout(
        const Duration(seconds: 2),
      );
      await response.drain();
      client.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _findPythonPath(String projectRoot) async {
    final venvPaths = [
      '$projectRoot/venv/bin/python3',
      '$projectRoot/.venv/bin/python3',
      '$projectRoot/env/bin/python3',
    ];
    for (final path in venvPaths) {
      if (File(path).existsSync()) {
        if (kDebugMode) print('FlaskServer: Found venv Python at $path');
        return path;
      }
    }

    for (final cmd in ['python3', 'python']) {
      try {
        final result = await Process.run('which', [cmd]);
        if (result.exitCode == 0) {
          final path = (result.stdout as String).trim();
          if (path.isNotEmpty) {
            final version = await Process.run(path, ['--version']);
            final versionStr = (version.stdout as String) +
                (version.stderr as String);
            if (versionStr.contains('Python 3')) {
              if (kDebugMode) print('FlaskServer: Found system Python at $path');
              return path;
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }

  /// Run pip install -r requirements.txt if requirements have changed since last install.
  Future<void> _syncPipDependencies(String root, String pythonPath) async {
    final reqFile = File('$root/requirements.txt');
    if (!reqFile.existsSync()) return;

    // Only run if using a venv (has pip alongside python)
    final pipPath = pythonPath.replaceAll(RegExp(r'python3?$'), 'pip3');
    if (!File(pipPath).existsSync() && !File(pipPath.replaceAll('pip3', 'pip')).existsSync()) return;
    final pip = File(pipPath).existsSync() ? pipPath : pipPath.replaceAll('pip3', 'pip');

    // Hash-based check: skip if requirements haven't changed
    final hashFile = File('$root/.requirements_hash');
    final currentHash = reqFile.readAsStringSync().hashCode.toString();
    if (hashFile.existsSync() && hashFile.readAsStringSync().trim() == currentHash) {
      return;
    }

    if (kDebugMode) print('FlaskServer: Syncing pip dependencies...');
    try {
      final result = await Process.run(
        pip,
        ['install', '-r', reqFile.path, '--quiet'],
        workingDirectory: root,
      );
      if (result.exitCode == 0) {
        hashFile.writeAsStringSync(currentHash);
        if (kDebugMode) print('FlaskServer: pip sync done');
      } else {
        if (kDebugMode) print('FlaskServer: pip sync failed: ${result.stderr}');
      }
    } catch (e) {
      if (kDebugMode) print('FlaskServer: pip sync error: $e');
    }
  }

  /// Find the bundled backend inside the app bundle (Contents/Resources/backend/).
  String? _findBundledBackend() {
    // Platform.resolvedExecutable → .../Nexus.app/Contents/MacOS/Nexus
    var dir = File(Platform.resolvedExecutable).parent; // MacOS/
    final resources = Directory('${dir.parent.path}/Resources/backend');
    if (resources.existsSync() &&
        File('${resources.path}/app/app.py').existsSync()) {
      return resources.path;
    }
    return null;
  }

  /// Copy bundled backend from app bundle to ~/Documents/Nexus.
  Future<bool> _extractBundledBackend() async {
    final bundlePath = _findBundledBackend();
    if (bundlePath == null) {
      if (kDebugMode) print('FlaskServer: No bundled backend found in app bundle');
      return false;
    }

    final home = Platform.environment['HOME'] ?? '';
    if (home.isEmpty) return false;

    final dest = '$home/Documents/Nexus';

    try {
      if (kDebugMode) print('FlaskServer: Extracting backend from $bundlePath to $dest');
      setupProgress.value = 'Backend wird nach ~/Documents/Nexus kopiert...';

      // Create destination if needed
      final destDir = Directory(dest);
      if (!destDir.existsSync()) {
        destDir.createSync(recursive: true);
      }

      // Use cp -R for reliable recursive copy
      final result = await Process.run('cp', ['-R', '$bundlePath/app', dest]);
      if (result.exitCode != 0) {
        if (kDebugMode) print('FlaskServer: cp app failed: ${result.stderr}');
        return false;
      }

      // Copy requirements.txt
      final reqSrc = File('$bundlePath/requirements.txt');
      if (reqSrc.existsSync()) {
        reqSrc.copySync('$dest/requirements.txt');
      }

      // Copy calendar_sync.py if present
      final calSrc = File('$bundlePath/calendar_sync.py');
      if (calSrc.existsSync()) {
        calSrc.copySync('$dest/calendar_sync.py');
      }

      setupProgress.value = '';
      if (kDebugMode) print('FlaskServer: Backend extracted successfully');
      return true;
    } catch (e) {
      if (kDebugMode) print('FlaskServer: Extract failed: $e');
      return false;
    }
  }

  Future<String?> _resolveProjectRoot() async {
    final envRoot = Platform.environment['NEXUS_ROOT'];
    if (envRoot != null && _hasAppPy(envRoot)) return envRoot;

    var dir = File(Platform.resolvedExecutable).parent;
    for (int i = 0; i < 10; i++) {
      if (_hasAppPy(dir.path)) return dir.path;
      dir = dir.parent;
    }

    final home = Platform.environment['HOME'] ?? '';
    final fallback = '$home/Documents/Nexus';
    if (_hasAppPy(fallback)) return fallback;

    return null;
  }

  bool _hasAppPy(String dir) {
    return File('$dir/app/app.py').existsSync();
  }

  Future<bool> _waitForServer({
    int maxRetries = 30,
    Duration interval = const Duration(milliseconds: 500),
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      await Future.delayed(interval);
      if (await _isServerRunning()) return true;

      if (_flaskProcess == null) return false;
    }
    return false;
  }

  Future<void> _killProcess() async {
    if (_flaskProcess == null) return;

    try {
      if (kDebugMode) print('FlaskServer: Sending SIGTERM');
      _flaskProcess!.kill(ProcessSignal.sigterm);

      final exited = await _flaskProcess!.exitCode
          .timeout(const Duration(seconds: 3), onTimeout: () => -1);

      if (exited == -1) {
        if (kDebugMode) print('FlaskServer: SIGTERM timeout, sending SIGKILL');
        _flaskProcess!.kill(ProcessSignal.sigkill);
      }
    } catch (e) {
      if (kDebugMode) print('FlaskServer: Error killing process: $e');
    }

    _flaskProcess = null;
  }
}
