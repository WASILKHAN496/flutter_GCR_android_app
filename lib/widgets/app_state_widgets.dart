import 'package:best_flutter_ui_templates/app_theme.dart';
import 'package:flutter/material.dart';

class AppLoadingCard extends StatelessWidget {
  const AppLoadingCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.cloud_sync_rounded,
    this.color = const Color(0xFF42A5F5),
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bool isLightMode = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          boxShadow: cardShadow(isLightMode),
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: color.withOpacity(0.13),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: SizedBox(
                  height: 26,
                  width: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: isLightMode ? AppTheme.darkText : AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: isLightMode
                          ? AppTheme.grey
                          : AppTheme.white.withOpacity(0.68),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppEmptyCard extends StatelessWidget {
  const AppEmptyCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.color = const Color(0xFFFFA726),
    this.buttonText,
    this.onButtonTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? buttonText;
  final VoidCallback? onButtonTap;

  @override
  Widget build(BuildContext context) {
    final bool isLightMode = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          boxShadow: cardShadow(isLightMode),
        ),
        child: Column(
          children: <Widget>[
            Container(
              height: 76,
              width: 76,
              decoration: BoxDecoration(
                color: color.withOpacity(0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 38,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isLightMode ? AppTheme.darkText : AppTheme.white,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontSize: 12.8,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: isLightMode
                    ? AppTheme.grey
                    : AppTheme.white.withOpacity(0.68),
              ),
            ),
            if (buttonText != null && onButtonTap != null) ...<Widget>[
              const SizedBox(height: 16),
              AppGradientButton(
                title: buttonText!,
                icon: Icons.refresh_rounded,
                onTap: onButtonTap!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppErrorCard extends StatelessWidget {
  const AppErrorCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.error_outline_rounded,
    this.color = const Color(0xFFEF5350),
    this.onRetry,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final bool isLightMode = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isLightMode ? Colors.white : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.20),
          ),
          boxShadow: cardShadow(isLightMode),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: color.withOpacity(0.13),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: isLightMode ? AppTheme.darkText : AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cleanError(subtitle),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontSize: 12.4,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: isLightMode
                          ? AppTheme.grey
                          : AppTheme.white.withOpacity(0.68),
                    ),
                  ),
                  if (onRetry != null) ...<Widget>[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 120,
                      child: AppGradientButton(
                        title: 'Retry',
                        icon: Icons.refresh_rounded,
                        onTap: onRetry!,
                        height: 42,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String cleanError(String error) {
    if (error.trim().isEmpty) {
      return 'Something went wrong. Please try again.';
    }

    return error
        .replaceAll('Exception:', '')
        .replaceAll('ApiRequestError', '')
        .trim();
  }
}

class AppGradientButton extends StatelessWidget {
  const AppGradientButton({
    super.key,
    required this.title,
    required this.onTap,
    this.icon,
    this.height = 46,
  });

  final String title;
  final VoidCallback onTap;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF00AEEF),
              Color(0xFF2633C5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 7),
            ],
            Text(
              title,
              style: const TextStyle(
                fontFamily: AppTheme.fontName,
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<BoxShadow> cardShadow(bool isLightMode) {
  return <BoxShadow>[
    BoxShadow(
      color: isLightMode
          ? AppTheme.grey.withOpacity(0.15)
          : Colors.black.withOpacity(0.22),
      offset: const Offset(1, 3),
      blurRadius: 10,
    ),
  ];
}