import '../models/competition_model.dart';
import '../models/lineup_model.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/standing_model.dart';
import '../models/team_model.dart';

class MockData {
  static const teams = [
    TeamModel(id: 1, name: 'Argentina', shortName: 'ARG', logo: 'ARG', nationality: 'Argentina'),
    TeamModel(id: 2, name: 'Brazil', shortName: 'BRA', logo: 'BRA', nationality: 'Brazil'),
    TeamModel(id: 3, name: 'France', shortName: 'FRA', logo: 'FRA', nationality: 'France'),
    TeamModel(id: 4, name: 'Spain', shortName: 'ESP', logo: 'ESP', nationality: 'Spain'),
    TeamModel(id: 5, name: 'Morocco', shortName: 'MAR', logo: 'MAR', nationality: 'Morocco'),
    TeamModel(id: 6, name: 'Germany', shortName: 'GER', logo: 'GER', nationality: 'Germany'),
  ];

  static const competitions = [
    CompetitionModel(id: 1, name: 'World Cup 2026', region: 'International', logo: 'WC', isFeatured: true),
    CompetitionModel(id: 2, name: 'Premier League', region: 'England', logo: 'PL'),
    CompetitionModel(id: 3, name: 'La Liga', region: 'Spain', logo: 'LL'),
    CompetitionModel(id: 4, name: 'Serie A', region: 'Italy', logo: 'SA'),
    CompetitionModel(id: 5, name: 'Bundesliga', region: 'Germany', logo: 'BL'),
  ];

  static const standings = [
    StandingModel(position: 1, team: TeamModel(id: 1, name: 'Argentina', shortName: 'ARG', logo: 'ARG', nationality: 'Argentina'), played: 3, wins: 3, draws: 0, losses: 0, goalDifference: 6, points: 9),
    StandingModel(position: 2, team: TeamModel(id: 2, name: 'Brazil', shortName: 'BRA', logo: 'BRA', nationality: 'Brazil'), played: 3, wins: 2, draws: 1, losses: 0, goalDifference: 4, points: 7),
    StandingModel(position: 3, team: TeamModel(id: 3, name: 'France', shortName: 'FRA', logo: 'FRA', nationality: 'France'), played: 3, wins: 2, draws: 0, losses: 1, goalDifference: 3, points: 6),
    StandingModel(position: 4, team: TeamModel(id: 4, name: 'Spain', shortName: 'ESP', logo: 'ESP', nationality: 'Spain'), played: 3, wins: 1, draws: 1, losses: 1, goalDifference: 0, points: 4),
    StandingModel(position: 5, team: TeamModel(id: 5, name: 'Morocco', shortName: 'MAR', logo: 'MAR', nationality: 'Morocco'), played: 3, wins: 1, draws: 0, losses: 2, goalDifference: -2, points: 3),
    StandingModel(position: 6, team: TeamModel(id: 6, name: 'Germany', shortName: 'GER', logo: 'GER', nationality: 'Germany'), played: 3, wins: 0, draws: 0, losses: 3, goalDifference: -11, points: 0),
  ];

  static final List<PlayerModel> players = [
    PlayerModel(id: 10, name: 'Lionel Messi', shortName: 'MES', number: 10, nationality: 'Argentina', age: 39, height: 170, weight: 72, position: 'RW', team: 'Argentina', teamLogoShort: 'ARG', appearances: 24, minutesPlayed: 2011, goals: 12, assists: 11, yellowCards: 2, redCards: 0, isCaptain: true, preferredFoot: 'Left', matchRating: 8.2, seasonRating: '8.1', career: ['Barcelona', 'PSG', 'Inter Miami', 'Argentina'], recentMatches: const [PlayerRecentMatch(opponent: 'France', rating: '8.4', goals: 1, assists: 0), PlayerRecentMatch(opponent: 'Brazil', rating: '7.9', goals: 0, assists: 1)]),
    PlayerModel(id: 9, name: 'Julian Alvarez', shortName: 'ALV', number: 9, nationality: 'Argentina', age: 26, height: 172, position: 'ST', team: 'Argentina', teamLogoShort: 'ARG', appearances: 28, minutesPlayed: 2100, goals: 16, assists: 5, yellowCards: 3, redCards: 0, preferredFoot: 'Right', matchRating: 7.6, seasonRating: '7.5'),
    PlayerModel(id: 11, name: 'Nicolas Gonzalez', shortName: 'GON', number: 11, nationality: 'Argentina', age: 28, height: 180, position: 'LW', team: 'Argentina', teamLogoShort: 'ARG', appearances: 22, goals: 7, assists: 4, yellowCards: 4, redCards: 0, preferredFoot: 'Left', matchRating: 6.9),
    PlayerModel(id: 7, name: 'Rodri De Paul', shortName: 'RDP', number: 7, nationality: 'Argentina', age: 31, height: 180, position: 'CM', team: 'Argentina', teamLogoShort: 'ARG', appearances: 27, goals: 2, assists: 6, yellowCards: 7, redCards: 0, preferredFoot: 'Right', matchRating: 7.3),
    PlayerModel(id: 5, name: 'Leandro Paredes', shortName: 'PAR', number: 5, nationality: 'Argentina', age: 32, height: 180, position: 'DM', team: 'Argentina', teamLogoShort: 'ARG', appearances: 23, goals: 1, assists: 3, yellowCards: 6, redCards: 0, matchRating: 6.8),
    PlayerModel(id: 8, name: 'Enzo Fernandez', shortName: 'ENZ', number: 8, nationality: 'Argentina', age: 25, height: 178, position: 'CM', team: 'Argentina', teamLogoShort: 'ARG', appearances: 30, goals: 4, assists: 7, yellowCards: 5, redCards: 0, preferredFoot: 'Right', matchRating: 7.1),
    PlayerModel(id: 3, name: 'Nicolas Tagliafico', shortName: 'TAG', number: 3, nationality: 'Argentina', age: 33, height: 172, position: 'LB', team: 'Argentina', teamLogoShort: 'ARG', appearances: 21, goals: 1, assists: 2, yellowCards: 5, redCards: 0, matchRating: 6.7),
    PlayerModel(id: 6, name: 'Lisandro Martinez', shortName: 'LMA', number: 6, nationality: 'Argentina', age: 28, height: 175, position: 'CB', team: 'Argentina', teamLogoShort: 'ARG', appearances: 20, goals: 0, assists: 1, yellowCards: 4, redCards: 0, preferredFoot: 'Left', matchRating: 7.0),
    PlayerModel(id: 2, name: 'Cristian Romero', shortName: 'ROM', number: 2, nationality: 'Argentina', age: 28, height: 185, position: 'CB', team: 'Argentina', teamLogoShort: 'ARG', appearances: 26, goals: 2, assists: 0, yellowCards: 8, redCards: 1, matchRating: 6.4),
    PlayerModel(id: 4, name: 'Nahuel Molina', shortName: 'MOL', number: 4, nationality: 'Argentina', age: 28, height: 175, position: 'RB', team: 'Argentina', teamLogoShort: 'ARG', appearances: 24, goals: 1, assists: 4, yellowCards: 3, redCards: 0, matchRating: 6.9),
    PlayerModel(id: 1, name: 'Emiliano Martinez', shortName: 'EMI', number: 1, nationality: 'Argentina', age: 34, height: 195, weight: 88, position: 'GK', team: 'Argentina', teamLogoShort: 'ARG', appearances: 31, minutesPlayed: 2790, goals: 0, assists: 0, yellowCards: 1, redCards: 0, preferredFoot: 'Right', matchRating: 7.8, career: const ['Arsenal', 'Aston Villa', 'Argentina']),
    PlayerModel(id: 110, name: 'Exequiel Palacios', shortName: 'PAL', number: 14, nationality: 'Argentina', age: 27, height: 177, position: 'CM', team: 'Argentina', teamLogoShort: 'ARG', appearances: 18, goals: 1, assists: 2, yellowCards: 3, redCards: 0),
    PlayerModel(id: 111, name: 'Lautaro Martinez', shortName: 'LAU', number: 22, nationality: 'Argentina', age: 28, height: 174, position: 'ST', team: 'Argentina', teamLogoShort: 'ARG', appearances: 30, goals: 19, assists: 4, yellowCards: 4, redCards: 0),
    PlayerModel(id: 112, name: 'Angel Di Maria', shortName: 'DIM', number: 11, nationality: 'Argentina', age: 37, height: 178, position: 'RW', team: 'Argentina', teamLogoShort: 'ARG', appearances: 20, goals: 5, assists: 6, yellowCards: 2, redCards: 0),
    PlayerModel(id: 30, name: 'Kylian Mbappe', shortName: 'MBP', number: 10, nationality: 'France', age: 28, height: 178, weight: 75, position: 'LW', team: 'France', teamLogoShort: 'FRA', appearances: 25, minutesPlayed: 2190, goals: 21, assists: 8, yellowCards: 2, redCards: 0, isCaptain: true, preferredFoot: 'Right', matchRating: 8.0, seasonRating: '8.2', career: const ['Monaco', 'PSG', 'France']),
    PlayerModel(id: 31, name: 'Marcus Thuram', shortName: 'THU', number: 9, nationality: 'France', age: 29, height: 192, position: 'ST', team: 'France', teamLogoShort: 'FRA', appearances: 22, goals: 13, assists: 4, yellowCards: 3, redCards: 0, preferredFoot: 'Right', matchRating: 7.0),
    PlayerModel(id: 32, name: 'Ousmane Dembele', shortName: 'DEM', number: 11, nationality: 'France', age: 29, height: 178, position: 'RW', team: 'France', teamLogoShort: 'FRA', appearances: 23, goals: 9, assists: 7, yellowCards: 4, redCards: 0, preferredFoot: 'Left', matchRating: 7.2),
    PlayerModel(id: 33, name: 'Rabiot', shortName: 'RAB', number: 14, nationality: 'France', age: 31, height: 188, position: 'CM', team: 'France', teamLogoShort: 'FRA', appearances: 27, goals: 3, assists: 5, yellowCards: 5, redCards: 0, matchRating: 6.9),
    PlayerModel(id: 34, name: 'Camavinga', shortName: 'CAM', number: 6, nationality: 'France', age: 24, height: 182, position: 'CM', team: 'France', teamLogoShort: 'FRA', appearances: 24, goals: 2, assists: 4, yellowCards: 6, redCards: 0, preferredFoot: 'Left', matchRating: 6.6),
    PlayerModel(id: 35, name: 'Tchouameni', shortName: 'TCH', number: 8, nationality: 'France', age: 26, height: 187, position: 'DM', team: 'France', teamLogoShort: 'FRA', appearances: 25, goals: 2, assists: 2, yellowCards: 5, redCards: 0, matchRating: 7.0),
    PlayerModel(id: 36, name: 'Theo Hernandez', shortName: 'THE', number: 22, nationality: 'France', age: 29, height: 184, position: 'LB', team: 'France', teamLogoShort: 'FRA', appearances: 20, goals: 1, assists: 5, yellowCards: 3, redCards: 0, preferredFoot: 'Left', matchRating: 7.4),
    PlayerModel(id: 37, name: 'Saliba', shortName: 'SAL', number: 17, nationality: 'France', age: 26, height: 192, position: 'CB', team: 'France', teamLogoShort: 'FRA', appearances: 21, goals: 1, assists: 0, yellowCards: 2, redCards: 0, matchRating: 7.1),
    PlayerModel(id: 38, name: 'Upamecano', shortName: 'UPA', number: 4, nationality: 'France', age: 28, height: 186, position: 'CB', team: 'France', teamLogoShort: 'FRA', appearances: 21, goals: 0, assists: 0, yellowCards: 4, redCards: 0, matchRating: 6.8),
    PlayerModel(id: 39, name: 'Kounde', shortName: 'KOU', number: 5, nationality: 'France', age: 28, height: 180, position: 'RB', team: 'France', teamLogoShort: 'FRA', appearances: 23, goals: 0, assists: 2, yellowCards: 3, redCards: 0, preferredFoot: 'Right', matchRating: 7.0),
    PlayerModel(id: 40, name: 'Maignan', shortName: 'MAI', number: 1, nationality: 'France', age: 32, height: 191, weight: 86, position: 'GK', team: 'France', teamLogoShort: 'FRA', appearances: 20, minutesPlayed: 1800, goals: 0, assists: 0, yellowCards: 1, redCards: 0, preferredFoot: 'Right', matchRating: 7.5, career: const ['Lille', 'AC Milan', 'France']),
    PlayerModel(id: 120, name: 'Kolo Muani', shortName: 'KOL', number: 12, nationality: 'France', age: 26, height: 187, position: 'ST', team: 'France', teamLogoShort: 'FRA', appearances: 15, goals: 5, assists: 2, yellowCards: 1, redCards: 0),
    PlayerModel(id: 121, name: 'Konate', shortName: 'KON', number: 24, nationality: 'France', age: 26, height: 194, position: 'CB', team: 'France', teamLogoShort: 'FRA', appearances: 12, goals: 0, assists: 0, yellowCards: 2, redCards: 0),
    PlayerModel(id: 122, name: 'Fofana', shortName: 'FOF', number: 19, nationality: 'France', age: 25, height: 185, position: 'CM', team: 'France', teamLogoShort: 'FRA', appearances: 10, goals: 1, assists: 1, yellowCards: 1, redCards: 0),
    // Spain 3-5-2 (demo)
    PlayerModel(id: 201, name: 'Simon', shortName: 'SIM', number: 1, nationality: 'Spain', age: 28, height: 190, position: 'GK', team: 'Spain', teamLogoShort: 'ESP', appearances: 40, goals: 0, assists: 0, yellowCards: 1, redCards: 0, matchRating: 7.2),
    PlayerModel(id: 202, name: 'Laporte', shortName: 'LAP', number: 24, nationality: 'Spain', age: 31, height: 191, position: 'CB', team: 'Spain', teamLogoShort: 'ESP', appearances: 35, goals: 2, assists: 1, yellowCards: 4, redCards: 0, isCaptain: true, matchRating: 7.0),
    PlayerModel(id: 203, name: 'Le Normand', shortName: 'NOR', number: 3, nationality: 'Spain', age: 28, height: 187, position: 'CB', team: 'Spain', teamLogoShort: 'ESP', appearances: 20, goals: 1, assists: 0, yellowCards: 3, redCards: 0, matchRating: 6.9),
    PlayerModel(id: 204, name: 'Nacho', shortName: 'NAC', number: 4, nationality: 'Spain', age: 35, height: 180, position: 'CB', team: 'Spain', teamLogoShort: 'ESP', appearances: 45, goals: 2, assists: 1, yellowCards: 5, redCards: 0, matchRating: 6.8),
    PlayerModel(id: 205, name: 'Cucurella', shortName: 'CUC', number: 14, nationality: 'Spain', age: 27, height: 173, position: 'LWB', team: 'Spain', teamLogoShort: 'ESP', appearances: 18, goals: 0, assists: 3, yellowCards: 4, redCards: 0, preferredFoot: 'Left', matchRating: 7.1),
    PlayerModel(id: 206, name: 'Carvajal', shortName: 'CAR', number: 2, nationality: 'Spain', age: 33, height: 173, position: 'RWB', team: 'Spain', teamLogoShort: 'ESP', appearances: 50, goals: 3, assists: 8, yellowCards: 12, redCards: 0, matchRating: 7.0),
    PlayerModel(id: 207, name: 'Rodri', shortName: 'ROD', number: 16, nationality: 'Spain', age: 29, height: 191, position: 'CM', team: 'Spain', teamLogoShort: 'ESP', appearances: 55, goals: 5, assists: 4, yellowCards: 8, redCards: 0, matchRating: 7.8),
    PlayerModel(id: 208, name: 'Pedri', shortName: 'PED', number: 8, nationality: 'Spain', age: 22, height: 174, position: 'CM', team: 'Spain', teamLogoShort: 'ESP', appearances: 30, goals: 4, assists: 6, yellowCards: 2, redCards: 0, preferredFoot: 'Right', matchRating: 7.6),
    PlayerModel(id: 209, name: 'Dani Olmo', shortName: 'OLM', number: 10, nationality: 'Spain', age: 27, height: 179, position: 'CM', team: 'Spain', teamLogoShort: 'ESP', appearances: 28, goals: 6, assists: 5, yellowCards: 3, redCards: 0, matchRating: 7.2),
    PlayerModel(id: 210, name: 'Morata', shortName: 'MOR', number: 7, nationality: 'Spain', age: 32, height: 190, position: 'ST', team: 'Spain', teamLogoShort: 'ESP', appearances: 48, goals: 22, assists: 6, yellowCards: 6, redCards: 0, matchRating: 7.0),
    PlayerModel(id: 211, name: 'Yamal', shortName: 'YAM', number: 19, nationality: 'Spain', age: 18, height: 180, position: 'ST', team: 'Spain', teamLogoShort: 'ESP', appearances: 12, goals: 4, assists: 3, yellowCards: 1, redCards: 0, preferredFoot: 'Left', matchRating: 7.9),
    PlayerModel(id: 212, name: 'Merino', shortName: 'MER', number: 6, nationality: 'Spain', age: 28, height: 188, position: 'CM', team: 'Spain', teamLogoShort: 'ESP', appearances: 25, goals: 3, assists: 4, yellowCards: 5, redCards: 0),
    // Germany 4-3-3
    PlayerModel(id: 250, name: 'Neuer', shortName: 'NEU', number: 1, nationality: 'Germany', age: 39, height: 193, position: 'GK', team: 'Germany', teamLogoShort: 'GER', appearances: 120, goals: 0, assists: 0, yellowCards: 2, redCards: 0, isCaptain: true, matchRating: 7.0),
    PlayerModel(id: 251, name: 'Kimmich', shortName: 'KIM', number: 6, nationality: 'Germany', age: 30, height: 176, position: 'RB', team: 'Germany', teamLogoShort: 'GER', appearances: 90, goals: 6, assists: 20, yellowCards: 15, redCards: 0, matchRating: 7.4),
    PlayerModel(id: 252, name: 'Tah', shortName: 'TAH', number: 4, nationality: 'Germany', age: 29, height: 195, position: 'CB', team: 'Germany', teamLogoShort: 'GER', appearances: 25, goals: 1, assists: 0, yellowCards: 3, redCards: 0, matchRating: 6.9),
    PlayerModel(id: 253, name: 'Rudiger', shortName: 'RUD', number: 2, nationality: 'Germany', age: 32, height: 190, position: 'CB', team: 'Germany', teamLogoShort: 'GER', appearances: 65, goals: 3, assists: 3, yellowCards: 20, redCards: 1, matchRating: 7.1),
    PlayerModel(id: 254, name: 'Raum', shortName: 'RAU', number: 3, nationality: 'Germany', age: 27, height: 180, position: 'LB', team: 'Germany', teamLogoShort: 'GER', appearances: 22, goals: 0, assists: 5, yellowCards: 4, redCards: 0, matchRating: 6.8),
    PlayerModel(id: 255, name: 'Goretzka', shortName: 'GOR', number: 8, nationality: 'Germany', age: 30, height: 189, position: 'CM', team: 'Germany', teamLogoShort: 'GER', appearances: 60, goals: 14, assists: 10, yellowCards: 12, redCards: 0, matchRating: 7.0),
    PlayerModel(id: 256, name: 'Kroos', shortName: 'KRO', number: 21, nationality: 'Germany', age: 35, height: 183, position: 'CM', team: 'Germany', teamLogoShort: 'GER', appearances: 110, goals: 17, assists: 20, yellowCards: 14, redCards: 0, preferredFoot: 'Left', matchRating: 7.5),
    PlayerModel(id: 257, name: 'Musiala', shortName: 'MUS', number: 10, nationality: 'Germany', age: 22, height: 184, position: 'CM', team: 'Germany', teamLogoShort: 'GER', appearances: 35, goals: 8, assists: 7, yellowCards: 2, redCards: 0, preferredFoot: 'Right', matchRating: 7.8),
    PlayerModel(id: 258, name: 'Sane', shortName: 'SAN', number: 19, nationality: 'Germany', age: 29, height: 183, position: 'LW', team: 'Germany', teamLogoShort: 'GER', appearances: 55, goals: 15, assists: 12, yellowCards: 5, redCards: 0, matchRating: 7.2),
    PlayerModel(id: 259, name: 'Wirtz', shortName: 'WIR', number: 17, nationality: 'Germany', age: 22, height: 177, position: 'RW', team: 'Germany', teamLogoShort: 'GER', appearances: 20, goals: 5, assists: 6, yellowCards: 1, redCards: 0, matchRating: 7.6),
    PlayerModel(id: 260, name: 'Fullkrug', shortName: 'FUL', number: 9, nationality: 'Germany', age: 32, height: 189, position: 'ST', team: 'Germany', teamLogoShort: 'GER', appearances: 18, goals: 8, assists: 2, yellowCards: 2, redCards: 0, matchRating: 6.9),
    PlayerModel(id: 261, name: 'Undav', shortName: 'UND', number: 14, nationality: 'Germany', age: 29, height: 179, position: 'ST', team: 'Germany', teamLogoShort: 'GER', appearances: 8, goals: 3, assists: 1, yellowCards: 1, redCards: 0),
  ];

  static PlayerModel playerById(int id) => players.firstWhere((p) => p.id == id);

  static LineupModel argentinaLineup() => LineupModel(
        formation: '4-3-3',
        coach: 'Lionel Scaloni',
        lines: [
          [playerById(1)],
          [playerById(3), playerById(6), playerById(2), playerById(4)],
          [playerById(7), playerById(5), playerById(8)],
          [playerById(11), playerById(9), playerById(10)],
        ],
        substitutes: [playerById(110), playerById(111), playerById(112)],
        injured: const ['Marcos Acuna'],
        missing: const ['Paulo Dybala'],
      );

  static LineupModel franceLineup() => LineupModel(
        formation: '4-2-3-1',
        coach: 'Didier Deschamps',
        lines: [
          [playerById(40)],
          [playerById(36), playerById(37), playerById(38), playerById(39)],
          [playerById(35), playerById(34)],
          [playerById(30), playerById(33), playerById(32)],
          [playerById(31)],
        ],
        substitutes: [playerById(120), playerById(121), playerById(122)],
        injured: const ['Mike Maignan (fitness check)'],
        missing: const [],
      );

  static LineupModel spain352Lineup() => LineupModel(
        formation: '3-5-2',
        coach: 'Luis de la Fuente',
        lines: [
          [playerById(201)],
          [playerById(202), playerById(203), playerById(204)],
          [playerById(205), playerById(207), playerById(208), playerById(209), playerById(206)],
          [playerById(210), playerById(211)],
        ],
        substitutes: [playerById(212)],
        injured: const ['Gavi'],
        missing: const [],
      );

  static LineupModel germany433Lineup() => LineupModel(
        formation: '4-3-3',
        coach: 'Julian Nagelsmann',
        lines: [
          [playerById(250)],
          [playerById(254), playerById(253), playerById(252), playerById(251)],
          [playerById(255), playerById(256), playerById(257)],
          [playerById(258), playerById(260), playerById(259)],
        ],
        substitutes: [playerById(261)],
        injured: const [],
        missing: const ['Serge Gnabry'],
      );

  static List<MatchModel> matches() {
    return [
      MatchModel(
        id: 100,
        homeTeam: teams[0],
        awayTeam: teams[2],
        homeScore: 2,
        awayScore: 1,
        status: MatchStatus.live,
        timeLabel: '67\'',
        competition: competitions[0],
        date: DateTime.now(),
        stadium: 'MetLife Stadium',
        homeLineup: argentinaLineup(),
        awayLineup: franceLineup(),
        standings: standings,
        momentumHome: 0.58,
        liveCommentary: const [
          'Argentina pressing high after the second goal.',
          'France looking for a late equalizer down the channels.',
          'Crowd noise rising — end-to-end action.',
        ],
        events: const [
          MatchEvent(minute: '12\'', type: MatchEventType.goal, playerName: 'Alvarez', assistName: 'Messi', description: 'Tap-in after a low cross', isHome: true),
          MatchEvent(minute: '18\'', type: MatchEventType.ownGoal, playerName: 'Upamecano', description: 'Deflection into own net', isHome: false),
          MatchEvent(minute: '22\'', type: MatchEventType.goal, playerName: 'Messi', assistName: 'De Paul', description: 'Left-foot finish from inside the box', isHome: true),
          MatchEvent(minute: '33\'', type: MatchEventType.varDecision, playerName: 'VAR', description: 'On-field review — no penalty', isHome: false),
          MatchEvent(minute: '40\'', type: MatchEventType.yellowCard, playerName: 'Camavinga', description: 'Late challenge in midfield', isHome: false),
          MatchEvent(minute: '52\'', type: MatchEventType.penalty, playerName: 'Mbappe', description: 'Saved by Martinez — rebound cleared', isHome: false),
          MatchEvent(minute: '61\'', type: MatchEventType.substitution, playerName: 'Thuram', description: 'Replaces Giroud', isHome: false),
          MatchEvent(minute: '64\'', type: MatchEventType.goal, playerName: 'Alvarez', assistName: 'Messi', description: 'Counter-attack finish', isHome: true),
          MatchEvent(minute: '66\'', type: MatchEventType.redCard, playerName: 'Romero', description: 'Second yellow — dismissal', isHome: true),
        ],
        stats: const [
          MatchStat(title: 'Possession', home: 56, away: 44, homeValue: '56%', awayValue: '44%'),
          MatchStat(title: 'Shots', home: 14, away: 9, homeValue: '14', awayValue: '9'),
          MatchStat(title: 'Shots on target', home: 6, away: 4, homeValue: '6', awayValue: '4'),
          MatchStat(title: 'Corners', home: 7, away: 3, homeValue: '7', awayValue: '3'),
          MatchStat(title: 'Fouls', home: 12, away: 10, homeValue: '12', awayValue: '10'),
          MatchStat(title: 'Yellow cards', home: 2, away: 3, homeValue: '2', awayValue: '3'),
          MatchStat(title: 'Red cards', home: 1, away: 0, homeValue: '1', awayValue: '0'),
          MatchStat(title: 'Pass accuracy', home: 89, away: 84, homeValue: '89%', awayValue: '84%'),
          MatchStat(title: 'Big chances', home: 3, away: 2, homeValue: '3', awayValue: '2'),
          MatchStat(title: 'Expected goals', home: 1.85, away: 1.12, homeValue: '1.85', awayValue: '1.12'),
        ],
      ),
      MatchModel(
        id: 101,
        homeTeam: teams[4],
        awayTeam: teams[1],
        homeScore: 0,
        awayScore: 0,
        status: MatchStatus.live,
        timeLabel: 'HT',
        competition: competitions[0],
        date: DateTime.now(),
        stadium: 'Lusail Stadium',
        momentumHome: 0.48,
        liveCommentary: const ['Half-time — both sides settling into shape.', 'Morocco compact in the low block.'],
      ),
      MatchModel(
        id: 102,
        homeTeam: teams[3],
        awayTeam: teams[5],
        homeScore: 0,
        awayScore: 0,
        status: MatchStatus.upcoming,
        timeLabel: '20:00',
        competition: competitions[0],
        date: DateTime.now().add(const Duration(hours: 4)),
        stadium: 'Azteca Stadium',
        homeLineup: spain352Lineup(),
        awayLineup: germany433Lineup(),
        standings: standings,
      ),
      MatchModel(id: 103, homeTeam: teams[2], awayTeam: teams[4], homeScore: 1, awayScore: 1, status: MatchStatus.finished, timeLabel: 'FT', competition: competitions[1], date: DateTime.now().subtract(const Duration(hours: 5)), stadium: 'Parc des Princes'),
    ];
  }

  static List<TeamModel> competitionTeams(int competitionId) {
    if (competitionId == 1) return teams;
    return teams.take(4).toList();
  }

  static List<PlayerModel> topScorers(int competitionId) {
    return players.where((p) => p.goals > 5).take(8).toList();
  }
}
