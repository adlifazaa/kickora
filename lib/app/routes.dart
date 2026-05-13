import 'package:flutter/material.dart';

import '../models/competition_model.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../screens/about_screen.dart';
import '../screens/competition_details_screen.dart';
import '../screens/competitions_screen.dart';
import '../screens/home_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/match_details_screen.dart';
import '../screens/matches_screen.dart';
import '../screens/player_details_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/terms_of_use_screen.dart';
import '../screens/standings_screen.dart';
import '../widgets/micro_interactions.dart';

class AppRoutes {
  static const splash = '/';
  static const mainNavigation = '/main';
  static const matches = '/matches';
  static const matchDetails = '/match-details';
  static const competitions = '/competitions';
  static const standings = '/standings';
  static const competitionDetails = '/competition-details';
  static const playerDetails = '/player-details';
  static const about = '/about';
  static const privacy = '/privacy';
  static const terms = '/terms';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        // Splash should use the platform default fade so the first paint
        // doesn't feel "pushed".
        return MaterialPageRoute(
            settings: settings,
            builder: (context) => const SplashScreen());
      case mainNavigation:
        return MaterialPageRoute(
            settings: settings,
            builder: (context) => const MainNavigationScreen());
      case matches:
        return PremiumPageRoute(
            settings: settings,
            builder: (context) => const MatchesScreen());
      case matchDetails:
        final match = settings.arguments as MatchModel;
        return PremiumPageRoute(
            settings: settings,
            builder: (context) => MatchDetailsScreen(match: match));
      case competitions:
        return PremiumPageRoute(
            settings: settings,
            builder: (context) => const CompetitionsScreen());
      case standings:
        return PremiumPageRoute(
            settings: settings,
            builder: (context) => const StandingsScreen());
      case competitionDetails:
        final competition = settings.arguments as CompetitionModel;
        return PremiumPageRoute(
            settings: settings,
            builder: (context) =>
                CompetitionDetailsScreen(competition: competition));
      case playerDetails:
        final player = settings.arguments as PlayerModel;
        return PremiumPageRoute(
            settings: settings,
            builder: (context) => PlayerDetailsScreen(player: player));
      case about:
        return PremiumPageRoute(
            settings: settings, builder: (context) => const AboutScreen());
      case privacy:
        return PremiumPageRoute(
            settings: settings,
            builder: (context) => const PrivacyPolicyScreen());
      case terms:
        return PremiumPageRoute(
            settings: settings,
            builder: (context) => const TermsOfUseScreen());
      default:
        return MaterialPageRoute(
            settings: settings, builder: (context) => const HomeScreen());
    }
  }
}
