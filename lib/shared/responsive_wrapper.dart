import 'package:flutter/material.dart';

/// Widget utilitaire qui choisit le layout mobile ou PC
/// selon la largeur de l'écran (breakpoint : 700px)
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget pc;
  final int breakpoint;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.pc,
    this.breakpoint = 700,
  });

  static bool isPC(BuildContext context, {int breakpoint = 700}) =>
      MediaQuery.of(context).size.width >= breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) return pc;
        return mobile;
      },
    );
  }
}

/// Widget pour les sous-pages : centre le contenu avec une largeur max
/// sur grand écran. Utiliser comme body ou enfant du scrollable.
class PcPageBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;

  const PcPageBody({
    super.key,
    required this.child,
    this.maxWidth = 1100,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? maxWidth : double.infinity),
        child: Padding(
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: isWide ? 32.0 : 0.0,
                vertical: isWide ? 8.0 : 0.0,
              ),
          child: child,
        ),
      ),
    );
  }
}
