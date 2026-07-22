import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Verrouille l'écran avec un loader non-fermable pendant l'exécution de
/// [work] (généralement la phase de construction du document PDF :
/// chargement des polices Google, image logo, addPage, etc.).
///
/// Le loader est fermé **automatiquement** dès que [work] se termine, juste
/// avant que la prévisualisation native (`Printing.layoutPdf`) ne soit
/// affichée par l'appelant.
///
/// Sécurité :
/// - `barrierDismissible: false` → empêche la fermeture par tap hors dialogue.
/// - `PopScope(canPop: false)` → bloque le bouton retour Android.
/// - `rootNavigator: true` → on ferme bien notre dialogue, pas un autre.
Future<T> runWithPdfLoadingOverlay<T>({
  required BuildContext context,
  required Future<T> Function() work,
  String? messageKey,
  Color spinnerColor = const Color(0xFF5A47C9),
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  bool overlayShown = false;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.15),
    useRootNavigator: true,
    builder: (_) => PopScope(
      canPop: false,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Center(
          child: _PdfLoadingCard(
            spinnerColor: spinnerColor,
            message: (messageKey ?? 'pdf_loading_generating').tr(),
          ),
        ),
      ),
    ),
  );
  overlayShown = true;

  try {
    return await work();
  } finally {
    if (overlayShown) {
      try {
        navigator.pop();
      } catch (_) {}
    }
  }
}

/// Carte visuelle du loader PDF — design moderne, non intrusif.
class _PdfLoadingCard extends StatefulWidget {
  final Color spinnerColor;
  final String message;

  const _PdfLoadingCard({required this.spinnerColor, required this.message});

  @override
  State<_PdfLoadingCard> createState() => _PdfLoadingCardState();
}

class _PdfLoadingCardState extends State<_PdfLoadingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          width: 240,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: widget.spinnerColor.withOpacity(0.12),
                blurRadius: 32,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône PDF avec spinner autour
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(widget.spinnerColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: widget.spinnerColor.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      color: widget.spinnerColor,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: Colors.grey.shade800,
                  height: 1.4,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'pdf_loading_subtitle'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.grey.shade500,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
