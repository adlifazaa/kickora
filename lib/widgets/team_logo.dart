import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../core/mock/mock_visual_resolver.dart';
import '../data/models/competition_model.dart';
import '../data/models/team_model.dart';
import 'api_display_text.dart';
import 'mock_competition_badge.dart';
import 'mock_flag_badge.dart';
import 'network_logo_image.dart';

/// Team crest — API logo, flag, local mock flag, then initials.
class TeamLogo extends StatelessWidget {
  const TeamLogo({
    super.key,
    required this.shortName,
    this.imageUrl,
    this.flagUrl,
    this.countryName,
    this.countryCode,
    this.teamId,
    this.size = 36,
  });

  final String shortName;
  final String? imageUrl;
  final String? flagUrl;
  final String? countryName;
  final String? countryCode;
  final int? teamId;
  final double size;

  factory TeamLogo.fromTeam(TeamModel team, {Key? key, double size = 36}) {
    return TeamLogo(
      key: key,
      shortName: teamShortCode(team.shortName, team.name),
      imageUrl: team.logoUrl.isNotEmpty ? team.logoUrl : team.logo,
      flagUrl: team.flagUrl,
      countryName: team.countryName,
      countryCode: team.countryCode,
      teamId: team.id,
      size: size,
    );
  }

  static const List<List<Color>> _palettes = [
    [Color(0xFF00D1C1), Color(0xFF008F86)],
    [Color(0xFF7CFF00), Color(0xFF2EA90E)],
    [Color(0xFFFFB020), Color(0xFFE0541A)],
    [Color(0xFF63D4FF), Color(0xFF1E78D4)],
    [Color(0xFFFF5A63), Color(0xFFB1213F)],
    [Color(0xFFBBA3FF), Color(0xFF6A4AE0)],
    [Color(0xFFFFE566), Color(0xFFFFA22A)],
    [Color(0xFFE0E6EE), Color(0xFF7A8290)],
  ];

  List<Color> _palette() {
    if (shortName.isEmpty) return _palettes[0];
    final code = shortName.codeUnitAt(0) + shortName.length * 7;
    return _palettes[code % _palettes.length];
  }

  String get _initials {
    final code = sanitizeApiDisplayText(shortName);
    if (code.isNotEmpty) {
      return code.substring(0, code.length.clamp(1, 3));
    }
    return '?';
  }

  String? get _resolvedNetworkUrl {
    final logo = imageUrl?.trim();
    if (isNetworkImageUrl(logo)) return logo;
    final flag = flagUrl?.trim();
    if (isNetworkImageUrl(flag)) return flag;
    return null;
  }

  String? get _resolvedAssetPath {
    return MockVisualResolver.bundledAssetPath(imageUrl) ??
        MockVisualResolver.bundledAssetPath(flagUrl);
  }

  Widget? get _mockFlagVisual {
    final key = MockVisualResolver.flagKeyForTeam(
      shortName: shortName,
      countryName: countryName,
      countryCode: countryCode,
      teamId: teamId,
    );
    if (key == null) return null;
    return MockFlagBadge(flagKey: key, size: size);
  }

  Widget _initialsBadge() {
    final colors = _palette();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.35),
            blurRadius: size * 0.4,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.32,
          letterSpacing: 0.4,
          shadows: const [
            Shadow(blurRadius: 4, color: Color(0x88000000)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NetworkLogoImage(
      size: size,
      imageUrl: _resolvedNetworkUrl,
      assetPath: _resolvedAssetPath,
      localVisual: _mockFlagVisual,
      fallback: _initialsBadge(),
    );
  }
}

/// Compact horizontally-laid out crest used in lists and headers.
class TeamCrestTile extends StatelessWidget {
  const TeamCrestTile({
    super.key,
    required this.shortName,
    required this.name,
    this.imageUrl,
    this.flagUrl,
    this.countryName,
    this.countryCode,
    this.teamId,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  factory TeamCrestTile.fromTeam(
    TeamModel team, {
    Key? key,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return TeamCrestTile(
      key: key,
      shortName: team.shortName,
      name: team.name,
      imageUrl: team.logoUrl.isNotEmpty ? team.logoUrl : team.logo,
      flagUrl: team.flagUrl,
      countryName: team.countryName,
      countryCode: team.countryCode,
      teamId: team.id,
      subtitle: subtitle ?? team.countryName,
      trailing: trailing,
      onTap: onTap,
    );
  }

  final String shortName;
  final String name;
  final String? imageUrl;
  final String? flagUrl;
  final String? countryName;
  final String? countryCode;
  final int? teamId;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
          child: Row(
            children: [
              TeamLogo(
                shortName: teamShortCode(shortName, name),
                imageUrl: imageUrl,
                flagUrl: flagUrl,
                countryName: countryName,
                countryCode: countryCode,
                teamId: teamId,
                size: 34,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    if (subtitle != null &&
                        sanitizeApiDisplayText(subtitle).isNotEmpty)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Competition badge — API crest, mock league shield, then initials.
class CompetitionBadge extends StatelessWidget {
  const CompetitionBadge({
    super.key,
    required this.logo,
    this.size = 40,
    this.competitionId,
    this.competitionName,
  });

  factory CompetitionBadge.fromCompetition(
    CompetitionModel competition, {
    Key? key,
    double size = 40,
  }) {
    return CompetitionBadge(
      key: key,
      logo: competition.logoUrl.isNotEmpty
          ? competition.logoUrl
          : competition.logo,
      competitionId: competition.id,
      competitionName: competition.name,
      size: size,
    );
  }

  final String logo;
  final double size;
  final int? competitionId;
  final String? competitionName;

  String get _initials {
    if (logo.isEmpty) return '?';
    if (isNetworkImageUrl(logo)) {
      return '?';
    }
    return logo.length <= 3 ? logo : logo.substring(0, 3);
  }

  Widget _initialsBadge() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.teal, AppColors.tealDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.25),
            blurRadius: size * 0.4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.34,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget? get _mockCompetitionVisual {
    final key = MockVisualResolver.competitionKeyFor(
      logo: logo,
      name: competitionName,
      id: competitionId,
    );
    if (key == null) return null;
    return MockCompetitionBadge(competitionKey: key, size: size);
  }

  @override
  Widget build(BuildContext context) {
    final networkUrl = isNetworkImageUrl(logo) ? logo : null;
    return NetworkLogoImage(
      size: size,
      imageUrl: networkUrl,
      assetPath: MockVisualResolver.bundledAssetPath(logo),
      localVisual: _mockCompetitionVisual,
      fallback: _initialsBadge(),
    );
  }
}
