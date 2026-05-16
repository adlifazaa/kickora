import 'package:flutter/material.dart';

import 'network_logo_image.dart';

/// Safe display string — never lay out raw image URLs as text.
String sanitizeApiDisplayText(String? value) {
  if (value == null) return '';
  final trimmed = value.trim();
  if (trimmed.isEmpty || isNetworkImageUrl(trimmed)) return '';
  return trimmed;
}

/// Ellipsis text for API-backed labels inside width-bounded parents.
class ApiDisplayText extends StatelessWidget {
  const ApiDisplayText(
    this.value, {
    super.key,
    required this.style,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
  });

  final String? value;
  final TextStyle style;
  final int maxLines;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final label = sanitizeApiDisplayText(value);
    if (label.isEmpty) return const SizedBox.shrink();
    return Text(
      label,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      textAlign: textAlign,
      style: style,
    );
  }
}

/// Three-letter style code from a team name when API code is missing or is a URL.
String abbreviateTeamName(String name) {
  final clean = sanitizeApiDisplayText(name);
  if (clean.isEmpty) return '?';
  final parts =
      clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final word = parts.first;
    return word.length <= 3
        ? word.toUpperCase()
        : word.substring(0, 3).toUpperCase();
  }
  final code = parts.map((p) => p[0]).join();
  return code.length <= 3
      ? code.toUpperCase()
      : code.substring(0, 3).toUpperCase();
}

String teamShortCode(String shortName, String fullName) {
  final code = sanitizeApiDisplayText(shortName);
  if (code.isNotEmpty) return code;
  return abbreviateTeamName(fullName);
}
