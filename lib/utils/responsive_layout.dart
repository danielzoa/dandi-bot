import 'package:flutter/material.dart';

import 'responsive_breakpoints.dart';

abstract final class ResponsiveLayout {
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < ResponsiveBreakpoints.mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= ResponsiveBreakpoints.mobile &&
        width < ResponsiveBreakpoints.tablet;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= ResponsiveBreakpoints.tablet;
  }
}
