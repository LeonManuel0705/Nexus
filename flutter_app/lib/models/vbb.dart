import 'dart:convert';

class VbbLocation {
  final String id;
  final String name;
  final String type;
  final double? latitude;
  final double? longitude;
  final List<String>? products;

  VbbLocation({
    required this.id,
    required this.name,
    required this.type,
    this.latitude,
    this.longitude,
    this.products,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'products': products != null ? jsonEncode(products) : null,
    };
  }

  factory VbbLocation.fromMap(Map<String, dynamic> map) {
    return VbbLocation(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String? ?? 'station',
      latitude: (map['latitude'] as num?)?.toDouble() ??
                (map['location'] != null ? (map['location']['latitude'] as num?)?.toDouble() : null),
      longitude: (map['longitude'] as num?)?.toDouble() ??
                 (map['location'] != null ? (map['location']['longitude'] as num?)?.toDouble() : null),
      products: map['products'] != null
          ? (map['products'] is String
              ? (jsonDecode(map['products'] as String) as List).cast<String>()
              : (map['products'] as Map<String, dynamic>)
                  .entries
                  .where((e) => e.value == true)
                  .map((e) => e.key)
                  .toList())
          : null,
    );
  }

  factory VbbLocation.fromApiResponse(Map<String, dynamic> json) {
    final products = <String>[];
    if (json['products'] != null) {
      final p = json['products'] as Map<String, dynamic>;
      if (p['suburban'] == true) products.add('S-Bahn');
      if (p['subway'] == true) products.add('U-Bahn');
      if (p['tram'] == true) products.add('Tram');
      if (p['bus'] == true) products.add('Bus');
      if (p['ferry'] == true) products.add('Fähre');
      if (p['express'] == true) products.add('Express');
      if (p['regional'] == true) products.add('Regional');
    }

    return VbbLocation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'station',
      latitude: json['location'] != null
          ? (json['location']['latitude'] as num?)?.toDouble()
          : null,
      longitude: json['location'] != null
          ? (json['location']['longitude'] as num?)?.toDouble()
          : null,
      products: products.isNotEmpty ? products : null,
    );
  }

  String get productsDisplay => products?.join(', ') ?? '';
}

class VbbKnownLocation {
  final String id;
  final String name;
  final String alias;
  final String locationId;
  final String locationName;
  final double? latitude;
  final double? longitude;

  VbbKnownLocation({
    required this.id,
    required this.name,
    required this.alias,
    required this.locationId,
    required this.locationName,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'alias': alias,
      'location_id': locationId,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory VbbKnownLocation.fromMap(Map<String, dynamic> map) {
    return VbbKnownLocation(
      id: map['id'] as String,
      name: map['name'] as String,
      alias: map['alias'] as String,
      locationId: map['location_id'] as String,
      locationName: map['location_name'] as String,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  VbbLocation toLocation() {
    return VbbLocation(
      id: locationId,
      name: locationName,
      type: 'station',
      latitude: latitude,
      longitude: longitude,
    );
  }
}

class VbbJourney {
  final String id;
  final VbbLocation from;
  final VbbLocation to;
  final DateTime departure;
  final DateTime arrival;
  final Duration duration;
  final int transfers;
  final List<VbbLeg> legs;
  final double? price;
  final String? tariffZone;

  VbbJourney({
    required this.id,
    required this.from,
    required this.to,
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.transfers,
    required this.legs,
    this.price,
    this.tariffZone,
  });

  factory VbbJourney.fromApiResponse(Map<String, dynamic> json) {
    final legs = (json['legs'] as List)
        .map((leg) => VbbLeg.fromApiResponse(leg as Map<String, dynamic>))
        .toList();

    final departure = DateTime.parse(json['legs'][0]['departure'] as String);
    final arrival = DateTime.parse(json['legs'].last['arrival'] as String);

    double? price;
    String? tariffZone;
    final ticketsData = json['tickets'] as List?;
    if (ticketsData != null) {
      for (final category in ticketsData) {
        final catMap = category as Map<String, dynamic>;
        final name = catMap['name'] as String? ?? '';
        if (name.contains('Einzelfahrausweis')) {
          tariffZone = catMap['description'] as String?;
          if (tariffZone != null && tariffZone.startsWith('Via: ')) {
            tariffZone = tariffZone.substring(5);
          }
          final subTickets = catMap['tickets'] as List?;
          if (subTickets != null) {
            for (final sub in subTickets) {
              final subMap = sub as Map<String, dynamic>;
              if (subMap['name'] == 'Regeltarif') {
                final priceData = subMap['price'] as Map<String, dynamic>?;
                if (priceData != null) {
                  price = (priceData['amount'] as num).toDouble() / 100;
                }
                break;
              }
            }
          }
          break;
        }
      }
    }
    if (price == null && json['price'] != null) {
      final priceData = json['price'] as Map<String, dynamic>;
      price = (priceData['amount'] as num).toDouble() / 100;
    }

    return VbbJourney(
      id: '${departure.millisecondsSinceEpoch}_${arrival.millisecondsSinceEpoch}',
      from: VbbLocation.fromApiResponse(json['legs'][0]['origin'] as Map<String, dynamic>),
      to: VbbLocation.fromApiResponse(json['legs'].last['destination'] as Map<String, dynamic>),
      departure: departure,
      arrival: arrival,
      duration: arrival.difference(departure),
      transfers: legs.where((l) => l.line != null).length - 1,
      legs: legs,
      price: price,
      tariffZone: tariffZone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from': from.toMap(),
      'to': to.toMap(),
      'departure': departure.toIso8601String(),
      'arrival': arrival.toIso8601String(),
      'duration': duration.inSeconds,
      'transfers': transfers,
      'legs': legs.map((l) => l.toMap()).toList(),
      'price': price,
      'tariffZone': tariffZone,
    };
  }

  factory VbbJourney.fromMap(Map<String, dynamic> map) {
    return VbbJourney(
      id: map['id'] as String,
      from: VbbLocation.fromMap(map['from'] as Map<String, dynamic>),
      to: VbbLocation.fromMap(map['to'] as Map<String, dynamic>),
      departure: DateTime.parse(map['departure'] as String),
      arrival: DateTime.parse(map['arrival'] as String),
      duration: Duration(seconds: map['duration'] as int),
      transfers: map['transfers'] as int,
      legs: (map['legs'] as List).map((l) => VbbLeg.fromMap(l as Map<String, dynamic>)).toList(),
      price: (map['price'] as num?)?.toDouble(),
      tariffZone: map['tariffZone'] as String?,
    );
  }

  String get durationDisplay {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '$hours Std. $minutes Min.';
    }
    return '$minutes Min.';
  }

  String get departureTime =>
      '${departure.hour}:${departure.minute.toString().padLeft(2, '0')}';

  String get arrivalTime =>
      '${arrival.hour}:${arrival.minute.toString().padLeft(2, '0')}';

  bool get hasDelays => legs.any((l) => l.isDelayed);
  bool get hasCancellation => legs.any((l) => l.cancelled);

  String get delayInfo {
    final delayed = legs.where((l) => l.isDelayed && !l.cancelled).toList();
    final cancelled = legs.where((l) => l.cancelled).toList();
    if (cancelled.isNotEmpty) return 'Ausfall: ${cancelled.map((l) => l.line).join(', ')}';
    if (delayed.isNotEmpty) {
      final maxDelay = delayed.map((l) => l.departureDelay ?? 0).reduce((a, b) => a > b ? a : b);
      return '+${maxDelay ~/ 60} Min.';
    }
    return '';
  }
}

class VbbLeg {
  final VbbLocation origin;
  final VbbLocation destination;
  final DateTime departure;
  final DateTime? arrival;
  final String? line;
  final String? lineName;
  final String? direction;
  final String mode;
  final int? duration;
  final String? platform;
  final List<VbbStop>? stops;
  final bool isWalking;
  final int? departureDelay;
  final int? arrivalDelay;
  final bool cancelled;

  VbbLeg({
    required this.origin,
    required this.destination,
    required this.departure,
    this.arrival,
    this.line,
    this.lineName,
    this.direction,
    required this.mode,
    this.duration,
    this.platform,
    this.stops,
    this.isWalking = false,
    this.departureDelay,
    this.arrivalDelay,
    this.cancelled = false,
  });

  factory VbbLeg.fromApiResponse(Map<String, dynamic> json) {
    final isWalking = json['walking'] == true;

    List<VbbStop>? stops;
    if (json['stopovers'] != null) {
      stops = (json['stopovers'] as List)
          .map((s) => VbbStop.fromApiResponse(s as Map<String, dynamic>))
          .toList();
    }

    return VbbLeg(
      origin: VbbLocation.fromApiResponse(json['origin'] as Map<String, dynamic>),
      destination: VbbLocation.fromApiResponse(json['destination'] as Map<String, dynamic>),
      departure: DateTime.parse(json['departure'] as String),
      arrival: json['arrival'] != null ? DateTime.parse(json['arrival'] as String) : null,
      line: json['line']?['name'] as String?,
      lineName: json['line']?['productName'] as String?,
      direction: json['direction'] as String?,
      mode: json['line']?['product'] as String? ?? (isWalking ? 'walking' : 'unknown'),
      duration: json['duration'] as int?,
      platform: json['departurePlatform'] as String?,
      stops: stops,
      isWalking: isWalking,
      departureDelay: json['departureDelay'] as int?,
      arrivalDelay: json['arrivalDelay'] as int?,
      cancelled: json['cancelled'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'origin': origin.toMap(),
      'destination': destination.toMap(),
      'departure': departure.toIso8601String(),
      'arrival': arrival?.toIso8601String(),
      'line': line,
      'lineName': lineName,
      'direction': direction,
      'mode': mode,
      'duration': duration,
      'platform': platform,
      'stops': stops?.map((s) => s.toMap()).toList(),
      'isWalking': isWalking,
      'departureDelay': departureDelay,
      'arrivalDelay': arrivalDelay,
      'cancelled': cancelled,
    };
  }

  factory VbbLeg.fromMap(Map<String, dynamic> map) {
    return VbbLeg(
      origin: VbbLocation.fromMap(map['origin'] as Map<String, dynamic>),
      destination: VbbLocation.fromMap(map['destination'] as Map<String, dynamic>),
      departure: DateTime.parse(map['departure'] as String),
      arrival: map['arrival'] != null ? DateTime.parse(map['arrival'] as String) : null,
      line: map['line'] as String?,
      lineName: map['lineName'] as String?,
      direction: map['direction'] as String?,
      mode: map['mode'] as String? ?? 'unknown',
      duration: map['duration'] as int?,
      platform: map['platform'] as String?,
      stops: map['stops'] != null
          ? (map['stops'] as List).map((s) => VbbStop.fromMap(s as Map<String, dynamic>)).toList()
          : null,
      isWalking: map['isWalking'] as bool? ?? false,
      departureDelay: map['departureDelay'] as int?,
      arrivalDelay: map['arrivalDelay'] as int?,
      cancelled: map['cancelled'] as bool? ?? false,
    );
  }

  bool get isDelayed => (departureDelay != null && departureDelay! > 0) || cancelled;

  String get delayDisplay {
    if (cancelled) return 'Ausfall';
    if (departureDelay == null || departureDelay! <= 0) return '';
    final minutes = departureDelay! ~/ 60;
    return '+$minutes';
  }

  String get departureTime =>
      '${departure.hour}:${departure.minute.toString().padLeft(2, '0')}';

  String get arrivalTime => arrival != null
      ? '${arrival!.hour}:${arrival!.minute.toString().padLeft(2, '0')}'
      : '';

  String get modeIcon {
    switch (mode) {
      case 'suburban':
        return 'S';
      case 'subway':
        return 'U';
      case 'tram':
        return 'M';
      case 'bus':
        return 'BUS';
      case 'ferry':
        return 'F';
      case 'express':
      case 'regional':
        return 'RE';
      case 'walking':
        return '🚶';
      default:
        return '';
    }
  }
}

class VbbStop {
  final VbbLocation stop;
  final DateTime? arrival;
  final DateTime? departure;
  final String? platform;

  VbbStop({
    required this.stop,
    this.arrival,
    this.departure,
    this.platform,
  });

  factory VbbStop.fromApiResponse(Map<String, dynamic> json) {
    return VbbStop(
      stop: VbbLocation.fromApiResponse(json['stop'] as Map<String, dynamic>),
      arrival: json['arrival'] != null ? DateTime.parse(json['arrival'] as String) : null,
      departure: json['departure'] != null ? DateTime.parse(json['departure'] as String) : null,
      platform: json['platform'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stop': stop.toMap(),
      'arrival': arrival?.toIso8601String(),
      'departure': departure?.toIso8601String(),
      'platform': platform,
    };
  }

  factory VbbStop.fromMap(Map<String, dynamic> map) {
    return VbbStop(
      stop: VbbLocation.fromMap(map['stop'] as Map<String, dynamic>),
      arrival: map['arrival'] != null ? DateTime.parse(map['arrival'] as String) : null,
      departure: map['departure'] != null ? DateTime.parse(map['departure'] as String) : null,
      platform: map['platform'] as String?,
    );
  }
}

class VbbDeparture {
  final String tripId;
  final String line;
  final String lineName;
  final String direction;
  final DateTime when;
  final DateTime? plannedWhen;
  final int? delay;
  final String? platform;
  final String mode;

  VbbDeparture({
    required this.tripId,
    required this.line,
    required this.lineName,
    required this.direction,
    required this.when,
    this.plannedWhen,
    this.delay,
    this.platform,
    required this.mode,
  });

  factory VbbDeparture.fromApiResponse(Map<String, dynamic> json) {
    return VbbDeparture(
      tripId: json['tripId'] as String? ?? '',
      line: json['line']?['name'] as String? ?? '',
      lineName: json['line']?['productName'] as String? ?? '',
      direction: json['direction'] as String? ?? '',
      when: DateTime.parse(json['when'] as String? ?? json['plannedWhen'] as String),
      plannedWhen: json['plannedWhen'] != null
          ? DateTime.parse(json['plannedWhen'] as String)
          : null,
      delay: json['delay'] as int?,
      platform: json['platform'] as String?,
      mode: json['line']?['product'] as String? ?? 'unknown',
    );
  }

  String get departureTime =>
      '${when.hour}:${when.minute.toString().padLeft(2, '0')}';

  bool get isDelayed => delay != null && delay! > 0;

  String get delayDisplay {
    if (delay == null || delay! <= 0) return '';
    final minutes = delay! ~/ 60;
    return '+$minutes';
  }

  String get minutesUntil {
    final diff = when.difference(DateTime.now());
    if (diff.inMinutes <= 0) return 'jetzt';
    if (diff.inMinutes < 60) return '${diff.inMinutes} Min.';
    return '${diff.inHours}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}';
  }
}

class VbbFavoriteRoute {
  final String id;
  final String name;
  final String fromId;
  final String fromName;
  final String toId;
  final String toName;
  final DateTime createdAt;

  VbbFavoriteRoute({
    required this.id,
    required this.name,
    required this.fromId,
    required this.fromName,
    required this.toId,
    required this.toName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'from_id': fromId,
      'from_name': fromName,
      'to_id': toId,
      'to_name': toName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory VbbFavoriteRoute.fromMap(Map<String, dynamic> map) {
    return VbbFavoriteRoute(
      id: map['id'] as String,
      name: map['name'] as String,
      fromId: map['from_id'] as String,
      fromName: map['from_name'] as String,
      toId: map['to_id'] as String,
      toName: map['to_name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class VbbTicket {
  final String id;
  final String ticketType;
  final String ticketName;
  final String zoneCoverage;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool autoRenews;
  final DateTime createdAt;

  VbbTicket({
    required this.id,
    required this.ticketType,
    required this.ticketName,
    required this.zoneCoverage,
    this.validFrom,
    this.validUntil,
    this.autoRenews = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticket_type': ticketType,
      'ticket_name': ticketName,
      'zone_coverage': zoneCoverage,
      'valid_from': validFrom?.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'auto_renews': autoRenews ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory VbbTicket.fromMap(Map<String, dynamic> map) {
    return VbbTicket(
      id: map['id'] as String,
      ticketType: map['ticket_type'] as String? ?? 'custom',
      ticketName: map['ticket_name'] as String,
      zoneCoverage: map['zone_coverage'] as String? ?? 'all',
      validFrom: map['valid_from'] != null
          ? DateTime.parse(map['valid_from'] as String)
          : null,
      validUntil: map['valid_until'] != null
          ? DateTime.parse(map['valid_until'] as String)
          : null,
      autoRenews: map['auto_renews'] == 1 || map['auto_renews'] == true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  bool get isValid {
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) {
      if (!autoRenews) return false;
    }
    return true;
  }

  bool get expiresSoon {
    if (validUntil == null) return false;
    final daysLeft = validUntil!.difference(DateTime.now()).inDays;
    return daysLeft >= 0 && daysLeft <= 7;
  }

  String get validityDisplay {
    if (validUntil != null) {
      final formatted = '${validUntil!.day.toString().padLeft(2, '0')}.${validUntil!.month.toString().padLeft(2, '0')}.${validUntil!.year}';
      return 'bis $formatted';
    }
    if (autoRenews) return 'Abo';
    return 'unbegrenzt';
  }

  String get zoneDisplay {
    switch (zoneCoverage) {
      case 'AB':
        return 'Berlin AB';
      case 'ABC':
        return 'Berlin ABC';
      case 'all':
        return 'Deutschlandweit';
      default:
        return zoneCoverage;
    }
  }
}