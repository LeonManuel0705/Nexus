import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  static const double phone = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double sidebar = 768;
}

enum DeviceType { phone, tablet, desktop }

class Responsive {

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

  static bool isPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < ResponsiveBreakpoints.phone;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ResponsiveBreakpoints.phone && width < ResponsiveBreakpoints.desktop;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktop;
  }

  static bool useTabletLayout(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.sidebar;
  }

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
