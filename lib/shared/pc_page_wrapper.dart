import 'package:flutter/material.dart';
import 'responsive_wrapper.dart';

/// Wrapper pour les sous-pages (hors dashboard) sur PC.
/// Centre le contenu avec un max-width et ajoute un fond discret.
/// Le layout mobile reste inchangé.
class PcPageScaffold extends StatelessWidget {
  final Widget appBar; // AppBar mobile (PreferredSizeWidget passé comme Widget)
  final Widget body;
  final double maxWidth;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const PcPageScaffold({
    super.key,
    required this.appBar,
    required this.body,
    this.maxWidth = 960,
    this.backgroundColor,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    if (!ResponsiveLayout.isPC(context)) {
      // Mobile : renvoyer tel quel — pas d'usage prévu ici, géré dans chaque page
      return body;
    }
    return body;
  }
}

/// Utilitaire : enveloppe le body d'une page dans un Container centré
/// adapté au PC. À utiliser dans le body d'un Scaffold.
class PcCenteredBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;
  final Color backgroundColor;

  const PcCenteredBody({
    super.key,
    required this.child,
    this.maxWidth = 960,
    this.padding,
    this.backgroundColor = const Color(0xFFF4F6FA),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Helper : renvoie le padding horizontal adapté à la taille d'écran
EdgeInsets adaptivePadding(BuildContext context,
    {double mobile = 16, double tablet = 32, double pc = 48}) {
  final w = MediaQuery.of(context).size.width;
  final h = w >= 700
      ? pc
      : w >= 500
          ? tablet
          : mobile;
  return EdgeInsets.symmetric(horizontal: h, vertical: 16);
}

/// Helper : max-width pour les listes et formulaires sur PC
double pcMaxWidth(BuildContext context, {double max = 960}) {
  return MediaQuery.of(context).size.width >= 700 ? max : double.infinity;
}
