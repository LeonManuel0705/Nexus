import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

class UpdateService {
  // Hardcoded current version
  static const String currentVersion = '0.2';
  static const String currentVersionName = '0.2 Closed Beta';

  static const String _versionUrl = 'https://nexus-lifehub.netlify.app/version.json';
  static const Duration _connectionTimeout = Duration(seconds: 2);

  /// Check if an update is available
  /// Returns null if no update available or connection failed
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse(_versionUrl))
          .timeout(_connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final remoteVersion = data['version'] as String;

        if (_isNewerVersion(remoteVersion, currentVersion)) {
          return UpdateInfo(
            version: remoteVersion,
            versionName: data['versionName'] as String? ?? remoteVersion,
            updateUrl: data['updateUrl'] as String? ?? 'https://nexus-lifehub.netlify.app/download',
            changelog: (data['changelog'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ?? [],
          );
        }
      }
    } on TimeoutException {
      // No internet connection (timeout)
      debugPrint('Update check: Connection timeout');
    } catch (e) {
      debugPrint('Update check error: $e');
    }
    return null;
  }

  /// Compare versions (simple semver comparison)
  static bool _isNewerVersion(String remote, String current) {
    try {
      final remoteParts = remote.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();

      for (int i = 0; i < remoteParts.length && i < currentParts.length; i++) {
        if (remoteParts[i] > currentParts[i]) return true;
        if (remoteParts[i] < currentParts[i]) return false;
      }
      return remoteParts.length > currentParts.length;
    } catch (e) {
      return remote != current;
    }
  }

  /// Show update dialog
  static Future<void> showUpdateDialog(BuildContext context, UpdateInfo updateInfo) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => UpdateDialog(updateInfo: updateInfo),
    );
  }
}

class UpdateInfo {
  final String version;
  final String versionName;
  final String updateUrl;
  final List<String> changelog;

  UpdateInfo({
    required this.version,
    required this.versionName,
    required this.updateUrl,
    required this.changelog,
  });
}

class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    NexusTheme.darkCard,
                    NexusTheme.darkCard.withOpacity(0.95),
                  ]
                : [
                    NexusTheme.lightCard,
                    NexusTheme.lightCard.withOpacity(0.98),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: NexusTheme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: NexusTheme.primaryColor.withOpacity(0.15),
              blurRadius: 40,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient accent
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    NexusTheme.primaryColor.withOpacity(0.1),
                    NexusTheme.secondaryColor.withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Update icon with glow
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: NexusTheme.primaryGradient,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: NexusTheme.primaryColor.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    'Neues Update verfügbar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? NexusTheme.darkText : NexusTheme.lightText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Version badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          NexusTheme.primaryColor.withOpacity(0.2),
                          NexusTheme.secondaryColor.withOpacity(0.2),
                        ],
                      ),
                      border: Border.all(
                        color: NexusTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Version ${updateInfo.versionName}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: NexusTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Changelog section
            if (updateInfo.changelog.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Neuheiten',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? NexusTheme.darkTextSecondary
                            : NexusTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...updateInfo.changelog.take(4).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: NexusTheme.primaryGradient,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? NexusTheme.darkTextMuted
                                    : NexusTheme.lightTextMuted,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),

            // Divider
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    (isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder)
                        .withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Update button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openUpdateUrl(updateInfo.updateUrl);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ).copyWith(
                        backgroundColor: MaterialStateProperty.all(Colors.transparent),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: NexusTheme.primaryGradient,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: NexusTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.download_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Jetzt aktualisieren',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Skip button
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    child: Text(
                      'Später',
                      style: TextStyle(
                        color: isDark
                            ? NexusTheme.darkTextMuted
                            : NexusTheme.lightTextMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Current version footer
            Container(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Installiert: ${UpdateService.currentVersionName}',
                style: TextStyle(
                  fontSize: 12,
                  color: (isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted)
                      .withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUpdateUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch URL: $url');
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
    }
  }
}
