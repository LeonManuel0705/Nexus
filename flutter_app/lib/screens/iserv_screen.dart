import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NexusTheme.darkCard,
        title: const Text('Mit IServ verbinden'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'IServ URL',
                  hintText: 'z.B. gymnasium.iserv.de',
                  prefixIcon: Icon(Icons.public),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Benutzername',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Passwort',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          Consumer<IServProvider>(
            builder: (context, provider, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (provider.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        provider.error!,
                        style: TextStyle(
                          color: NexusTheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            if (usernameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bitte Benutzername eingeben'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            if (passwordController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bitte Passwort eingeben'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            if (urlController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bitte IServ URL eingeben'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            final result = await provider.connect(
                              username: usernameController.text.trim(),
                              password: passwordController.text,
                              iservUrl: urlController.text.trim(),
                            );
                            if (result['success'] == true && mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Erfolgreich mit IServ verbunden'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else if (result['success'] != true && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['error'] ?? 'Anmeldung fehlgeschlagen'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verbinden'),
                  ),
                ],
              );
            },
          ),
        ],
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
              onPressed: () => _showDisconnectDialog(provider),
              backgroundColor: NexusTheme.error,
              icon: const Icon(Icons.logout),
              label: const Text('Trennen'),
            );
          }
          return FloatingActionButton.extended(
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
