import 'package:flutter/material.dart';

/// Breakpoints responsivos y utilidades para Hyro.
///
/// - Móvil:     < 768px
/// - Tablet:    768px — 1200px
/// - Escritorio: > 1200px
class Responsive {
  Responsive._();

  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  /// Devuelve valores diferentes según el breakpoint actual.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }
}

/// Un widget constructor responsivo que se reconstruye con los cambios de diseño.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Responsive.tabletBreakpoint) {
          return (desktop ?? tablet ?? mobile)(context);
        }
        if (constraints.maxWidth >= Responsive.mobileBreakpoint) {
          return (tablet ?? mobile)(context);
        }
        return mobile(context);
      },
    );
  }
}
