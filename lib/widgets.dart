import 'package:flutter/material.dart';

import 'store.dart';
import 'theme.dart';

/// Rounded white card with a soft pastel shadow.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = Pal.card,
    this.radius = 24,
    this.shadow = true,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final bool shadow;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ? softShadow : null,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

/// Topic avatar shown at the top of the dashboard.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.gender, this.size = 46});

  final String gender;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String asset = gender == 'female'
        ? 'assets/avatars/female.png'
        : 'assets/avatars/male.png';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Pal.lavenderSoft, Pal.blushSoft],
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: tinyShadow,
      ),
      padding: EdgeInsets.all(size * 0.06),
      child: ClipOval(
        child: Image.asset(asset, fit: BoxFit.cover),
      ),
    );
  }
}

/// Compact name + avatar strip shown at the top of the main tabs.
class UserStrip extends StatelessWidget {
  const UserStrip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final AppStore store = AppStore.instance;
    return Row(
      children: <Widget>[
        Avatar(gender: store.gender, size: 34),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                store.name.isEmpty ? 'Learner' : store.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Pal.ink,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Pal.inkSoft, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Rounded progress bar with pastel track/fill.
class PastelProgress extends StatelessWidget {
  const PastelProgress({
    super.key,
    required this.value,
    this.color = Pal.lavender,
    this.trackColor = Pal.lavenderSoft,
    this.height = 10,
  });

  /// 0..1 progress.
  final double value;
  final Color color;
  final Color trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: trackColor,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

/// Small label pill.
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.text,
    this.color = Pal.lavender,
    this.soft = Pal.lavenderSoft,
    this.icon,
  });

  final String text;
  final Color color;
  final Color soft;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Consistent page spacing wrapper.
class PagePad extends StatelessWidget {
  const PagePad({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: child,
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message});

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 64, color: Pal.lavenderSoft),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Pal.ink,
              ),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Pal.inkSoft, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
