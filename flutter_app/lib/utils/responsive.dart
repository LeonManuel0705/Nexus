import 'package:flutter/material.dart';

/// Responsive breakpoints for different device sizes
class ResponsiveBreakpoints {
  static const double phone = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Device type enum
enum DeviceType { phone, tablet, desktop }

/// Helper class for responsive design
class Responsive {
  /// Get the device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < ResponsiveBreakpoints.phone) {
      return DeviceType.phone;
    } else if (width < ResponsiveBreakpoints.tablet) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Check if device is a phone
  static bool isPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < ResponsiveBreakpoints.phone;
  }

  /// Check if device is a tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ResponsiveBreakpoints.phone && width < ResponsiveBreakpoints.desktop;
  }

  /// Check if device is desktop-sized
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktop;
  }

  /// Check if device should use tablet/desktop layout (not phone)
  static bool useTabletLayout(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.phone;
  }

  /// Get sidebar width for tablet/desktop
  static double getSidebarWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= ResponsiveBreakpoints.desktop) {
      return 280;
    } else if (width >= ResponsiveBreakpoints.tablet) {
      return 240;
    } else {
      return 200;
    }
  }

  /// Get number of grid columns based on screen width
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= ResponsiveBreakpoints.desktop) {
      return 4;
    } else if (width >= ResponsiveBreakpoints.tablet) {
      return 3;
    } else if (width >= ResponsiveBreakpoints.phone) {
      return 2;
    }
    return 1;
  }

  /// Get content padding based on device type
  static EdgeInsets getContentPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.desktop:
        return const EdgeInsets.all(32);
      case DeviceType.tablet:
        return const EdgeInsets.all(24);
      case DeviceType.phone:
        return const EdgeInsets.all(16);
    }
  }
}

/// Widget that builds different layouts for phone/tablet
class ResponsiveBuilder extends StatelessWidget {
  final Widget phone;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.phone,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = Responsive.getDeviceType(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? phone;
      case DeviceType.tablet:
        return tablet ?? phone;
      case DeviceType.phone:
        return phone;
    }
  }
}
