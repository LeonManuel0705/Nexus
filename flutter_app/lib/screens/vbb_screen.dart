import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vbb_provider.dart';
import '../models/vbb.dart';
import '../theme.dart';

class VbbScreen extends StatefulWidget {
  const VbbScreen({super.key});

  @override
  State<VbbScreen> createState() => _VbbScreenState();
}

class _VbbScreenState extends State<VbbScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isSelectingFrom = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VbbProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showLocationSearch(bool isFrom) {
    _isSelectingFrom = isFrom;
    _searchController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NexusTheme.darkSurface,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _LocationSearchSheet(
          isFrom: isFrom,
          scrollController: scrollController,
          onLocationSelected: (location) {
            final provider = context.read<VbbProvider>();
            if (isFrom) {
              provider.setFromLocation(location);
            } else {
              provider.setToLocation(location);
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexusTheme.darkBackground,
      appBar: AppBar(
        title: const Text('VBB Fahrinfo'),
        backgroundColor: NexusTheme.darkSurface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Routenplaner'),
            Tab(text: 'Abfahrten'),
          ],
        ),
      ),
      body: Consumer<VbbProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.needsSetup) {
            return _SetupWizard(
              provider: provider,
              onComplete: () {
                provider.refreshKnownLocations();
              },
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _RoutePlannerTab(
                provider: provider,
                onFromTap: () => _showLocationSearch(true),
                onToTap: () => _showLocationSearch(false),
              ),
              _DeparturesTab(
                provider: provider,
                onStationTap: () => _showStationSearch(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStationSearch(VbbProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NexusTheme.darkSurface,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _LocationSearchSheet(
          isFrom: false,
          scrollController: scrollController,
          onLocationSelected: (location) {
            provider.setSelectedStation(location);
            provider.loadDepartures();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class _LocationSearchSheet extends StatefulWidget {
  final bool isFrom;
  final ScrollController scrollController;
  final void Function(VbbLocation) onLocationSelected;

  const _LocationSearchSheet({
    required this.isFrom,
    required this.scrollController,
    required this.onLocationSelected,
  });

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: Text(widget.isFrom ? 'Von' : 'Nach'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Station oder Adresse suchen...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: NexusTheme.darkCard,
            ),
            onChanged: (value) {
              context.read<VbbProvider>().searchLocations(value);
            },
          ),
        ),
        Expanded(
          child: Consumer<VbbProvider>(
            builder: (context, provider, child) {

              if (_searchController.text.isEmpty) {
                return ListView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const Text(
                      'Gespeicherte Orte',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...provider.knownLocations.map((location) => ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: NexusTheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getAliasIcon(location.alias),
                          color: NexusTheme.primary,
                        ),
                      ),
                      title: Text(location.name),
                      subtitle: Text(location.locationName),
                      onTap: () => widget.onLocationSelected(location.toLocation()),
                    )),
                  ],
                );
              }

              if (provider.isSearching) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.searchResults.isEmpty) {
                return Center(
                  child: Text(
                    provider.isOnline
                        ? 'Keine Ergebnisse'
                        : 'Offline - Suche nicht möglich',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                );
              }

              return ListView.builder(
                controller: widget.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: provider.searchResults.length,
                itemBuilder: (context, index) {
                  final location = provider.searchResults[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: NexusTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        location.type == 'station'
                            ? Icons.train
                            : Icons.location_on,
                        color: NexusTheme.primary,
                      ),
                    ),
                    title: Text(location.name),
                    subtitle: location.productsDisplay.isNotEmpty
                        ? Text(
                            location.productsDisplay,
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                    onTap: () => widget.onLocationSelected(location),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getAliasIcon(String alias) {
    switch (alias) {
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'work':
        return Icons.work;
      case 'gym':
        return Icons.fitness_center;
      default:
        return Icons.place;
    }
  }
}

class _RoutePlannerTab extends StatelessWidget {
  final VbbProvider provider;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;

  const _RoutePlannerTab({
    required this.provider,
    required this.onFromTap,
    required this.onToTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NexusTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [

              InkWell(
                onTap: onFromTap,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.trip_origin, color: Colors.green, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        provider.fromLocation?.name ?? 'Von...',
                        style: TextStyle(
                          color: provider.fromLocation != null
                              ? Colors.white
                              : Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  const Expanded(child: Divider()),
                  IconButton(
                    icon: const Icon(Icons.swap_vert),
                    onPressed: () => provider.swapLocations(),
                    tooltip: 'Vertauschen',
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: onToTap,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: NexusTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.location_on, color: NexusTheme.primary, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        provider.toLocation?.name ?? 'Nach...',
                        style: TextStyle(
                          color: provider.toLocation != null
                              ? Colors.white
                              : Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: provider.fromLocation != null && provider.toLocation != null
                      ? () => provider.searchRoutes()
                      : null,
                  icon: provider.isLoadingRoutes
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('Verbindung suchen'),
                ),
              ),
            ],
          ),
        ),

        if (provider.knownLocations.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => provider.planRouteToSchool(),
                    icon: const Icon(Icons.school, size: 18),
                    label: const Text('Zur Schule'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => provider.planRouteHome(),
                    icon: const Icon(Icons.home, size: 18),
                    label: const Text('Nach Hause'),
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: _buildRouteResults(provider),
        ),
      ],
    );
  }

  Widget _buildRouteResults(VbbProvider provider) {
    if (provider.isLoadingRoutes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            provider.error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ),
      );
    }

    if (provider.journeys.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_transit,
              size: 64,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Suche nach Verbindungen',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.journeys.length,
      itemBuilder: (context, index) {
        final journey = provider.journeys[index];
        return _JourneyCard(journey: journey);
      },
    );
  }
}

class _JourneyCard extends StatelessWidget {
  final VbbJourney journey;

  const _JourneyCard({required this.journey});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: NexusTheme.darkCard,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showJourneyDetails(context, journey),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  Text(
                    journey.departureTime,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, size: 16),
                  ),
                  Text(
                    journey.arrivalTime,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: NexusTheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      journey.durationDisplay,
                      style: TextStyle(
                        color: NexusTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  ...journey.legs
                      .where((leg) => !leg.isWalking && leg.line != null)
                      .take(4)
                      .map((leg) => _buildLineBadge(leg)),
                  if (journey.transfers > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${journey.transfers} Umstieg${journey.transfers > 1 ? 'e' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineBadge(VbbLeg leg) {
    Color bgColor;
    switch (leg.mode) {
      case 'suburban':
        bgColor = Colors.green;
        break;
      case 'subway':
        bgColor = Colors.blue;
        break;
      case 'tram':
        bgColor = Colors.red;
        break;
      case 'bus':
        bgColor = Colors.purple;
        break;
      default:
        bgColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        leg.line ?? '',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showJourneyDetails(BuildContext context, VbbJourney journey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NexusTheme.darkSurface,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            AppBar(
              title: const Text('Verbindungsdetails'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: journey.legs.length,
                itemBuilder: (context, index) {
                  final leg = journey.legs[index];
                  return _LegDetailCard(leg: leg, isLast: index == journey.legs.length - 1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegDetailCard extends StatelessWidget {
  final VbbLeg leg;
  final bool isLast;

  const _LegDetailCard({
    required this.leg,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    if (leg.isWalking) {
      return Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: const Icon(Icons.directions_walk, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Fußweg (${(leg.duration ?? 0) ~/ 60} Min.)',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 60,
                      color: Colors.white24,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        leg.departureTime,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          leg.origin.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildLineBadge(),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Richtung ${leg.direction ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (leg.platform != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Gleis/Steig ${leg.platform}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),

        if (isLast)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: NexusTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      leg.arrivalTime,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        leg.destination.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildLineBadge() {
    Color bgColor;
    switch (leg.mode) {
      case 'suburban':
        bgColor = Colors.green;
        break;
      case 'subway':
        bgColor = Colors.blue;
        break;
      case 'tram':
        bgColor = Colors.red;
        break;
      case 'bus':
        bgColor = Colors.purple;
        break;
      default:
        bgColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        leg.line ?? '',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DeparturesTab extends StatelessWidget {
  final VbbProvider provider;
  final VoidCallback onStationTap;

  const _DeparturesTab({
    required this.provider,
    required this.onStationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Container(
          margin: const EdgeInsets.all(16),
          child: InkWell(
            onTap: onStationTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NexusTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.train, color: NexusTheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      provider.selectedStation?.name ?? 'Station auswählen...',
                      style: TextStyle(
                        color: provider.selectedStation != null
                            ? Colors.white
                            : Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          child: _buildDeparturesList(provider),
        ),
      ],
    );
  }

  Widget _buildDeparturesList(VbbProvider provider) {
    if (provider.selectedStation == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.departure_board,
              size: 64,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Wähle eine Station',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    if (provider.isLoadingDepartures) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.departures.isEmpty) {
      return Center(
        child: Text(
          provider.isOnline
              ? 'Keine Abfahrten'
              : 'Offline - Abfahrten nicht verfügbar',
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => provider.loadDepartures(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: provider.departures.length,
        itemBuilder: (context, index) {
          final departure = provider.departures[index];
          return _DepartureCard(departure: departure);
        },
      ),
    );
  }
}

class _DepartureCard extends StatelessWidget {
  final VbbDeparture departure;

  const _DepartureCard({required this.departure});

  @override
  Widget build(BuildContext context) {
    Color lineColor;
    switch (departure.mode) {
      case 'suburban':
        lineColor = Colors.green;
        break;
      case 'subway':
        lineColor = Colors.blue;
        break;
      case 'tram':
        lineColor = Colors.red;
        break;
      case 'bus':
        lineColor = Colors.purple;
        break;
      default:
        lineColor = Colors.grey;
    }

    return Card(
      color: NexusTheme.darkCard,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [

            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: lineColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                departure.line,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    departure.direction,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (departure.platform != null)
                    Text(
                      'Gleis ${departure.platform}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  departure.minutesUntil,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (departure.isDelayed)
                  Text(
                    departure.delayDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: NexusTheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupWizard extends StatefulWidget {
  final VbbProvider provider;
  final VoidCallback onComplete;

  const _SetupWizard({
    required this.provider,
    required this.onComplete,
  });

  @override
  State<_SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<_SetupWizard> {
  int _currentStep = 0;
  VbbLocation? _homeLocation;
  VbbLocation? _schoolLocation;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isSearchingHome => _currentStep == 1;
  bool get _isSearchingSchool => _currentStep == 3;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 32),

        Icon(
          Icons.directions_transit,
          size: 64,
          color: NexusTheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'VBB Einrichtung',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Richte deine Orte ein, um schnell Verbindungen zu finden.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildProgressDot(0),
            Container(
              width: 40,
              height: 2,
              color: _currentStep >= 2 ? NexusTheme.primary : Colors.white24,
            ),
            _buildProgressDot(2),
          ],
        ),
        const SizedBox(height: 32),

        if (_currentStep == 0) _buildHomeIntro(),
        if (_currentStep == 1) _buildLocationSearch('Zuhause', true),
        if (_currentStep == 2) _buildSchoolIntro(),
        if (_currentStep == 3) _buildLocationSearch('Schule', false),
        if (_currentStep == 4) _buildComplete(),
      ],
    );
  }

  Widget _buildProgressDot(int step) {
    final isActive = _currentStep >= step;
    final isComplete = step == 0 ? _homeLocation != null : _schoolLocation != null;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isComplete
            ? NexusTheme.success
            : isActive
                ? NexusTheme.primary
                : Colors.white24,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isComplete
            ? Icons.check
            : step == 0
                ? Icons.home
                : Icons.school,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildHomeIntro() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: NexusTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NexusTheme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.home,
                  size: 48,
                  color: NexusTheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Wo wohnst du?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Suche nach deiner nächsten Haltestelle oder gib deine Adresse ein.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => setState(() => _currentStep = 1),
            icon: const Icon(Icons.search),
            label: const Text('Standort suchen'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        if (widget.provider.hasHome) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _currentStep = 2),
            child: const Text('Überspringen'),
          ),
        ],
      ],
    );
  }

  Widget _buildSchoolIntro() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: NexusTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NexusTheme.info.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school,
                  size: 48,
                  color: NexusTheme.info,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Wo ist deine Schule?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Suche nach der Haltestelle bei deiner Schule.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => setState(() => _currentStep = 3),
            icon: const Icon(Icons.search),
            label: const Text('Schule suchen'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        if (widget.provider.hasSchool) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _currentStep = 4),
            child: const Text('Überspringen'),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationSearch(String label, bool isHome) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '$label suchen...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: NexusTheme.darkCard,
          ),
          onChanged: (value) {
            widget.provider.searchLocations(value);
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: Consumer<VbbProvider>(
            builder: (context, provider, child) {
              if (provider.isSearching) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_searchController.text.length < 2) {
                return Center(
                  child: Text(
                    'Mindestens 2 Zeichen eingeben',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                );
              }

              if (provider.searchResults.isEmpty) {
                return Center(
                  child: Text(
                    provider.isOnline
                        ? 'Keine Ergebnisse'
                        : 'Offline - Suche nicht möglich',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                );
              }

              return ListView.builder(
                itemCount: provider.searchResults.length,
                itemBuilder: (context, index) {
                  final location = provider.searchResults[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: NexusTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        location.type == 'station'
                            ? Icons.train
                            : Icons.location_on,
                        color: NexusTheme.primary,
                      ),
                    ),
                    title: Text(location.name),
                    subtitle: location.productsDisplay.isNotEmpty
                        ? Text(location.productsDisplay, style: const TextStyle(fontSize: 12))
                        : null,
                    onTap: () async {
                      if (isHome) {
                        _homeLocation = location;
                        await widget.provider.addKnownLocation(
                          name: 'Zuhause',
                          alias: 'home',
                          location: location,
                        );
                        _searchController.clear();
                        setState(() => _currentStep = 2);
                      } else {
                        _schoolLocation = location;
                        await widget.provider.addKnownLocation(
                          name: 'Schule',
                          alias: 'school',
                          location: location,
                        );
                        _searchController.clear();
                        setState(() => _currentStep = 4);
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            _searchController.clear();
            setState(() => _currentStep = isHome ? 0 : 2);
          },
          child: const Text('Zurück'),
        ),
      ],
    );
  }

  Widget _buildComplete() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: NexusTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NexusTheme.success.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 48,
                  color: NexusTheme.success,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Alles eingerichtet!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Du kannst jetzt schnell Verbindungen zwischen Zuhause und Schule finden.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              if (_homeLocation != null || widget.provider.hasHome)
                _buildConfiguredLocation(
                  'Zuhause',
                  _homeLocation?.name ?? widget.provider.homeLocation?.locationName ?? '',
                  Icons.home,
                  NexusTheme.primary,
                ),
              const SizedBox(height: 12),
              if (_schoolLocation != null || widget.provider.hasSchool)
                _buildConfiguredLocation(
                  'Schule',
                  _schoolLocation?.name ?? widget.provider.schoolLocation?.locationName ?? '',
                  Icons.school,
                  NexusTheme.info,
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: widget.onComplete,
            icon: const Icon(Icons.check),
            label: const Text('Fertig'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: NexusTheme.success,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfiguredLocation(String label, String name, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: color),
        ],
      ),
    );
  }
}
