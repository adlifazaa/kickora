import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/world_cup_config.dart';

/// Countdown to World Cup final kickoff.
class WorldCupFinalCountdown extends StatefulWidget {
  const WorldCupFinalCountdown({super.key, required this.isArabic});

  final bool isArabic;

  @override
  State<WorldCupFinalCountdown> createState() => _WorldCupFinalCountdownState();
}

class _WorldCupFinalCountdownState extends State<WorldCupFinalCountdown> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
  }

  void _tick() {
    final target = WorldCupConfig.finalKickoffUtc.toLocal();
    final now = DateTime.now();
    setState(() {
      _remaining =
          target.isAfter(now) ? target.difference(now) : Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining <= Duration.zero) {
      return Text(
        widget.isArabic ? 'انطلقت البطولة!' : 'Tournament is underway!',
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      );
    }
    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _unit(days, widget.isArabic ? 'يوم' : 'Days'),
        const SizedBox(width: 16),
        _unit(hours, widget.isArabic ? 'ساعة' : 'Hours'),
      ],
    );
  }

  Widget _unit(int value, String label) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }
}
