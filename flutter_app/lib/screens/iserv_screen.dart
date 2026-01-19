import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../providers/iserv_provider.dart';
import '../models/iserv.dart';
import '../theme.dart';

class IServScreen extends StatefulWidget {
  const IServScreen({super.key});

  @override
  State<IServScreen> createState() => _IServScreenState();
}

class _IServScreenState extends State<IServScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IServProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showLoginDialog() {
    final urlController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          bool isLoading = false;
          String? errorMessage;

          return AlertDialog(
            backgroundColor: NexusTheme.darkCard,
            title: const Text('Mit IServ verbinden'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Gib deine IServ-Zugangsdaten ein.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'IServ URL',
                      hintText: 'z.B. gymnasium.iserv.de',
                      prefixIcon: Icon(Icons.public),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Benutzername',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Passwort',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Abbrechen'),
              ),
              StatefulBuilder(
                builder: (context, setButtonState) {
                  bool buttonLoading = false;

                  return ElevatedButton(
                    onPressed: buttonLoading
                        ? null
                        : () async {
                            final url = urlController.text.trim();
                            final username = usernameController.text.trim();
                            final password = passwordController.text;

                            if (url.isEmpty || username.isEmpty || password.isEmpty) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bitte alle Felder ausfüllen'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            setButtonState(() => buttonLoading = true);

                            final provider = this.context.read<IServProvider>();
                            final result = await provider.connect(
                              username: username,
                              password: password,
                              iservUrl: url,
                            );

                            if (!mounted) return;

                            if (result['success'] == true) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Erfolgreich mit IServ verbunden'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              setButtonState(() => buttonLoading = false);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(result['error'] ?? 'Anmeldung fehlgeschlagen'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    child: buttonLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Anmelden'),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexusTheme.darkBackground,
      appBar: AppBar(
        title: const Text('IServ'),
        backgroundColor: NexusTheme.darkSurface,
        actions: [
          Consumer<IServProvider>(
            builder: (context, provider, child) {
              if (!provider.isConnected) return const SizedBox();
              return IconButton(
                icon: provider.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: provider.isSyncing ? null : () => provider.syncData(),
                tooltip: 'Aktualisieren',
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Nachrichten'),
            Tab(text: 'Aufgaben'),
            Tab(text: 'Termine'),
            Tab(text: 'Vertretung'),
          ],
        ),
      ),
      body: Consumer<IServProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !provider.isConnected) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!provider.isConnected && provider.username == null) {
            return _NotConnectedView(onConnect: _showLoginDialog);
          }

          return Column(
            children: [

              if (provider.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: NexusTheme.error.withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: NexusTheme.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          provider.error!,
                          style: TextStyle(color: NexusTheme.error, fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () => provider.syncData(),
                        child: const Text('Erneut'),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _NotificationsTab(notifications: provider.notifications),
                    _ExercisesTab(exercises: provider.exercises),
                    _EventsTab(events: provider.events),
                    const _VertretungsplanTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<IServProvider>(
        builder: (context, provider, child) {
          if (provider.isConnected) {
            return FloatingActionButton.extended(
              heroTag: 'fab_iserv_disconnect',
              onPressed: () => _showDisconnectDialog(provider),
              backgroundColor: NexusTheme.error,
              icon: const Icon(Icons.logout),
              label: const Text('Trennen'),
            );
          }
          return FloatingActionButton.extended(
            heroTag: 'fab_iserv_connect',
            onPressed: _showLoginDialog,
            backgroundColor: NexusTheme.primary,
            icon: const Icon(Icons.login),
            label: const Text('Verbinden'),
          );
        },
      ),
    );
  }

  void _showDisconnectDialog(IServProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NexusTheme.darkCard,
        title: const Text('Von IServ trennen?'),
        content: const Text('Deine Anmeldedaten werden gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.disconnect();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NexusTheme.error,
            ),
            child: const Text('Trennen'),
          ),
        ],
      ),
    );
  }
}

class _NotConnectedView extends StatelessWidget {
  final VoidCallback onConnect;

  const _NotConnectedView({required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: NexusTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school_outlined,
                size: 64,
                color: NexusTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mit IServ verbinden',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verbinde dich mit deinem IServ-Konto um Nachrichten, Aufgaben und Termine zu sehen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onConnect,
              icon: const Icon(Icons.login),
              label: const Text('Anmelden'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsTab extends StatelessWidget {
  final List<IServNotification> notifications;

  const _NotificationsTab({required this.notifications});

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return _EmptyTabView(
        icon: Icons.notifications_outlined,
        message: 'Keine Nachrichten',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Card(
          color: NexusTheme.darkCard,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: notification.read
                    ? NexusTheme.darkSurface
                    : NexusTheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                notification.read
                    ? Icons.mail_outlined
                    : Icons.mail,
                color: notification.read
                    ? Colors.white54
                    : NexusTheme.primary,
              ),
            ),
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.read
                    ? FontWeight.normal
                    : FontWeight.bold,
              ),
            ),
            subtitle: notification.message != null
                ? Text(
                    notification.message!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: Text(
              _formatDate(notification.timestamp),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return 'vor ${diff.inMinutes} Min.';
    } else if (diff.inHours < 24) {
      return 'vor ${diff.inHours} Std.';
    } else if (diff.inDays < 7) {
      return 'vor ${diff.inDays} Tagen';
    } else {
      return '${date.day}.${date.month}.';
    }
  }
}

class _ExercisesTab extends StatelessWidget {
  final List<IServExercise> exercises;

  const _ExercisesTab({required this.exercises});

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return _EmptyTabView(
        icon: Icons.assignment_outlined,
        message: 'Keine Aufgaben',
      );
    }

    final openExercises = exercises.where((e) => e.status == 'open').toList();
    final completedExercises = exercises.where((e) => e.status != 'open').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (openExercises.isNotEmpty) ...[
          Text(
            'Offen (${openExercises.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...openExercises.map((e) => _ExerciseCard(exercise: e)),
        ],
        if (completedExercises.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Erledigt (${completedExercises.length})',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          ...completedExercises.map((e) => _ExerciseCard(exercise: e)),
        ],
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final IServExercise exercise;

  const _ExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: NexusTheme.darkCard,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (exercise.isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: NexusTheme.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Überfällig',
                      style: TextStyle(
                        fontSize: 11,
                        color: NexusTheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (exercise.course != null) ...[
                  if (exercise.isOverdue) const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: NexusTheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      exercise.course!,
                      style: TextStyle(
                        fontSize: 11,
                        color: NexusTheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              exercise.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (exercise.description != null) ...[
              const SizedBox(height: 4),
              Text(
                exercise.description!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (exercise.dueDate != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: exercise.isOverdue
                        ? NexusTheme.error
                        : Colors.white54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Fällig: ${_formatDate(exercise.dueDate!)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: exercise.isOverdue
                          ? NexusTheme.error
                          : Colors.white54,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

class _EventsTab extends StatelessWidget {
  final List<IServEvent> events;

  const _EventsTab({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _EmptyTabView(
        icon: Icons.event_outlined,
        message: 'Keine Termine',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          color: NexusTheme.darkCard,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: NexusTheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (event.startTime != null) ...[
                    Text(
                      '${event.startTime!.day}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: NexusTheme.primary,
                      ),
                    ),
                    Text(
                      _monthAbbr(event.startTime!.month),
                      style: TextStyle(
                        fontSize: 10,
                        color: NexusTheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            title: Text(event.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.startTime != null)
                  Text(
                    event.allDay
                        ? 'Ganztägig'
                        : '${event.startTime!.hour}:${event.startTime!.minute.toString().padLeft(2, '0')} Uhr',
                    style: const TextStyle(fontSize: 13),
                  ),
                if (event.location != null)
                  Text(
                    event.location!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _monthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
    return months[month - 1];
  }
}

class _EmptyTabView extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyTabView({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _VertretungsplanTab extends StatefulWidget {
  const _VertretungsplanTab();

  @override
  State<_VertretungsplanTab> createState() => _VertretungsplanTabState();
}

class _VertretungsplanTabState extends State<_VertretungsplanTab>
    with SingleTickerProviderStateMixin {
  late TabController _innerTabController;
  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _innerTabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVertretungsplan();
    });
  }

  @override
  void dispose() {
    _innerTabController.dispose();
    super.dispose();
  }

  void _loadVertretungsplan() {
    context.read<IServProvider>().fetchVertretungsplan();
  }

  String _formatCacheTime(DateTime? cachedAt) {
    if (cachedAt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(cachedAt);

    if (diff.inMinutes < 1) {
      return 'gerade eben';
    } else if (diff.inMinutes < 60) {
      return 'vor ${diff.inMinutes} Min.';
    } else if (diff.inHours < 24) {
      return 'vor ${diff.inHours} Std.';
    } else {
      return '${cachedAt.day}.${cachedAt.month}. ${cachedAt.hour}:${cachedAt.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<IServProvider>(
      builder: (context, provider, child) {
        if (provider.isVertretungsplanLoading && provider.vertretungsplanHtml == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.vertretungsplanError != null && provider.vertretungsplanHtml == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: NexusTheme.error.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.vertretungsplanError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadVertretungsplan,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            if (provider.isVertretungsplanFromCache)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.orange.withOpacity(0.15),
                child: Row(
                  children: [
                    const Icon(Icons.offline_bolt, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Offline-Modus${provider.vertretungsplanCachedAt != null ? ' (${_formatCacheTime(provider.vertretungsplanCachedAt)})' : ''}',
                        style: const TextStyle(color: Colors.orange, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: provider.isVertretungsplanLoading ? null : _loadVertretungsplan,
                      child: provider.isVertretungsplanLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Aktualisieren'),
                    ),
                  ],
                ),
              ),

            Container(
              color: NexusTheme.darkSurface,
              child: TabBar(
                controller: _innerTabController,
                tabs: const [
                  Tab(text: 'Infobildschirm'),
                  Tab(text: 'Info'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _innerTabController,
                children: [
                  _buildWebViewContent(provider.vertretungsplanHtml),
                  _buildInfoContent(provider.vertretungsplanHtml),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWebViewContent(String? html) {
    if (html == null || html.isEmpty) {
      return _EmptyTabView(
        icon: Icons.web,
        message: 'Keine Daten verfügbar',
      );
    }

    return InAppWebView(
      initialData: InAppWebViewInitialData(
        data: html,
        baseUrl: WebUri('https://ehgwerder.de'),
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        supportZoom: true,
        builtInZoomControls: true,
        displayZoomControls: false,
        transparentBackground: true,
      ),
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
    );
  }

  Widget _buildInfoContent(String? html) {
    if (html == null || html.isEmpty) {
      return _EmptyTabView(
        icon: Icons.info_outline,
        message: 'Keine Informationen verfügbar',
      );
    }

    final infoSections = <Map<String, String>>[];

    final titleMatch = RegExp(r'<title>([^<]+)</title>', caseSensitive: false).firstMatch(html);
    final title = titleMatch?.group(1)?.trim() ?? 'Vertretungsplan';

    final dateMatch = RegExp(r'(\d{1,2}\.\d{1,2}\.\d{4})', caseSensitive: false).firstMatch(html);
    final date = dateMatch?.group(1);

    final infoPatterns = [
      RegExp(r'<div[^>]*class="[^"]*info[^"]*"[^>]*>(.*?)</div>', caseSensitive: false, dotAll: true),
      RegExp(r'<p[^>]*class="[^"]*message[^"]*"[^>]*>(.*?)</p>', caseSensitive: false, dotAll: true),
      RegExp(r'<span[^>]*class="[^"]*notice[^"]*"[^>]*>(.*?)</span>', caseSensitive: false, dotAll: true),
    ];

    for (final pattern in infoPatterns) {
      final matches = pattern.allMatches(html);
      for (final match in matches) {
        final content = match.group(1)?.replaceAll(RegExp(r'<[^>]+>'), '').trim();
        if (content != null && content.isNotEmpty) {
          infoSections.add({'type': 'info', 'content': content});
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: NexusTheme.darkCard,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: NexusTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.school, color: NexusTheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (date != null)
                            Text(
                              date,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        if (infoSections.isEmpty)
          Card(
            color: NexusTheme.darkCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Keine zusätzlichen Informationen',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...infoSections.map((section) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              color: NexusTheme.darkCard,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  section['content'] ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          )),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: NexusTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: NexusTheme.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: NexusTheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Wechsel zu "Infobildschirm" für die vollständige Ansicht',
                  style: TextStyle(
                    color: NexusTheme.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
